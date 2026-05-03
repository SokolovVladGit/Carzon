import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/top_level_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/validation/listing_valid_years.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../models/create_listing_photo_draft.dart';
import '../widgets/create_listing_media_section.dart';

/// English catalog sentinel — persisted in `make` when the seller picks «Other» without text.
final String _kListingBrandCatalogOther = kListingBrandCatalog.last; // "Other"

String _localizedBrandCatalogLabel(AppLocalizations l10n, String catalogValue) {
  return catalogValue == _kListingBrandCatalogOther
      ? l10n.createListingBrandOther
      : catalogValue;
}

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
      appBar: AppBar(title: Text(l10n.createListingTitle)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState.status != AuthStatus.authenticated ||
              authState.user == null) {
            return _SignInRequired(
              onSignIn: () => context.go(AppRoutes.signIn),
            );
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
            const Icon(Icons.lock_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(l10n.createListingSignInRequired, textAlign: TextAlign.center),
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

  /// Brand row — validates against [_selectedBrand].
  final GlobalKey<FormFieldState<String?>> _brandFieldKey =
      GlobalKey<FormFieldState<String?>>();

  /// Year picker — validates against internal value managed by FormField only.
  final GlobalKey<FormFieldState<int?>> _yearFieldKey =
      GlobalKey<FormFieldState<int?>>();

  final _title = TextEditingController();
  final _model = TextEditingController();
  final _customBrand = TextEditingController();

  /// Free-text controllers preserved from the legacy layout.
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();

  bool _whatsappEnabled = false;
  ListingType _type = ListingType.sale;

  MarketRegion _marketRegion = MarketRegion.transnistria;

  ListingCurrency _priceCurrency = ListingCurrency.eur;
  String? _selectedBrandCatalogValue;

  final List<CreateListingPhotoDraft> _photoDrafts = [];

  final ImagePicker _picker = ImagePicker();

  bool _pickingImage = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _model,
      _customBrand,
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

  String _effectiveMakeForSubmit() {
    final brandKey = _selectedBrandCatalogValue;
    if (brandKey == null) return '';
    if (brandKey == _kListingBrandCatalogOther) {
      final trimmed = _customBrand.text.trim();
      return trimmed.isNotEmpty ? trimmed : _kListingBrandCatalogOther;
    }
    return brandKey;
  }

  Future<void> _addPhoto(BuildContext outerContext) async {
    final l10n = outerContext.l10n;

    if (_photoDrafts.length >= kMaxListingPhotos) {
      ScaffoldMessenger.maybeOf(outerContext)?.showSnackBar(
        SnackBar(content: Text(l10n.createListingMaxPhotos(kMaxListingPhotos))),
      );
      return;
    }

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
        _photoDrafts.add(
          CreateListingPhotoDraft(
            bytes: bytes,
            contentType: _resolveContentType(picked),
            fileName: picked.name,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.imagePickerLoadFailed)));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removePhotoAt(int index) {
    setState(() {
      if (index < 0 || index >= _photoDrafts.length) return;
      _photoDrafts.removeAt(index);
    });
  }

  String _resolveContentType(XFile file) {
    final reported = file.mimeType?.trim().toLowerCase();
    if (reported != null && reported.isNotEmpty) return reported;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _openBrandSheet() async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _BrandCatalogPickSheet(appL10n: l10n),
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedBrandCatalogValue = picked;
      if (picked != _kListingBrandCatalogOther) {
        _customBrand.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _brandFieldKey.currentState?.didChange(_selectedBrandCatalogValue);
      _brandFieldKey.currentState?.validate();
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final input = NewListingInput(
      sellerId: widget.sellerId,
      title: _title.text.trim(),
      make: _effectiveMakeForSubmit(),
      model: _model.text.trim(),
      year: _yearFieldKey.currentState!.value!,
      priceEur: num.parse(_price.text.trim()),
      priceCurrency: _priceCurrency,
      mileageKm: int.parse(_mileage.text.trim()),
      type: _type,
      city: _city.text.trim(),
      marketRegion: _marketRegion,
      contactPhone: _phone.text.trim(),
      telegramUsername: normalizeTelegramUsername(_telegram.text),
      whatsappEnabled: _whatsappEnabled,
    );

    final uploads = [
      for (final d in _photoDrafts)
        CoverImageUpload(
          sellerId: widget.sellerId,
          bytes: d.bytes,
          contentType: d.contentType,
          originalFileName: d.fileName,
        ),
    ];

    context.read<CreateListingCubit>().submit(
      listingInput: input,
      orderedPhotos: uploads,
    );
  }

  String? _required(AppLocalizations l10n, String? v) =>
      (v == null || v.trim().isEmpty) ? l10n.validationRequired : null;

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

  Widget _mutedSectionLabel(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _elevatedSheet(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<CreateListingCubit, CreateListingState>(
      listener: (context, state) {
        if (state.status == CreateListingStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.listingCreated)));
          context.go(AppRoutes.listings);
        } else if (state.status == CreateListingStatus.failure) {
          final message = switch (state.failureKind) {
            CreateListingFailureKind.upload =>
              l10n.createListingPhotosUploadFailed,
            CreateListingFailureKind.sessionExpired =>
              l10n.listingCreateSessionExpired,
            CreateListingFailureKind.serviceUnavailable =>
              l10n.listingCreateServiceUnavailable,
            CreateListingFailureKind.validationRejected =>
              l10n.checkDetailsAndRetry,
            CreateListingFailureKind.genericCreate =>
              l10n.listingCreateFailedRetry,
            null => l10n.listingCreateFailedRetry,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final submitting = state.status == CreateListingStatus.submitting;

        final brandDisplay = _selectedBrandCatalogValue == null
            ? l10n.createListingChooseBrand
            : _localizedBrandCatalogLabel(l10n, _selectedBrandCatalogValue!);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            16,
            kFloatingCapsuleNavClearance,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _elevatedSheet(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingMediaSection(
                        photos: _photoDrafts,
                        pickingImage: _pickingImage,
                        disabled: submitting,
                        onAddPhoto: () => _addPhoto(context),
                        onRemovePhotoAt: _removePhotoAt,
                      ),
                      const SizedBox(height: 22),
                      _mutedSectionLabel(context, l10n.fieldTitle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _title,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _elevatedSheet(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mutedSectionLabel(context, l10n.fieldCity),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _city,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 18),
                      FormField<String?>(
                        key: _brandFieldKey,
                        validator: (_) {
                          return _selectedBrandCatalogValue == null
                              ? l10n.validationRequired
                              : null;
                        },
                        builder: (fieldState) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            key: const ValueKey('create_listing_brand_field'),
                            onTap: submitting
                                ? null
                                : () async {
                                    await _openBrandSheet();
                                    fieldState.didChange(
                                      _selectedBrandCatalogValue,
                                    );
                                  },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface.withValues(
                                  alpha: .22,
                                ),
                                labelText: l10n.createListingBrandLabel,
                                errorText: fieldState.errorText,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  brandDisplay,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_selectedBrandCatalogValue ==
                          _kListingBrandCatalogOther) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _customBrand,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            hintText: l10n.createListingCustomBrandHint,
                            fillColor: theme.colorScheme.surface.withValues(
                              alpha: .22,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          enabled: !submitting,
                        ),
                      ],

                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _model,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldModel,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),

                      const SizedBox(height: 18),
                      FormField<int?>(
                        key: _yearFieldKey,
                        initialValue: null,
                        validator: (y) =>
                            y == null ? l10n.validationRequired : null,
                        builder: (fieldState) {
                          final yr = fieldState.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            key: const ValueKey('create_listing_year_field'),
                            onTap: submitting
                                ? null
                                : () async {
                                    final picked =
                                        await showModalBottomSheet<int>(
                                          context: context,
                                          showDragHandle: true,
                                          builder: (sheetCtx) => SafeArea(
                                            child: _YearPickSheet(
                                              appL10n: l10n,
                                            ),
                                          ),
                                        );
                                    if (!context.mounted) return;
                                    if (picked != null) {
                                      fieldState.didChange(picked);
                                      fieldState.validate();
                                    }
                                  },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface.withValues(
                                  alpha: .22,
                                ),
                                labelText: l10n.createListingYearLabel,
                                errorText: fieldState.errorText,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  yr == null
                                      ? l10n.createListingChooseYear
                                      : '$yr',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),
                      DropdownButtonFormField<ListingType>(
                        initialValue: _type,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldType,
                        ),
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
                            : (v) =>
                                  setState(() => _type = v ?? ListingType.sale),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<MarketRegion>(
                        initialValue: _marketRegion,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldRegion,
                        ),
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
                                () => _marketRegion =
                                    v ?? MarketRegion.transnistria,
                              ),
                        validator: (v) =>
                            v == null ? l10n.regionRequired : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _elevatedSheet(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _mutedSectionLabel(context, l10n.createListingCurrency),
                      const SizedBox(height: 10),
                      SegmentedButton<ListingCurrency>(
                        key: const ValueKey('create_listing_currency_selector'),
                        emptySelectionAllowed: false,
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        segments: [
                          ButtonSegment<ListingCurrency>(
                            value: ListingCurrency.eur,
                            label: Text(l10n.currencyCodeEur),
                          ),
                          ButtonSegment<ListingCurrency>(
                            value: ListingCurrency.usd,
                            label: Text(l10n.currencyCodeUsd),
                          ),
                        ],
                        selected: {_priceCurrency},
                        onSelectionChanged: submitting
                            ? null
                            : (next) =>
                                  setState(() => _priceCurrency = next.single),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _price,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.createListingPriceAmount,
                          hintText:
                              '${l10n.createListingCurrency} ${_priceCurrency == ListingCurrency.eur ? '€' : '\$'}',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => _validatePrice(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _mileage,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldMileageKm,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => _validateMileage(l10n, v),
                        enabled: !submitting,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _elevatedSheet(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.publishListing.toUpperCase(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const PublicContactNotice(),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldPhone,
                          hintText: l10n.fieldPhoneHint,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => validatePhone(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _telegram,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface.withValues(
                            alpha: .22,
                          ),
                          labelText: l10n.fieldTelegram,
                          hintText: l10n.fieldTelegramHint,
                        ),
                        validator: (v) => validateTelegramUsername(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.whatsappToggle),
                        value: _whatsappEnabled,
                        onChanged: submitting
                            ? null
                            : (v) => setState(() => _whatsappEnabled = v),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: StadiumBorder(),
                        ),
                        onPressed: submitting ? null : _submit,
                        child: submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.publishListing),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandCatalogPickSheet extends StatefulWidget {
  const _BrandCatalogPickSheet({required this.appL10n});

  final AppLocalizations appL10n;

  @override
  State<_BrandCatalogPickSheet> createState() => _BrandCatalogPickSheetState();
}

class _BrandCatalogPickSheetState extends State<_BrandCatalogPickSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.appL10n;
    final q = _query.text.trim().toLowerCase();

    final filtered = kListingBrandCatalog
        .where(
          (b) =>
              q.isEmpty ||
              _localizedBrandCatalogLabel(l10n, b).toLowerCase().contains(q),
        )
        .toList(growable: false);

    return AnimatedPadding(
      duration: Duration.zero,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.createListingChooseBrand,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commonCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.createListingSearchBrandsHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: .5,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final brandEnglish = filtered[index];
                  final label = _localizedBrandCatalogLabel(l10n, brandEnglish);
                  return ListTile(
                    title: Text(label),
                    onTap: () => Navigator.pop(context, brandEnglish),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearPickSheet extends StatelessWidget {
  const _YearPickSheet({required this.appL10n});

  final AppLocalizations appL10n;

  @override
  Widget build(BuildContext context) {
    final years = listingYearsOrderedNewestFirst();
    final newest = years.first;
    final theme = Theme.of(context);
    final listHeight = MediaQuery.sizeOf(context).height * .5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  appL10n.createListingChooseYear,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: appL10n.commonDone,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.done_rounded),
              ),
            ],
          ),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 28),
            itemCount: years.length,
            itemBuilder: (_, i) {
              final yr = years[i];
              return ListTile(
                title: Text('$yr'),
                trailing: yr == newest
                    ? Text(
                        '•',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
                onTap: () => Navigator.pop(context, yr),
              );
            },
          ),
        ),
      ],
    );
  }
}
