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
import '../../../../core/widgets/auth_required_prompt.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/domain/catalog/listing_city_catalog.dart';
import '../../../listings/domain/repositories/vehicle_model_catalog_repository.dart';
import '../../../listings/presentation/widgets/listing_brand_pick_sheet.dart';
import '../../../listings/presentation/widgets/listing_city_pick_sheet.dart';
import '../../../listings/presentation/widgets/listing_model_pick_sheet.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/constants/listing_text_limits.dart';
import '../../../listings/domain/listing_submit_title.dart';
import '../../../listings/domain/validation/listing_vin.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/listing_vehicle_spec_pickers.dart';
import '../../../listings/presentation/widgets/listing_year_pick_sheet.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../models/create_listing_photo_draft.dart';
import '../widgets/create_listing_compose_layout.dart';
import '../widgets/create_listing_contact_notice.dart';
import '../widgets/create_listing_media_section.dart';
import '../widgets/create_listing_picker_field.dart';
import '../widgets/listing_body_type_pick_sheet.dart';
import '../widgets/listing_type_deal_selector.dart';
import '../widgets/market_placement_selector.dart';
import '../widgets/premium_listing_controls.dart';

@visibleForTesting
typedef CreateListingImagePicker =
    Future<XFile?> Function({
      required ImageSource source,
      required double maxWidth,
      required int imageQuality,
    });

/// Extra scroll padding below the publish section beyond the device bottom inset.
const double _kCreateListingScrollBottomExtra = 30;

/// Minimum bottom inset for scroll padding when the OS reports no bottom safe area.
const double _kCreateListingScrollBottomInsetFloor = 14;

/// English catalog sentinel — persisted in `make` when the seller picks «Other» without text.
final String _kListingBrandCatalogOther = kListingBrandCatalog.last; // "Other"

class CreateListingPage extends StatelessWidget {
  const CreateListingPage({
    super.key,
    @visibleForTesting this.imagePicker,
    @visibleForTesting this.vehicleModelCatalog,
  });

  @visibleForTesting
  final CreateListingImagePicker? imagePicker;

  @visibleForTesting
  final VehicleModelCatalogRepository? vehicleModelCatalog;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateListingCubit>(),
      child: _CreateListingView(
        imagePicker: imagePicker,
        vehicleModelCatalog: vehicleModelCatalog,
      ),
    );
  }
}

class _CreateListingView extends StatelessWidget {
  const _CreateListingView({this.imagePicker, this.vehicleModelCatalog});

  final CreateListingImagePicker? imagePicker;
  final VehicleModelCatalogRepository? vehicleModelCatalog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: createListingCanvasColor(theme),
      appBar: AppBar(
        backgroundColor: createListingCanvasColor(theme),
        title: Text(
          l10n.createListingTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.32,
            height: 1.12,
          ),
        ),
        leading: const AppBackButton(fallback: AppRoutes.listings),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: scheme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: DecoratedBox(
        decoration: createListingCanvasDecoration(theme),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState.status != AuthStatus.authenticated ||
                authState.user == null) {
              return AuthRequiredPrompt(
                icon: const Icon(Icons.lock_outline_rounded, size: 48),
                message: l10n.createListingSignInRequired,
                primaryButtonLabel: l10n.commonSignIn,
                onPrimaryPressed: () => context.go(AppRoutes.signIn),
              );
            }
            return _CreateListingForm(
              sellerId: authState.user!.id,
              imagePicker: imagePicker,
              vehicleModelCatalog: vehicleModelCatalog,
            );
          },
        ),
      ),
    );
  }
}

class _CreateListingForm extends StatefulWidget {
  const _CreateListingForm({
    required this.sellerId,
    this.imagePicker,
    this.vehicleModelCatalog,
  });

  final String sellerId;
  final CreateListingImagePicker? imagePicker;
  final VehicleModelCatalogRepository? vehicleModelCatalog;

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
  final _variant = TextEditingController();
  final _customBrand = TextEditingController();

  /// Free-text controllers preserved from the legacy layout.
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _city = TextEditingController();
  final GlobalKey<FormFieldState<String>> _citySelectorKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _modelSelectorKey =
      GlobalKey<FormFieldState<String>>();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();

  bool _whatsappEnabled = false;
  ListingType _type = ListingType.sale;

