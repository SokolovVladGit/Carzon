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
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../create_listing/domain/constants/listing_gallery_limits.dart';
import '../../../create_listing/domain/entities/cover_image_upload.dart';
import '../../../create_listing/presentation/widgets/create_listing_compose_layout.dart';
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/domain/constants/listing_text_limits.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../../../listings/domain/listing_submit_title.dart';
import '../../../listings/domain/validation/listing_valid_years.dart';
import '../../../listings/domain/validation/listing_vin.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import '../../../listings/presentation/widgets/listing_brand_pick_sheet.dart';
import '../../../listings/presentation/widgets/listing_year_pick_sheet.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/utils/edit_listing_vin_rpc_submission.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';
import '../utils/edit_listing_owner_vin_report_ui.dart';
import '../bloc/edit_listing_cubit.dart';
import '../bloc/edit_listing_state.dart';
import '../models/edit_listing_gallery_slot.dart';
import '../utils/edit_listing_gallery_initializer.dart';
import '../widgets/edit_listing_gallery_section.dart';

final String _kListingBrandCatalogOther = kListingBrandCatalog.last;

/// Maps cubit failure kind to localized user-facing text.
String _failureMessage(AppLocalizations l10n, EditListingFailureKind? kind) {
  return switch (kind) {
    EditListingFailureKind.load => l10n.editListingLoadFailed,
    EditListingFailureKind.notAllowed => l10n.notAllowedEdit,
    EditListingFailureKind.invalidDetails => l10n.checkDetailsAndRetry,
    EditListingFailureKind.uploadFailed => l10n.createListingPhotosUploadFailed,
    EditListingFailureKind.galleryReplaceFailed =>
      l10n.editListingGalleryReplaceFailed,
    EditListingFailureKind.coverUpdateFailed => l10n.coverUpdateFailedRetry,
    EditListingFailureKind.detailsFailed ||
    null => l10n.listingUpdateFailedRetry,
  };
}

@visibleForTesting
typedef EditListingImagePicker =
    Future<XFile?> Function({
      required ImageSource source,
      required double maxWidth,
      required int imageQuality,
    });

class EditListingPage extends StatelessWidget {
  const EditListingPage({
    super.key,
    required this.listingId,
    @visibleForTesting this.imagePicker,
  });

  final String listingId;

