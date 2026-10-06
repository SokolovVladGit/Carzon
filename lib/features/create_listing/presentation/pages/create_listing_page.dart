import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/utils/result.dart';
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
import '../../domain/validation/listing_publish_numeric.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../bloc/manual_smart_fill_cubit.dart';
import '../bloc/manual_smart_fill_state.dart';
import '../models/catalog_resolved_form_prefill.dart';
import '../models/create_listing_draft_dirty.dart';
import '../models/create_listing_photo_draft.dart';
import '../models/create_listing_step.dart';
import '../models/listing_preview_data.dart';
import '../models/vin_resolved_form_prefill.dart';
import '../widgets/create_listing_exit_dialog.dart';
import '../widgets/create_listing_characteristics_facts.dart';
import '../widgets/create_listing_compact_summary.dart';
import '../widgets/create_listing_compose_layout.dart';
import '../widgets/create_listing_step_chrome.dart';
import '../widgets/create_listing_step_stage.dart';
import '../widgets/create_listing_quiet_surface.dart';
import '../widgets/create_listing_manual_identity_row.dart';
import '../widgets/create_listing_mmy_row.dart';
import '../widgets/listing_preview_card.dart';
import '../widgets/create_listing_contact_notice.dart';
import '../widgets/create_listing_manual_smart_fill_panel.dart';
import '../widgets/create_listing_smart_fill_sheet.dart';
import '../widgets/create_listing_media_section.dart';
import '../widgets/create_listing_picker_field.dart';
import '../widgets/create_listing_vehicle_resolve_panel.dart';
import '../widgets/create_listing_vin_card.dart';
import '../../domain/entities/manual_smart_fill_refinement.dart';
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

/// English catalog sentinel — persisted in `make` when the seller picks «Other» without text.
final String _kListingBrandCatalogOther = kListingBrandCatalog.last; // "Other"

class _VinCatalogEnrichmentToken {
  const _VinCatalogEnrichmentToken({
    required this.generation,
    required this.applyRevision,
    required this.normalizedVin,
    required this.sellerId,
    required this.make,
    required this.model,
    required this.year,
  });

  final int generation;
  final int applyRevision;
  final String? normalizedVin;
  final String sellerId;
  final String make;
  final String model;
  final int year;
}