  MarketRegion _marketRegion = MarketRegion.transnistria;
  String? _selectedCanonicalCity;
  bool _manualCity = false;

  ListingBodyType? _bodyType;

  ListingFuelType? _fuelType;
  ListingDrivetrain? _drivetrain;
  ListingTransmissionType? _transmissionType;
  final _engineDisplacement = TextEditingController();
  final _enginePower = TextEditingController();
  final _registration = TextEditingController();
  final _vin = TextEditingController();
  final _description = TextEditingController();

  ListingCurrency _priceCurrency = ListingCurrency.eur;
  String? _selectedBrandCatalogValue;
  String? _selectedCanonicalModel;
  bool _manualModel = false;

  final List<CreateListingPhotoDraft> _photoDrafts = [];

  final ImagePicker _picker = ImagePicker();

  bool _pickingImage = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _model,
      _variant,
      _customBrand,
      _price,
      _mileage,
      _city,
      _phone,
      _telegram,
      _engineDisplacement,
      _enginePower,
      _registration,
      _vin,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _effectiveMakeForSubmit() => effectiveListingMakeForSubmit(
    catalogKey: _selectedBrandCatalogValue,
    customMakeText: _customBrand.text,
  );

  bool get _isCustomMake =>
      _selectedBrandCatalogValue == _kListingBrandCatalogOther;

  VehicleModelCatalogRepository? get _catalog => widget.vehicleModelCatalog;

