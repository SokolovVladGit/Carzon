import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../create_listing/domain/entities/cover_image_upload.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../bloc/edit_listing_cubit.dart';
import '../bloc/edit_listing_state.dart';

/// Owner-only edit-listing screen. Loads the target listing via
/// [EditListingCubit.load] to seed the form, then submits edits
/// through the narrow `update_listing_details` RPC. The cover image
/// can be replaced or removed via a separate narrow
/// `update_listing_cover_image` RPC; both changes are committed
/// together when the user taps Save. Status changes remain out of
/// scope here — they are owned by the existing owner-status actions
/// on My Listings.
@visibleForTesting
typedef EditListingImagePicker = Future<XFile?> Function({
  required ImageSource source,
  required double maxWidth,
  required int imageQuality,
});

/// Maps a cubit failure kind to a localized, user-facing message. Kept
/// at file scope so both the snackbar path and the form body can reuse
/// the same mapping.
String _failureMessage(AppLocalizations l10n, EditListingFailureKind? kind) {
  return switch (kind) {
    EditListingFailureKind.load => l10n.editListingLoadFailed,
    EditListingFailureKind.notAllowed => l10n.notAllowedEdit,
    EditListingFailureKind.invalidDetails => l10n.checkDetailsAndRetry,
    EditListingFailureKind.uploadFailed => l10n.coverUploadFailedRetry,
    EditListingFailureKind.coverUpdateFailed => l10n.coverUpdateFailedRetry,
    EditListingFailureKind.detailsFailed || null => l10n.listingUpdateFailedRetry,
  };
}

class EditListingPage extends StatelessWidget {
  const EditListingPage({
    super.key,
    required this.listingId,
    @visibleForTesting this.imagePicker,
  });

  final String listingId;

  /// Test seam: overrides the default `ImagePicker().pickImage` call
  /// so widget tests can simulate gallery selection without touching
  /// platform channels.
  @visibleForTesting
  final EditListingImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditListingCubit>()..load(listingId),
      child: _EditListingView(
        listingId: listingId,
        imagePicker: imagePicker,
      ),
    );
  }
}

class _EditListingView extends StatelessWidget {
  const _EditListingView({required this.listingId, this.imagePicker});

  final String listingId;
  final EditListingImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.myListings),
        title: Text(l10n.editListingTitle),
      ),
      body: BlocConsumer<EditListingCubit, EditListingState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            (curr.status == EditListingStatus.success ||
                (curr.status == EditListingStatus.failure &&
                    curr.listing != null)),
        listener: (context, state) {
          if (state.status == EditListingStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.listingUpdated)),
            );
            // The app routes with `context.go`, so navigate back to
            // My Listings explicitly. That also re-creates the page
            // and its cubit, which naturally reloads the (now
            // updated) rows.
            context.go(AppRoutes.myListings);
          } else if (state.status == EditListingStatus.failure &&
              state.listing != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_failureMessage(l10n, state.failureKind)),
              ),
            );
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case EditListingStatus.initial:
            case EditListingStatus.loading:
              return const LoadingView();
            case EditListingStatus.failure:
              // Load failure: no listing seeded → show the error view.
              if (state.listing == null) {
                return ErrorView(
                  message: l10n.editListingLoadFailed,
                  onRetry: () =>
                      context.read<EditListingCubit>().load(listingId),
                );
              }
              // Save failure with a seeded listing → fall through to
              // the form (snackbar already shown by the listener).
              return _EditListingForm(
                listing: state.listing!,
                submitting: false,
                pendingCoverReplacement: state.pendingCoverReplacement,
                pendingCoverRemoval: state.pendingCoverRemoval,
                imagePicker: imagePicker,
              );
            case EditListingStatus.ready:
              return _EditListingForm(
                listing: state.listing!,
                submitting: false,
                pendingCoverReplacement: state.pendingCoverReplacement,
                pendingCoverRemoval: state.pendingCoverRemoval,
                imagePicker: imagePicker,
              );
            case EditListingStatus.submitting:
              return _EditListingForm(
                listing: state.listing!,
                submitting: true,
                pendingCoverReplacement: state.pendingCoverReplacement,
                pendingCoverRemoval: state.pendingCoverRemoval,
                imagePicker: imagePicker,
              );
            case EditListingStatus.success:
              // The listener navigates away; rendering the spinner
              // keeps the UI stable for the frame between success
              // emission and pop/go.
              return const LoadingView();
          }
        },
      ),
    );
  }
}

class _EditListingForm extends StatefulWidget {
  const _EditListingForm({
    required this.listing,
    required this.submitting,
    required this.pendingCoverReplacement,
    required this.pendingCoverRemoval,
    this.imagePicker,
  });

  final Listing listing;
  final bool submitting;
  final CoverImageUpload? pendingCoverReplacement;
  final bool pendingCoverRemoval;
  final EditListingImagePicker? imagePicker;

  @override
  State<_EditListingForm> createState() => _EditListingFormState();
}

