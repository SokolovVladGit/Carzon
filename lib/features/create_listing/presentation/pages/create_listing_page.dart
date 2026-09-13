import 'dart:async';
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
import '../../domain/entities/seller_listing_defaults.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../bloc/manual_smart_fill_cubit.dart';
import '../bloc/manual_smart_fill_state.dart';
import '../models/catalog_resolved_form_prefill.dart';
import '../models/create_listing_characteristics_summary.dart';
import '../models/create_listing_photo_draft.dart';
import '../models/listing_preview_data.dart';
import '../models/vin_resolved_form_prefill.dart';
import '../widgets/create_listing_compact_summary.dart';
import '../widgets/create_listing_compose_layout.dart';
import '../widgets/listing_preview_card.dart';
import '../widgets/create_listing_contact_notice.dart';
import '../widgets/create_listing_manual_smart_fill_panel.dart';
import '../widgets/create_listing_media_section.dart';
import '../widgets/create_listing_picker_field.dart';
import '../widgets/create_listing_vehicle_resolve_panel.dart';
import '../../domain/entities/manual_smart_fill_result.dart';
import '../widgets/listing_body_type_pick_sheet.dart';
import '../widgets/listing_type_deal_selector.dart';
import '../widgets/market_placement_selector.dart';
import '../widgets/premium_listing_controls.dart';
import '../../domain/entities/vehicle_resolve_result.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CreateListingCubit>()),
        BlocProvider(create: (_) => sl<ManualSmartFillCubit>()),
      ],
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
          style: createListingAppBarTitleStyle(theme),
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
              key: ValueKey(authState.user!.id),
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
    super.key,
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
  bool _scanningVin = false;
  int _lastAppliedResolveRevision = 0;
  int _lastAppliedDefaultsRevision = 0;
  bool _applyingListingDefaults = false;
  bool _makeFromVin = false;
  bool _modelFromVin = false;
  bool _yearFromVin = false;
  bool _variantFromVin = false;
  bool _bodyTypeFromVin = false;
  bool _fuelTypeFromVin = false;
  bool _drivetrainFromVin = false;
  bool _transmissionTypeFromVin = false;
  bool _engineDisplacementFromVin = false;
  bool _bodyTypeFromCatalog = false;
  bool _fuelTypeFromCatalog = false;
  bool _engineDisplacementFromCatalog = false;
  bool _enginePowerFromCatalog = false;
  bool _transmissionTypeFromCatalog = false;
  bool _applyingVinSpecs = false;
  bool _applyingCatalogSpecs = false;
  Timer? _smartFillDebounce;
  String? _lastSmartFillMake;
  String? _lastSmartFillModel;
  int? _lastSmartFillYear;
  bool _hasAdoptedIdentity = false;
  bool _editingLocation = false;
  bool _editingContact = false;
  bool _locationSummaryAllowed = false;
  bool _contactSummaryAllowed = false;
  bool _attemptedPublish = false;
  bool _manualIdentityOpen = false;
  bool _priceTouched = false;
  bool _mileageTouched = false;
  bool _cityTouched = false;
  bool _phoneTouched = false;

  @override
  void initState() {
    super.initState();
    context.read<CreateListingCubit>().loadListingDefaults(
      userId: widget.sellerId,
    );
    context.read<ManualSmartFillCubit>().reset();
  }

  @override
  void didUpdateWidget(covariant _CreateListingForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sellerId == widget.sellerId) return;
    _resetContactAndLocationForAccountSwitch();
    context.read<CreateListingCubit>().loadListingDefaults(
      userId: widget.sellerId,
    );
    context.read<ManualSmartFillCubit>().reset();
  }

  void _resetContactAndLocationForAccountSwitch() {
    _phone.clear();
    _telegram.clear();
    _whatsappEnabled = false;
    _marketRegion = MarketRegion.transnistria;
    _selectedCanonicalCity = null;
    _manualCity = false;
    _city.clear();
    _lastAppliedDefaultsRevision = 0;
    _editingLocation = false;
    _editingContact = false;
    _locationSummaryAllowed = false;
    _contactSummaryAllowed = false;
    _attemptedPublish = false;
    _manualIdentityOpen = false;
    _priceTouched = false;
    _mileageTouched = false;
    _cityTouched = false;
    _phoneTouched = false;
  }

  @override
  void dispose() {
    for (final c in [
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
    _smartFillDebounce?.cancel();
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
    _modelFromVin = false;
    _variantFromVin = false;
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
    _makeFromVin = false;
    final applied = applyListingBrandPick(picked);
    _selectedBrandCatalogValue = applied.catalogKey;
    if (applied.catalogKey == _kListingBrandCatalogOther) {
      _customBrand.text = applied.customMakeText;
    } else {
      _customBrand.clear();
    }
    _clearModelSelection();
    _onManualIdentityMaybeChanged(immediate: true);
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
      _modelFromVin = false;
      _variantFromVin = false;
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
    _onManualIdentityMaybeChanged(immediate: true);
  }

  String _effectiveCityForSubmit() {
    final trimmed = _city.text.trim();
    if (!_manualCity) return _selectedCanonicalCity ?? trimmed;
    return resolveListingCity(_marketRegion, trimmed)?.canonicalValue ??
        trimmed;
  }

  bool get _hasValidLocation => _effectiveCityForSubmit().isNotEmpty;

  bool _hasValidContact(AppLocalizations l10n) {
    return validatePhone(l10n, _phone.text) == null &&
        validateTelegramUsername(l10n, _telegram.text) == null;
  }

  bool get _showLocationSummary =>
      _locationSummaryAllowed && _hasValidLocation && !_editingLocation;

  bool _showContactSummary(AppLocalizations l10n) =>
      _contactSummaryAllowed && _hasValidContact(l10n) && !_editingContact;

  ListingPreviewData _listingPreviewData(AppLocalizations l10n) {
    return listingPreviewDataFromCreateForm(
      l10n: l10n,
      coverBytes: _photoDrafts.isEmpty ? null : _photoDrafts.first.bytes,
      make: _effectiveMakeForSubmit(),
      model: _effectiveModelForSubmit(),
      variant: _variantForSubmit(),
      year: _yearFieldKey.currentState?.value,
      priceText: _price.text,
      currency: _priceCurrency,
      mileageText: _mileage.text,
      marketRegion: _marketRegion,
      city: _effectiveCityForSubmit(),
      listingType: _type,
      vinText: _vin.text,
      bodyType: _bodyType,
      fuelType: _fuelType,
      transmissionType: _transmissionType,
      drivetrain: _drivetrain,
      engineDisplacementLiters: _engineDisplacementFromField(),
      enginePowerHp: _enginePowerFromField(),
    );
  }

  void _resetCityValidation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _citySelectorKey.currentState?.reset();
    });
  }

  void _onRegionChanged(MarketRegion region) {
    if (region == _marketRegion) return;
    if (!_applyingListingDefaults) {
      context.read<CreateListingCubit>().markRegionEdited();
    }
    setState(() {
      if (!_applyingListingDefaults) _cityTouched = true;
      _editingLocation = true;
      _marketRegion = region;
      _selectedCanonicalCity = null;
      _manualCity = false;
      _city.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _citySelectorKey.currentState?.validate();
    });
  }

  Future<void> _openCitySheet() async {
    final result = await showListingCityPickSheet(
      context: context,
      l10n: context.l10n,
      region: _marketRegion,
      selectedCanonicalCity: _selectedCanonicalCity,
    );
    if (!mounted || result == null) return;
    context.read<CreateListingCubit>().markCityEdited();
    setState(() {
      _cityTouched = true;
      if (result.manual) {
        _selectedCanonicalCity = null;
        _manualCity = true;
        _city.clear();
        _editingLocation = true;
      } else {
        final wasEditing = _editingLocation;
        _selectedCanonicalCity = result.canonicalValue;
        _manualCity = false;
        _city.text = result.canonicalValue!;
        if (wasEditing &&
            _locationSummaryAllowed &&
            _effectiveCityForSubmit().isNotEmpty) {
          _editingLocation = false;
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_manualCity) {
        _formKey.currentState?.validate();
      } else {
        _citySelectorKey.currentState?.reset();
      }
    });
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

    setState(() {
      _bodyTypeFromVin = false;
      _bodyTypeFromCatalog = false;
      _bodyType = picked.value;
    });
    _cancelProgressiveRefinementForSellerEdit();
  }

  Future<void> _openFuelTypeSheet() async {
    final l10n = context.l10n;
    final picked = await showListingFuelTypePickerSheet(
      context: context,
      l10n: l10n,
      selected: _fuelType,
    );
    if (!mounted) return;
    setState(() {
      _fuelTypeFromVin = false;
      _fuelTypeFromCatalog = false;
      _fuelType = picked;
    });
    _cancelProgressiveRefinementForSellerEdit();
  }

  Future<void> _openDrivetrainSheet() async {
    final l10n = context.l10n;
    final picked = await showListingDrivetrainPickerSheet(
      context: context,
      l10n: l10n,
      selected: _drivetrain,
    );
    if (!mounted) return;
    setState(() {
      _drivetrainFromVin = false;
      _drivetrain = picked;
    });
  }

  void _applyListingDefaultsPrefill(SellerListingDefaultsPrefill prefill) {
    if (!prefill.hasAny) return;
    _applyingListingDefaults = true;
    setState(() {
      if (prefill.contactPhone != null) {
        _phone.text = prefill.contactPhone!;
      }
      if (prefill.telegramUsername != null) {
        _telegram.text = prefill.telegramUsername!;
      }
      if (prefill.whatsappEnabled != null) {
        _whatsappEnabled = prefill.whatsappEnabled!;
      }
      if (prefill.marketRegion != null &&
          prefill.marketRegion != _marketRegion) {
        _marketRegion = prefill.marketRegion!;
        _selectedCanonicalCity = null;
        _manualCity = false;
        _city.clear();
      }
      if (prefill.city != null) {
        final region = prefill.marketRegion ?? _marketRegion;
        final resolved = resolveListingCity(region, prefill.city!);
        if (resolved != null) {
          _selectedCanonicalCity = resolved.canonicalValue;
          _manualCity = false;
          _city.text = resolved.canonicalValue;
        } else {
          _selectedCanonicalCity = null;
          _manualCity = true;
          _city.text = prefill.city!;
        }
        _resetCityValidation();
      }
      if (prefill.city != null && _hasValidLocation) {
        _locationSummaryAllowed = true;
      }
      if (prefill.contactPhone != null &&
          mounted &&
          _hasValidContact(context.l10n)) {
        _contactSummaryAllowed = true;
      }
    });
    _applyingListingDefaults = false;
  }

  void _applyConfirmedIdentity(ConfirmedVehicleIdentity identity) {
    setState(() {
      _hasAdoptedIdentity = true;
      _manualIdentityOpen = false;
      _lastSmartFillMake = identity.make;
      _lastSmartFillModel = identity.model;
      _lastSmartFillYear = identity.year;
      _makeFromVin = true;
      _modelFromVin = true;
      _yearFromVin = true;
      final applied = applyListingBrandPick(identity.make);
      _selectedBrandCatalogValue = applied.catalogKey;
      if (applied.catalogKey == _kListingBrandCatalogOther) {
        _customBrand.text = applied.customMakeText.isEmpty
            ? identity.make
            : applied.customMakeText;
      } else {
        _customBrand.clear();
      }
      _manualModel = true;
      _selectedCanonicalModel = null;
      _model.text = identity.model;
      if (_variant.text.trim().isEmpty && identity.variant != null) {
        _variant.text = identity.variant!;
        _variantFromVin = true;
      }
    });
    _brandFieldKey.currentState?.didChange(_selectedBrandCatalogValue);
    _yearFieldKey.currentState?.didChange(identity.year);
    _yearFieldKey.currentState?.validate();
    _modelSelectorKey.currentState?.didChange(null);
  }

  void _applyConfirmedVinSpecs(
    VehicleResolveSuggestion? vehicle, {
    List<String> warnings = const [],
  }) {
    if (vehicle == null) return;
    final prefill = vinResolvedFormPrefill(vehicle, warnings: warnings);
    if (prefill.isEmpty) return;
    _applyingVinSpecs = true;
    setState(() {
      if (vinMayReplaceField(
            isEmpty: _bodyType == null,
            catalogOwned: _bodyTypeFromCatalog,
          ) &&
          prefill.bodyType != null) {
        _bodyType = prefill.bodyType;
        _bodyTypeFromVin = true;
        _bodyTypeFromCatalog = false;
      }
      if (vinMayReplaceField(
            isEmpty: _fuelType == null,
            catalogOwned: _fuelTypeFromCatalog,
          ) &&
          prefill.fuelType != null) {
        _fuelType = prefill.fuelType;
        _fuelTypeFromVin = true;
        _fuelTypeFromCatalog = false;
      }
      if (vinMayReplaceField(
            isEmpty: _transmissionType == null,
            catalogOwned: _transmissionTypeFromCatalog,
          ) &&
          prefill.transmissionType != null) {
        _transmissionType = prefill.transmissionType;
        _transmissionTypeFromVin = true;
        _transmissionTypeFromCatalog = false;
      }
      if (_drivetrain == null && prefill.drivetrain != null) {
        _drivetrain = prefill.drivetrain;
        _drivetrainFromVin = true;
      }
      if (vinMayReplaceField(
            isEmpty: _engineDisplacement.text.trim().isEmpty,
            catalogOwned: _engineDisplacementFromCatalog,
          ) &&
          prefill.engineDisplacementLiters != null) {
        _engineDisplacement.text = formatVinDisplacementField(
          prefill.engineDisplacementLiters!,
        );
        _engineDisplacementFromVin = true;
        _engineDisplacementFromCatalog = false;
      }
    });
    _applyingVinSpecs = false;
  }

  bool get _hasVinOwnedOptionalSpecs =>
      _bodyTypeFromVin ||
      _fuelTypeFromVin ||
      _drivetrainFromVin ||
      _transmissionTypeFromVin ||
      _engineDisplacementFromVin;

  void _invalidateAdoptedIdentity() {
    if (!_hasAdoptedIdentity && !_hasVinOwnedOptionalSpecs) return;
    setState(() {
      if (_makeFromVin) {
        _selectedBrandCatalogValue = null;
        _customBrand.clear();
        _brandFieldKey.currentState?.didChange(null);
      }
      if (_modelFromVin) {
        _model.clear();
        _selectedCanonicalModel = null;
        _modelSelectorKey.currentState?.didChange(null);
      }
      if (_yearFromVin) _yearFieldKey.currentState?.didChange(null);
      if (_variantFromVin) _variant.clear();
      if (_bodyTypeFromVin) _bodyType = null;
      if (_fuelTypeFromVin) _fuelType = null;
      if (_drivetrainFromVin) _drivetrain = null;
      if (_transmissionTypeFromVin) _transmissionType = null;
      if (_engineDisplacementFromVin) _engineDisplacement.clear();
      _makeFromVin = _modelFromVin = _yearFromVin = _variantFromVin = false;
      _bodyTypeFromVin = _fuelTypeFromVin = _drivetrainFromVin =
          _transmissionTypeFromVin = _engineDisplacementFromVin = false;
      _hasAdoptedIdentity = false;
    });
  }

  Future<void> _openTransmissionSheet() async {
    final l10n = context.l10n;
    final picked = await showListingTransmissionTypePickerSheet(
      context: context,
      l10n: l10n,
      selected: _transmissionType,
    );
    if (!mounted) return;
    setState(() {
      _transmissionTypeFromVin = false;
      _transmissionTypeFromCatalog = false;
      _transmissionType = picked;
    });
    _cancelProgressiveRefinementForSellerEdit();
  }

  Future<void> _scanVin() async {
    if (_scanningVin) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final vinAtOpen = _vin.text;
    setState(() => _scanningVin = true);
    try {
      final result = await const MethodChannel('carzon/vin_scanner')
          .invokeMethod<Object?>('scanVin', <String, String>{
            'title': l10n.vinScannerTitle,
            'instruction': l10n.vinScannerInstruction,
            'hint': l10n.vinScannerHint,
            'initializing': l10n.vinScannerInitializing,
            'found': l10n.vinScannerFound,
            'use': l10n.vinScannerUse,
            'again': l10n.vinScannerAgain,
            'close': l10n.vinScannerClose,
            'deniedTitle': l10n.vinScannerDeniedTitle,
            'denied': l10n.vinScannerDenied,
            'unavailableTitle': l10n.vinScannerUnavailableTitle,
            'unavailable': l10n.vinScannerUnavailable,
            'settings': l10n.vinScannerSettings,
            'torchOn': l10n.vinScannerTorchOn,
            'torchOff': l10n.vinScannerTorchOff,
            'retry': l10n.vinScannerRetry,
          });
      if (!mounted || result == null) return;
      // A scanner result is only text input, never vehicle identity authority.
      if (context.read<AuthCubit>().state.user?.id != widget.sellerId ||
          _vin.text != vinAtOpen ||
          context.read<CreateListingCubit>().state.status ==
              CreateListingStatus.submitting) {
        return;
      }
      final vin = result is String
          ? ListingVin.normalizeOptional(result)
          : null;
      if (vin == null || !ListingVin.isValidNormalized(vin)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vinScannerInvalid)));
        return;
      }
      _vin.value = TextEditingValue(
        text: vin,
        selection: TextSelection.collapsed(offset: vin.length),
      );
      context.read<CreateListingCubit>().onVinChanged(vin);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vinScannerUnavailable)));
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vinScannerUnavailable)));
      }
    } finally {
      if (mounted) setState(() => _scanningVin = false);
    }
  }

  bool get _revealVehicleIdentityErrors {
    if (_attemptedPublish) return true;
    return (_brandFieldKey.currentState?.hasInteractedByUser ?? false) ||
        (_yearFieldKey.currentState?.hasInteractedByUser ?? false);
  }

  String? _visibleVehicleIdentityError(FormFieldState<dynamic> field) {
    return _revealVehicleIdentityErrors ? field.errorText : null;
  }

  String? _deferredTextError({
    required bool touched,
    required String? Function() validate,
  }) {
    if (_attemptedPublish || touched) return validate();
    return null;
  }

  bool _showIdentityEditors(CreateListingVehicleResolve resolve) {
    if (resolve.confirmed &&
        resolve.status == CreateListingVinResolveStatus.resolved) {
      return false;
    }
    if (_manualIdentityOpen || _attemptedPublish) return true;
    return switch (resolve.status) {
      CreateListingVinResolveStatus.manual ||
      CreateListingVinResolveStatus.partial ||
      CreateListingVinResolveStatus.noData ||
      CreateListingVinResolveStatus.failure => true,
      CreateListingVinResolveStatus.idle ||
      CreateListingVinResolveStatus.resolving ||
      CreateListingVinResolveStatus.resolved ||
      CreateListingVinResolveStatus.likelyInputError => false,
    };
  }

  void _enterManualIdentity() {
    setState(() => _manualIdentityOpen = true);
    context.read<CreateListingCubit>().enterManualMode();
    _onManualIdentityMaybeChanged(immediate: true);
  }

  bool _isSmartFillEligible(CreateListingVehicleResolve resolve) {
    if (resolve.confirmed) return false;
    if (!_showIdentityEditors(resolve)) return false;
    return _effectiveMakeForSubmit().isNotEmpty &&
        _effectiveModelForSubmit().isNotEmpty &&
        _yearFieldKey.currentState?.value != null;
  }

  void _onManualIdentityMaybeChanged({required bool immediate}) {
    final make = _effectiveMakeForSubmit();
    final model = _effectiveModelForSubmit();
    final year = _yearFieldKey.currentState?.value;
    final mmyChanged =
        make != _lastSmartFillMake ||
        model != _lastSmartFillModel ||
        year != _lastSmartFillYear;
    if (mmyChanged) {
      _clearCatalogOwnedSpecs();
      _clearStaleVinOwnedOptionalSpecs(
        currentMake: make,
        currentModel: model,
        currentYear: year,
      );
      _lastSmartFillMake = make;
      _lastSmartFillModel = model;
      _lastSmartFillYear = year;
    }
    if (immediate) {
      _smartFillDebounce?.cancel();
      _syncManualSmartFill();
    } else {
      _smartFillDebounce?.cancel();
      _smartFillDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _syncManualSmartFill();
      });
    }
  }

  void _syncManualSmartFill() {
    if (!mounted) return;
    final cubit = context.read<ManualSmartFillCubit>();
    final resolve = context.read<CreateListingCubit>().state.vehicleResolve;
    if (!_isSmartFillEligible(resolve)) {
      cubit.reset();
      return;
    }
    cubit.lookup(
      make: _effectiveMakeForSubmit(),
      model: _effectiveModelForSubmit(),
      year: _yearFieldKey.currentState!.value!,
    );
  }

  void _cancelProgressiveRefinementForSellerEdit() {
    if (_applyingCatalogSpecs || _applyingVinSpecs) return;
    context.read<ManualSmartFillCubit>().cancelForManualOverride();
  }

  void _restartProgressiveSmartFill() {
    if (context.read<ManualSmartFillCubit>().state.cancelledByManualOverride) {
      return;
    }
    _clearCatalogOwnedSpecs();
    context.read<ManualSmartFillCubit>().restart();
  }

  void _clearCatalogOwnedSpecs() {
    if (!_bodyTypeFromCatalog &&
        !_fuelTypeFromCatalog &&
        !_engineDisplacementFromCatalog &&
        !_enginePowerFromCatalog &&
        !_transmissionTypeFromCatalog) {
      return;
    }
    setState(() {
      if (_bodyTypeFromCatalog) {
        _bodyType = null;
        _bodyTypeFromCatalog = false;
      }
      if (_fuelTypeFromCatalog) {
        _fuelType = null;
        _fuelTypeFromCatalog = false;
      }
      if (_engineDisplacementFromCatalog) {
        _engineDisplacement.clear();
        _engineDisplacementFromCatalog = false;
      }
      if (_enginePowerFromCatalog) {
        _enginePower.clear();
        _enginePowerFromCatalog = false;
      }
      if (_transmissionTypeFromCatalog) {
        _transmissionType = null;
        _transmissionTypeFromCatalog = false;
      }
    });
  }

  void _clearStaleVinOwnedOptionalSpecs({
    required String currentMake,
    required String currentModel,
    required int? currentYear,
  }) {
    if (!_hasVinOwnedOptionalSpecs) return;
    final identity = context
        .read<CreateListingCubit>()
        .state
        .vehicleResolve
        .confirmedIdentity;
    if (identity != null &&
        identity.make == currentMake &&
        identity.model == currentModel &&
        identity.year == currentYear) {
      return;
    }
    setState(() {
      if (_bodyTypeFromVin) {
        _bodyType = null;
        _bodyTypeFromVin = false;
      }
      if (_fuelTypeFromVin) {
        _fuelType = null;
        _fuelTypeFromVin = false;
      }
      if (_drivetrainFromVin) {
        _drivetrain = null;
        _drivetrainFromVin = false;
      }
      if (_transmissionTypeFromVin) {
        _transmissionType = null;
        _transmissionTypeFromVin = false;
      }
      if (_engineDisplacementFromVin) {
        _engineDisplacement.clear();
        _engineDisplacementFromVin = false;
      }
    });
  }

  void _applyCatalogSpecs(ManualSmartFillConsensusSpecs specs) {
    final prefill = catalogResolvedFormPrefill(specs);
    if (prefill.isEmpty) return;
    _applyingCatalogSpecs = true;
    setState(() {
      if (catalogMayFillField(
            isEmpty: _bodyType == null,
            vinOwned: _bodyTypeFromVin,
            catalogOwned: _bodyTypeFromCatalog,
          ) &&
          prefill.bodyType != null) {
        _bodyType = prefill.bodyType;
        _bodyTypeFromCatalog = true;
      }
      if (catalogMayFillField(
            isEmpty: _fuelType == null,
            vinOwned: _fuelTypeFromVin,
            catalogOwned: _fuelTypeFromCatalog,
          ) &&
          prefill.fuelType != null) {
        _fuelType = prefill.fuelType;
        _fuelTypeFromCatalog = true;
      }
      if (catalogMayFillField(
            isEmpty: _engineDisplacement.text.trim().isEmpty,
            vinOwned: _engineDisplacementFromVin,
            catalogOwned: _engineDisplacementFromCatalog,
          ) &&
          prefill.engineDisplacementLiters != null) {
        _engineDisplacement.text = formatCatalogDisplacementField(
          prefill.engineDisplacementLiters!,
        );
        _engineDisplacementFromCatalog = true;
      }
      if (catalogMayFillField(
            isEmpty: _enginePower.text.trim().isEmpty,
            vinOwned: false,
            catalogOwned: _enginePowerFromCatalog,
          ) &&
          prefill.enginePowerHp != null) {
        _enginePower.text = '${prefill.enginePowerHp}';
        _enginePowerFromCatalog = true;
      }
      if (catalogMayFillField(
            isEmpty: _transmissionType == null,
            vinOwned: _transmissionTypeFromVin,
            catalogOwned: _transmissionTypeFromCatalog,
          ) &&
          prefill.transmissionType != null) {
        _transmissionType = prefill.transmissionType;
        _transmissionTypeFromCatalog = true;
      }
    });
    _applyingCatalogSpecs = false;
  }

  String _smartFillFilledSummary(AppLocalizations l10n) {
    if (!_bodyTypeFromCatalog &&
        !_fuelTypeFromCatalog &&
        !_engineDisplacementFromCatalog) {
      return '';
    }
    return manualSmartFillFilledSummary(
      l10n,
      bodyType: _bodyTypeFromCatalog ? _bodyType : null,
      fuelType: _fuelTypeFromCatalog ? _fuelType : null,
      displacementLiters: _engineDisplacementFromCatalog
          ? _engineDisplacementFromField()
          : null,
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _attemptedPublish = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final l10n = context.l10n;
    final input = NewListingInput(
      sellerId: widget.sellerId,
      title: resolvedListingTitleForSubmit(
        trimmedUserTitle: '',
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
    if (!n.isFinite || n > 30) {
      return '${l10n.validationEngineDisplacementPositive} ≤ 30';
    }
    return null;
  }

  String? _validateOptionalPower(AppLocalizations l10n, String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return l10n.validationEnginePowerPositive;
    if (n > 3000) return '${l10n.validationEnginePowerPositive} ≤ 3000';
    return null;
  }

  String? _validateOptionalVin(AppLocalizations l10n, String? v) {
    if (ListingVin.isBlankInput(v)) return null;
    if (!ListingVin.isOptionalInputValid(v)) return l10n.validationVinInvalid;
    final normalized = ListingVin.normalizeOptional(v);
    if (normalized != null &&
        ListingVin.checkDigitStatus(normalized) ==
            ListingVinCheckDigitStatus.invalid) {
      return l10n.createListingVinChecksumHint;
    }
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

    return BlocListener<ManualSmartFillCubit, ManualSmartFillState>(
      listener: (context, smartFill) {
        final result = smartFill.result;
        if (result == null) return;
        if (result.resolution != ManualSmartFillResolution.ok) return;
        if (context.read<CreateListingCubit>().state.vehicleResolve.confirmed) {
          return;
        }
        _applyCatalogSpecs(result.consensus);
      },
      child: BlocConsumer<CreateListingCubit, CreateListingState>(
        listener: (context, state) {
          final revision = state.vehicleResolve.applyRevision;
          final identity = state.vehicleResolve.confirmedIdentity;
          if (identity == null) _invalidateAdoptedIdentity();
          if (state.vehicleResolve.confirmed) {
            context.read<ManualSmartFillCubit>().cancelForVinAuthority();
          } else if (!_showIdentityEditors(state.vehicleResolve)) {
            context.read<ManualSmartFillCubit>().reset();
          }
          if (revision != _lastAppliedResolveRevision && identity != null) {
            _lastAppliedResolveRevision = revision;
            _applyConfirmedIdentity(identity);
            context.read<ManualSmartFillCubit>().cancelForVinAuthority();
            _applyConfirmedVinSpecs(
              state.vehicleResolve.suggestion?.vehicle,
              warnings: state.vehicleResolve.suggestion?.warnings ?? const [],
            );
          }
          final defaultsRevision = state.listingDefaults.applyRevision;
          if (defaultsRevision != _lastAppliedDefaultsRevision &&
              defaultsRevision > 0) {
            _lastAppliedDefaultsRevision = defaultsRevision;
            _applyListingDefaultsPrefill(state.listingDefaults.prefill);
          }
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
                    key: const ValueKey('create_listing_vehicle_section'),
                    title: l10n.createListingSectionVehicle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CreateListingTextSurface(
                          controller: _vin,
                          builder: (context, hasValue) {
                            return TextFormField(
                              key: const ValueKey('create_listing_vin_field'),
                              controller: _vin,
                              decoration:
                                  createListingFieldDecoration(
                                    theme,
                                    hintText: l10n.listingVinFieldLabel,
                                    helperText:
                                        l10n.createListingVinAutofillHint,
                                    hasValue: hasValue,
                                    prefixIcon: Icon(
                                      CarzonIcons.scan,
                                      size: 18,
                                      color: createListingContactIconColor(
                                        theme,
                                      ),
                                    ),
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      key: const ValueKey(
                                        'create_listing_scan_vin',
                                      ),
                                      tooltip: l10n.vinScannerTitle,
                                      onPressed: submitting || _scanningVin
                                          ? null
                                          : _scanVin,
                                      icon: const Icon(
                                        Icons.document_scanner_outlined,
                                      ),
                                    ),
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
                              onChanged: (v) => context
                                  .read<CreateListingCubit>()
                                  .onVinChanged(v),
                            );
                          },
                        ),
                        CreateListingVehicleResolvePanel(
                          l10n: l10n,
                          theme: theme,
                          resolve: state.vehicleResolve,
                          enabled: !submitting,
                          compactMake: _effectiveMakeForSubmit(),
                          compactModel: _effectiveModelForSubmit(),
                          compactYear: _yearFieldKey.currentState?.value,
                          compactVariant: _variantForSubmit(),
                          onConfirm: () => context
                              .read<CreateListingCubit>()
                              .confirmSuggestion(),
                          onEnterManual: _enterManualIdentity,
                          onRetry: () =>
                              context.read<CreateListingCubit>().retryResolve(),
                        ),
                        Offstage(
                          key: const ValueKey(
                            'create_listing_identity_editors',
                          ),
                          offstage: !_showIdentityEditors(state.vehicleResolve),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: kCreateListingFieldGap),
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
                                    errorText: _visibleVehicleIdentityError(
                                      fieldState,
                                    ),
                                    onTap: () async {
                                      await _openBrandSheet();
                                      fieldState.didChange(
                                        _selectedBrandCatalogValue,
                                      );
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
                                      key: const ValueKey(
                                        'create_listing_custom_brand_field',
                                      ),
                                      controller: _customBrand,
                                      decoration: createListingFieldDecoration(
                                        theme,
                                        hintText:
                                            l10n.createListingCustomBrandHint,
                                        hasValue: hasValue,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      enabled: !submitting,
                                      onChanged: (_) {
                                        setState(() => _makeFromVin = false);
                                        _onManualIdentityMaybeChanged(
                                          immediate: false,
                                        );
                                      },
                                      validator: (v) =>
                                          validateListingCustomMakeField(
                                            l10n,
                                            catalogKey:
                                                _selectedBrandCatalogValue,
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
                                        manualMode:
                                            _manualModel || _isCustomMake,
                                        canonicalModel: _selectedCanonicalModel,
                                        onTap: _openModelSheet,
                                        placeholder:
                                            _selectedBrandCatalogValue == null
                                            ? l10n.listingModelChooseMakeFirst
                                            : null,
                                        borderRadius: kCreateListingFieldRadius,
                                        decoration:
                                            createListingFieldDecoration(
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
                                      onChanged: (_) {
                                        _modelFromVin = false;
                                        _onManualIdentityMaybeChanged(
                                          immediate: false,
                                        );
                                      },
                                      decoration: createListingFieldDecoration(
                                        theme,
                                        hintText:
                                            l10n.listingModelManualFieldLabel,
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
                                    key: const ValueKey(
                                      'create_listing_variant_field',
                                    ),
                                    controller: _variant,
                                    onChanged: (_) => _variantFromVin = false,
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
                                    validator: (v) =>
                                        _validateOptionalVariant(l10n, v),
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
                                    errorText: _visibleVehicleIdentityError(
                                      fieldState,
                                    ),
                                    onTap: () async {
                                      final picked =
                                          await showListingYearPickSheet(
                                            context: context,
                                            l10n: l10n,
                                            selectedYear: yr,
                                          );
                                      if (!context.mounted) return;
                                      if (picked != null) {
                                        setState(() {
                                          _yearFromVin = false;
                                          fieldState.didChange(picked);
                                        });
                                        fieldState.validate();
                                        _onManualIdentityMaybeChanged(
                                          immediate: true,
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        BlocBuilder<ManualSmartFillCubit, ManualSmartFillState>(
                          builder: (context, smartFill) {
                            if (state.vehicleResolve.confirmed ||
                                !_showIdentityEditors(state.vehicleResolve)) {
                              return const SizedBox.shrink();
                            }
                            return CreateListingManualSmartFillPanel(
                              l10n: l10n,
                              theme: theme,
                              state: smartFill,
                              enabled: !submitting,
                              filledSummary: _smartFillFilledSummary(l10n),
                              onSelectOption: (option) {
                                context
                                    .read<ManualSmartFillCubit>()
                                    .selectOption(option);
                              },
                              onDontKnow: () => context
                                  .read<ManualSmartFillCubit>()
                                  .skipCurrent(),
                              onRestart: _restartProgressiveSmartFill,
                              onRetry: () =>
                                  context.read<ManualSmartFillCubit>().retry(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  CreateListingFormSection(
                    key: const ValueKey('create_listing_photos_section'),
                    title: l10n.createListingSectionPhotosLead,
                    child: CreateListingMediaSection(
                      photos: _photoDrafts,
                      pickingImage: _pickingImage,
                      disabled: submitting,
                      onAddPhoto: () => _addPhoto(context),
                      onRemovePhotoAt: _removePhotoAt,
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  CreateListingFormSection(
                    key: const ValueKey('create_listing_type_section'),
                    title: l10n.createListingSectionDeal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CreateListingResponsiveFieldRow(
                          key: const ValueKey('create_listing_price_section'),
                          start: CreateListingTextSurface(
                            controller: _price,
                            builder: (context, hasValue) {
                              return TextFormField(
                                key: const ValueKey(
                                  'create_listing_price_field',
                                ),
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
                                validator: (v) => _deferredTextError(
                                  touched: _priceTouched,
                                  validate: () => _validatePrice(l10n, v),
                                ),
                                enabled: !submitting,
                                onChanged: (_) {
                                  if (_priceTouched) return;
                                  setState(() => _priceTouched = true);
                                },
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
                                  hintText:
                                      l10n.createListingMileagePlaceholder,
                                  hasValue: hasValue,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) => _deferredTextError(
                                  touched: _mileageTouched,
                                  validate: () => _validateMileage(l10n, v),
                                ),
                                enabled: !submitting,
                                onChanged: (_) {
                                  if (_mileageTouched) return;
                                  setState(() => _mileageTouched = true);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: kCreateListingFieldGap),
                        PremiumListingCurrencyBar(
                          key: const ValueKey(
                            'create_listing_currency_selector',
                          ),
                          theme: theme,
                          enabled: !submitting,
                          selected: _priceCurrency,
                          eurLabel: l10n.currencyCodeEur,
                          usdLabel: l10n.currencyCodeUsd,
                          onChanged: (c) => setState(() => _priceCurrency = c),
                        ),
                        const SizedBox(height: kCreateListingFieldGap),
                        ListingTypeDealSelector(
                          l10n: l10n,
                          theme: theme,
                          value: _type,
                          submitting: submitting,
                          onChanged: (t) => setState(() => _type = t),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  CreateListingFormSection(
                    key: const ValueKey('create_listing_location_section'),
                    title: l10n.createListingSectionLocation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showLocationSummary)
                          CreateListingCompactSummary(
                            key: const ValueKey(
                              'create_listing_location_summary',
                            ),
                            primary: _effectiveCityForSubmit(),
                            secondary: formatMarketRegion(l10n, _marketRegion),
                            changeLabel: l10n.createListingChange,
                            changeKey: const ValueKey(
                              'create_listing_change_location',
                            ),
                            onChange: () =>
                                setState(() => _editingLocation = true),
                          ),
                        Offstage(
                          key: const ValueKey(
                            'create_listing_location_editors',
                          ),
                          offstage: _showLocationSummary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MarketPlacementSelector(
                                key: const ValueKey(
                                  'create_listing_region_selector',
                                ),
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
                                    key: const ValueKey(
                                      'create_listing_city_field',
                                    ),
                                    formFieldKey: _citySelectorKey,
                                    l10n: l10n,
                                    enabled: !submitting,
                                    manualMode: _manualCity,
                                    canonicalCity: _selectedCanonicalCity,
                                    onTap: _openCitySheet,
                                    borderRadius: kCreateListingFieldRadius,
                                    validator: (_) => _deferredTextError(
                                      touched: _cityTouched,
                                      validate: () =>
                                          !_manualCity &&
                                              _selectedCanonicalCity == null
                                          ? l10n.validationRequired
                                          : null,
                                    ),
                                    decoration: createListingFieldDecoration(
                                      theme,
                                      hasValue:
                                          _selectedCanonicalCity != null ||
                                          _manualCity,
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
                                        hintText:
                                            l10n.listingCityManualFieldLabel,
                                        hasValue: hasValue,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (v) => _deferredTextError(
                                        touched: _cityTouched,
                                        validate: () => _required(l10n, v),
                                      ),
                                      enabled: !submitting,
                                      onChanged: (_) {
                                        if (_applyingListingDefaults) return;
                                        setState(() {
                                          _cityTouched = true;
                                          _editingLocation = true;
                                        });
                                        context
                                            .read<CreateListingCubit>()
                                            .markCityEdited();
                                      },
                                    );
                                  },
                                ),
                              ],
                              if (_editingLocation && _hasValidLocation)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CreateListingSecondaryAction(
                                    key: const ValueKey(
                                      'create_listing_done_location',
                                    ),
                                    label: l10n.commonDone,
                                    enabled: !submitting,
                                    onPressed: () => setState(() {
                                      _editingLocation = false;
                                      if (_hasValidLocation) {
                                        _locationSummaryAllowed = true;
                                      }
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  KeyedSubtree(
                    key: const ValueKey('create_listing_contact_section'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showContactSummary(l10n))
                          CreateListingCompactSummary(
                            key: const ValueKey(
                              'create_listing_contact_summary',
                            ),
                            primary: _phone.text.trim(),
                            secondary: createListingContactChannelsSummary(
                              l10n: l10n,
                              hasTelegram: _telegram.text.trim().isNotEmpty,
                              whatsappEnabled: _whatsappEnabled,
                            ),
                            changeLabel: l10n.createListingChange,
                            changeKey: const ValueKey(
                              'create_listing_change_contact',
                            ),
                            onChange: () =>
                                setState(() => _editingContact = true),
                          ),
                        Offstage(
                          key: const ValueKey('create_listing_contact_editors'),
                          offstage: _showContactSummary(l10n),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const CreateListingContactNotice(),
                              const SizedBox(height: kCreateListingFieldGap),
                              CreateListingTextSurface(
                                controller: _phone,
                                builder: (context, hasValue) {
                                  return TextFormField(
                                    key: const ValueKey(
                                      'create_listing_phone_field',
                                    ),
                                    controller: _phone,
                                    decoration: createListingFieldDecoration(
                                      theme,
                                      hintText: l10n.fieldPhone,
                                      hasValue: hasValue,
                                      prefixIcon: Icon(
                                        CarzonIcons.phone,
                                        size: kCreateListingContactIconSize,
                                        color: createListingContactIconColor(
                                          theme,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => _deferredTextError(
                                      touched: _phoneTouched,
                                      validate: () => validatePhone(l10n, v),
                                    ),
                                    enabled: !submitting,
                                    onChanged: (_) {
                                      if (_applyingListingDefaults) return;
                                      setState(() {
                                        _phoneTouched = true;
                                        _editingContact = true;
                                      });
                                      context
                                          .read<CreateListingCubit>()
                                          .markPhoneEdited();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: kCreateListingFieldGap),
                              CreateListingTextSurface(
                                controller: _telegram,
                                builder: (context, hasValue) {
                                  return TextFormField(
                                    key: const ValueKey(
                                      'create_listing_telegram_field',
                                    ),
                                    controller: _telegram,
                                    decoration: createListingFieldDecoration(
                                      theme,
                                      hintText:
                                          l10n.createListingTelegramPlaceholder,
                                      hasValue: hasValue,
                                      prefixIcon: Icon(
                                        CarzonIcons.send,
                                        size: kCreateListingContactIconSize,
                                        color: createListingContactIconColor(
                                          theme,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        validateTelegramUsername(l10n, v),
                                    enabled: !submitting,
                                    onChanged: (_) {
                                      if (_applyingListingDefaults) return;
                                      setState(() => _editingContact = true);
                                      context
                                          .read<CreateListingCubit>()
                                          .markTelegramEdited();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: kCreateListingFieldGap),
                              PremiumWhatsAppToggleRow(
                                theme: theme,
                                l10n: l10n,
                                value: _whatsappEnabled,
                                submitting: submitting,
                                onChanged: (v) {
                                  context
                                      .read<CreateListingCubit>()
                                      .markWhatsappEdited();
                                  setState(() {
                                    _editingContact = true;
                                    _whatsappEnabled = v;
                                  });
                                },
                              ),
                              if (_editingContact && _hasValidContact(l10n))
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CreateListingSecondaryAction(
                                    key: const ValueKey(
                                      'create_listing_done_contact',
                                    ),
                                    label: l10n.commonDone,
                                    enabled: !submitting,
                                    onPressed: () => setState(() {
                                      _editingContact = false;
                                      if (_hasValidContact(l10n)) {
                                        _contactSummaryAllowed = true;
                                      }
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  CreateListingFormSection(
                    key: const ValueKey(
                      'create_listing_characteristics_section',
                    ),
                    title: l10n.listingDetailsSpecs,
                    child: DecoratedBox(
                      decoration: createListingIdentityCardDecoration(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              kCreateListingModulePad,
                              14,
                              kCreateListingModulePad,
                              0,
                            ),
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                _engineDisplacement,
                                _enginePower,
                              ]),
                              builder: (context, _) {
                                final summary =
                                    createListingCharacteristicsSummary(
                                      l10n,
                                      bodyType: _bodyType,
                                      fuelType: _fuelType,
                                      engineDisplacementLiters:
                                          _engineDisplacementFromField(),
                                      enginePowerHp: _enginePowerFromField(),
                                      transmissionType: _transmissionType,
                                    );
                                final hasSummary = summary.isNotEmpty;
                                return Text(
                                  hasSummary
                                      ? summary
                                      : l10n.createListingCharacteristicsEmpty,
                                  key: const ValueKey(
                                    'create_listing_characteristics_summary',
                                  ),
                                  style: hasSummary
                                      ? theme.textTheme.bodyMedium?.copyWith(
                                          color: createListingValueColor(
                                            theme,
                                            enabled: true,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                          letterSpacing: -0.1,
                                        )
                                      : createListingSupportStyle(theme),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              kCreateListingModulePad,
                              0,
                              kCreateListingModulePad,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 2,
                                    bottom: 6,
                                  ),
                                  child: Text(
                                    l10n.listingDrivetrain,
                                    style: createListingSupportStyle(theme)
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.5,
                                        ),
                                  ),
                                ),
                                CreateListingPickerField(
                                  fieldKey: const ValueKey(
                                    'create_listing_drivetrain_field',
                                  ),
                                  label:
                                      l10n.createListingDrivetrainNotSpecified,
                                  value: _drivetrain == null
                                      ? ''
                                      : formatListingDrivetrain(
                                          l10n,
                                          _drivetrain!,
                                        ),
                                  empty: _drivetrain == null,
                                  enabled: !submitting,
                                  onTap: _openDrivetrainSheet,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kCreateListingModulePad,
                            ),
                            child: ColoredBox(
                              color: createListingHairlineColor(theme),
                              child: const SizedBox(height: 1),
                            ),
                          ),
                          Theme(
                            data: theme.copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              key: const ValueKey(
                                'create_listing_additional_details',
                              ),
                              tilePadding: const EdgeInsets.fromLTRB(
                                kCreateListingModulePad,
                                2,
                                8,
                                2,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                kCreateListingModulePad,
                                4,
                                kCreateListingModulePad,
                                16,
                              ),
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                              iconColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.46,
                              ),
                              collapsedIconColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.46),
                              collapsedShape: const RoundedRectangleBorder(),
                              shape: const RoundedRectangleBorder(),
                              title: Text(
                                l10n.createListingEditCharacteristics,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.12,
                                  height: 1.25,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: theme.brightness == Brightness.light
                                        ? 0.72
                                        : 0.80,
                                  ),
                                ),
                              ),
                              children: [
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
                                  fieldKey: const ValueKey(
                                    'create_listing_fuel_field',
                                  ),
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
                                      key: const ValueKey(
                                        'create_listing_engine_displacement_field',
                                      ),
                                      controller: _engineDisplacement,
                                      decoration: createListingFieldDecoration(
                                        theme,
                                        hintText: l10n
                                            .createListingEngineLitersPlaceholder,
                                        hasValue: hasValue,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) =>
                                          _validateOptionalDisplacement(
                                            l10n,
                                            v,
                                          ),
                                      enabled: !submitting,
                                      onChanged: (_) {
                                        if (_applyingVinSpecs ||
                                            _applyingCatalogSpecs) {
                                          return;
                                        }
                                        if (!_engineDisplacementFromVin &&
                                            !_engineDisplacementFromCatalog) {
                                          return;
                                        }
                                        setState(() {
                                          _engineDisplacementFromVin = false;
                                          _engineDisplacementFromCatalog =
                                              false;
                                        });
                                        _cancelProgressiveRefinementForSellerEdit();
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: kCreateListingFieldGap),
                                CreateListingTextSurface(
                                  controller: _enginePower,
                                  builder: (context, hasValue) {
                                    return TextFormField(
                                      key: const ValueKey(
                                        'create_listing_engine_power_field',
                                      ),
                                      controller: _enginePower,
                                      decoration: createListingFieldDecoration(
                                        theme,
                                        hintText: l10n
                                            .createListingEnginePowerPlaceholder,
                                        hasValue: hasValue,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) =>
                                          _validateOptionalPower(l10n, v),
                                      enabled: !submitting,
                                      onChanged: (_) {
                                        if (_applyingCatalogSpecs) return;
                                        if (!_enginePowerFromCatalog) return;
                                        setState(
                                          () => _enginePowerFromCatalog = false,
                                        );
                                        _cancelProgressiveRefinementForSellerEdit();
                                      },
                                    );
                                  },
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
                                        hintText: l10n
                                            .createListingRegistrationPlaceholder,
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
                                          _validateOptionalRegistration(
                                            l10n,
                                            v,
                                          ),
                                      enabled: !submitting,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  CreateListingFormSection(
                    key: const ValueKey('create_listing_description_section'),
                    title: l10n.listingDetailsDescriptionSection,
                    child: CreateListingTextSurface(
                      controller: _description,
                      builder: (context, hasValue) {
                        return TextFormField(
                          key: const ValueKey(
                            'create_listing_description_field',
                          ),
                          controller: _description,
                          minLines: 3,
                          maxLines: 12,
                          maxLength: kListingDescriptionMaxLength,
                          decoration:
                              createListingFieldDecoration(
                                theme,
                                hintText: l10n.createListingDescriptionHint,
                                hasValue: hasValue,
                              ).copyWith(
                                contentPadding: const EdgeInsets.fromLTRB(
                                  kCreateListingFieldHPad,
                                  14,
                                  kCreateListingFieldHPad,
                                  12,
                                ),
                              ),
                          enabled: !submitting,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: kCreateListingInterSectionGap),

                  KeyedSubtree(
                    key: const ValueKey('create_listing_publish_section'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _price,
                            _mileage,
                            _model,
                            _variant,
                            _customBrand,
                            _city,
                            _vin,
                            _engineDisplacement,
                            _enginePower,
                          ]),
                          builder: (context, _) {
                            return ListingPreviewCard(
                              data: _listingPreviewData(l10n),
                              l10n: l10n,
                            );
                          },
                        ),
                        const SizedBox(height: kCreateListingFinishingGap),
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
      ),
    );
  }
}
