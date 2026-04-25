import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';

class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateListingCubit>(),
      child: const _CreateListingView(),
    );
  }
}

class _CreateListingView extends StatelessWidget {
  const _CreateListingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TopLevelScaffold(
      destination: TopLevelDestination.createListing,
      appBar: AppBar(
        title: Text(l10n.createListingTitle),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated || authState.user == null) {
            return _SignInRequired(onSignIn: () => context.go(AppRoutes.signIn));
          }
          return _CreateListingForm(sellerId: authState.user!.id);
        },
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.createListingSignInRequired,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSignIn, child: Text(l10n.commonSignIn)),
          ],
        ),
      ),
    );
  }
}

class _CreateListingForm extends StatefulWidget {
  const _CreateListingForm({required this.sellerId});
  final String sellerId;

  @override
  State<_CreateListingForm> createState() => _CreateListingFormState();
}

class _CreateListingFormState extends State<_CreateListingForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();
  bool _whatsappEnabled = false;
  ListingType _type = ListingType.sale;
  // Default to Transnistria — the cold-start launch wedge. Sellers outside
  // of Transnistria must change this explicitly.
  MarketRegion _marketRegion = MarketRegion.transnistria;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _coverBytes;
  String? _coverContentType;
  String? _coverFileName;
  bool _pickingImage = false;

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

  Future<void> _pickCoverImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _coverBytes = bytes;
        _coverContentType = _resolveContentType(picked);
        _coverFileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.imageLoadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeCoverImage() {
    setState(() {
      _coverBytes = null;
      _coverContentType = null;
      _coverFileName = null;
    });
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
    final input = NewListingInput(
      sellerId: widget.sellerId,
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
    final bytes = _coverBytes;
    final cover = bytes == null
        ? null
        : CoverImageUpload(
            sellerId: widget.sellerId,
            bytes: bytes,
            contentType: _coverContentType ?? 'image/jpeg',
            originalFileName: _coverFileName,
          );
    context.read<CreateListingCubit>().submit(input, coverImage: cover);
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
    if (n == null || n <= 0) return l10n.validationPositive;
    return null;
  }

  String? _validateMileage(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return l10n.validationNonNegative;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<CreateListingCubit, CreateListingState>(
      listener: (context, state) {
        if (state.status == CreateListingStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.listingCreated)),
          );
          context.go(AppRoutes.listings);
        } else if (state.status == CreateListingStatus.failure) {
          final message = switch (state.failureKind) {
            CreateListingFailureKind.upload => l10n.coverUploadFailedRetry,
            CreateListingFailureKind.create ||
            null =>
              l10n.listingCreateFailedRetry,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == CreateListingStatus.submitting;
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
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _make,
                  decoration: InputDecoration(labelText: l10n.fieldMake),
                  validator: (v) => _required(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model,
                  decoration: InputDecoration(labelText: l10n.fieldModel),
                  validator: (v) => _required(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _year,
                  decoration: InputDecoration(labelText: l10n.fieldYear),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validateYear(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  decoration: InputDecoration(labelText: l10n.fieldPriceEur),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => _validatePrice(l10n, v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mileage,
                  decoration: InputDecoration(labelText: l10n.fieldMileageKm),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validateMileage(l10n, v),
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
                _CoverPhotoPicker(
                  bytes: _coverBytes,
                  picking: _pickingImage,
                  disabled: submitting,
                  onPick: _pickCoverImage,
                  onRemove: _removeCoverImage,
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
                      : Text(l10n.publishListing),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// MVP cover photo picker — single image, preview with remove action,
/// or a placeholder tile that opens the gallery. Intentionally simple:
/// no multi-image gallery, no cropping, no compression. The `disabled`
/// flag is the submitting state from the cubit.
class _CoverPhotoPicker extends StatelessWidget {
  const _CoverPhotoPicker({
    required this.bytes,
    required this.picking,
    required this.disabled,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final bool picking;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasImage = bytes != null;
    final tapDisabled = disabled || picking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.coverPhotoOptional,
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: hasImage || tapDisabled ? null : onPick,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            onPressed: tapDisabled ? null : onRemove,
                            icon: const Icon(Icons.close),
                            tooltip: l10n.coverRemoveTooltip,
                          ),
                        ),
                      ],
                    )
                  : Center(
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
          ),
        ),
      ],
    );
  }
}
