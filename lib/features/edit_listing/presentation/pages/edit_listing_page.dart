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
import '../../../listings/domain/catalog/listing_brands.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../../../listings/domain/validation/listing_valid_years.dart';
import '../../../listings/presentation/utils/contact_format.dart';
import '../../../listings/presentation/widgets/public_contact_notice.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../bloc/edit_listing_cubit.dart';
import '../bloc/edit_listing_state.dart';
import '../models/edit_listing_gallery_slot.dart';
import '../utils/edit_listing_gallery_initializer.dart';
import '../widgets/edit_listing_gallery_section.dart';

final String _kListingBrandCatalogOther = kListingBrandCatalog.last;

String _localizedBrandCatalogLabel(AppLocalizations l10n, String catalogValue) {
  return catalogValue == _kListingBrandCatalogOther
      ? l10n.createListingBrandOther
      : catalogValue;
}

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
              );
            case EditListingStatus.ready:
              return _EditListingForm(
                listing: state.listing!,
                listingGalleryImages: state.listingGalleryImages,
                galleryLoadSucceeded: state.galleryLoadSucceeded,
                submitting: false,
                imagePicker: imagePicker,
              );
            case EditListingStatus.submitting:
              return _EditListingForm(
                listing: state.listing!,
                listingGalleryImages: state.listingGalleryImages,
                galleryLoadSucceeded: state.galleryLoadSucceeded,
                submitting: true,
                imagePicker: imagePicker,
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
  });

  final Listing listing;
  final List<ListingImage> listingGalleryImages;
  final bool galleryLoadSucceeded;
  final bool submitting;
  final EditListingImagePicker? imagePicker;

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

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final year = _yearFieldKey.currentState!.value!;
    final input = EditListingInput(
      listingId: widget.listing.id,
      title: _title.text.trim(),
      make: _effectiveMakeForSubmit(),
      model: _model.text.trim(),
      year: year,
      priceEur: num.parse(_price.text.trim()),
      mileageKm: int.parse(_mileage.text.trim()),
      type: _type,
      city: _city.text.trim(),
      marketRegion: _marketRegion,
      contactPhone: _phone.text.trim(),
      telegramUsername: normalizeTelegramUsername(_telegram.text),
      whatsappEnabled: _whatsappEnabled,
      priceCurrency: _priceCurrency,
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
                                final picked = await showModalBottomSheet<int>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (sheetCtx) => SafeArea(
                                    child: _YearPickSheet(appL10n: l10n),
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
        .where((b) {
          final label = _localizedBrandCatalogLabel(l10n, b);
          return q.isEmpty || label.toLowerCase().contains(q);
        })
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
                icon: Icon(Icons.done_rounded),
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