  @visibleForTesting
  final EditListingImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditListingCubit>()..load(listingId),
      child: _EditListingView(listingId: listingId, imagePicker: imagePicker),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.listingUpdated)));
            context.go(AppRoutes.myListings);
          } else if (state.status == EditListingStatus.failure &&
              state.listing != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_failureMessage(l10n, state.failureKind))),
            );
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case EditListingStatus.initial:
            case EditListingStatus.loading:
              return const LoadingView();
            case EditListingStatus.failure:
              if (state.listing == null) {
                return ErrorView(
                  message: l10n.editListingLoadFailed,
                  onRetry: () =>
                      context.read<EditListingCubit>().load(listingId),
                );
              }
              return _EditListingForm(
                listing: state.listing!,
                listingGalleryImages: state.listingGalleryImages,
                galleryLoadSucceeded: state.galleryLoadSucceeded,
                submitting: false,
                imagePicker: imagePicker,
                ownerVinNormalizedForEdit: state.ownerVinNormalizedForEdit,
                ownerVinLookupFailed: state.ownerVinLookupFailed,
                ownerVinReportStatus: state.ownerVinReportStatus,
                ownerVinReportLookupFailed: state.ownerVinReportLookupFailed,
                ownerVinSourceResults: state.ownerVinSourceResults,
                ownerVinSourceResultsLookupFailed:
                    state.ownerVinSourceResultsLookupFailed,
              );
            case EditListingStatus.ready:
              return _EditListingForm(
                listing: state.listing!,
                listingGalleryImages: state.listingGalleryImages,
                galleryLoadSucceeded: state.galleryLoadSucceeded,
                submitting: false,
                imagePicker: imagePicker,
                ownerVinNormalizedForEdit: state.ownerVinNormalizedForEdit,
                ownerVinLookupFailed: state.ownerVinLookupFailed,
                ownerVinReportStatus: state.ownerVinReportStatus,
                ownerVinReportLookupFailed: state.ownerVinReportLookupFailed,
                ownerVinSourceResults: state.ownerVinSourceResults,
                ownerVinSourceResultsLookupFailed:
                    state.ownerVinSourceResultsLookupFailed,
              );
            case EditListingStatus.submitting:
              return _EditListingForm(
                listing: state.listing!,
                listingGalleryImages: state.listingGalleryImages,
                galleryLoadSucceeded: state.galleryLoadSucceeded,
                submitting: true,
                imagePicker: imagePicker,
                ownerVinNormalizedForEdit: state.ownerVinNormalizedForEdit,
                ownerVinLookupFailed: state.ownerVinLookupFailed,
                ownerVinReportStatus: state.ownerVinReportStatus,
                ownerVinReportLookupFailed: state.ownerVinReportLookupFailed,
                ownerVinSourceResults: state.ownerVinSourceResults,
                ownerVinSourceResultsLookupFailed:
                    state.ownerVinSourceResultsLookupFailed,
              );
            case EditListingStatus.success:
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
    required this.listingGalleryImages,
    required this.galleryLoadSucceeded,
    required this.submitting,
    this.imagePicker,
    required this.ownerVinNormalizedForEdit,
    required this.ownerVinLookupFailed,
    required this.ownerVinReportStatus,
    required this.ownerVinReportLookupFailed,
    required this.ownerVinSourceResults,
    required this.ownerVinSourceResultsLookupFailed,
  });

  final Listing listing;
  final List<ListingImage> listingGalleryImages;
  final bool galleryLoadSucceeded;
  final bool submitting;
  final EditListingImagePicker? imagePicker;

  /// Owner-private normalized VIN from RPC when lookup succeeds.
  final String? ownerVinNormalizedForEdit;

  /// When true, omit/clear VIN submissions must stay conservative on save.
  final bool ownerVinLookupFailed;

  final OwnerListingVinReportStatus? ownerVinReportStatus;

  final bool ownerVinReportLookupFailed;

  final List<OwnerListingVinSourceResult> ownerVinSourceResults;

  final bool ownerVinSourceResultsLookupFailed;

  @override
  State<_EditListingForm> createState() => _EditListingFormState();
}