class _EditListingFormState extends State<_EditListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _price;
  late final TextEditingController _mileage;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;
  late ListingType _type;
  late MarketRegion _marketRegion;
  late bool _whatsappEnabled;

  final ImagePicker _defaultPicker = ImagePicker();
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _title = TextEditingController(text: l.title);
    _make = TextEditingController(text: l.make);
    _model = TextEditingController(text: l.model);
    _year = TextEditingController(text: l.year.toString());
    _price = TextEditingController(text: _priceText(l.priceEur));
    _mileage = TextEditingController(text: l.mileageKm.toString());
    _city = TextEditingController(text: l.city);
    _phone = TextEditingController(text: l.contactPhone ?? '');
    _telegram = TextEditingController(text: l.telegramUsername ?? '');
    _type = l.type;
    _marketRegion = l.marketRegion;
    _whatsappEnabled = l.whatsappEnabled;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _make,
      _model,
      _year,
      _price,
      _mileage,
      _city,
      _phone,
      _telegram,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Numeric price shown in the field. We avoid trailing `.00` on
  /// whole-euro amounts so the input looks like what the seller
  /// originally typed.
  static String _priceText(num value) {
    if (value is int) return value.toString();
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }

  String? _required(AppLocalizations l10n, String? v) =>
      (v == null || v.trim().isEmpty) ? l10n.validationRequired : null;

  String? _validateYear(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    final n = int.tryParse(v.trim());
    final maxYear = DateTime.now().year + 1;
    if (n == null || n < 1900 || n > maxYear) {
      return l10n.validationYearRange(maxYear);
    }
    return null;
  }

  String? _validatePrice(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    final n = num.tryParse(v.trim());
    if (n == null || n < 0) return l10n.validationNonNegative;
    return null;
  }

  String? _validateMileage(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return l10n.validationNonNegative;
    return null;
  }

  Future<void> _pickCoverImage() async {
    if (_pickingImage || widget.submitting) return;
    final sellerId = widget.listing.sellerId;
    if (sellerId == null || sellerId.isEmpty) {
      // Defensive guard — the edit page is only reachable for the
      // signed-in owner of the listing, so this should not occur in
      // practice. Failing silently is better than uploading a file
      // with an empty owner segment that storage would reject.
      return;
    }
    setState(() => _pickingImage = true);
    try {
      final picker = widget.imagePicker ?? _defaultPicker.pickImage;
      final picked = await picker(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final upload = CoverImageUpload(
        sellerId: sellerId,
        bytes: bytes,
        contentType: _resolveContentType(picked),
        originalFileName: picked.name,
      );
      context.read<EditListingCubit>().stageCoverReplacement(upload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imageLoadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeCover() {
    if (widget.submitting) return;
    context.read<EditListingCubit>().stageCoverRemoval();
  }

  void _undoCoverChange() {
    if (widget.submitting) return;
    context.read<EditListingCubit>().clearCoverChange();
  }

  /// Falls back to `image/jpeg` if the platform did not report a
  /// MIME type on the picked XFile. The data layer normalizes the
  /// same way, so the fallback is safe.
  String _resolveContentType(XFile file) {
    final reported = file.mimeType?.trim().toLowerCase();
    if (reported != null && reported.isNotEmpty) return reported;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final input = EditListingInput(
      listingId: widget.listing.id,
      title: _title.text.trim(),
      make: _make.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text.trim()),
      priceEur: num.parse(_price.text.trim()),
      mileageKm: int.parse(_mileage.text.trim()),
      type: _type,
      city: _city.text.trim(),
      marketRegion: _marketRegion,
      contactPhone: _phone.text.trim(),
      telegramUsername: normalizeTelegramUsername(_telegram.text),
      whatsappEnabled: _whatsappEnabled,
    );
    context.read<EditListingCubit>().save(input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final submitting = widget.submitting;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.fieldTitle),
              validator: (v) => _required(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _make,
              decoration: InputDecoration(labelText: l10n.fieldMake),
              validator: (v) => _required(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: InputDecoration(labelText: l10n.fieldModel),
              validator: (v) => _required(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _year,
              decoration: InputDecoration(labelText: l10n.fieldYear),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _validateYear(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(labelText: l10n.fieldPriceEur),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => _validatePrice(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileage,
              decoration: InputDecoration(labelText: l10n.fieldMileageKm),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _validateMileage(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ListingType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.fieldType),
              items: [
                DropdownMenuItem(
                  value: ListingType.sale,
                  child: Text(l10n.formatTypeSale),
                ),
                DropdownMenuItem(
                  value: ListingType.exchange,
                  child: Text(l10n.formatTypeExchange),
                ),
                DropdownMenuItem(
                  value: ListingType.both,
                  child: Text(l10n.formatTypeBoth),
                ),
              ],
              onChanged: submitting
                  ? null
                  : (v) => setState(() => _type = v ?? ListingType.sale),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MarketRegion>(
              initialValue: _marketRegion,
              decoration: InputDecoration(labelText: l10n.fieldRegion),
              items: [
                DropdownMenuItem(
                  value: MarketRegion.transnistria,
                  child: Text(l10n.regionTransnistria),
                ),
                DropdownMenuItem(
                  value: MarketRegion.moldova,
                  child: Text(l10n.regionMoldova),
                ),
              ],
              onChanged: submitting
                  ? null
                  : (v) => setState(
                      () => _marketRegion = v ?? MarketRegion.transnistria),
              validator: (v) => v == null ? l10n.regionRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(labelText: l10n.fieldCity),
              validator: (v) => _required(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 16),
            const PublicContactNotice(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                labelText: l10n.fieldPhone,
                hintText: l10n.fieldPhoneHint,
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => validatePhone(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telegram,
              decoration: InputDecoration(
                labelText: l10n.fieldTelegram,
                hintText: l10n.fieldTelegramHint,
              ),
              validator: (v) => validateTelegramUsername(l10n, v),
              enabled: !submitting,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.whatsappToggle),
              value: _whatsappEnabled,
              onChanged: submitting
                  ? null
                  : (v) => setState(() => _whatsappEnabled = v),
            ),
            const SizedBox(height: 16),
            _CoverEditor(
              existingUrl: widget.listing.coverImageUrl,
              pendingReplacement: widget.pendingCoverReplacement,
              pendingRemoval: widget.pendingCoverRemoval,
              picking: _pickingImage,
              disabled: submitting,
              onPick: _pickCoverImage,
              onRemove: _removeCover,
              onUndo: _undoCoverChange,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit-listing cover photo editor.
///
/// Rendering rules (only one branch is active at a time):
///   * pending replacement picked → preview the picked bytes and
///     offer `Change photo` / `Cancel change` actions
///   * pending removal flagged → show a "will be removed on save"
///     notice and offer `Cancel removal`
///   * existing cover URL present (and no staged change) → preview
///     the existing URL and offer `Replace photo` / `Remove photo`
///   * no existing cover URL (and no staged change) → show the
///     `Add photo` placeholder tile
class _CoverEditor extends StatelessWidget {
  const _CoverEditor({
    required this.existingUrl,
    required this.pendingReplacement,
    required this.pendingRemoval,
    required this.picking,
    required this.disabled,
    required this.onPick,
    required this.onRemove,
    required this.onUndo,
  });

  final String? existingUrl;
  final CoverImageUpload? pendingReplacement;
  final bool pendingRemoval;
  final bool picking;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tapDisabled = disabled || picking;

    Widget preview;
    final actions = <Widget>[];

    if (pendingReplacement != null) {
      preview = _MemoryPreview(bytes: pendingReplacement!.bytes);
      actions.addAll([
        TextButton.icon(
          onPressed: tapDisabled ? null : onPick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.coverChangePhoto),
        ),
        TextButton.icon(
          onPressed: tapDisabled ? null : onUndo,
          icon: const Icon(Icons.undo),
          label: Text(l10n.coverCancelChange),
        ),
      ]);
    } else if (pendingRemoval) {
      preview = _RemovalPlaceholder(theme: theme);
      actions.add(
        TextButton.icon(
          onPressed: tapDisabled ? null : onUndo,
          icon: const Icon(Icons.undo),
          label: Text(l10n.coverCancelRemoval),
        ),
      );
    } else if (existingUrl != null && existingUrl!.trim().isNotEmpty) {
      preview = _NetworkPreview(url: existingUrl!);
      actions.addAll([
        TextButton.icon(
          onPressed: tapDisabled ? null : onPick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.coverReplacePhoto),
        ),
        TextButton.icon(
          onPressed: tapDisabled ? null : onRemove,
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.coverRemovePhoto),
        ),
      ]);
    } else {
      preview = _EmptyPlaceholder(
        theme: theme,
        picking: picking,
        onTap: tapDisabled ? null : onPick,
      );
      actions.add(
        TextButton.icon(
          onPressed: tapDisabled ? null : onPick,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(l10n.coverAddPhoto),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.coverPhotoLabel,
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: preview,
          ),
        ),
        if (pendingRemoval) ...[
          const SizedBox(height: 6),
          Text(
            l10n.coverWillBeRemovedNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (pendingReplacement != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.coverWillBeReplacedNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: actions),
      ],
    );
  }
}

class _MemoryPreview extends StatelessWidget {
  const _MemoryPreview({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(bytes, fit: BoxFit.cover);
  }
}

class _NetworkPreview extends StatelessWidget {
  const _NetworkPreview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _RemovalPlaceholder extends StatelessWidget {
  const _RemovalPlaceholder({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: theme.colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 32,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.coverPlaceholderWillBeRemoved,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({
    required this.theme,
    required this.picking,
    required this.onTap,
  });

  final ThemeData theme;
  final bool picking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: picking
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.coverAddPhoto,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
