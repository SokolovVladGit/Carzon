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
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/presentation/widgets/listing_brand_pick_sheet.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/constants/listing_text_limits.dart';
import '../../../listings/domain/listing_submit_title.dart';
import '../../../listings/domain/validation/listing_vin.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/listing_vehicle_spec_pickers.dart';
import '../../../listings/presentation/widgets/listing_year_pick_sheet.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/new_listing_input.dart';
import '../bloc/create_listing_cubit.dart';
import '../bloc/create_listing_state.dart';
import '../models/create_listing_photo_draft.dart';
import '../widgets/create_listing_compose_layout.dart';
import '../widgets/create_listing_media_section.dart';
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
  const CreateListingPage({super.key, @visibleForTesting this.imagePicker});

  @visibleForTesting
  final CreateListingImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateListingCubit>(),
      child: _CreateListingView(imagePicker: imagePicker),
    );
  }
}

class _CreateListingView extends StatelessWidget {
  const _CreateListingView({this.imagePicker});

  final CreateListingImagePicker? imagePicker;

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
            );
          },
        ),
      ),
    );
  }
}

class _CreateListingForm extends StatefulWidget {
  const _CreateListingForm({required this.sellerId, this.imagePicker});

  final String sellerId;
  final CreateListingImagePicker? imagePicker;

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
        model: _model.text.trim(),
        year: _yearFieldKey.currentState!.value!,
        l10n: l10n,
      ),
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
            : localizedListingBrandCatalogLabel(
                l10n,
                _selectedBrandCatalogValue!,
              );

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
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
                CreateListingComposeHero(l10n: l10n),
                const SizedBox(height: 20),
                CreateListingPremiumSection(
                  stepIndex: 1,
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
                      const SizedBox(height: 26),
                      CreateListingFieldLabel(l10n.fieldTitleOptional),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _title,
                        decoration: createListingFieldDecoration(theme),
                        textInputAction: TextInputAction.next,
                        validator: (_) => null,
                        enabled: !submitting,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                CreateListingPremiumSection(
                  stepIndex: 2,
                  tone: CreateListingSectionTone.identity,
                  title: l10n.createListingSectionVehicle,
                  subtitle: l10n.createListingSectionVehicleSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingFieldLabel(l10n.fieldCity),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _city,
                        decoration: createListingFieldDecoration(theme),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 22),
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
                              decoration: createListingFieldDecoration(
                                theme,
                                labelText: l10n.createListingBrandLabel,
                              ).copyWith(errorText: fieldState.errorText),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  brandDisplay,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
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
                          decoration: createListingFieldDecoration(
                            theme,
                            hintText: l10n.createListingCustomBrandHint,
                          ),
                          textInputAction: TextInputAction.next,
                          enabled: !submitting,
                        ),
                      ],

                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _model,
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.fieldModel,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => _required(l10n, v),
                        enabled: !submitting,
                      ),

                      const SizedBox(height: 22),
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
                            splashColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            highlightColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.02),
                            onTap: submitting
                                ? null
                                : () async {
                                    final picked =
                                        await showListingYearPickSheet(
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
                            child: InputDecorator(
                              decoration: createListingFieldDecoration(
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
                      const SizedBox(height: 22),
                      CreateListingFieldLabel(l10n.listingBodyTypeSectionTitle),
                      const SizedBox(height: 6),
                      CreateListingHelperText(
                        l10n.listingBodyTypeSectionSubtitle,
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('create_listing_body_type_field'),
                          borderRadius: BorderRadius.circular(14),
                          splashColor: theme.colorScheme.onSurface.withValues(
                            alpha: 0.038,
                          ),
                          highlightColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.018),
                          onTap: submitting ? null : _openBodyTypeSheet,
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: theme.brightness == Brightness.light
                                      ? 0.18
                                      : 0.34,
                                ),
                              ),
                              color: Color.alphaBlend(
                                theme.colorScheme.primary.withValues(
                                  alpha: theme.brightness == Brightness.light
                                      ? 0.036
                                      : 0.085,
                                ),
                                theme.colorScheme.surface,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(17, 15, 12, 15),
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
                                      theme.colorScheme.primary.withValues(
                                        alpha:
                                            theme.brightness == Brightness.light
                                            ? 0.070
                                            : 0.16,
                                      ),
                                      theme.colorScheme.surface,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.18),
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
                      const SizedBox(height: 24),
                      CreateListingHelperText(
                        l10n.createListingSectionSpecsSubtitle,
                      ),
                      const SizedBox(height: 14),
                      CreateListingFieldLabel(l10n.listingFuelType),
                      const SizedBox(height: 8),
                      ListingVehicleSpecPickerRow(
                        valueText: _fuelType == null
                            ? l10n.listingBodyTypeNotSpecified
                            : formatListingFuelType(l10n, _fuelType!),
                        enabled: !submitting,
                        onTap: submitting ? null : () => _openFuelTypeSheet(),
                        fieldKey: const ValueKey('create_listing_fuel_field'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _engineDisplacement,
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.listingEngineDisplacement,
                          hintText: l10n.listingEngineDisplacementHint,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            _validateOptionalDisplacement(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _enginePower,
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.listingEnginePower,
                          hintText: l10n.listingEnginePowerHint,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => _validateOptionalPower(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 16),
                      CreateListingFieldLabel(l10n.listingDrivetrain),
                      const SizedBox(height: 8),
                      ListingVehicleSpecPickerRow(
                        valueText: _drivetrain == null
                            ? l10n.listingBodyTypeNotSpecified
                            : formatListingDrivetrain(l10n, _drivetrain!),
                        enabled: !submitting,
                        onTap: submitting ? null : () => _openDrivetrainSheet(),
                        fieldKey: const ValueKey(
                          'create_listing_drivetrain_field',
                        ),
                      ),
                      const SizedBox(height: 16),
                      CreateListingFieldLabel(l10n.listingTransmission),
                      const SizedBox(height: 8),
                      ListingVehicleSpecPickerRow(
                        valueText: _transmissionType == null
                            ? l10n.listingBodyTypeNotSpecified
                            : formatListingTransmissionType(
                                l10n,
                                _transmissionType!,
                              ),
                        enabled: !submitting,
                        onTap: submitting
                            ? null
                            : () => _openTransmissionSheet(),
                        fieldKey: const ValueKey(
                          'create_listing_transmission_field',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _registration,
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.listingRegistration,
                          hintText: l10n.listingRegistrationHint,
                          helperText: l10n.listingRegistrationHelper,
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vin,
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.listingVinFieldLabel,
                          helperText: l10n.listingVinFieldHelper,
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                CreateListingPremiumSection(
                  stepIndex: 3,
                  tone: CreateListingSectionTone.identity,
                  title: l10n.createListingSectionDescription,
                  subtitle: l10n.createListingSectionDescriptionSubtitle,
                  child: TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 12,
                    maxLength: kListingDescriptionMaxLength,
                    decoration: createListingFieldDecoration(
                      theme,
                      labelText: l10n.createListingDescriptionLabel,
                      hintText: l10n.createListingDescriptionHint,
                    ),
                    enabled: !submitting,
                  ),
                ),

                const SizedBox(height: 30),

                CreateListingPremiumSection(
                  stepIndex: 4,
                  tone: CreateListingSectionTone.placement,
                  title: l10n.createListingSectionDeal,
                  subtitle: l10n.createListingSectionDealSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingFieldLabel(l10n.fieldType),
                      const SizedBox(height: 12),
                      ListingTypeDealSelector(
                        l10n: l10n,
                        theme: theme,
                        value: _type,
                        submitting: submitting,
                        onChanged: (t) => setState(() => _type = t),
                      ),
                      const SizedBox(height: 24),
                      CreateListingFieldLabel(l10n.fieldRegion),
                      const SizedBox(height: 6),
                      CreateListingHelperText(l10n.fieldRegionHelper),
                      const SizedBox(height: 12),
                      MarketPlacementSelector(
                        l10n: l10n,
                        theme: theme,
                        value: _marketRegion,
                        submitting: submitting,
                        onChanged: (r) => setState(() => _marketRegion = r),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                CreateListingPremiumSection(
                  stepIndex: 5,
                  tone: CreateListingSectionTone.metrics,
                  title: l10n.createListingSectionPrice,
                  subtitle: l10n.createListingSectionPriceSubtitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateListingFieldLabel(l10n.createListingCurrency),
                      const SizedBox(height: 10),
                      PremiumListingCurrencyBar(
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
                        decoration: createListingFieldDecoration(
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
                        decoration: createListingFieldDecoration(
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

                const SizedBox(height: 30),

                CreateListingPremiumSection(
                  stepIndex: 6,
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
                        decoration: createListingFieldDecoration(
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
                        decoration: createListingFieldDecoration(
                          theme,
                          labelText: l10n.fieldTelegram,
                          hintText: l10n.fieldTelegramHint,
                        ),
                        validator: (v) => validateTelegramUsername(l10n, v),
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 4),
                      PremiumWhatsAppToggleRow(
                        theme: theme,
                        l10n: l10n,
                        value: _whatsappEnabled,
                        submitting: submitting,
                        onChanged: (v) => setState(() => _whatsappEnabled = v),
                      ),
                      const SizedBox(height: 24),
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
