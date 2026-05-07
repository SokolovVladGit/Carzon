import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/validation/listing_valid_years.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../models/create_listing_photo_draft.dart';
import '../widgets/create_listing_compose_layout.dart';
import '../widgets/create_listing_media_section.dart';

/// Extra scroll padding below the publish section beyond the device bottom inset.
const double _kCreateListingScrollBottomExtra = 30;

/// Minimum bottom inset for scroll padding when the OS reports no bottom safe area.
const double _kCreateListingScrollBottomInsetFloor = 14;

/// Wraps a concrete body-type choice so sheet dismissal (`null`) stays distinct.
class _BodyTypeSelection {
  const _BodyTypeSelection(this.value);
  final ListingBodyType? value;
}

InputDecoration _createListingFieldDecoration(
  ThemeData theme, {
  String? labelText,
  String? hintText,
}) {
  final cs = theme.colorScheme;
  final br = theme.brightness;
  final radius = BorderRadius.circular(16);
  final fillBase = br == Brightness.light
      ? cs.surface
      : cs.surfaceContainerLowest;
  final subtleFill = Color.alphaBlend(
    cs.outlineVariant.withValues(alpha: br == Brightness.light ? 0.055 : 0.10),
    fillBase,
  );
  final focusBorderColor = cs.onSurface.withValues(
    alpha: br == Brightness.light ? 0.34 : 0.42,
  );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    floatingLabelBehavior: labelText != null
        ? FloatingLabelBehavior.auto
        : FloatingLabelBehavior.never,
    labelStyle: TextStyle(
      color: cs.onSurfaceVariant.withValues(alpha: 0.94),
      fontWeight: FontWeight.w500,
    ),
    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.74)),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: cs.outlineVariant.withValues(
          alpha: br == Brightness.light ? 0.36 : 0.40,
        ),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: focusBorderColor, width: 1.12),
    ),
    errorBorder: OutlineInputBorder(borderRadius: radius),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: cs.error, width: 1.22),
    ),
    filled: true,
    fillColor: subtleFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
  );
}

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createListingTitle),
        leading: const AppBackButton(fallback: AppRoutes.listings),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
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

  ListingBodyType? _bodyType;

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

  Future<void> _openBodyTypeSheet() async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<_BodyTypeSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _ListingBodyTypePickSheet(appL10n: l10n, selected: _bodyType),
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() => _bodyType = picked.value);
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
      bodyType: _bodyType,
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
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            math.max(
                  MediaQuery.paddingOf(context).bottom,
                  _kCreateListingScrollBottomInsetFloor,
                ) +
                _kCreateListingScrollBottomExtra,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreateListingComposeIntro(l10n: l10n),
                const SizedBox(height: 8),
                CreateListingPremiumSection(
                  tone: CreateListingSectionTone.hero,
                  title: l10n.createListingSectionPhotosLead,
                  subtitle: l10n.createListingSectionPhotosLeadSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingMediaSection(
                        photos: _photoDrafts,
                        pickingImage: _pickingImage,
                        disabled: submitting,
                        onAddPhoto: () => _addPhoto(context),
                        onRemovePhotoAt: _removePhotoAt,
                        showHeading: false,
                      ),
                      const SizedBox(height: 24),
                      CreateListingFieldLabel(l10n.fieldTitle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _title,
                        decoration: _createListingFieldDecoration(theme),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                CreateListingPremiumSection(
                  tone: CreateListingSectionTone.identity,
                  title: l10n.createListingSectionVehicle,
                  subtitle: l10n.createListingSectionVehicleSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingFieldLabel(l10n.fieldCity),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _city,
                        decoration: _createListingFieldDecoration(theme),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 20),
                      FormField<String?>(
                        key: _brandFieldKey,
                        validator: (_) {
                          return _selectedBrandCatalogValue == null
                              ? l10n.validationRequired
                              : null;
                        },
                        builder: (fieldState) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            key: const ValueKey('create_listing_brand_field'),
                            splashColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            highlightColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.02),
                            onTap: submitting
                                ? null
                                : () async {
                                    await _openBrandSheet();
                                    fieldState.didChange(
                                      _selectedBrandCatalogValue,
                                    );
                                  },
                            child: InputDecorator(
                              decoration: _createListingFieldDecoration(
                                theme,
                                labelText: l10n.createListingBrandLabel,
                              ).copyWith(errorText: fieldState.errorText),
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
                          decoration: _createListingFieldDecoration(
                            theme,
                            hintText: l10n.createListingCustomBrandHint,
                          ),
                          textInputAction: TextInputAction.next,
                          enabled: !submitting,
                        ),
                      ],

                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _model,
                        decoration: _createListingFieldDecoration(
                          theme,
                          labelText: l10n.fieldModel,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),

                      const SizedBox(height: 20),
                      FormField<int?>(
                        key: _yearFieldKey,
                        initialValue: null,
                        validator: (y) =>
                            y == null ? l10n.validationRequired : null,
                        builder: (fieldState) {
                          final yr = fieldState.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            key: const ValueKey('create_listing_year_field'),
                            splashColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            highlightColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.02),
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
                              decoration: _createListingFieldDecoration(
                                theme,
                                labelText: l10n.createListingYearLabel,
                              ).copyWith(errorText: fieldState.errorText),
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
                      const SizedBox(height: 20),
                      CreateListingFieldLabel(l10n.listingBodyTypeSectionTitle),
                      const SizedBox(height: 6),
                      Text(
                        l10n.listingBodyTypeSectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('create_listing_body_type_field'),
                          borderRadius: BorderRadius.circular(16),
                          splashColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.038,
                          ),
                          highlightColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.018),
                          onTap: submitting ? null : _openBodyTypeSheet,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(
                                      alpha:
                                          theme.brightness == Brightness.light
                                          ? 0.32
                                          : 0.38,
                                    ),
                              ),
                              color: Color.alphaBlend(
                                theme.colorScheme.outlineVariant.withValues(
                                  alpha: theme.brightness == Brightness.light
                                      ? 0.042
                                      : 0.078,
                                ),
                                theme.colorScheme.surface,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _bodyType == null
                                        ? l10n.listingBodyTypeNotSpecified
                                        : formatListingBodyType(
                                            l10n,
                                            _bodyType!,
                                          ),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.22,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.94),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Color.alphaBlend(
                                      theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.11),
                                      theme.colorScheme.surface,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.26),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(
                                      Icons.expand_more_rounded,
                                      size: 20,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                CreateListingPremiumSection(
                  tone: CreateListingSectionTone.placement,
                  title: l10n.createListingSectionDeal,
                  subtitle: l10n.createListingSectionDealSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingFieldLabel(l10n.fieldType),
                      const SizedBox(height: 12),
                      _ListingTypeDealSelector(
                        l10n: l10n,
                        theme: theme,
                        value: _type,
                        submitting: submitting,
                        onChanged: (t) => setState(() => _type = t),
                      ),
                      const SizedBox(height: 24),
                      CreateListingFieldLabel(l10n.fieldRegion),
                      const SizedBox(height: 12),
                      _MarketPlacementSelector(
                        l10n: l10n,
                        theme: theme,
                        value: _marketRegion,
                        submitting: submitting,
                        onChanged: (r) => setState(() => _marketRegion = r),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                CreateListingPremiumSection(
                  tone: CreateListingSectionTone.metrics,
                  title: l10n.createListingSectionPrice,
                  subtitle: l10n.createListingSectionPriceSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.createListingCurrency,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PremiumListingCurrencyBar(
                        key: const ValueKey('create_listing_currency_selector'),
                        theme: theme,
                        enabled: !submitting,
                        selected: _priceCurrency,
                        eurLabel: l10n.currencyCodeEur,
                        usdLabel: l10n.currencyCodeUsd,
                        onChanged: (c) => setState(() => _priceCurrency = c),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _price,
                        decoration: _createListingFieldDecoration(
                          theme,
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mileage,
                        decoration: _createListingFieldDecoration(
                          theme,
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

                const SizedBox(height: 28),

                CreateListingPremiumSection(
                  tone: CreateListingSectionTone.finale,
                  kicker: l10n.createListingPublishKicker,
                  title: l10n.createListingSectionPublish,
                  subtitle: l10n.createListingSectionPublishSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PublicContactNotice(),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _phone,
                        decoration: _createListingFieldDecoration(
                          theme,
                          labelText: l10n.fieldPhone,
                          hintText: l10n.fieldPhoneHint,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => validatePhone(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telegram,
                        decoration: _createListingFieldDecoration(
                          theme,
                          labelText: l10n.fieldTelegram,
                          hintText: l10n.fieldTelegramHint,
                        ),
                        validator: (v) => validateTelegramUsername(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 4),
                      _PremiumWhatsAppToggleRow(
                        theme: theme,
                        l10n: l10n,
                        value: _whatsappEnabled,
                        submitting: submitting,
                        onChanged: (v) => setState(() => _whatsappEnabled = v),
                      ),
                      const SizedBox(height: 24),
                      _PremiumPublishActionButton(
                        theme: theme,
                        l10n: l10n,
                        submitting: submitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Modal picker for optional listing body type; pops [_BodyTypeSelection] on tap.
class _ListingBodyTypePickSheet extends StatelessWidget {
  const _ListingBodyTypePickSheet({
    required this.appL10n,
    required this.selected,
  });

  final AppLocalizations appL10n;
  final ListingBodyType? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final items = <({ListingBodyType? value, String label})>[
      (value: null, label: appL10n.listingBodyTypeNotSpecified),
      ...ListingBodyType.values.map(
        (e) => (value: e, label: formatListingBodyType(appL10n, e)),
      ),
    ];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appL10n.listingBodyTypeSectionTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: appL10n.commonCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: items.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSel = item.value == selected;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      splashColor: cs.onSurface.withValues(alpha: 0.038),
                      highlightColor: cs.onSurface.withValues(alpha: 0.018),
                      onTap: () => Navigator.pop(
                        context,
                        _BodyTypeSelection(item.value),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? cs.onSurface.withValues(
                                    alpha: br == Brightness.light ? 0.26 : 0.34,
                                  )
                                : cs.outlineVariant.withValues(alpha: 0.30),
                          ),
                          color: isSel
                              ? Color.alphaBlend(
                                  cs.onSurface.withValues(
                                    alpha: br == Brightness.light
                                        ? 0.065
                                        : 0.11,
                                  ),
                                  cs.surfaceContainerLowest,
                                )
                              : Color.alphaBlend(
                                  cs.outlineVariant.withValues(alpha: 0.035),
                                  cs.surfaceContainerLowest,
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.12,
                                  color: cs.onSurface.withValues(
                                    alpha: isSel ? 1 : 0.82,
                                  ),
                                ),
                              ),
                            ),
                            if (isSel)
                              Icon(
                                Icons.check_rounded,
                                size: 21,
                                color: cs.onSurface.withValues(alpha: 0.58),
                              ),
                          ],
                        ),
                      ),
                    ),
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

/// Capsule-style EUR / USD control replacing Material [SegmentedButton].
class _PremiumListingCurrencyBar extends StatelessWidget {
  const _PremiumListingCurrencyBar({
    super.key,
    required this.theme,
    required this.selected,
    required this.enabled,
    required this.eurLabel,
    required this.usdLabel,
    required this.onChanged,
  });

  final ThemeData theme;
  final ListingCurrency selected;
  final bool enabled;
  final String eurLabel;
  final String usdLabel;
  final ValueChanged<ListingCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final trackFill = Color.alphaBlend(
      cs.outlineVariant.withValues(
        alpha: br == Brightness.light ? 0.028 : 0.052,
      ),
      cs.surface,
    );
    final trackBorder = cs.outlineVariant.withValues(
      alpha: br == Brightness.light ? 0.28 : 0.34,
    );

    Widget segment(ListingCurrency currency, String label) {
      final on = selected == currency;
      final thumbFill = on
          ? Color.alphaBlend(
              cs.onSurface.withValues(
                alpha: br == Brightness.light ? 0.068 : 0.11,
              ),
              cs.surface,
            )
          : Colors.transparent;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          splashColor: cs.onSurface.withValues(alpha: 0.038),
          highlightColor: cs.onSurface.withValues(alpha: 0.018),
          onTap: enabled && !on ? () => onChanged(currency) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: thumbFill,
              border: on
                  ? Border.all(
                      color: cs.onSurface.withValues(
                        alpha: br == Brightness.light ? 0.18 : 0.26,
                      ),
                      width: 1,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.08,
                color: cs.onSurface.withValues(alpha: on ? 1 : 0.70),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: trackBorder),
          color: trackFill,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: segment(ListingCurrency.eur, eurLabel)),
              VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
                color: cs.outlineVariant.withValues(alpha: 0.34),
              ),
              Expanded(child: segment(ListingCurrency.usd, usdLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

/// WhatsApp availability toggle styled as a calm editorial row.
class _PremiumWhatsAppToggleRow extends StatelessWidget {
  const _PremiumWhatsAppToggleRow({
    required this.theme,
    required this.l10n,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool value;
  final bool submitting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final enabled = !submitting;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: cs.onSurface.withValues(alpha: 0.038),
                highlightColor: cs.onSurface.withValues(alpha: 0.018),
                onTap: enabled ? () => onChanged(!value) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.whatsappToggle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width publish control — inverted editorial emphasis without loud chrome.
class _PremiumPublishActionButton extends StatelessWidget {
  const _PremiumPublishActionButton({
    required this.theme,
    required this.l10n,
    required this.submitting,
    required this.onPressed,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final canTap = !submitting;

    final baseFill = Color.alphaBlend(
      cs.onSurface.withValues(alpha: br == Brightness.light ? 0.50 : 0.34),
      br == Brightness.light ? cs.surface : cs.surfaceContainerHigh,
    );
    final fill = submitting
        ? Color.alphaBlend(
            cs.surface.withValues(alpha: br == Brightness.light ? 0.22 : 0.14),
            baseFill,
          )
        : baseFill;
    final onFill = br == Brightness.light
        ? cs.surface
        : cs.surface.withValues(alpha: 0.97);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: fill,
        elevation: br == Brightness.light ? (submitting ? 1 : 2) : 0,
        shadowColor: Colors.black.withValues(
          alpha: br == Brightness.light ? (submitting ? 0.06 : 0.085) : 0,
        ),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? onPressed : null,
          splashColor: onFill.withValues(alpha: 0.09),
          highlightColor: onFill.withValues(alpha: 0.05),
          child: Center(
            child: submitting
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: onFill.withValues(alpha: 0.82),
                    ),
                  )
                : Text(
                    l10n.publishListing,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.18,
                      color: onFill,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Single selectable card for deal type and market — consistent premium control.
class _ComposeChoiceCard extends StatelessWidget {
  const _ComposeChoiceCard({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.theme,
    this.compact = false,
    this.labelTextAlign = TextAlign.start,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool compact;
  final TextAlign labelTextAlign;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final bg = selected
        ? Color.alphaBlend(
            cs.onSurface.withValues(
              alpha: br == Brightness.light ? 0.07 : 0.11,
            ),
            cs.surfaceContainerLowest,
          )
        : Color.alphaBlend(
            cs.outlineVariant.withValues(alpha: 0.045),
            cs.surfaceContainerLowest,
          );

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: cs.onSurface.withValues(alpha: 0.038),
          highlightColor: cs.onSurface.withValues(alpha: 0.018),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: bg,
              border: Border.all(
                color: selected
                    ? cs.onSurface.withValues(
                        alpha: br == Brightness.light ? 0.26 : 0.34,
                      )
                    : cs.outlineVariant.withValues(alpha: 0.30),
                width: selected ? 1.15 : 1,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 11 : 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: labelTextAlign,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                      letterSpacing: -0.12,
                      color: cs.onSurface.withValues(
                        alpha: selected ? 1 : 0.82,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingTypeDealSelector extends StatelessWidget {
  const _ListingTypeDealSelector({
    required this.l10n,
    required this.theme,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final ListingType value;
  final bool submitting;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = submitting;
    return LayoutBuilder(
      builder: (context, c) {
        final gap = 10.0;
        final maxW = c.maxWidth;
        final half = (maxW - gap) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: half,
                    child: _ComposeChoiceCard(
                      label: l10n.formatTypeSale,
                      selected: value == ListingType.sale,
                      enabled: !disabled,
                      onTap: () => onChanged(ListingType.sale),
                      theme: theme,
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: half,
                    child: _ComposeChoiceCard(
                      label: l10n.formatTypeExchange,
                      selected: value == ListingType.exchange,
                      enabled: !disabled,
                      onTap: () => onChanged(ListingType.exchange),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            _ComposeChoiceCard(
              label: l10n.formatTypeBoth,
              selected: value == ListingType.both,
              enabled: !disabled,
              onTap: () => onChanged(ListingType.both),
              theme: theme,
              compact: true,
              labelTextAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _MarketPlacementSelector extends StatelessWidget {
  const _MarketPlacementSelector({
    required this.l10n,
    required this.theme,
    required this.value,
    required this.submitting,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final MarketRegion value;
  final bool submitting;
  final ValueChanged<MarketRegion> onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = submitting;
    return LayoutBuilder(
      builder: (context, c) {
        final gap = 10.0;
        final half = (c.maxWidth - gap) / 2;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: half,
                child: _ComposeChoiceCard(
                  label: l10n.regionTransnistria,
                  selected: value == MarketRegion.transnistria,
                  enabled: !disabled,
                  onTap: () => onChanged(MarketRegion.transnistria),
                  theme: theme,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: half,
                child: _ComposeChoiceCard(
                  label: l10n.regionMoldova,
                  selected: value == MarketRegion.moldova,
                  enabled: !disabled,
                  onTap: () => onChanged(MarketRegion.moldova),
                  theme: theme,
                ),
              ),
            ],
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