  void _clearModelSelection() {
    _selectedCanonicalModel = null;
    _manualModel = _isCustomMake;
    _model.clear();
    _variant.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _modelSelectorKey.currentState?.reset();
    });
  }

  String? _variantForSubmit() {
    final t = _variant.text.trim();
    return t.isEmpty ? null : t;
  }

  String _effectiveModelForSubmit() {
    if (_manualModel || _isCustomMake) return _model.text.trim();
    return _selectedCanonicalModel?.trim() ?? '';
  }

  void _applyBrandPick(String picked) {
    final applied = applyListingBrandPick(picked);
    _selectedBrandCatalogValue = applied.catalogKey;
    if (applied.catalogKey == _kListingBrandCatalogOther) {
      _customBrand.text = applied.customMakeText;
    } else {
      _customBrand.clear();
    }
    _clearModelSelection();
  }

  Future<void> _openModelSheet() async {
    if (_selectedBrandCatalogValue == null || _isCustomMake) return;
    final picked = await showListingModelPickSheet(
      context: context,
      l10n: context.l10n,
      make: _selectedBrandCatalogValue!,
      selectedCanonicalModel: _selectedCanonicalModel,
      catalog: _catalog,
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (picked.manual) {
        _manualModel = true;
        _selectedCanonicalModel = null;
      } else {
        _manualModel = false;
        _selectedCanonicalModel = picked.canonicalValue;
        _model.clear();
      }
      _variant.clear();
    });
    _modelSelectorKey.currentState?.didChange(_selectedCanonicalModel);
  }

  String _effectiveCityForSubmit() {
    final trimmed = _city.text.trim();
    if (!_manualCity) return _selectedCanonicalCity ?? trimmed;
    return resolveListingCity(_marketRegion, trimmed)?.canonicalValue ??
        trimmed;
  }

  void _resetCityValidation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _citySelectorKey.currentState?.reset();
    });
  }

  void _onRegionChanged(MarketRegion region) {
    if (region == _marketRegion) return;
    setState(() {
      _marketRegion = region;
      _selectedCanonicalCity = null;
      _manualCity = false;
      _city.clear();
    });
    _resetCityValidation();
  }

  Future<void> _openCitySheet() async {
    final result = await showListingCityPickSheet(
      context: context,
      l10n: context.l10n,
      region: _marketRegion,
      selectedCanonicalCity: _selectedCanonicalCity,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.manual) {
        _selectedCanonicalCity = null;
        _manualCity = true;
        _city.clear();
      } else {
        _selectedCanonicalCity = result.canonicalValue;
        _manualCity = false;
        _city.text = result.canonicalValue!;
      }
    });
    _resetCityValidation();
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
      final picker = widget.imagePicker ?? _picker.pickImage;
      final picked = await picker(
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
    final picked = await showListingBrandPickSheet(
      context: context,
      l10n: l10n,
    );

    if (!mounted || picked == null) return;

    setState(() => _applyBrandPick(picked));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _brandFieldKey.currentState?.didChange(_selectedBrandCatalogValue);
      _brandFieldKey.currentState?.validate();
      _formKey.currentState?.validate();
    });
  }

  Future<void> _openBodyTypeSheet() async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<ListingBodyTypeSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: ListingBodyTypePickSheet(appL10n: l10n, selected: _bodyType),
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() => _bodyType = picked.value);
  }

  Future<void> _openFuelTypeSheet() async {
    final l10n = context.l10n;
    final picked = await showListingFuelTypePickerSheet(
      context: context,
      l10n: l10n,
      selected: _fuelType,
    );
    if (!mounted) return;
    setState(() => _fuelType = picked);
  }

  Future<void> _openDrivetrainSheet() async {
    final l10n = context.l10n;
    final picked = await showListingDrivetrainPickerSheet(
      context: context,
      l10n: l10n,
      selected: _drivetrain,
    );
    if (!mounted) return;
    setState(() => _drivetrain = picked);
  }

  Future<void> _openTransmissionSheet() async {
    final l10n = context.l10n;
    final picked = await showListingTransmissionTypePickerSheet(
      context: context,
      l10n: l10n,
      selected: _transmissionType,
    );
    if (!mounted) return;
    setState(() => _transmissionType = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final l10n = context.l10n;
    final input = NewListingInput(
      sellerId: widget.sellerId,
      title: resolvedListingTitleForSubmit(
        trimmedUserTitle: _title.text.trim(),
        make: _effectiveMakeForSubmit(),
        model: _effectiveModelForSubmit(),
        year: _yearFieldKey.currentState!.value!,
        l10n: l10n,
        variant: _variantForSubmit(),
      ),
      make: _effectiveMakeForSubmit(),
      model: _effectiveModelForSubmit(),
      variant: _variantForSubmit(),
      year: _yearFieldKey.currentState!.value!,
      priceEur: num.parse(_price.text.trim()),
      priceCurrency: _priceCurrency,
      mileageKm: int.parse(_mileage.text.trim()),
      type: _type,
      city: _effectiveCityForSubmit(),
      marketRegion: _marketRegion,
      bodyType: _bodyType,
      fuelType: _fuelType,
      engineDisplacementLiters: _engineDisplacementFromField(),
      enginePowerHp: _enginePowerFromField(),
      drivetrain: _drivetrain,
      transmissionType: _transmissionType,
      registration: _registration.text.trim().isEmpty
          ? null
          : _registration.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      vin: ListingVin.normalizedOrNullForCreate(_vin.text),
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

  String? _validateOptionalDisplacement(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = num.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) {
      return l10n.validationEngineDisplacementPositive;
    }
    return null;
  }

  String? _validateOptionalPower(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return l10n.validationEnginePowerPositive;
    return null;
  }

  String? _validateOptionalVin(AppLocalizations l10n, String? v) {
    if (ListingVin.isBlankInput(v)) return null;
    if (!ListingVin.isOptionalInputValid(v)) return l10n.validationVinInvalid;
    return null;
  }

  String? _validateOptionalVariant(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > kListingVariantMaxLength) {
      return l10n.listingVariantTooLong;
    }
    return null;
  }

  String? _validateOptionalRegistration(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > kListingRegistrationMaxLength) {
      return l10n.validationRegistrationTooLong;
    }
    return null;
  }

  double? _engineDisplacementFromField() {
    final t = _engineDisplacement.text.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t.replaceAll(',', '.'))?.toDouble();
  }

  int? _enginePowerFromField() {
    final t = _enginePower.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
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
            CreateListingFailureKind.invalidVin =>
              l10n.listingCreateVinInvalidServer,
            CreateListingFailureKind.rpcSchemaNotReady =>
              l10n.listingCreateRpcNotReady,
            CreateListingFailureKind.permissionDenied =>
              l10n.listingCreatePermissionDenied,
            CreateListingFailureKind.checkConstraintViolation =>
              l10n.listingCreateCheckConstraint,
            CreateListingFailureKind.validationRejected =>
              l10n.checkDetailsAndRetry,
            CreateListingFailureKind.contentRejected =>
              l10n.contentModerationRejected,
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

        final brandDisplay = listingBrandFieldDisplay(
          l10n: l10n,
          catalogKey: _selectedBrandCatalogValue,
          customMakeText: _customBrand.text,
        );

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            kCreateListingPageHorizontalPadding,
            16,
            kCreateListingPageHorizontalPadding,
            math.max(
                  MediaQuery.paddingOf(context).bottom,
                  _kCreateListingScrollBottomInsetFloor,
                ) +
                _kCreateListingScrollBottomExtra +
                MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreateListingFormSection(
                  key: const ValueKey('create_listing_photos_section'),
                  title: l10n.createListingSectionPhotosLead,
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
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _title,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _title,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText: l10n.fieldTitleOptional,
                              hasValue: hasValue,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (_) => null,
                            enabled: !submitting,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_vehicle_section'),
                  title: l10n.createListingSectionVehicle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormField<String?>(
                        key: _brandFieldKey,
                        validator: (_) {
                          return _selectedBrandCatalogValue == null
                              ? l10n.validationRequired
                              : null;
                        },
                        builder: (fieldState) {
                          return CreateListingPickerField(
                            fieldKey: const ValueKey(
                              'create_listing_brand_field',
                            ),
                            label: l10n.createListingChooseBrand,
                            value: brandDisplay,
                            empty: _selectedBrandCatalogValue == null,
                            enabled: !submitting,
                            errorText: fieldState.errorText,
                            onTap: () async {
                              await _openBrandSheet();
                              fieldState.didChange(_selectedBrandCatalogValue);
                            },
                          );
                        },
                      ),
                      if (_selectedBrandCatalogValue ==
                          _kListingBrandCatalogOther) ...[
                        const SizedBox(height: kCreateListingFieldGap),
                        CreateListingTextSurface(
                          controller: _customBrand,
                          builder: (context, hasValue) {
                            return TextFormField(
                              controller: _customBrand,
                              decoration: createListingFieldDecoration(
                                theme,
                                hintText: l10n.createListingCustomBrandHint,
                                hasValue: hasValue,
                              ),
                              textInputAction: TextInputAction.next,
                              enabled: !submitting,
                              onChanged: (_) => setState(() {}),
                              validator: (v) => validateListingCustomMakeField(
                                l10n,
                                catalogKey: _selectedBrandCatalogValue,
                                customMakeText: v ?? '',
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: kCreateListingFieldGap),
                      Builder(
                        builder: (context) {
                          final modelEnabled =
                              !submitting &&
                              _selectedBrandCatalogValue != null &&
                              !_isCustomMake;
                          final modelEmpty =
                              _selectedCanonicalModel == null &&
                              !_manualModel &&
                              !_isCustomMake;
                          return Opacity(
                            opacity: modelEnabled ? 1 : 0.48,
                            child: IconTheme(
                              data: IconThemeData(
                                color: createListingPickerChevronColor(
                                  theme,
                                  enabled: modelEnabled,
                                  empty: modelEmpty,
                                ),
                              ),
                              child: ListingModelSelectorField(
                                key: const ValueKey(
                                  'create_listing_model_field',
                                ),
                                formFieldKey: _modelSelectorKey,
                                l10n: l10n,
                                enabled: modelEnabled,
                                manualMode: _manualModel || _isCustomMake,
                                canonicalModel: _selectedCanonicalModel,
                                onTap: _openModelSheet,
                                placeholder: _selectedBrandCatalogValue == null
                                    ? l10n.listingModelChooseMakeFirst
                                    : null,
                                borderRadius: kCreateListingFieldRadius,
                                decoration: createListingFieldDecoration(
                                  theme,
                                  hasValue: !modelEmpty,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_manualModel || _isCustomMake) ...[
                        const SizedBox(height: kCreateListingFieldGap),
                        CreateListingTextSurface(
                          controller: _model,
                          builder: (context, hasValue) {
                            return TextFormField(
                              key: const ValueKey(
                                'create_listing_manual_model',
                              ),
                              controller: _model,
                              decoration: createListingFieldDecoration(
                                theme,
                                hintText: l10n.listingModelManualFieldLabel,
                                hasValue: hasValue,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => _required(l10n, v),
                              enabled: !submitting,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _variant,
                        builder: (context, hasValue) {
                          return TextFormField(
                            key: const ValueKey('create_listing_variant_field'),
                            controller: _variant,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText: l10n.listingVariantLabel,
                              hasValue: hasValue,
                            ),
                            textInputAction: TextInputAction.next,
                            maxLength: kListingVariantMaxLength,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            validator: (v) => _validateOptionalVariant(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      FormField<int?>(
                        key: _yearFieldKey,
                        initialValue: null,
                        validator: (y) =>
                            y == null ? l10n.validationRequired : null,
                        builder: (fieldState) {
                          final yr = fieldState.value;
                          return CreateListingPickerField(
                            fieldKey: const ValueKey(
                              'create_listing_year_field',
                            ),
                            label: l10n.createListingYearLabel,
                            value: yr == null ? '' : '$yr',
                            empty: yr == null,
                            enabled: !submitting,
                            errorText: fieldState.errorText,
                            onTap: () async {
                              final picked = await showListingYearPickSheet(
                                context: context,
                                l10n: l10n,
                                selectedYear: yr,
                              );
                              if (!context.mounted) return;
                              if (picked != null) {
                                fieldState.didChange(picked);
                                fieldState.validate();
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingPickerField(
                        fieldKey: const ValueKey(
                          'create_listing_body_type_field',
                        ),
                        label: l10n.listingBodyTypeSectionTitle,
                        value: _bodyType == null
                            ? ''
                            : formatListingBodyType(l10n, _bodyType!),
                        empty: _bodyType == null,
                        enabled: !submitting,
                        onTap: _openBodyTypeSheet,
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingPickerField(
                        fieldKey: const ValueKey('create_listing_fuel_field'),
                        label: l10n.listingFuelType,
                        value: _fuelType == null
                            ? ''
                            : formatListingFuelType(l10n, _fuelType!),
                        empty: _fuelType == null,
                        enabled: !submitting,
                        onTap: _openFuelTypeSheet,
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _engineDisplacement,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _engineDisplacement,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText:
                                  l10n.createListingEngineLitersPlaceholder,
                              hasValue: hasValue,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                _validateOptionalDisplacement(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _enginePower,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _enginePower,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText:
                                  l10n.createListingEnginePowerPlaceholder,
                              hasValue: hasValue,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) => _validateOptionalPower(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingPickerField(
                        fieldKey: const ValueKey(
                          'create_listing_drivetrain_field',
                        ),
                        label: l10n.listingDrivetrain,
                        value: _drivetrain == null
                            ? ''
                            : formatListingDrivetrain(l10n, _drivetrain!),
                        empty: _drivetrain == null,
                        enabled: !submitting,
                        onTap: _openDrivetrainSheet,
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingPickerField(
                        fieldKey: const ValueKey(
                          'create_listing_transmission_field',
                        ),
                        label: l10n.listingTransmission,
                        value: _transmissionType == null
                            ? ''
                            : formatListingTransmissionType(
                                l10n,
                                _transmissionType!,
                              ),
                        empty: _transmissionType == null,
                        enabled: !submitting,
                        onTap: _openTransmissionSheet,
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _registration,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _registration,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText:
                                  l10n.createListingRegistrationPlaceholder,
                              hasValue: hasValue,
                            ),
                            maxLength: kListingRegistrationMaxLength,
                            maxLines: 1,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            validator: (v) =>
                                _validateOptionalRegistration(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _vin,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _vin,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText: l10n.listingVinFieldLabel,
                              helperText: l10n.createListingVinPrivacyHelper,
                              hasValue: hasValue,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 32,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            validator: (v) => _validateOptionalVin(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_description_section'),
                  title: l10n.createListingSectionDescription,
                  child: CreateListingTextSurface(
                    controller: _description,
                    builder: (context, hasValue) {
                      return TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 12,
                        maxLength: kListingDescriptionMaxLength,
                        decoration: createListingFieldDecoration(
                          theme,
                          hintText: l10n.createListingDescriptionHint,
                          hasValue: hasValue,
                        ),
                        enabled: !submitting,
                      );
                    },
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_type_section'),
                  title: l10n.createListingSectionDeal,
                  child: ListingTypeDealSelector(
                    l10n: l10n,
                    theme: theme,
                    value: _type,
                    submitting: submitting,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_location_section'),
                  title: l10n.createListingSectionLocation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MarketPlacementSelector(
                        key: const ValueKey('create_listing_region_selector'),
                        l10n: l10n,
                        theme: theme,
                        value: _marketRegion,
                        submitting: submitting,
                        onChanged: _onRegionChanged,
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      Opacity(
                        opacity: submitting ? 0.48 : 1,
                        child: IconTheme(
                          data: IconThemeData(
                            color: createListingPickerChevronColor(
                              theme,
                              enabled: !submitting,
                              empty:
                                  _selectedCanonicalCity == null &&
                                  !_manualCity,
                            ),
                          ),
                          child: ListingCitySelectorField(
                            key: const ValueKey('create_listing_city_field'),
                            formFieldKey: _citySelectorKey,
                            l10n: l10n,
                            enabled: !submitting,
                            manualMode: _manualCity,
                            canonicalCity: _selectedCanonicalCity,
                            onTap: _openCitySheet,
                            borderRadius: kCreateListingFieldRadius,
                            decoration: createListingFieldDecoration(
                              theme,
                              hasValue:
                                  _selectedCanonicalCity != null || _manualCity,
                            ),
                          ),
                        ),
                      ),
                      if (_manualCity) ...[
                        const SizedBox(height: kCreateListingFieldGap),
                        CreateListingTextSurface(
                          controller: _city,
                          builder: (context, hasValue) {
                            return TextFormField(
                              key: const ValueKey(
                                'create_listing_manual_city_field',
                              ),
                              controller: _city,
                              decoration: createListingFieldDecoration(
                                theme,
                                hintText: l10n.listingCityManualFieldLabel,
                                hasValue: hasValue,
                              ),
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => _required(l10n, v),
                              enabled: !submitting,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_price_section'),
                  title: l10n.createListingSectionPrice,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumListingCurrencyBar(
                        key: const ValueKey('create_listing_currency_selector'),
                        theme: theme,
                        enabled: !submitting,
                        selected: _priceCurrency,
                        eurLabel: l10n.currencyCodeEur,
                        usdLabel: l10n.currencyCodeUsd,
                        onChanged: (c) => setState(() => _priceCurrency = c),
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingResponsiveFieldRow(
                        start: CreateListingTextSurface(
                          controller: _price,
                          builder: (context, hasValue) {
                            return TextFormField(
                              key: const ValueKey('create_listing_price_field'),
                              controller: _price,
                              decoration: createListingFieldDecoration(
                                theme,
                                hintText: l10n.createListingPricePlaceholder,
                                hasValue: hasValue,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _validatePrice(l10n, v),
                              enabled: !submitting,
                            );
                          },
                        ),
                        end: CreateListingTextSurface(
                          controller: _mileage,
                          builder: (context, hasValue) {
                            return TextFormField(
                              key: const ValueKey(
                                'create_listing_mileage_field',
                              ),
                              controller: _mileage,
                              decoration: createListingFieldDecoration(
                                theme,
                                hintText: l10n.createListingMileagePlaceholder,
                                hasValue: hasValue,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) => _validateMileage(l10n, v),
                              enabled: !submitting,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: kCreateListingInterSectionGap),

                CreateListingFormSection(
                  key: const ValueKey('create_listing_publish_section'),
                  title: l10n.createListingSectionPublish,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CreateListingContactNotice(),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _phone,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _phone,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText: l10n.fieldPhone,
                              hasValue: hasValue,
                              prefixIcon: Icon(
                                CarzonIcons.phone,
                                size: kCreateListingContactIconSize,
                                color: createListingContactIconColor(theme),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => validatePhone(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      CreateListingTextSurface(
                        controller: _telegram,
                        builder: (context, hasValue) {
                          return TextFormField(
                            controller: _telegram,
                            decoration: createListingFieldDecoration(
                              theme,
                              hintText: l10n.createListingTelegramPlaceholder,
                              hasValue: hasValue,
                              prefixIcon: Icon(
                                CarzonIcons.send,
                                size: kCreateListingContactIconSize,
                                color: createListingContactIconColor(theme),
                              ),
                            ),
                            validator: (v) => validateTelegramUsername(l10n, v),
                            enabled: !submitting,
                          );
                        },
                      ),
                      const SizedBox(height: kCreateListingFieldGap),
                      PremiumWhatsAppToggleRow(
                        theme: theme,
                        l10n: l10n,
                        value: _whatsappEnabled,
                        submitting: submitting,
                        onChanged: (v) => setState(() => _whatsappEnabled = v),
                      ),
                      const SizedBox(height: 16),
                      PremiumPublishActionButton(
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