class CreateListingPage extends StatelessWidget {
  /// Test-only. Old widget tests still exercise every field in one tree.
  /// Production flow keeps this false.
  @visibleForTesting
  static bool debugRevealAllSteps = false;

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

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final unauthenticated =
            authState.status != AuthStatus.authenticated ||
            authState.user == null;
        final heroDark = scheme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: unauthenticated
              ? (heroDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
              : heroDark
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
          child: Scaffold(
            backgroundColor: unauthenticated
                ? createListingCanvasColor(theme)
                : CreateListingFlowShell.scaffoldFallback(scheme.brightness),
            appBar: unauthenticated
                ? AppBar(
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
                  )
                : null,
            body: unauthenticated
                ? DecoratedBox(
                    decoration: createListingCanvasDecoration(theme),
                    child: AuthRequiredPrompt(
                      icon: const Icon(Icons.lock_outline_rounded, size: 48),
                      message: l10n.createListingSignInRequired,
                      primaryButtonLabel: l10n.commonSignIn,
                      onPrimaryPressed: () => context.go(AppRoutes.signIn),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          CreateListingFlowShell.backgroundAssetFor(
                            scheme.brightness,
                          ),
                          key: CreateListingFlowShell.imageKey,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return ColoredBox(
                              color: CreateListingFlowShell.scaffoldFallback(
                                scheme.brightness,
                              ),
                            );
                          },
                        ),
                      ),
                      _CreateListingForm(
                        key: ValueKey(authState.user!.id),
                        sellerId: authState.user!.id,
                        imagePicker: imagePicker,
                        vehicleModelCatalog: vehicleModelCatalog,
                      ),
                    ],
                  ),
          ),
        );
      },
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
  final _engineCylinders = TextEditingController();
  final _doors = TextEditingController();
  final _seats = TextEditingController();
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
  int _vinCatalogEnrichmentGeneration = 0;
  String? _vinCatalogEnrichmentKey;
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
  bool _engineCylindersFromVin = false;
  bool _doorsFromVin = false;
  bool _seatsFromVin = false;
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
  bool _identityAttempted = false;
  bool _manualIdentityOpen = false;
  bool _manualIdentityCollapsed = false;
  CreateListingStep _step = CreateListingStep.identity;

  /// When set, [Form.validate] only enforces fields that belong to this step.
  /// Null means every field rule is active (interactive checks and Publish).
  CreateListingStep? _validatingStep;
  bool _editingCharacteristics = false;
  bool _priceTouched = false;
  bool _allowRoutePop = false;
  bool _exitDialogOpen = false;
  CreateListingExitBaseline _exitBaseline = const CreateListingExitBaseline();
  bool _mileageTouched = false;
  bool _cityTouched = false;
  bool _phoneTouched = false;
  bool _clarificationSheetOpen = false;
  bool _resolvingSmartFillContinue = false;
  StreamSubscription<ManualSmartFillState>? _smartFillContinueSub;
  Completer<ManualSmartFillState>? _smartFillContinueWait;

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
    _vinCatalogEnrichmentGeneration += 1;
    _vinCatalogEnrichmentKey = null;
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
    _manualIdentityCollapsed = false;
    _priceTouched = false;
    _mileageTouched = false;
    _cityTouched = false;
    _phoneTouched = false;
    _exitBaseline = const CreateListingExitBaseline();
    _allowRoutePop = false;
  }

  @override
  void dispose() {
    _vinCatalogEnrichmentGeneration += 1;
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
      _engineCylinders,
      _doors,
      _seats,
      _registration,
      _vin,
      _description,
    ]) {
      c.dispose();
    }
    _smartFillDebounce?.cancel();
    _smartFillContinueSub?.cancel();
    final pending = _smartFillContinueWait;
    if (pending != null && !pending.isCompleted) {
      pending.complete(const ManualSmartFillState.idle());
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

  /// Chosen location stays on screen while its editors are open.
  bool get _showLocationSummary => _locationSummaryAllowed && _hasValidLocation;

  void _openCharacteristicsEditors() {
    setState(() => _editingCharacteristics = true);
  }

  Widget _locationEditors({
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool submitting,
    required bool offstage,
  }) {
    return Offstage(
      key: const ValueKey('create_listing_location_editors'),
      offstage: offstage,
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
                  empty: _selectedCanonicalCity == null && !_manualCity,
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
                validator: (_) {
                  if (!_fieldRuleActive(CreateListingStep.contact)) return null;
                  return _deferredTextError(
                    touched: _cityTouched,
                    validate: () =>
                        !_manualCity && _selectedCanonicalCity == null
                        ? l10n.validationRequired
                        : null,
                  );
                },
                decoration: createListingFieldDecoration(
                  theme,
                  hasValue: _selectedCanonicalCity != null || _manualCity,
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
                  key: const ValueKey('create_listing_manual_city_field'),
                  controller: _city,
                  decoration: createListingFieldDecoration(
                    theme,
                    hintText: l10n.listingCityManualFieldLabel,
                    hasValue: hasValue,
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (!_fieldRuleActive(CreateListingStep.contact)) {
                      return null;
                    }
                    return _deferredTextError(
                      touched: _cityTouched,
                      validate: () => _required(l10n, v),
                    );
                  },
                  enabled: !submitting,
                  onChanged: (_) {
                    if (_applyingListingDefaults) {
                      return;
                    }
                    setState(() {
                      _cityTouched = true;
                      _editingLocation = true;
                    });
                    context.read<CreateListingCubit>().markCityEdited();
                  },
                );
              },
            ),
          ],
          if (_editingLocation && _hasValidLocation)
            Align(
              alignment: Alignment.centerLeft,
              child: CreateListingSecondaryAction(
                key: const ValueKey('create_listing_done_location'),
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
    );
  }

  void _openLocationEditors() {
    setState(() {
      if (_editingLocation && _hasValidLocation) {
        _editingLocation = false;
      } else {
        _editingLocation = true;
      }
    });
  }

  bool _showContactSummary(AppLocalizations l10n) =>
      _contactSummaryAllowed && _hasValidContact(l10n) && !_editingContact;

  /// True only when every populated characteristic came from VIN or catalog.
  /// Mixed or seller-owned data returns false so the UI stays neutral.
  bool _characteristicsFilledAutomatically() {
    var automatic = 0;
    var seller = 0;
    void mark(bool present, bool fromAutomatic) {
      if (!present) return;
      if (fromAutomatic) {
        automatic++;
      } else {
        seller++;
      }
    }

    mark(_bodyType != null, _bodyTypeFromVin || _bodyTypeFromCatalog);
    mark(_fuelType != null, _fuelTypeFromVin || _fuelTypeFromCatalog);
    mark(
      createListingHasMeaningfulText(_engineDisplacement.text),
      _engineDisplacementFromVin || _engineDisplacementFromCatalog,
    );
    mark(
      createListingHasMeaningfulText(_enginePower.text),
      _enginePowerFromCatalog,
    );
    mark(
      _transmissionType != null,
      _transmissionTypeFromVin || _transmissionTypeFromCatalog,
    );
    mark(_drivetrain != null, _drivetrainFromVin);
    mark(
      createListingHasMeaningfulText(_engineCylinders.text),
      _engineCylindersFromVin,
    );
    mark(createListingHasMeaningfulText(_doors.text), _doorsFromVin);
    mark(createListingHasMeaningfulText(_seats.text), _seatsFromVin);
    mark(createListingHasMeaningfulText(_registration.text), false);
    return automatic > 0 && seller == 0;
  }

  bool _hasPopulatedCharacteristics() {
    return _bodyType != null ||
        _fuelType != null ||
        _drivetrain != null ||
        _transmissionType != null ||
        createListingHasMeaningfulText(_engineDisplacement.text) ||
        createListingHasMeaningfulText(_enginePower.text) ||
        createListingHasMeaningfulText(_engineCylinders.text) ||
        createListingHasMeaningfulText(_doors.text) ||
        createListingHasMeaningfulText(_seats.text) ||
        createListingHasMeaningfulText(_registration.text);
  }

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
      engineCylinders: _countFromField(_engineCylinders, max: 16),
      doors: _countFromField(_doors, max: 6),
      seats: _countFromField(_seats, max: 15),
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
    _bumpVinCatalogEnrichment();
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
    _bumpVinCatalogEnrichment();
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
      _exitBaseline = _exitBaseline.copyWithApplied(
        phone: prefill.contactPhone != null ? _phone.text : null,
        telegram: prefill.telegramUsername != null ? _telegram.text : null,
        whatsapp: prefill.whatsappEnabled != null ? _whatsappEnabled : null,
        region: prefill.marketRegion != null ? _marketRegion : null,
        city: prefill.city != null ? _city.text.trim() : null,
      );
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
      if (vinMayReplaceField(
            isEmpty: _engineCylinders.text.trim().isEmpty,
            catalogOwned: false,
          ) &&
          prefill.engineCylinders != null) {
        _engineCylinders.text = '${prefill.engineCylinders}';
        _engineCylindersFromVin = true;
      }
      if (vinMayReplaceField(
            isEmpty: _doors.text.trim().isEmpty,
            catalogOwned: false,
          ) &&
          prefill.doors != null) {
        _doors.text = '${prefill.doors}';
        _doorsFromVin = true;
      }
      if (vinMayReplaceField(
            isEmpty: _seats.text.trim().isEmpty,
            catalogOwned: false,
          ) &&
          prefill.seats != null) {
        _seats.text = '${prefill.seats}';
        _seatsFromVin = true;
      }
    });
    _applyingVinSpecs = false;
  }

  void _scheduleVinCatalogEnrichment(CreateListingVehicleResolve resolve) {
    final identity = resolve.confirmedIdentity;
    if (!resolve.confirmed || identity == null) return;
    if (!_vinCatalogEnrichmentHasGap()) return;
    final key = [
      widget.sellerId,
      resolve.applyRevision,
      resolve.normalizedVin,
      identity.make,
      identity.model,
      identity.year,
    ].join('|');
    if (_vinCatalogEnrichmentKey == key) return;
    _vinCatalogEnrichmentKey = key;
    final token = _VinCatalogEnrichmentToken(
      generation: ++_vinCatalogEnrichmentGeneration,
      applyRevision: resolve.applyRevision,
      normalizedVin: resolve.normalizedVin,
      sellerId: widget.sellerId,
      make: identity.make,
      model: identity.model,
      year: identity.year,
    );
    unawaited(_runVinCatalogEnrichment(token));
  }

  bool _vinCatalogEnrichmentHasGap() {
    return _catalogGap(
          isEmpty: _bodyType == null,
          vinOwned: _bodyTypeFromVin,
          catalogOwned: _bodyTypeFromCatalog,
        ) ||
        _catalogGap(
          isEmpty: _fuelType == null,
          vinOwned: _fuelTypeFromVin,
          catalogOwned: _fuelTypeFromCatalog,
        ) ||
        _catalogGap(
          isEmpty: _engineDisplacement.text.trim().isEmpty,
          vinOwned: _engineDisplacementFromVin,
          catalogOwned: _engineDisplacementFromCatalog,
        ) ||
        _catalogGap(
          isEmpty: _enginePower.text.trim().isEmpty,
          vinOwned: false,
          catalogOwned: _enginePowerFromCatalog,
        ) ||
        _catalogGap(
          isEmpty: _transmissionType == null,
          vinOwned: _transmissionTypeFromVin,
          catalogOwned: _transmissionTypeFromCatalog,
        );
  }

  bool _catalogGap({
    required bool isEmpty,
    required bool vinOwned,
    required bool catalogOwned,
  }) {
    return catalogMayFillField(
      isEmpty: isEmpty,
      vinOwned: vinOwned,
      catalogOwned: catalogOwned,
    );
  }

  Future<void> _runVinCatalogEnrichment(
    _VinCatalogEnrichmentToken token,
  ) async {
    final Result<ManualSmartFillResult> result;
    try {
      result = await context.read<ManualSmartFillCubit>().peekIdentityConsensus(
        make: token.make,
        model: token.model,
        year: token.year,
      );
    } catch (_) {
      return;
    }
    if (!_vinCatalogEnrichmentCurrent(token)) return;
    if (result is! Success<ManualSmartFillResult>) return;
    _applyVinCatalogEnrichment(token, result.value);
  }

  void _applyVinCatalogEnrichment(
    _VinCatalogEnrichmentToken token,
    ManualSmartFillResult result,
  ) {
    if (result.resolution != ManualSmartFillResolution.ok) return;
    final blocked = _blockedCatalogKinds(result);
    if (result.clarification != null &&
        parseManualSmartFillRefinementKind(result.clarification!.attribute) ==
            null &&
        result.nextRefinement == null) {
      return;
    }
    final prefill = catalogResolvedFormPrefill(result.consensus);
    if (prefill.isEmpty) return;
    if (!_vinCatalogEnrichmentCurrent(token)) return;
    _applyingCatalogSpecs = true;
    setState(() {
      if (!_vinCatalogEnrichmentCurrent(token)) return;
      if (!blocked.contains(ManualSmartFillRefinementKind.body) &&
          _catalogGap(
            isEmpty: _bodyType == null,
            vinOwned: _bodyTypeFromVin,
            catalogOwned: _bodyTypeFromCatalog,
          ) &&
          prefill.bodyType != null) {
        _bodyType = prefill.bodyType;
        _bodyTypeFromCatalog = true;
        _bodyTypeFromVin = false;
      }
      if (!blocked.contains(ManualSmartFillRefinementKind.fuel) &&
          _catalogGap(
            isEmpty: _fuelType == null,
            vinOwned: _fuelTypeFromVin,
            catalogOwned: _fuelTypeFromCatalog,
          ) &&
          prefill.fuelType != null) {
        _fuelType = prefill.fuelType;
        _fuelTypeFromCatalog = true;
        _fuelTypeFromVin = false;
      }
      final engineBlocked = blocked.contains(
        ManualSmartFillRefinementKind.engine,
      );
      if (!engineBlocked &&
          _catalogGap(
            isEmpty: _engineDisplacement.text.trim().isEmpty,
            vinOwned: _engineDisplacementFromVin,
            catalogOwned: _engineDisplacementFromCatalog,
          ) &&
          prefill.engineDisplacementLiters != null) {
        _engineDisplacement.text = formatCatalogDisplacementField(
          prefill.engineDisplacementLiters!,
        );
        _engineDisplacementFromCatalog = true;
        _engineDisplacementFromVin = false;
      }
      if (!engineBlocked &&
          _catalogGap(
            isEmpty: _enginePower.text.trim().isEmpty,
            vinOwned: false,
            catalogOwned: _enginePowerFromCatalog,
          ) &&
          prefill.enginePowerHp != null) {
        _enginePower.text = '${prefill.enginePowerHp}';
        _enginePowerFromCatalog = true;
      }
      if (!blocked.contains(ManualSmartFillRefinementKind.transmission) &&
          _catalogGap(
            isEmpty: _transmissionType == null,
            vinOwned: _transmissionTypeFromVin,
            catalogOwned: _transmissionTypeFromCatalog,
          ) &&
          prefill.transmissionType != null) {
        _transmissionType = prefill.transmissionType;
        _transmissionTypeFromCatalog = true;
        _transmissionTypeFromVin = false;
      }
    });
    _applyingCatalogSpecs = false;
  }

  Set<ManualSmartFillRefinementKind> _blockedCatalogKinds(
    ManualSmartFillResult result,
  ) {
    final blocked = <ManualSmartFillRefinementKind>{};
    final next = result.nextRefinement?.kind;
    if (next != null) blocked.add(next);
    final parsed = parseManualSmartFillRefinementKind(
      result.clarification?.attribute,
    );
    if (parsed != null) blocked.add(parsed);
    return blocked;
  }

  bool _vinCatalogEnrichmentCurrent(_VinCatalogEnrichmentToken token) {
    if (!mounted || token.generation != _vinCatalogEnrichmentGeneration) {
      return false;
    }
    if (widget.sellerId != token.sellerId || _manualIdentityOpen) return false;
    final cubit = context.read<CreateListingCubit>();
    final status = cubit.state.status;
    if (status == CreateListingStatus.submitting ||
        status == CreateListingStatus.success) {
      return false;
    }
    final resolve = cubit.state.vehicleResolve;
    final identity = resolve.confirmedIdentity;
    if (!resolve.confirmed || identity == null) return false;
    if (resolve.applyRevision != token.applyRevision) return false;
    if (resolve.normalizedVin != token.normalizedVin) return false;
    if (identity.make != token.make ||
        identity.model != token.model ||
        identity.year != token.year) {
      return false;
    }
    if (!_makeFromVin) {
      final make = _effectiveMakeForSubmit();
      if (make.isNotEmpty && make != token.make) return false;
    }
    if (!_modelFromVin) {
      final model = _effectiveModelForSubmit();
      if (model.isNotEmpty && model != token.model) return false;
    }
    if (!_yearFromVin) {
      final year = _yearFieldKey.currentState?.value;
      if (year != null && year != token.year) return false;
    }
    return true;
  }

  bool get _hasVinOwnedOptionalSpecs =>
      _bodyTypeFromVin ||
      _fuelTypeFromVin ||
      _drivetrainFromVin ||
      _transmissionTypeFromVin ||
      _engineDisplacementFromVin ||
      _engineCylindersFromVin ||
      _doorsFromVin ||
      _seatsFromVin;

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
      if (_engineCylindersFromVin) _engineCylinders.clear();
      if (_doorsFromVin) _doors.clear();
      if (_seatsFromVin) _seats.clear();
      _makeFromVin = _modelFromVin = _yearFromVin = _variantFromVin = false;
      _bodyTypeFromVin = _fuelTypeFromVin = _drivetrainFromVin =
          _transmissionTypeFromVin = _engineDisplacementFromVin =
              _engineCylindersFromVin = _doorsFromVin = _seatsFromVin = false;
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
    _bumpVinCatalogEnrichment();
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
    if (_attemptedPublish || _identityAttempted) return true;
    return (_brandFieldKey.currentState?.hasInteractedByUser ?? false) ||
        (_yearFieldKey.currentState?.hasInteractedByUser ?? false);
  }

  bool _fieldRuleActive(CreateListingStep owner) {
    final step = _validatingStep;
    if (step == null || step == CreateListingStep.review) return true;
    return step == owner;
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
    if (_manualIdentityOpen || _attemptedPublish || _identityAttempted) {
      return true;
    }
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

  /// Accordion visibility. Idle/manual follow the presentation flags.
  /// Other resolve states keep [_showIdentityEditors].
  bool _manualIdentityExpanded(CreateListingVehicleResolve resolve) {
    if (resolve.confirmed &&
        resolve.status == CreateListingVinResolveStatus.resolved) {
      return false;
    }
    return switch (resolve.status) {
      CreateListingVinResolveStatus.idle => _manualIdentityOpen,
      CreateListingVinResolveStatus.manual =>
        _manualIdentityOpen || !_manualIdentityCollapsed,
      _ => _showIdentityEditors(resolve),
    };
  }

  void _toggleManualIdentity() {
    final resolve = context.read<CreateListingCubit>().state.vehicleResolve;
    if (_manualIdentityExpanded(resolve)) {
      setState(() {
        _manualIdentityCollapsed = true;
        _manualIdentityOpen = false;
      });
      return;
    }
    _manualIdentityCollapsed = false;
    if (resolve.status == CreateListingVinResolveStatus.manual) {
      setState(() => _manualIdentityOpen = true);
      return;
    }
    _enterManualIdentity();
  }

  void _enterManualIdentity() {
    _bumpVinCatalogEnrichment();
    setState(() {
      _manualIdentityOpen = true;
      _manualIdentityCollapsed = false;
    });
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
      if (_engineCylindersFromVin) {
        _engineCylinders.clear();
        _engineCylindersFromVin = false;
      }
      if (_doorsFromVin) {
        _doors.clear();
        _doorsFromVin = false;
      }
      if (_seatsFromVin) {
        _seats.clear();
        _seatsFromVin = false;
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

  void _confirmResolvedVinIfNeeded() {
    final cubit = context.read<CreateListingCubit>();
    final resolve = cubit.state.vehicleResolve;
    final suggestion = resolve.suggestion;
    if (resolve.confirmed) return;
    if (resolve.status != CreateListingVinResolveStatus.resolved) return;
    if (suggestion == null || !suggestion.vehicle.hasCoreIdentity) return;
    if (suggestion.resolution != VehicleResolveResolution.resolved) return;
    cubit.confirmSuggestion();
    // Bloc listeners are asynchronous. Apply the confirmed identity before
    // step validation so Continue can advance in the same turn.
    final updated = cubit.state.vehicleResolve;
    final identity = updated.confirmedIdentity;
    if (!updated.confirmed || identity == null) return;
    if (updated.applyRevision == _lastAppliedResolveRevision) return;
    _lastAppliedResolveRevision = updated.applyRevision;
    _applyConfirmedIdentity(identity);
    context.read<ManualSmartFillCubit>().cancelForVinAuthority();
    _applyConfirmedVinSpecs(
      updated.suggestion?.vehicle,
      warnings: updated.suggestion?.warnings ?? const [],
    );
    _scheduleVinCatalogEnrichment(updated);
  }

  bool _coreIdentityReady() {
    return _effectiveMakeForSubmit().isNotEmpty &&
        _effectiveModelForSubmit().isNotEmpty &&
        _yearFieldKey.currentState?.value != null;
  }

  CreateListingStep? _firstInvalidStep(AppLocalizations l10n) {
    if (_validateOptionalVin(l10n, _vin.text) != null) {
      return CreateListingStep.identity;
    }
    if (_selectedBrandCatalogValue == null) return CreateListingStep.identity;
    if (validateListingCustomMakeField(
          l10n,
          catalogKey: _selectedBrandCatalogValue,
          customMakeText: _customBrand.text,
        ) !=
        null) {
      return CreateListingStep.identity;
    }
    if ((_manualModel || _isCustomMake) &&
        _required(l10n, _model.text) != null) {
      return CreateListingStep.identity;
    }
    if (_effectiveModelForSubmit().isEmpty) return CreateListingStep.identity;
    if (_yearFieldKey.currentState?.value == null) {
      return CreateListingStep.identity;
    }
    if (_validateOptionalVariant(l10n, _variant.text) != null) {
      return CreateListingStep.identity;
    }
    if (_validatePrice(l10n, _price.text) != null)
      return CreateListingStep.offer;
    if (_validateMileage(l10n, _mileage.text) != null) {
      return CreateListingStep.offer;
    }
    if (_validateOptionalDisplacement(l10n, _engineDisplacement.text) != null ||
        _validateOptionalPower(l10n, _enginePower.text) != null ||
        _validateOptionalCount(l10n, _engineCylinders.text, max: 16) != null ||
        _validateOptionalCount(l10n, _doors.text, max: 6) != null ||
        _validateOptionalCount(l10n, _seats.text, max: 15) != null ||
        _validateOptionalRegistration(l10n, _registration.text) != null) {
      return CreateListingStep.characteristics;
    }
    final cityMissing = _manualCity
        ? _required(l10n, _city.text) != null
        : _selectedCanonicalCity == null;
    if (cityMissing) return CreateListingStep.contact;
    if (validatePhone(l10n, _phone.text) != null) {
      return CreateListingStep.contact;
    }
    if (validateTelegramUsername(l10n, _telegram.text) != null) {
      return CreateListingStep.contact;
    }
    return null;
  }

  bool get _draftIsDirty {
    final confirmed =
        _hasAdoptedIdentity ||
        context.read<CreateListingCubit>().state.vehicleResolve.confirmed;
    final model = _model.text.trim().isNotEmpty
        ? _model.text
        : (_selectedCanonicalModel ?? '');
    return createListingRouteExitIsDirty(
      vin: _vin.text,
      identityConfirmed: confirmed,
      make: '',
      model: model,
      customMake: _customBrand.text,
      variant: _variant.text,
      year: _yearFieldKey.currentState?.value,
      brandChosen: _selectedBrandCatalogValue != null,
      photoCount: _photoDrafts.length,
      price: _price.text,
      mileage: _mileage.text,
      dealType: _type,
      currency: _priceCurrency,
      description: _description.text,
      hasTechnicalValue:
          _bodyType != null ||
          _fuelType != null ||
          _drivetrain != null ||
          _transmissionType != null ||
          _engineDisplacement.text.trim().isNotEmpty ||
          _enginePower.text.trim().isNotEmpty ||
          _registration.text.trim().isNotEmpty,
      phone: _phone.text,
      telegram: _telegram.text,
      whatsapp: _whatsappEnabled,
      region: _marketRegion,
      city: _city.text,
      baseline: _exitBaseline,
    );
  }

  void _retreat() {
    final previous = _step.previous;
    if (previous == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = previous);
  }

  Future<void> _requestLeave() async {
    if (!mounted || _allowRoutePop || _exitDialogOpen) return;
    if (!_draftIsDirty) {
      _completeLeave();
      return;
    }
    _exitDialogOpen = true;
    final leave = await showCreateListingExitDialog(context);
    if (!mounted) return;
    _exitDialogOpen = false;
    if (!leave) return;
    _completeLeave();
  }

  void _completeLeave() {
    if (!mounted) return;
    setState(() => _allowRoutePop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        context.go(AppRoutes.listings);
      }
    });
  }

  CreateListingStepFragment _during(CreateListingStep step, Widget child) {
    return CreateListingStepFragment(step: step, child: child);
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    switch (_step) {
      case CreateListingStep.identity:
        final resolve = context.read<CreateListingCubit>().state.vehicleResolve;
        if (resolve.status == CreateListingVinResolveStatus.resolving) return;
        _confirmResolvedVinIfNeeded();
        _identityAttempted = true;
        _validatingStep = CreateListingStep.identity;
        final formValid = _formKey.currentState?.validate() ?? false;
        _validatingStep = null;
        final ready = formValid && _coreIdentityReady();
        if (!ready) {
          setState(() {
            _manualIdentityOpen = true;
            _manualIdentityCollapsed = false;
          });
          return;
        }
        if (_resolvingSmartFillContinue || _clarificationSheetOpen) return;
        final smartFill = context.read<ManualSmartFillCubit>();
        if (smartFill.state.status == ManualSmartFillStatus.loading) {
          await _continueWhenSmartFillSettles(smartFill);
          return;
        }
        if (smartFill.state.showClarification) {
          await _presentClarificationSheet(advanceWhenFinished: true);
          return;
        }
        break;
      case CreateListingStep.photos:
        break;
      case CreateListingStep.offer:
        _priceTouched = true;
        _mileageTouched = true;
        _validatingStep = CreateListingStep.offer;
        final formValid = _formKey.currentState?.validate() ?? false;
        _validatingStep = null;
        if (!formValid) {
          setState(() {});
          return;
        }
        break;
      case CreateListingStep.characteristics:
        _validatingStep = CreateListingStep.characteristics;
        final formValid = _formKey.currentState?.validate() ?? false;
        _validatingStep = null;
        if (!formValid) {
          setState(() => _editingCharacteristics = true);
          return;
        }
        break;
      case CreateListingStep.contact:
        _cityTouched = true;
        _phoneTouched = true;
        _validatingStep = CreateListingStep.contact;
        final formValid = _formKey.currentState?.validate() ?? false;
        _validatingStep = null;
        if (!formValid || !_hasValidLocation || !_hasValidContact(l10n)) {
          setState(() {
            _editingLocation = true;
            _editingContact = true;
          });
          return;
        }
        break;
      case CreateListingStep.review:
        return;
    }
    final next = _step.next;
    if (next == null) return;
    setState(() => _step = next);
  }

  bool _smartFillContinueIsTerminal(
    ManualSmartFillState state,
    ManualSmartFillQuery? query,
  ) {
    if (state.status == ManualSmartFillStatus.idle) return true;
    if (query != null && state.query != null && state.query != query) {
      return true;
    }
    return state.status != ManualSmartFillStatus.loading;
  }

  Future<ManualSmartFillState> _awaitCurrentSmartFill(
    ManualSmartFillCubit cubit,
    ManualSmartFillQuery? query,
  ) {
    if (_smartFillContinueIsTerminal(cubit.state, query)) {
      return Future.value(cubit.state);
    }
    final completer = Completer<ManualSmartFillState>();
    _smartFillContinueWait = completer;
    late final StreamSubscription<ManualSmartFillState> sub;
    sub = cubit.stream.listen(
      (state) {
        if (!_smartFillContinueIsTerminal(state, query) ||
            completer.isCompleted) {
          return;
        }
        completer.complete(state);
        sub.cancel();
        if (identical(_smartFillContinueSub, sub)) {
          _smartFillContinueSub = null;
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(cubit.state);
      },
    );
    _smartFillContinueSub = sub;
    if (_smartFillContinueIsTerminal(cubit.state, query) &&
        !completer.isCompleted) {
      completer.complete(cubit.state);
      sub.cancel();
      _smartFillContinueSub = null;
    }
    return completer.future;
  }

  Future<void> _continueWhenSmartFillSettles(ManualSmartFillCubit cubit) async {
    if (!mounted || _resolvingSmartFillContinue) return;
    final query = cubit.state.query;
    setState(() => _resolvingSmartFillContinue = true);
    try {
      final resolved = await _awaitCurrentSmartFill(cubit, query);
      if (!mounted || _step != CreateListingStep.identity) return;
      if (context.read<CreateListingCubit>().state.vehicleResolve.confirmed) {
        return;
      }
      if (resolved.status == ManualSmartFillStatus.idle) return;
      if (query != null && resolved.query != null && resolved.query != query) {
        return;
      }
      if (resolved.showClarification) {
        await _presentClarificationSheet(advanceWhenFinished: true);
        return;
      }
      if (resolved.status == ManualSmartFillStatus.filled ||
          resolved.status == ManualSmartFillStatus.noData ||
          resolved.status == ManualSmartFillStatus.failure) {
        final next = _step.next;
        if (next == null) return;
        setState(() => _step = next);
      }
    } finally {
      if (mounted) setState(() => _resolvingSmartFillContinue = false);
    }
  }

  Future<void> _presentClarificationSheet({
    required bool advanceWhenFinished,
  }) async {
    if (!mounted || _clarificationSheetOpen) return;
    final cubit = context.read<ManualSmartFillCubit>();
    final opened = cubit.state;
    if (!opened.showClarification) return;
    final openedQuery = opened.query;
    _clarificationSheetOpen = true;
    var finished = false;
    try {
      finished =
          await showCreateListingSmartFillSheet(
            context: context,
            cubit: cubit,
            query: openedQuery,
            onRestart: _restartProgressiveSmartFill,
          ) ??
          false;
    } finally {
      _clarificationSheetOpen = false;
    }
    if (!mounted || !advanceWhenFinished || !finished) return;
    if (_step != CreateListingStep.identity) return;
    final current = context.read<ManualSmartFillCubit>().state;
    if (current.showClarification) return;
    if (openedQuery != null && current.query != openedQuery) return;
    if (current.status != ManualSmartFillStatus.filled &&
        current.status != ManualSmartFillStatus.noData) {
      return;
    }
    final next = _step.next;
    if (next == null) return;
    setState(() => _step = next);
  }

  void _submit() {
    _bumpVinCatalogEnrichment();
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    _priceTouched = true;
    _mileageTouched = true;
    _cityTouched = true;
    _phoneTouched = true;
    _identityAttempted = true;
    _attemptedPublish = true;
    _validatingStep = null;
    final formValid = _formKey.currentState?.validate() ?? false;
    final invalidStep = _firstInvalidStep(l10n);
    if (!formValid || invalidStep != null) {
      setState(() {
        if (invalidStep != null) _step = invalidStep;
        if (invalidStep == CreateListingStep.identity) {
          _manualIdentityOpen = true;
          _manualIdentityCollapsed = false;
        }
        if (invalidStep == CreateListingStep.characteristics) {
          _editingCharacteristics = true;
        }
        if (invalidStep == CreateListingStep.contact) {
          _editingLocation = true;
          _editingContact = true;
        }
      });
      return;
    }

    final priceEur = parseListingPublishPrice(_price.text);
    final mileageKm = parseListingPublishMileage(_mileage.text);
    if (priceEur == null || mileageKm == null) return;

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
      priceEur: priceEur,
      priceCurrency: _priceCurrency,
      mileageKm: mileageKm,
      type: _type,
      city: _effectiveCityForSubmit(),
      marketRegion: _marketRegion,
      bodyType: _bodyType,
      fuelType: _fuelType,
      engineDisplacementLiters: _engineDisplacementFromField(),
      enginePowerHp: _enginePowerFromField(),
      engineCylinders: _countFromField(_engineCylinders, max: 16),
      doors: _countFromField(_doors, max: 6),
      seats: _countFromField(_seats, max: 15),
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
    if (!_fieldRuleActive(CreateListingStep.offer)) return null;
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    if (parseListingPublishPrice(v) == null) return l10n.validationPositive;
    return null;
  }

  String? _validateMileage(AppLocalizations l10n, String? v) {
    if (!_fieldRuleActive(CreateListingStep.offer)) return null;
    if (v == null || v.trim().isEmpty) return l10n.validationRequired;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return l10n.validationNonNegative;
    if (n > kListingMileageKmMax) {
      return '${l10n.validationNonNegative} ≤ $kListingMileageKmMax';
    }
    return null;
  }

  String? _validateOptionalDisplacement(AppLocalizations l10n, String? v) {
    if (!_fieldRuleActive(CreateListingStep.characteristics)) return null;
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
    if (!_fieldRuleActive(CreateListingStep.characteristics)) return null;
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return l10n.validationEnginePowerPositive;
    if (n > 3000) return '${l10n.validationEnginePowerPositive} ≤ 3000';
    return null;
  }

  String? _validateOptionalVin(AppLocalizations l10n, String? v) {
    if (!_fieldRuleActive(CreateListingStep.identity)) return null;
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
    if (!_fieldRuleActive(CreateListingStep.identity)) return null;
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > kListingVariantMaxLength) {
      return l10n.listingVariantTooLong;
    }
    return null;
  }

  String? _validateOptionalRegistration(AppLocalizations l10n, String? v) {
    if (!_fieldRuleActive(CreateListingStep.characteristics)) return null;
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

  String? _validateOptionalCount(
    AppLocalizations l10n,
    String? v, {
    required int max,
  }) {
    if (!_fieldRuleActive(CreateListingStep.characteristics)) return null;
    return _countError(l10n, v, max: max);
  }

  String? _countError(AppLocalizations l10n, String? v, {required int max}) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 1 || n > max) return l10n.validationPositive;
    return null;
  }

  int? _countFromField(TextEditingController controller, {required int max}) {
    final t = controller.text.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 1 || n > max) return null;
    return n;
  }

  Widget _countField({
    required TextEditingController controller,
    required Key fieldKey,
    required String hint,
    required int max,
    required bool Function() fromVin,
    required void Function() clearVin,
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool submitting,
  }) {
    return CreateListingTextSurface(
      controller: controller,
      builder: (context, hasValue) {
        return TextFormField(
          key: fieldKey,
          controller: controller,
          decoration: createListingFieldDecoration(
            theme,
            hintText: hint,
            hasValue: hasValue,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => _validateOptionalCount(l10n, v, max: max),
          enabled: !submitting,
          onChanged: (_) {
            if (_applyingVinSpecs || _applyingCatalogSpecs) return;
            _bumpVinCatalogEnrichment();
            if (!fromVin()) return;
            setState(clearVin);
          },
        );
      },
    );
  }

  void _bumpVinCatalogEnrichment() {
    _vinCatalogEnrichmentGeneration += 1;
    _vinCatalogEnrichmentKey = null;
  }

  Widget _collapsedPhoneCell({
    required ThemeData theme,
    required AppLocalizations l10n,
    required bool submitting,
  }) {
    final cs = theme.colorScheme;
    final value = _phone.text.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('create_listing_contact_summary'),
        borderRadius: BorderRadius.circular(kCreateListingFactRadius),
        onTap: submitting ? null : () => setState(() => _editingContact = true),
        child: Ink(
          decoration: createListingFactSurfaceDecoration(theme),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  const CreateListingFactIconChip(
                    icon: kCreateListingIconPhone,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.createListingPhoneCaption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    kCreateListingIconChevronRight,
                    key: const ValueKey('create_listing_change_contact'),
                    size: kCreateListingChevronSize,
                    color: createListingChevronColor(theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          if (!state.vehicleResolve.confirmed) {
            _vinCatalogEnrichmentGeneration += 1;
          }
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
            if (state.vehicleResolve.confirmed) {
              _scheduleVinCatalogEnrichment(state.vehicleResolve);
            }
          }
          final defaultsRevision = state.listingDefaults.applyRevision;
          if (defaultsRevision != _lastAppliedDefaultsRevision &&
              defaultsRevision > 0) {
            _lastAppliedDefaultsRevision = defaultsRevision;
            _applyListingDefaultsPrefill(state.listingDefaults.prefill);
          }
          if (state.status == CreateListingStatus.success) {
            _allowRoutePop = true;
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
          final contactCollapsed = _showContactSummary(l10n);
          final editorsOpen = _manualIdentityExpanded(state.vehicleResolve);
          final showManualRow =
              state.vehicleResolve.status ==
                  CreateListingVinResolveStatus.idle ||
              state.vehicleResolve.status ==
                  CreateListingVinResolveStatus.manual;

          Widget priceField() {
            return CreateListingTextSurface(
              key: const ValueKey('create_listing_price_section'),
              controller: _price,
              builder: (context, hasValue) {
                return TextFormField(
                  key: const ValueKey('create_listing_price_field'),
                  controller: _price,
                  decoration:
                      createListingFieldDecoration(
                        theme,
                        hintText: '',
                        hasValue: hasValue,
                      ).copyWith(
                        labelText: l10n.createListingPricePlaceholder,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: null,
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.15,
                        ),
                        floatingLabelStyle: theme.textTheme.labelSmall
                            ?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.15,
                            ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Icon(
                            kCreateListingIconPrice,
                            size: kCreateListingRowIconSize,
                            color: createListingPassiveIconColor(theme),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 24,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(0, 20, 4, 16),
                        errorMaxLines: 3,
                        suffixIcon: PremiumListingCurrencyBar(
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
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 78,
                          minHeight: 32,
                        ),
                      ),
                  keyboardType: const TextInputType.numberWithOptions(
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
            );
          }

          Widget mileageField() {
            return CreateListingTextSurface(
              controller: _mileage,
              builder: (context, hasValue) {
                return TextFormField(
                  key: const ValueKey('create_listing_mileage_field'),
                  controller: _mileage,
                  decoration:
                      createListingFieldDecoration(
                        theme,
                        hintText: l10n.createListingMileagePlaceholder,
                        hasValue: hasValue,
                        prefixIcon: Icon(
                          kCreateListingIconMileage,
                          size: kCreateListingRowIconSize,
                          color: createListingPassiveIconColor(theme),
                        ),
                      ).copyWith(
                        labelText: l10n.listingFieldMileage,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.15,
                        ),
                        floatingLabelStyle: theme.textTheme.labelSmall
                            ?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.15,
                            ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          0,
                          20,
                          12,
                          16,
                        ),
                      ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            );
          }

          Widget phoneField() {
            return CreateListingTextSurface(
              controller: _phone,
              builder: (context, hasValue) {
                return TextFormField(
                  key: const ValueKey('create_listing_phone_field'),
                  controller: _phone,
                  decoration:
                      createListingFieldDecoration(
                        theme,
                        hintText: l10n.fieldPhone,
                        hasValue: hasValue,
                        prefixIcon: Icon(
                          kCreateListingIconPhone,
                          size: kCreateListingRowIconSize,
                          color: createListingPassiveIconColor(theme),
                        ),
                      ).copyWith(
                        labelText: l10n.createListingPhoneCaption,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        isDense: true,
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.1,
                        ),
                        floatingLabelStyle: theme.textTheme.labelSmall
                            ?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              height: 1.1,
                            ),
                        contentPadding: const EdgeInsets.fromLTRB(0, 10, 12, 8),
                      ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (!_fieldRuleActive(CreateListingStep.contact)) {
                      return null;
                    }
                    return _deferredTextError(
                      touched: _phoneTouched,
                      validate: () => validatePhone(l10n, v),
                    );
                  },
                  enabled: !submitting,
                  onChanged: (_) {
                    if (_applyingListingDefaults) {
                      return;
                    }
                    setState(() {
                      _phoneTouched = true;
                      _editingContact = true;
                    });
                    context.read<CreateListingCubit>().markPhoneEdited();
                  },
                );
              },
            );
          }

          Widget contactChannels({required bool includePhone}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (includePhone) ...[
                  const CreateListingContactNotice(),
                  const SizedBox(height: kCreateListingFieldGap),
                  phoneField(),
                  const SizedBox(height: kCreateListingFieldGap),
                ],
                CreateListingTextSurface(
                  controller: _telegram,
                  builder: (context, hasValue) {
                    return TextFormField(
                      key: const ValueKey('create_listing_telegram_field'),
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
                      validator: (v) =>
                          _fieldRuleActive(CreateListingStep.contact)
                          ? validateTelegramUsername(l10n, v)
                          : null,
                      enabled: !submitting,
                      onChanged: (_) {
                        if (_applyingListingDefaults) {
                          return;
                        }
                        setState(() => _editingContact = true);
                        context.read<CreateListingCubit>().markTelegramEdited();
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
                    context.read<CreateListingCubit>().markWhatsappEdited();
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
                      key: const ValueKey('create_listing_done_contact'),
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
            );
          }

          final brandDisplay = listingBrandFieldDisplay(
            l10n: l10n,
            catalogKey: _selectedBrandCatalogValue,
            customMakeText: _customBrand.text,
          );

          return PopScope(
            canPop: _allowRoutePop,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || _allowRoutePop || _exitDialogOpen) return;
              unawaited(_requestLeave());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreateListingFlowShell(
                  step: _step,
                  submitting: submitting,
                  onStepBack: _retreat,
                  onIdentityBack: () => unawaited(_requestLeave()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kCreateListingPageHorizontalPadding,
                          8,
                          kCreateListingPageHorizontalPadding,
                          0,
                        ),
                        child: CreateListingStepStage(
                          step: _step,
                          revealAll: CreateListingPage.debugRevealAllSteps,
                          fragments: [
                            _during(
                              CreateListingStep.identity,
                              CreateListingVinCard(
                                l10n: l10n,
                                theme: theme,
                                controller: _vin,
                                enabled: !submitting,
                                scanning: _scanningVin,
                                onScan: _scanVin,
                                onChanged: (v) => context
                                    .read<CreateListingCubit>()
                                    .onVinChanged(v),
                                validator: (v) => _validateOptionalVin(l10n, v),
                              ),
                            ),
                            _during(
                              CreateListingStep.identity,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      l10n.createListingVinAutofillHelper,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(
                                                  alpha:
                                                      theme.brightness ==
                                                          Brightness.light
                                                      ? 0.55
                                                      : 0.68,
                                                ),
                                            height: 1.3,
                                          ),
                                    ),
                                  ),
                                  if (state.vehicleResolve.status !=
                                          CreateListingVinResolveStatus.idle &&
                                      !state.vehicleResolve.confirmed)
                                    const SizedBox(
                                      height: kCreateListingFieldGap,
                                    ),
                                  CreateListingVehicleResolvePanel(
                                    l10n: l10n,
                                    theme: theme,
                                    resolve: state.vehicleResolve,
                                    enabled: !submitting,
                                    compactMake: _effectiveMakeForSubmit(),
                                    compactModel: _effectiveModelForSubmit(),
                                    compactYear:
                                        _yearFieldKey.currentState?.value,
                                    compactVariant: _variantForSubmit(),
                                    onEnterManual: _enterManualIdentity,
                                    onRetry: () => context
                                        .read<CreateListingCubit>()
                                        .retryResolve(),
                                  ),
                                ],
                              ),
                            ),
                            _during(
                              CreateListingStep.photos,
                              KeyedSubtree(
                                key: const ValueKey(
                                  'create_listing_photos_section',
                                ),
                                child: CreateListingQuietSurface(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              l10n.createListingSectionPhotosLead,
                                              style:
                                                  createListingQuietTitleStyle(
                                                    theme,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            l10n.createListingPhotoCount(
                                              _photoDrafts.length,
                                            ),
                                            style:
                                                createListingSupportStyle(
                                                  theme,
                                                )?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            kCreateListingHeadingToContentGap,
                                      ),
                                      CreateListingMediaSection(
                                        photos: _photoDrafts,
                                        pickingImage: _pickingImage,
                                        disabled: submitting,
                                        onAddPhoto: () => _addPhoto(context),
                                        onRemovePhotoAt: _removePhotoAt,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _during(
                              CreateListingStep.identity,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showManualRow) ...[
                                    const SizedBox(
                                      height: kCreateListingInterSectionGap,
                                    ),
                                    CreateListingManualIdentityRow(
                                      label:
                                          l10n.createListingManualVehicleTitle,
                                      enabled: !submitting,
                                      expanded: editorsOpen,
                                      onPressed: _toggleManualIdentity,
                                    ),
                                  ],
                                  SizedBox(
                                    height: editorsOpen
                                        ? (showManualRow
                                              ? kCreateListingFieldGap
                                              : kCreateListingInterSectionGap)
                                        : 0,
                                  ),
                                  KeyedSubtree(
                                    key: const ValueKey(
                                      'create_listing_vehicle_section',
                                    ),
                                    child: Offstage(
                                      key: const ValueKey(
                                        'create_listing_identity_editors',
                                      ),
                                      offstage: !editorsOpen,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          CreateListingQuietSurface(
                                            title: l10n
                                                .createListingManualVehicleSubtitle,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                CreateListingMmyRow(
                                                  make: FormField<String?>(
                                                    key: _brandFieldKey,
                                                    validator: (_) {
                                                      if (!_fieldRuleActive(
                                                        CreateListingStep
                                                            .identity,
                                                      )) {
                                                        return null;
                                                      }
                                                      return _selectedBrandCatalogValue ==
                                                              null
                                                          ? l10n.validationRequired
                                                          : null;
                                                    },
                                                    builder: (fieldState) {
                                                      return CreateListingPickerField(
                                                        fieldKey: const ValueKey(
                                                          'create_listing_brand_field',
                                                        ),
                                                        compact: true,
                                                        caption: l10n
                                                            .createListingBrandLabel,
                                                        label: l10n
                                                            .createListingMmyValuePlaceholder,
                                                        value: brandDisplay,
                                                        empty:
                                                            _selectedBrandCatalogValue ==
                                                            null,
                                                        enabled: !submitting,
                                                        errorText:
                                                            _visibleVehicleIdentityError(
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
                                                  model: Builder(
                                                    builder: (context) {
                                                      final modelEnabled =
                                                          !submitting &&
                                                          _selectedBrandCatalogValue !=
                                                              null &&
                                                          !_isCustomMake;
                                                      final modelEmpty =
                                                          _selectedCanonicalModel ==
                                                              null &&
                                                          !_manualModel &&
                                                          !_isCustomMake;
                                                      return ListingModelSelectorField(
                                                        key: const ValueKey(
                                                          'create_listing_model_field',
                                                        ),
                                                        formFieldKey:
                                                            _modelSelectorKey,
                                                        l10n: l10n,
                                                        enabled: modelEnabled,
                                                        dense: true,
                                                        caption:
                                                            l10n.fieldModel,
                                                        manualMode:
                                                            _manualModel ||
                                                            _isCustomMake,
                                                        canonicalModel:
                                                            _selectedCanonicalModel,
                                                        onTap: _openModelSheet,
                                                        placeholder:
                                                            _selectedBrandCatalogValue ==
                                                                null
                                                            ? l10n.createListingMmyValuePlaceholder
                                                            : null,
                                                        borderRadius:
                                                            kCreateListingFieldRadius,
                                                        denseSurface:
                                                            ({
                                                              required hasValue,
                                                              required hasError,
                                                            }) => createListingSoftSurfaceDecoration(
                                                              theme,
                                                              visualState:
                                                                  resolveCreateListingFieldVisualState(
                                                                    enabled:
                                                                        modelEnabled,
                                                                    hasValue:
                                                                        hasValue,
                                                                    error:
                                                                        hasError,
                                                                  ),
                                                              hasValue:
                                                                  hasValue,
                                                              enabled:
                                                                  modelEnabled,
                                                              error: hasError,
                                                            ),
                                                        decoration:
                                                            createListingFieldDecoration(
                                                              theme,
                                                              hasValue:
                                                                  !modelEmpty,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                  year: FormField<int?>(
                                                    key: _yearFieldKey,
                                                    initialValue: null,
                                                    validator: (y) {
                                                      if (!_fieldRuleActive(
                                                        CreateListingStep
                                                            .identity,
                                                      )) {
                                                        return null;
                                                      }
                                                      return y == null
                                                          ? l10n.validationRequired
                                                          : null;
                                                    },
                                                    builder: (fieldState) {
                                                      final yr =
                                                          fieldState.value;
                                                      return CreateListingPickerField(
                                                        fieldKey: const ValueKey(
                                                          'create_listing_year_field',
                                                        ),
                                                        compact: true,
                                                        caption: l10n.fieldYear,
                                                        label: l10n
                                                            .createListingMmyValuePlaceholder,
                                                        value: yr == null
                                                            ? ''
                                                            : '$yr',
                                                        empty: yr == null,
                                                        enabled: !submitting,
                                                        errorText:
                                                            _visibleVehicleIdentityError(
                                                              fieldState,
                                                            ),
                                                        onTap: () async {
                                                          final picked =
                                                              await showListingYearPickSheet(
                                                                context:
                                                                    context,
                                                                l10n: l10n,
                                                                selectedYear:
                                                                    yr,
                                                              );
                                                          if (!context.mounted)
                                                            return;
                                                          if (picked != null) {
                                                            setState(() {
                                                              _yearFromVin =
                                                                  false;
                                                              fieldState
                                                                  .didChange(
                                                                    picked,
                                                                  );
                                                            });
                                                            fieldState
                                                                .validate();
                                                            _onManualIdentityMaybeChanged(
                                                              immediate: true,
                                                            );
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                                if (_selectedBrandCatalogValue ==
                                                    _kListingBrandCatalogOther) ...[
                                                  const SizedBox(
                                                    height:
                                                        kCreateListingFieldGap,
                                                  ),
                                                  CreateListingTextSurface(
                                                    controller: _customBrand,
                                                    builder: (context, hasValue) {
                                                      return TextFormField(
                                                        key: const ValueKey(
                                                          'create_listing_custom_brand_field',
                                                        ),
                                                        controller:
                                                            _customBrand,
                                                        decoration:
                                                            createListingFieldDecoration(
                                                              theme,
                                                              hintText: l10n
                                                                  .createListingCustomBrandHint,
                                                              hasValue:
                                                                  hasValue,
                                                            ),
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        enabled: !submitting,
                                                        onChanged: (_) {
                                                          setState(
                                                            () => _makeFromVin =
                                                                false,
                                                          );
                                                          _onManualIdentityMaybeChanged(
                                                            immediate: false,
                                                          );
                                                        },
                                                        validator: (v) {
                                                          if (!_fieldRuleActive(
                                                            CreateListingStep
                                                                .identity,
                                                          )) {
                                                            return null;
                                                          }
                                                          return validateListingCustomMakeField(
                                                            l10n,
                                                            catalogKey:
                                                                _selectedBrandCatalogValue,
                                                            customMakeText:
                                                                v ?? '',
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ],
                                                if (_manualModel ||
                                                    _isCustomMake) ...[
                                                  const SizedBox(
                                                    height:
                                                        kCreateListingFieldGap,
                                                  ),
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
                                                        decoration:
                                                            createListingFieldDecoration(
                                                              theme,
                                                              hintText: l10n
                                                                  .listingModelManualFieldLabel,
                                                              hasValue:
                                                                  hasValue,
                                                            ),
                                                        textInputAction:
                                                            TextInputAction
                                                                .next,
                                                        validator: (v) =>
                                                            _fieldRuleActive(
                                                              CreateListingStep
                                                                  .identity,
                                                            )
                                                            ? _required(l10n, v)
                                                            : null,
                                                        enabled: !submitting,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          CreateListingTextSurface(
                                            controller: _variant,
                                            builder: (context, hasValue) {
                                              return TextFormField(
                                                key: const ValueKey(
                                                  'create_listing_variant_field',
                                                ),
                                                controller: _variant,
                                                onChanged: (_) =>
                                                    _variantFromVin = false,
                                                decoration:
                                                    createListingFieldDecoration(
                                                      theme,
                                                      hintText: l10n
                                                          .listingVariantLabel,
                                                      hasValue: hasValue,
                                                    ),
                                                textInputAction:
                                                    TextInputAction.next,
                                                maxLength:
                                                    kListingVariantMaxLength,
                                                buildCounter:
                                                    (
                                                      context, {
                                                      required currentLength,
                                                      required isFocused,
                                                      maxLength,
                                                    }) => null,
                                                validator: (v) =>
                                                    _validateOptionalVariant(
                                                      l10n,
                                                      v,
                                                    ),
                                                enabled: !submitting,
                                              );
                                            },
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          BlocBuilder<
                                            ManualSmartFillCubit,
                                            ManualSmartFillState
                                          >(
                                            builder: (context, smartFill) {
                                              if (state
                                                      .vehicleResolve
                                                      .confirmed ||
                                                  !_showIdentityEditors(
                                                    state.vehicleResolve,
                                                  )) {
                                                return const SizedBox.shrink();
                                              }
                                              return CreateListingManualSmartFillPanel(
                                                l10n: l10n,
                                                theme: theme,
                                                state: smartFill,
                                                enabled: !submitting,
                                                filledSummary:
                                                    _smartFillFilledSummary(
                                                      l10n,
                                                    ),
                                                onRestart:
                                                    _restartProgressiveSmartFill,
                                                onRetry: () => context
                                                    .read<
                                                      ManualSmartFillCubit
                                                    >()
                                                    .retry(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _during(
                              CreateListingStep.characteristics,
                              CreateListingQuietSurface(
                                key: const ValueKey(
                                  'create_listing_characteristics_section',
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l10n.createListingVehicleDataTitle,
                                      style: createListingQuietTitleStyle(
                                        theme,
                                      ),
                                    ),
                                    if (!_editingCharacteristics &&
                                        !_hasPopulatedCharacteristics()) ...[
                                      const SizedBox(height: 2),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final scale = MediaQuery.textScalerOf(
                                            context,
                                          ).scale(1);
                                          final hint = Text(
                                            l10n.createListingCharacteristicsAutoHelper,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(
                                                        alpha:
                                                            theme.brightness ==
                                                                Brightness.light
                                                            ? 0.55
                                                            : 0.68,
                                                      ),
                                                  height: 1.2,
                                                  fontSize: 13,
                                                ),
                                          );
                                          final action = CreateListingManualEntryLink(
                                            key: const ValueKey(
                                              'create_listing_edit_characteristics',
                                            ),
                                            label: l10n
                                                .createListingCharacteristicsEnterManually,
                                            enabled: !submitting,
                                            onPressed:
                                                _openCharacteristicsEditors,
                                          );
                                          if (constraints.maxWidth < 340 ||
                                              scale > 1.15) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [hint, action],
                                            );
                                          }
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(child: hint),
                                              Flexible(child: action),
                                            ],
                                          );
                                        },
                                      ),
                                    ] else ...[
                                      if (_characteristicsFilledAutomatically())
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                            bottom: 10,
                                          ),
                                          child: Text(
                                            l10n.createListingCharacteristicsFilledAutomatically,
                                            key: const ValueKey(
                                              'create_listing_characteristics_auto_status',
                                            ),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(
                                                        alpha:
                                                            theme.brightness ==
                                                                Brightness.light
                                                            ? 0.50
                                                            : 0.62,
                                                      ),
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.15,
                                                  fontSize: 12,
                                                  height: 1.2,
                                                ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 8),
                                      ListenableBuilder(
                                        listenable: Listenable.merge([
                                          _engineDisplacement,
                                          _enginePower,
                                          _engineCylinders,
                                          _doors,
                                          _seats,
                                          _registration,
                                        ]),
                                        builder: (context, _) {
                                          return CreateListingCharacteristicsFacts(
                                            facts: buildCreateListingTechnicalFacts(
                                              l10n,
                                              bodyType: _bodyType,
                                              displacementLiters:
                                                  _engineDisplacementFromField(),
                                              fuelType: _fuelType,
                                              drivetrain: _drivetrain,
                                              transmissionType:
                                                  _transmissionType,
                                              powerHp: _enginePowerFromField(),
                                              engineCylinders: _countFromField(
                                                _engineCylinders,
                                                max: 16,
                                              ),
                                              doors: _countFromField(
                                                _doors,
                                                max: 6,
                                              ),
                                              seats: _countFromField(
                                                _seats,
                                                max: 15,
                                              ),
                                              registration: _registration.text,
                                            ),
                                          );
                                        },
                                      ),
                                      if (!_editingCharacteristics)
                                        Padding(
                                          padding: EdgeInsets.zero,
                                          child: CreateListingManualEntryLink(
                                            key: const ValueKey(
                                              'create_listing_edit_characteristics',
                                            ),
                                            label: l10n
                                                .createListingEditCharacteristics,
                                            enabled: !submitting,
                                            opticalLift: 3,
                                            onPressed:
                                                _openCharacteristicsEditors,
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            l10n.createListingCharacteristicsEditorTitle,
                                            key: const ValueKey(
                                              'create_listing_characteristics_editor_title',
                                            ),
                                            style:
                                                (createListingQuietTitleStyle(
                                                          theme,
                                                        ) ??
                                                        const TextStyle())
                                                    .copyWith(
                                                      fontSize: 14,
                                                      height: 1.2,
                                                    ),
                                          ),
                                        ),
                                    ],
                                    Offstage(
                                      key: const ValueKey(
                                        'create_listing_additional_details',
                                      ),
                                      offstage: !_editingCharacteristics,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          CreateListingResponsiveFieldRow(
                                            start: CreateListingPickerField(
                                              fieldKey: const ValueKey(
                                                'create_listing_body_type_field',
                                              ),
                                              label: l10n
                                                  .listingBodyTypeSectionTitle,
                                              value: _bodyType == null
                                                  ? ''
                                                  : formatListingBodyType(
                                                      l10n,
                                                      _bodyType!,
                                                    ),
                                              empty: _bodyType == null,
                                              enabled: !submitting,
                                              onTap: _openBodyTypeSheet,
                                            ),
                                            end: CreateListingPickerField(
                                              fieldKey: const ValueKey(
                                                'create_listing_fuel_field',
                                              ),
                                              label: l10n.listingFuelType,
                                              value: _fuelType == null
                                                  ? ''
                                                  : formatListingFuelType(
                                                      l10n,
                                                      _fuelType!,
                                                    ),
                                              empty: _fuelType == null,
                                              enabled: !submitting,
                                              onTap: _openFuelTypeSheet,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          CreateListingResponsiveFieldRow(
                                            start: CreateListingTextSurface(
                                              controller: _engineDisplacement,
                                              builder: (context, hasValue) {
                                                return TextFormField(
                                                  key: const ValueKey(
                                                    'create_listing_engine_displacement_field',
                                                  ),
                                                  controller:
                                                      _engineDisplacement,
                                                  decoration:
                                                      createListingFieldDecoration(
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
                                                      _engineDisplacementFromVin =
                                                          false;
                                                      _engineDisplacementFromCatalog =
                                                          false;
                                                    });
                                                    _bumpVinCatalogEnrichment();
                                                    _cancelProgressiveRefinementForSellerEdit();
                                                  },
                                                );
                                              },
                                            ),
                                            end: CreateListingTextSurface(
                                              controller: _enginePower,
                                              builder: (context, hasValue) {
                                                return TextFormField(
                                                  key: const ValueKey(
                                                    'create_listing_engine_power_field',
                                                  ),
                                                  controller: _enginePower,
                                                  decoration:
                                                      createListingFieldDecoration(
                                                        theme,
                                                        hintText: l10n
                                                            .createListingEnginePowerPlaceholder,
                                                        hasValue: hasValue,
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  validator: (v) =>
                                                      _validateOptionalPower(
                                                        l10n,
                                                        v,
                                                      ),
                                                  enabled: !submitting,
                                                  onChanged: (_) {
                                                    if (_applyingCatalogSpecs) {
                                                      return;
                                                    }
                                                    if (!_enginePowerFromCatalog) {
                                                      return;
                                                    }
                                                    setState(
                                                      () =>
                                                          _enginePowerFromCatalog =
                                                              false,
                                                    );
                                                    _bumpVinCatalogEnrichment();
                                                    _cancelProgressiveRefinementForSellerEdit();
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          CreateListingResponsiveFieldRow(
                                            start: CreateListingPickerField(
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
                                            end: CreateListingPickerField(
                                              fieldKey: const ValueKey(
                                                'create_listing_drivetrain_field',
                                              ),
                                              label: l10n
                                                  .createListingDrivetrainNotSpecified,
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
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          CreateListingResponsiveFieldRow(
                                            start: _countField(
                                              controller: _engineCylinders,
                                              fieldKey: const ValueKey(
                                                'create_listing_engine_cylinders_field',
                                              ),
                                              hint: l10n
                                                  .createListingEngineCylindersPlaceholder,
                                              max: 16,
                                              fromVin: () =>
                                                  _engineCylindersFromVin,
                                              clearVin: () =>
                                                  _engineCylindersFromVin =
                                                      false,
                                              theme: theme,
                                              l10n: l10n,
                                              submitting: submitting,
                                            ),
                                            end: _countField(
                                              controller: _doors,
                                              fieldKey: const ValueKey(
                                                'create_listing_doors_field',
                                              ),
                                              hint: l10n
                                                  .createListingDoorsPlaceholder,
                                              max: 6,
                                              fromVin: () => _doorsFromVin,
                                              clearVin: () =>
                                                  _doorsFromVin = false,
                                              theme: theme,
                                              l10n: l10n,
                                              submitting: submitting,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          _countField(
                                            controller: _seats,
                                            fieldKey: const ValueKey(
                                              'create_listing_seats_field',
                                            ),
                                            hint: l10n
                                                .createListingSeatsPlaceholder,
                                            max: 15,
                                            fromVin: () => _seatsFromVin,
                                            clearVin: () =>
                                                _seatsFromVin = false,
                                            theme: theme,
                                            l10n: l10n,
                                            submitting: submitting,
                                          ),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                          CreateListingTextSurface(
                                            controller: _registration,
                                            builder: (context, hasValue) {
                                              return TextFormField(
                                                controller: _registration,
                                                decoration:
                                                    createListingFieldDecoration(
                                                      theme,
                                                      hintText: l10n
                                                          .createListingRegistrationPlaceholder,
                                                      hasValue: hasValue,
                                                    ),
                                                maxLength:
                                                    kListingRegistrationMaxLength,
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

                            _during(
                              CreateListingStep.offer,
                              Column(
                                key: const ValueKey(
                                  'create_listing_offer_section',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CreateListingQuietSurface(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      18,
                                    ),
                                    child: priceField(),
                                  ),
                                  const SizedBox(height: 14),
                                  CreateListingQuietSurface(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      18,
                                    ),
                                    child: mileageField(),
                                  ),
                                ],
                              ),
                            ),

                            _during(
                              CreateListingStep.contact,
                              Column(
                                key: const ValueKey(
                                  'create_listing_contact_section',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CreateListingQuietSurface(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (!contactCollapsed) ...[
                                          const CreateListingContactNotice(),
                                          const SizedBox(
                                            height: kCreateListingFieldGap,
                                          ),
                                        ],
                                        contactCollapsed
                                            ? _collapsedPhoneCell(
                                                theme: theme,
                                                l10n: l10n,
                                                submitting: submitting,
                                              )
                                            : phoneField(),
                                      ],
                                    ),
                                  ),
                                  Offstage(
                                    key: const ValueKey(
                                      'create_listing_contact_editors',
                                    ),
                                    offstage: contactCollapsed,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: contactCollapsed ? 0 : 8,
                                      ),
                                      child: contactCollapsed
                                          ? contactChannels(includePhone: true)
                                          : CreateListingQuietSurface(
                                              child: contactChannels(
                                                includePhone: false,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _during(
                              CreateListingStep.contact,
                              KeyedSubtree(
                                key: const ValueKey(
                                  'create_listing_location_section',
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_showLocationSummary)
                                      CreateListingCompactSummary(
                                        key: const ValueKey(
                                          'create_listing_location_summary',
                                        ),
                                        tapKey: const ValueKey(
                                          'create_listing_change_location',
                                        ),
                                        icon: kCreateListingIconLocation,
                                        label:
                                            l10n.createListingSectionLocation,
                                        primary: _effectiveCityForSubmit(),
                                        secondary: formatMarketRegion(
                                          l10n,
                                          _marketRegion,
                                        ),
                                        enabled: !submitting,
                                        expanded: _editingLocation,
                                        onPressed: _openLocationEditors,
                                      )
                                    else ...[
                                      Text(
                                        l10n.createListingSectionLocation,
                                        style: createListingQuietTitleStyle(
                                          theme,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (_showLocationSummary &&
                                        _editingLocation) ...[
                                      const SizedBox(
                                        height: kCreateListingFieldGap,
                                      ),
                                      _locationEditors(
                                        theme: theme,
                                        l10n: l10n,
                                        submitting: submitting,
                                        offstage: false,
                                      ),
                                    ],
                                    if (!(_showLocationSummary &&
                                        _editingLocation))
                                      _locationEditors(
                                        theme: theme,
                                        l10n: l10n,
                                        submitting: submitting,
                                        offstage: _showLocationSummary,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            _during(
                              CreateListingStep.offer,
                              Column(
                                key: const ValueKey(
                                  'create_listing_type_section',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CreateListingQuietSurface(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              kCreateListingIconListingType,
                                              size: kCreateListingEditIconSize,
                                              color:
                                                  createListingPassiveIconColor(
                                                    theme,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                l10n.createListingDealTypeLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    createListingQuietTitleStyle(
                                                      theme,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height:
                                              kCreateListingHeadingToContentGap,
                                        ),
                                        ListingTypeDealSelector(
                                          l10n: l10n,
                                          theme: theme,
                                          value: _type,
                                          submitting: submitting,
                                          onChanged: (t) =>
                                              setState(() => _type = t),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            _during(
                              CreateListingStep.review,
                              CreateListingQuietSurface(
                                title: l10n.listingDetailsDescriptionSection,
                                child: Column(
                                  key: const ValueKey(
                                    'create_listing_description_section',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CreateListingTextSurface(
                                      controller: _description,
                                      builder: (context, hasValue) {
                                        return TextFormField(
                                          key: const ValueKey(
                                            'create_listing_description_field',
                                          ),
                                          controller: _description,
                                          minLines: 4,
                                          maxLines: 8,
                                          maxLength:
                                              kListingDescriptionMaxLength,
                                          buildCounter:
                                              (
                                                context, {
                                                required currentLength,
                                                required isFocused,
                                                maxLength,
                                              }) {
                                                return Text(
                                                  '$currentLength / $maxLength',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha:
                                                                  theme.brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? 0.42
                                                                  : 0.58,
                                                            ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        letterSpacing: 0.3,
                                                        height: 1.1,
                                                      ),
                                                );
                                              },
                                          decoration:
                                              createListingFieldDecoration(
                                                theme,
                                                hintText: l10n
                                                    .createListingDescriptionHint,
                                                hasValue: hasValue,
                                                separated: true,
                                              ).copyWith(
                                                hintStyle: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha:
                                                                theme.brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? 0.42
                                                                : 0.58,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      height: 1.35,
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                      kCreateListingFieldHPad,
                                                      16,
                                                      kCreateListingFieldHPad,
                                                      16,
                                                    ),
                                              ),
                                          enabled: !submitting,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            _during(
                              CreateListingStep.review,
                              KeyedSubtree(
                                key: const ValueKey(
                                  'create_listing_publish_section',
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                    if (CreateListingPage
                                        .debugRevealAllSteps) ...[
                                      const SizedBox(
                                        height: kCreateListingFinishingGap,
                                      ),
                                      PremiumPublishActionButton(
                                        theme: theme,
                                        l10n: l10n,
                                        submitting: submitting,
                                        onPressed: _submit,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                CreateListingStepFooter(
                  step: _step,
                  submitting: submitting,
                  continueBusy: _resolvingSmartFillContinue,
                  onContinue: _onContinue,
                  onPublish: _submit,
                  l10n: l10n,
                  theme: theme,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