class _EditListingFormState extends State<_EditListingForm> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String?>> _brandFieldKey =
      GlobalKey<FormFieldState<String?>>();
  final GlobalKey<FormFieldState<int?>> _yearFieldKey =
      GlobalKey<FormFieldState<int?>>();

  late final TextEditingController _title;
  late final TextEditingController _model;
  late final TextEditingController _customBrand;
  late final TextEditingController _price;
  late final TextEditingController _mileage;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;

  late ListingType _type;
  late MarketRegion _marketRegion;
  ListingBodyType? _bodyType;
  ListingFuelType? _fuelType;
  ListingDrivetrain? _drivetrain;
  late final TextEditingController _engineDisplacement;
  late final TextEditingController _enginePower;
  late final TextEditingController _registration;
  late final TextEditingController _vin;
  late final TextEditingController _description;

  late bool _whatsappEnabled;
  late ListingCurrency _priceCurrency;

  String? _selectedBrandCatalogValue;
  late List<EditListingGallerySlot> _galleryDraft;

  final ImagePicker _defaultPicker = ImagePicker();
  bool _pickingImage = false;

  static String _priceText(num value) {
    if (value is int) return value.toString();
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }

  String _displacementFieldText(double liters) {
    if (liters == liters.roundToDouble()) {
      return liters.toInt().toString();
    }
    return liters.toString();
  }

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _title = TextEditingController(text: l.title);
    _model = TextEditingController(text: l.model);
    _customBrand = TextEditingController();
    _price = TextEditingController(text: _priceText(l.priceEur));
    _mileage = TextEditingController(text: l.mileageKm.toString());
    _city = TextEditingController(text: l.city);
    _phone = TextEditingController(text: l.contactPhone ?? '');
    _telegram = TextEditingController(text: l.telegramUsername ?? '');
    _type = l.type;
    _marketRegion = l.marketRegion;
    _bodyType = l.bodyType;
    _fuelType = l.fuelType;
    _drivetrain = l.drivetrain;
    _engineDisplacement = TextEditingController(
      text: l.engineDisplacementLiters == null
          ? ''
          : _displacementFieldText(l.engineDisplacementLiters!),
    );
    _enginePower = TextEditingController(
      text: l.enginePowerHp == null ? '' : '${l.enginePowerHp}',
    );
    _registration = TextEditingController(text: l.registration ?? '');
    _vin = TextEditingController(text: widget.ownerVinNormalizedForEdit ?? '');
    _description = TextEditingController(text: l.description ?? '');
    _whatsappEnabled = l.whatsappEnabled;
    _priceCurrency = l.priceCurrency;

    final normalized = listingBrandNormalizeForLookup(l.make);
    if (normalized != null) {
      _selectedBrandCatalogValue = normalized;
    } else {
      _selectedBrandCatalogValue = _kListingBrandCatalogOther;
      _customBrand.text = l.make;
    }

    _galleryDraft = List<EditListingGallerySlot>.from(
      buildInitialEditListingGallerySlots(
        listing: l,
        prefetchedGallery: widget.listingGalleryImages,
        galleryLoadSucceeded: widget.galleryLoadSucceeded,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _yearFieldKey.currentState?.didChange(l.year);
    });
  }

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

  Future<void> _addPhoto() async {
    final l10n = context.l10n;
    if (!widget.galleryLoadSucceeded) return;
    if (_galleryDraft.length >= kMaxListingPhotos) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.createListingMaxPhotos(kMaxListingPhotos))),
      );
      return;
    }
    if (_pickingImage || widget.submitting) return;

    final sellerId = widget.listing.sellerId;
    if (sellerId == null || sellerId.isEmpty) return;

    setState(() => _pickingImage = true);
    try {
      final picker = widget.imagePicker ?? _defaultPicker.pickImage;
      final picked = await picker(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      final upload = CoverImageUpload(
        sellerId: sellerId,
        bytes: bytes,
        contentType: _resolveContentType(picked),
        originalFileName: picked.name,
      );
      setState(() {
        _galleryDraft.add(EditListingGalleryLocalSlot(upload: upload));
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
    if (!widget.galleryLoadSucceeded || widget.submitting) return;
    setState(() {
      if (index < 0 || index >= _galleryDraft.length) return;
      _galleryDraft.removeAt(index);
    });
  }

  String _resolveContentType(XFile file) {
    final reported = file.mimeType?.trim().toLowerCase();
    if (reported != null && reported.isNotEmpty) return reported;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
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

  String? _validateOptionalVin(AppLocalizations l10n, String? v) {
    if (ListingVin.isBlankInput(v)) return null;
    if (!ListingVin.isOptionalInputValid(v)) return l10n.validationVinInvalid;
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final year = _yearFieldKey.currentState!.value!;
    final l10n = context.l10n;
    final vinDecision = resolveEditListingVinRpcSubmission(
      rawVinFieldText: _vin.text,
      ownerVinNormalizedForEdit: widget.ownerVinNormalizedForEdit,
      ownerVinLookupFailed: widget.ownerVinLookupFailed,
    );
    final input = EditListingInput(
      listingId: widget.listing.id,
      title: resolvedListingTitleForSubmit(
        trimmedUserTitle: _title.text.trim(),
        make: _effectiveMakeForSubmit(),
        model: _model.text.trim(),
        year: year,
        l10n: l10n,
      ),
      make: _effectiveMakeForSubmit(),
      model: _model.text.trim(),
      year: year,
      priceEur: num.parse(_price.text.trim()),
      mileageKm: int.parse(_mileage.text.trim()),
      type: _type,
      city: _city.text.trim(),
      marketRegion: _marketRegion,
      bodyType: _bodyType,
      fuelType: _fuelType,
      engineDisplacementLiters: _engineDisplacementFromField(),
      enginePowerHp: _enginePowerFromField(),
      drivetrain: _drivetrain,
      registration: _registration.text.trim().isEmpty
          ? null
          : _registration.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      contactPhone: _phone.text.trim(),
      telegramUsername: normalizeTelegramUsername(_telegram.text),
      whatsappEnabled: _whatsappEnabled,
      priceCurrency: _priceCurrency,
      submitVinParameterToRpc: vinDecision.submitVinParameterToRpc,
      vinParameter: vinDecision.vinParameter,
    );

    context.read<EditListingCubit>().save(
      input: input,
      galleryDraft: List<EditListingGallerySlot>.from(_galleryDraft),
    );
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

  String? _readOnlyCoverFallbackUrl() {
    if (widget.galleryLoadSucceeded) return null;
    final u = widget.listing.coverImageUrl?.trim();
    if (u == null || u.isEmpty) return null;
    return u;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final submitting = widget.submitting;

    final brandDisplay = _selectedBrandCatalogValue == null
        ? l10n.createListingChooseBrand
        : localizedListingBrandCatalogLabel(l10n, _selectedBrandCatalogValue!);

    final bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      kFloatingCapsuleNavClearance,
    );
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        bottomInset + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _elevatedSheet(
              context,
              child: EditListingGallerySection(
                slots: _galleryDraft,
                pickingImage: _pickingImage,
                submitting: submitting,
                galleryMutationsEnabled: widget.galleryLoadSucceeded,
                readOnlyHeroUrl: _readOnlyCoverFallbackUrl(),
                onAddPhoto: _addPhoto,
                onRemovePhotoAt: _removePhotoAt,
              ),
            ),
            const SizedBox(height: 14),
            _elevatedSheet(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _mutedSectionLabel(context, l10n.fieldTitleOptional),
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
                    validator: (_) => null,
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
                    initialValue: _selectedBrandCatalogValue,
                    validator: (_) {
                      return _selectedBrandCatalogValue == null
                          ? l10n.validationRequired
                          : null;
                    },
                    builder: (fieldState) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        key: const ValueKey('edit_listing_brand_field'),
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                    initialValue: widget.listing.year,
                    validator: (y) {
                      if (y == null) return l10n.validationRequired;
                      if (!isListingYearValid(y)) {
                        return l10n.validationYearRange(
                          listingYearMaxInclusive(),
                        );
                      }
                      return null;
                    },
                    builder: (fieldState) {
                      final yr = fieldState.value;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        key: const ValueKey('edit_listing_year_field'),
                        onTap: submitting
                            ? null
                            : () async {
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
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              yr == null ? l10n.createListingChooseYear : '$yr',
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
                        : (v) => setState(() => _type = v ?? ListingType.sale),
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
                            () =>
                                _marketRegion = v ?? MarketRegion.transnistria,
                          ),
                    validator: (v) => v == null ? l10n.regionRequired : null,
                  ),
                  const SizedBox(height: 18),
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
                  KeyedSubtree(
                    key: ValueKey(_bodyType),
                    child: DropdownButtonFormField<ListingBodyType?>(
                      key: const ValueKey('edit_listing_body_type_field'),
                      initialValue: _bodyType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface.withValues(
                          alpha: .22,
                        ),
                        labelText: l10n.listingBodyTypeSectionTitle,
                      ),
                      items: [
                        DropdownMenuItem<ListingBodyType?>(
                          value: null,
                          child: Text(l10n.listingBodyTypeNotSpecified),
                        ),
                        ...ListingBodyType.values.map(
                          (e) => DropdownMenuItem<ListingBodyType?>(
                            value: e,
                            child: Text(formatListingBodyType(l10n, e)),
                          ),
                        ),
                      ],
                      onChanged: submitting
                          ? null
                          : (v) => setState(() => _bodyType = v),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.createListingSectionSpecsSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<ListingFuelType?>(
                    initialValue: _fuelType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingFuelType,
                    ),
                    items: [
                      DropdownMenuItem<ListingFuelType?>(
                        value: null,
                        child: Text(l10n.listingBodyTypeNotSpecified),
                      ),
                      ...ListingFuelType.values.map(
                        (e) => DropdownMenuItem<ListingFuelType?>(
                          value: e,
                          child: Text(formatListingFuelType(l10n, e)),
                        ),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) => setState(() => _fuelType = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _engineDisplacement,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingEngineDisplacement,
                      hintText: l10n.listingEngineDisplacementHint,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateOptionalDisplacement(l10n, v),
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _enginePower,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingEnginePower,
                      hintText: l10n.listingEnginePowerHint,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _validateOptionalPower(l10n, v),
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ListingDrivetrain?>(
                    initialValue: _drivetrain,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingDrivetrain,
                    ),
                    items: [
                      DropdownMenuItem<ListingDrivetrain?>(
                        value: null,
                        child: Text(l10n.listingBodyTypeNotSpecified),
                      ),
                      ...ListingDrivetrain.values.map(
                        (e) => DropdownMenuItem<ListingDrivetrain?>(
                          value: e,
                          child: Text(formatListingDrivetrain(l10n, e)),
                        ),
                      ),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) => setState(() => _drivetrain = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _registration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingRegistration,
                      hintText: l10n.listingRegistrationHint,
                    ),
                    maxLength: kListingRegistrationMaxLength,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (v) => _validateOptionalRegistration(l10n, v),
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vin,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.listingVinFieldLabel,
                      helperText: l10n.listingVinFieldHelper,
                      helperMaxLines: 3,
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
                  const SizedBox(height: 10),
                  _EditListingOwnerVinStatusSection(
                    listingVinStatus: widget.listing.vinStatus,
                    ownerVinReportStatus: widget.ownerVinReportStatus,
                    ownerVinReportLookupFailed:
                        widget.ownerVinReportLookupFailed,
                    ownerVinSourceResults: widget.ownerVinSourceResults,
                    ownerVinSourceResultsLookupFailed:
                        widget.ownerVinSourceResultsLookupFailed,
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
                    key: const ValueKey('edit_listing_currency_selector'),
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  _mutedSectionLabel(
                    context,
                    l10n.listingDetailsDescriptionSection,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: .22,
                      ),
                      labelText: l10n.editListingDescriptionLabel,
                      alignLabelWithHint: true,
                      hintText: l10n.createListingDescriptionHint,
                    ),
                    minLines: 4,
                    maxLines: 10,
                    maxLength: kListingDescriptionMaxLength,
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
                    l10n.saveChanges.toUpperCase(),
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
                      shape: const StadiumBorder(),
                    ),
                    key: const ValueKey('edit_listing_save_button'),
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveChanges),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _EditListingOwnerVinStatusSection extends StatelessWidget {
  const _EditListingOwnerVinStatusSection({
    required this.listingVinStatus,
    required this.ownerVinReportStatus,
    required this.ownerVinReportLookupFailed,
    required this.ownerVinSourceResults,
    required this.ownerVinSourceResultsLookupFailed,
  });

  final ListingVinStatus listingVinStatus;
  final OwnerListingVinReportStatus? ownerVinReportStatus;
  final bool ownerVinReportLookupFailed;
  final List<OwnerListingVinSourceResult> ownerVinSourceResults;
  final bool ownerVinSourceResultsLookupFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kind = resolveEditListingOwnerVinReportUiKind(
      listingPublicVinStatus: listingVinStatus,
      reportFetchFailed: ownerVinReportLookupFailed,
      report: ownerVinReportStatus,
    );
    final primary = editListingOwnerVinReportPrimaryLine(l10n, kind);
    final basic = resolveOwnerVinBasicDecodeFields(
      report: ownerVinReportStatus,
      sourceResults: ownerVinSourceResults,
      sourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
    );

    return DecoratedBox(
      key: const ValueKey('edit_listing_owner_vin_report_section'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.editListingVinReportSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              primary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (basic != null && basic.hasAny) ...[
              const SizedBox(height: 14),
              Text(
                l10n.editListingVinReportBasicInfoHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (basic.make != null && basic.make!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedMakeLabel,
                  basic.make!.trim(),
                ),
              if (basic.model != null && basic.model!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedModelLabel,
                  basic.model!.trim(),
                ),
              if (basic.year != null)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedYearLabel,
                  '${basic.year}',
                ),
              if (basic.bodyType != null && basic.bodyType!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedBodyLabel,
                  basic.bodyType!.trim(),
                ),
              if (basic.fuelType != null && basic.fuelType!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedFuelLabel,
                  basic.fuelType!.trim(),
                ),
              const SizedBox(height: 10),
              Text(
                l10n.editListingVinReportSourceLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              l10n.editListingVinReportLimitationNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.editListingVinReportPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _ownerVinDecodeSummaryFieldRow(
  ThemeData theme,
  String label,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    ),
  );
}
