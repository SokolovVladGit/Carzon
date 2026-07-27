import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/app_localizations_x.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/listing.dart';
import '../../../domain/entities/listing_currency.dart';
import '../../../domain/entities/listing_sort_option.dart';
import '../../../domain/catalog/listing_brands.dart';
import '../../bloc/listings_state.dart';
import '../../utils/listing_formatters.dart';
import 'listing_filter_summary_presenter.dart';
import 'listings_filter_apply_result.dart';
import 'listings_filter_budget_panel.dart';
import 'listings_filter_form_seed.dart';
import 'listings_filter_labels.dart';
import 'listings_filter_section.dart';
import 'listings_filter_segmented_control.dart';
import 'listings_filter_sort_pick_sheet.dart';
import 'listings_filter_summary_strip.dart';
import 'listings_filter_vehicle_spec_selector_field.dart';
import '../../../../create_listing/presentation/widgets/listing_body_type_pick_sheet.dart';
import '../listing_brand_pick_sheet.dart';
import '../listing_vehicle_spec_pickers.dart';
import '../listing_year_pick_sheet.dart';

export 'listings_filter_form_seed.dart';

export 'listing_filter_summary_presenter.dart'
    show
        ListingsFilterSummaryView,
        buildListingsFilterSummaryView,
        isListingsFilterDraftVanilla;

/// Reusable discovery filter fields (browse feed + account filter-alert editor).
///
/// Pair with [ListingsFilterHost] or embed on any screen; submit via
/// [ListingsFilterFormState.submit].
class ListingsFilterForm extends StatefulWidget {
  const ListingsFilterForm({
    super.key,
    required this.seed,
    this.showDraftSummaryStrip = true,
    this.onDraftMutated,
  });

  final ListingsFilterFormSeed seed;

  /// When `false`, the live summary chip card is omitted (alert filter editor).
  final bool showDraftSummaryStrip;

  /// Optional hook when any controlled draft field updates (browse filter bell).
  final VoidCallback? onDraftMutated;

  @override
  State<ListingsFilterForm> createState() => ListingsFilterFormState();
}

class ListingsFilterFormState extends State<ListingsFilterForm> {
  static final String _brandOtherEnglish = kListingBrandCatalog.last;

  /// Visual-only placeholder for nullable min/max picks (localization not used).
  static const String _boundEmptyPlaceholder = '\u2014';

  late final TextEditingController _model;
  late final TextEditingController _customBrand;

  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  late final FocusNode _minPriceFocus;
  late final FocusNode _maxPriceFocus;
  late final TextEditingController _maxMileage;
  late final TextEditingController _city;
  late ListingTypeFilter _type;
  late MarketRegionFilter _region;
  late ListingSortOption _sort;
  ListingBodyType? _bodyType;
  ListingFuelType? _fuelType;
  ListingTransmissionType? _transmissionType;
  ListingDrivetrain? _drivetrain;
  late ListingPriceCurrencyFilter _priceCurrency;

  String? _catalogMake;
  int? _minYearValue;
  int? _maxYearValue;

  String? _minYearError;
  String? _maxYearError;
  String? _minPriceError;
  String? _maxPriceError;
  String? _maxMileageError;

  @override
  void initState() {
    super.initState();
    final w = widget.seed;
    _model = TextEditingController(text: w.model ?? '');
    _customBrand = TextEditingController();
    _hydrateCatalogMake(make: w.make);
    _minYearValue = w.minYear;
    _maxYearValue = w.maxYear;
    _minPrice = TextEditingController(
      text: w.minPrice != null ? w.minPrice.toString() : '',
    );
    _maxPrice = TextEditingController(
      text: w.maxPrice != null ? w.maxPrice.toString() : '',
    );
    _minPriceFocus = FocusNode(debugLabel: 'listings_filter_min_price');
    _maxPriceFocus = FocusNode(debugLabel: 'listings_filter_max_price');
    _minPriceFocus.addListener(_syncPriceFocusDecoration);
    _maxPriceFocus.addListener(_syncPriceFocusDecoration);
    _maxMileage = TextEditingController(text: w.maxMileage?.toString() ?? '');
    _city = TextEditingController(text: w.city ?? '');
    _type = w.typeFilter;
    _region = w.region;
    _sort = w.sort;
    _bodyType = w.bodyType;
    _fuelType = w.fuelType;
    _transmissionType = w.transmissionType;
    _drivetrain = w.drivetrain;
    _priceCurrency = w.priceCurrencyFilter;
    _model.addListener(_onDraftChanged);
    _customBrand.addListener(_onDraftChanged);
    _minPrice.addListener(_onDraftChanged);
    _maxPrice.addListener(_onDraftChanged);
    _maxMileage.addListener(_onDraftChanged);
    _city.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    widget.onDraftMutated?.call();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncPriceFocusDecoration() {
    if (mounted) {
      setState(() {});
    }
  }

  Color _compactFieldFill(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return scheme.surface.withValues(alpha: 0.42);
    }
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.05),
      scheme.surfaceContainerLow,
    );
  }

  Color _compactFieldBorder(
    ColorScheme scheme, {
    required bool hasError,
    required bool focused,
  }) {
    if (hasError) return scheme.error.withValues(alpha: 0.65);
    if (focused) {
      return scheme.brightness == Brightness.light
          ? scheme.primary.withValues(alpha: 0.5)
          : AppTheme.editorialDarkFieldFocusBorder(scheme);
    }
    return scheme.brightness == Brightness.light
        ? scheme.outlineVariant.withValues(alpha: 0.22)
        : scheme.outline.withValues(alpha: 0.32);
  }

  TextStyle _compactBoundPlaceholderStyle(
    ThemeData theme,
    ColorScheme scheme, {
    TextStyle? sizeReference,
  }) {
    final basis =
        sizeReference ??
        theme.textTheme.titleMedium ??
        theme.textTheme.bodyLarge ??
        const TextStyle();
    return basis.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
      color: scheme.onSurfaceVariant.withValues(
        alpha: scheme.brightness == Brightness.light ? 0.3 : 0.48,
      ),
    );
  }

  /// Draft criteria reflecting current field values (for live summary / previews).
  ListingsFilterFormSeed get draftSeed => ListingsFilterFormSeed(
    make: _effectiveMakeFilter(),
    model: _model.text.trim().isEmpty ? null : _model.text.trim(),
    minYear: _minYearValue,
    maxYear: _maxYearValue,
    minPrice: _parsePrice(_minPrice.text),
    maxPrice: _parsePrice(_maxPrice.text),
    maxMileage: _parseMileage(_maxMileage.text),
    city: _city.text.trim().isEmpty ? null : _city.text.trim(),
    typeFilter: _type,
    region: _region,
    sort: _sort,
    bodyType: _bodyType,
    fuelType: _fuelType,
    transmissionType: _transmissionType,
    drivetrain: _drivetrain,
    priceCurrencyFilter: _priceCurrency,
  );

  /// Resets all controls to the vanilla discovery baseline (draft only).
  void resetDraftToVanilla() {
    _catalogMake = null;
    _customBrand.clear();
    _model.clear();
    _minYearValue = null;
    _maxYearValue = null;
    _minPrice.clear();
    _maxPrice.clear();
    _maxMileage.clear();
    _city.clear();
    setState(() {
      _type = ListingTypeFilter.any;
      _region = MarketRegionFilter.both;
      _sort = ListingSortOption.newestFirst;
      _bodyType = null;
      _fuelType = null;
      _transmissionType = null;
      _drivetrain = null;
      _priceCurrency = ListingPriceCurrencyFilter.any;
      _minYearError = null;
      _maxYearError = null;
      _minPriceError = null;
      _maxPriceError = null;
      _maxMileageError = null;
    });
  }

  @override
  void dispose() {
    _model.removeListener(_onDraftChanged);
    _customBrand.removeListener(_onDraftChanged);
    _minPrice.removeListener(_onDraftChanged);
    _maxPrice.removeListener(_onDraftChanged);
    _maxMileage.removeListener(_onDraftChanged);
    _city.removeListener(_onDraftChanged);
    _model.dispose();
    _customBrand.dispose();
    _minPriceFocus.removeListener(_syncPriceFocusDecoration);
    _maxPriceFocus.removeListener(_syncPriceFocusDecoration);
    _minPriceFocus.dispose();
    _maxPriceFocus.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _maxMileage.dispose();
    _city.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(
    ThemeData theme, {
    required String label,
    String? hint,
    String? errorText,
  }) {
    return AppTheme.listingsFilterFieldDecoration(
      theme,
      label: label,
      hint: hint,
      errorText: errorText,
    );
  }

  void _hydrateCatalogMake({required String? make}) {
    if (make == null || make.trim().isEmpty) {
      _catalogMake = null;
      _customBrand.clear();
      return;
    }
    final t = make.trim();
    final norm = listingBrandNormalizeForLookup(t);
    if (norm != null) {
      _catalogMake = norm;
      if (norm == _brandOtherEnglish) {
        final onlySentinel = norm.toLowerCase() == t.toLowerCase();
        _customBrand.text = onlySentinel ? '' : t;
      } else {
        _customBrand.clear();
      }
    } else {
      _catalogMake = _brandOtherEnglish;
      _customBrand.text = t;
    }
  }

  String? _effectiveMakeFilter() {
    if (_catalogMake == null) return null;
    if (_catalogMake == _brandOtherEnglish) {
      final t = _customBrand.text.trim();
      return t.isEmpty ? _brandOtherEnglish : t;
    }
    return _catalogMake;
  }

  String _makeRowDisplay(AppLocalizations l10n) {
    if (_catalogMake == null) return l10n.createListingChooseBrand;
    if (_catalogMake == _brandOtherEnglish) {
      final custom = _customBrand.text.trim();
      if (custom.isEmpty) {
        return localizedListingBrandCatalogLabel(l10n, _brandOtherEnglish);
      }
      return custom;
    }
    return localizedListingBrandCatalogLabel(l10n, _catalogMake!);
  }

  Future<void> _openMakeSheet() async {
    final picked = await showListingBrandPickSheet(
      context: context,
      l10n: context.l10n,
    );
    if (!mounted || picked == null) return;
    _applyBrandPick(picked);
  }

  void _applyBrandPick(String picked) {
    final applied = applyListingBrandPick(picked);
    final prev = _catalogMake;
    setState(() {
      _catalogMake = applied.catalogKey;
      if (applied.catalogKey == _brandOtherEnglish) {
        _customBrand.text = applied.customMakeText;
      } else {
        _customBrand.clear();
      }
      if (prev != _catalogMake) {
        _model.clear();
      }
    });
    _notifyDraftMutated();
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
    _notifyDraftMutated();
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
    _notifyDraftMutated();
  }

  Future<void> _openTransmissionTypeSheet() async {
    final l10n = context.l10n;
    final picked = await showListingTransmissionTypePickerSheet(
      context: context,
      l10n: l10n,
      selected: _transmissionType,
    );
    if (!mounted) return;
    setState(() => _transmissionType = picked);
    _notifyDraftMutated();
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
    _notifyDraftMutated();
  }

  Future<void> _openSortSheet() async {
    final l10n = context.l10n;
    final picked = await showListingsFilterSortPickSheet(
      context: context,
      l10n: l10n,
      selected: _sort,
    );
    if (!mounted || picked == null) return;
    setState(() => _sort = picked);
    _notifyDraftMutated();
  }

  /// Notifies the host that the draft has been mutated through a
  /// non-controller path (chip/dropdown/year picker). Text controller
  /// listeners already fire `_onDraftChanged`, which calls this too.
  void _notifyDraftMutated() {
    widget.onDraftMutated?.call();
  }

  void _clearMakeSelection() {
    if (_catalogMake == null && _customBrand.text.trim().isEmpty) return;
    setState(() {
      _catalogMake = null;
      _customBrand.clear();
      _model.clear();
    });
    _notifyDraftMutated();
  }

  Future<void> _pickYear({required bool isMin}) async {
    final l10n = context.l10n;
    final out = await showListingYearWheelPickSheet(
      context: context,
      l10n: l10n,
      sheetTitle: isMin ? l10n.filterMinYear : l10n.filterMaxYear,
      selectedYear: isMin ? _minYearValue : _maxYearValue,
      allowClear: true,
    );
    if (!mounted || out == null) return;
    if (out is ListingYearPickerClear) {
      _clearYearPick(isMin: isMin);
      return;
    }
    if (out is ListingYearPickerChosen) {
      final yr = out.year;
      setState(() {
        if (isMin) {
          _minYearValue = yr;
          if (_maxYearValue != null && yr > _maxYearValue!) {
            _maxYearValue = null;
          }
        } else {
          _maxYearValue = yr;
          if (_minYearValue != null && yr < _minYearValue!) {
            _minYearValue = null;
          }
        }
        _minYearError = null;
        _maxYearError = null;
      });
      _notifyDraftMutated();
    }
  }

  void _clearYearPick({required bool isMin}) {
    setState(() {
      if (isMin) {
        _minYearValue = null;
      } else {
        _maxYearValue = null;
      }
      _minYearError = null;
      _maxYearError = null;
    });
    _notifyDraftMutated();
  }

  Widget _filterYearCompactCell({
    required ThemeData theme,
    required ColorScheme scheme,
    required String boundLabel,
    required int? year,
    required String? errorText,
    required bool isMin,
  }) {
    final isBoundEmpty = year == null;
    final valueCaption = isBoundEmpty ? _boundEmptyPlaceholder : '$year';

    final fill = _compactFieldFill(scheme);
    final borderRadius = BorderRadius.circular(14);
    final hasError = errorText != null;
    final borderColor = _compactFieldBorder(
      scheme,
      hasError: hasError,
      focused: false,
    );

    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
          height: 1.15,
          color: hasError
              ? scheme.error.withValues(alpha: 0.92)
              : scheme.onSurfaceVariant.withValues(alpha: 0.88),
        ) ??
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
        );

    var valueStyleStrong =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.12,
          height: 1.2,
        ) ??
        theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);

    valueStyleStrong = valueStyleStrong.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.9),
    );

    final placeholderStyle = _compactBoundPlaceholderStyle(
      theme,
      scheme,
      sizeReference: valueStyleStrong,
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topLeft,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: borderRadius,
                  key: ValueKey<String>(
                    isMin
                        ? 'listings_filter_min_year_pick'
                        : 'listings_filter_max_year_pick',
                  ),
                  onTap: () => _pickYear(isMin: isMin),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: fill,
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isBoundEmpty)
                          Center(
                            child: Text(
                              valueCaption,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: placeholderStyle,
                            ),
                          )
                        else
                          Text(
                            valueCaption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: valueStyleStrong,
                          ),
                        if (errorText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            errorText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.error.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ) ??
                                TextStyle(
                                  color: scheme.error.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                color: fill,
                child: Text(
                  boundLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPriceCompactField({
    required ThemeData theme,
    required ColorScheme scheme,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String boundLabel,
    required String? errorText,
    required bool isMin,
  }) {
    final fill = _compactFieldFill(scheme);
    final borderRadius = BorderRadius.circular(14);
    final hasError = errorText != null;
    final focused = focusNode.hasFocus;
    final borderColor = _compactFieldBorder(
      scheme,
      hasError: hasError,
      focused: focused,
    );
    final borderWidth = !hasError && focused ? 1.25 : 1.0;

    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
          height: 1.15,
          color: hasError
              ? scheme.error.withValues(alpha: 0.92)
              : scheme.onSurfaceVariant.withValues(alpha: 0.88),
        ) ??
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
        );

    var valueStyleStrong =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.12,
          height: 1.2,
        ) ??
        theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);

    valueStyleStrong = valueStyleStrong.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.9),
    );

    final showEmptyPlaceholder = controller.text.trim().isEmpty && !focused;

    final hintStyle = _compactBoundPlaceholderStyle(
      theme,
      scheme,
      sizeReference: valueStyleStrong,
    );

    final pickKey = isMin
        ? 'listings_filter_min_price_pick'
        : 'listings_filter_max_price_pick';
    final fieldKey = isMin
        ? 'listings_filter_min_price_field'
        : 'listings_filter_max_price_field';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: KeyedSubtree(
          key: ValueKey<String>(pickKey),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topLeft,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: fill,
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextField(
                          key: ValueKey<String>(fieldKey),
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          textAlign: showEmptyPlaceholder
                              ? TextAlign.center
                              : TextAlign.start,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: valueStyleStrong,
                          onChanged: (_) => _clearPriceErrorsIfNeeded(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            filled: false,
                            isCollapsed: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: showEmptyPlaceholder
                                ? _boundEmptyPlaceholder
                                : null,
                            hintStyle: hintStyle,
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            errorText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.error.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ) ??
                                TextStyle(
                                  color: scheme.error.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  color: fill,
                  child: Text(
                    boundLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  num? _parsePrice(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }

  int? _parseMileage(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void _clearPriceErrorsIfNeeded() {
    if (_minPriceError != null || _maxPriceError != null) {
      setState(() {
        _minPriceError = null;
        _maxPriceError = null;
      });
    }
  }

  /// Validates fields and returns an apply result, or `null` if validation failed.
  ListingsFilterApplyResult? submit() {
    return _buildApplyOutcome(l10n: context.l10n, mutateInlineErrors: true);
  }

  /// Same validation as [submit] without touching inline errors (peek only).
  ListingsFilterApplyResult? peekValidatedApplyOutcome() {
    return _buildApplyOutcome(l10n: context.l10n, mutateInlineErrors: false);
  }

  ListingsFilterApplyResult? _buildApplyOutcome({
    required AppLocalizations l10n,
    required bool mutateInlineErrors,
  }) {
    final makeDraft = _effectiveMakeFilter();
    final model = _model.text.trim();
    final minYear = _minYearValue;
    final maxYear = _maxYearValue;
    final minPrice = _parsePrice(_minPrice.text);
    final maxPrice = _parsePrice(_maxPrice.text);
    final maxMileage = _parseMileage(_maxMileage.text);
    final city = _city.text.trim();

    String? minYearErr;
    String? maxYearErr;
    String? minPriceErr;
    String? maxPriceErr;
    String? maxMileageErr;

    if (_minPrice.text.trim().isNotEmpty && minPrice == null) {
      minPriceErr = l10n.filterMustBeNumber;
    }
    if (_maxPrice.text.trim().isNotEmpty && maxPrice == null) {
      maxPriceErr = l10n.filterMustBeNumber;
    }
    if (_maxMileage.text.trim().isNotEmpty && maxMileage == null) {
      maxMileageErr = l10n.filterMustBeNumber;
    }
    if (minYear != null && maxYear != null && minYear > maxYear) {
      minYearErr = l10n.filterYearRangeInverted;
      maxYearErr = l10n.filterYearRangeInverted;
    }
    if (minPriceErr == null &&
        maxPriceErr == null &&
        minPrice != null &&
        maxPrice != null &&
        minPrice > maxPrice) {
      minPriceErr = l10n.filterMustBeMaxPrice;
      maxPriceErr = l10n.filterMustBeMinPrice;
    }

    if (minYearErr != null ||
        maxYearErr != null ||
        minPriceErr != null ||
        maxPriceErr != null ||
        maxMileageErr != null) {
      if (mutateInlineErrors) {
        setState(() {
          _minYearError = minYearErr;
          _maxYearError = maxYearErr;
          _minPriceError = minPriceErr;
          _maxPriceError = maxPriceErr;
          _maxMileageError = maxMileageErr;
        });
      }
      return null;
    }

    if (isListingsFilterDraftVanilla(draftSeed)) {
      return const ListingsFilterApplyResult.clear();
    }

    return ListingsFilterApplyResult.apply(
      make: makeDraft,
      model: model.isEmpty ? null : model,
      minYear: minYear,
      maxYear: maxYear,
      minPrice: minPrice,
      maxPrice: maxPrice,
      maxMileage: maxMileage,
      city: city.isEmpty ? null : city,
      typeFilter: _type,
      sort: _sort,
      region: _region,
      bodyType: _bodyType,
      fuelType: _fuelType,
      transmissionType: _transmissionType,
      drivetrain: _drivetrain,
      priceCurrencyFilter: _priceCurrency,
    );
  }

  Widget _regionSelector(AppLocalizations l10n) {
    return ListingsFilterSegmentedControl<MarketRegionFilter>(
      key: const ValueKey<String>('listings_filter_region_segmented'),
      variant: ListingsFilterSegmentedControlVariant.region,
      value: _region,
      onChanged: (v) {
        setState(() => _region = v);
        _notifyDraftMutated();
      },
      entries: [
        ListingsFilterSegmentEntry(
          value: MarketRegionFilter.transnistria,
          label: Text(
            l10n.regionTransnistria,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          icon: Icons.map_outlined,
          semanticsLabel: l10n.regionTransnistria,
        ),
        ListingsFilterSegmentEntry(
          value: MarketRegionFilter.moldova,
          label: Text(
            l10n.regionMoldova,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          icon: Icons.map_outlined,
          semanticsLabel: l10n.regionMoldova,
        ),
        ListingsFilterSegmentEntry(
          value: MarketRegionFilter.both,
          label: Text(
            l10n.regionBoth,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          icon: Icons.language_outlined,
          isNeutralOption: true,
          semanticsLabel: l10n.regionBoth,
        ),
      ],
    );
  }

  Widget _listingTypeSelector(AppLocalizations l10n) {
    return ListingsFilterSegmentedControl<ListingTypeFilter>(
      key: const ValueKey<String>('listings_filter_type_segmented'),
      variant: ListingsFilterSegmentedControlVariant.listingType,
      value: _type,
      onChanged: (v) {
        setState(() => _type = v);
        _notifyDraftMutated();
      },
      entries: [
        ListingsFilterSegmentEntry(
          value: ListingTypeFilter.any,
          label: Text(l10n.typeAny, textAlign: TextAlign.center),
          icon: Icons.apps_rounded,
          isNeutralOption: true,
          semanticsLabel: l10n.typeAny,
        ),
        ListingsFilterSegmentEntry(
          value: ListingTypeFilter.sale,
          label: Text(l10n.typeSale, textAlign: TextAlign.center),
          icon: Icons.sell_outlined,
          semanticsLabel: l10n.typeSale,
        ),
        ListingsFilterSegmentEntry(
          value: ListingTypeFilter.exchange,
          label: Text(l10n.typeExchange, textAlign: TextAlign.center),
          icon: Icons.swap_horiz_rounded,
          semanticsLabel: l10n.typeExchange,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDraftSummaryStrip)
          ListingsFilterSummaryStrip(
            view: buildListingsFilterSummaryView(l10n, draftSeed),
          )
        else
          const SizedBox(height: 10),
        ListingsFilterSection(
          sectionIndex: '01',
          title: l10n.filtersSectionMakeModel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputDecorator(
                decoration: _fieldDeco(theme, label: l10n.filterMake).copyWith(
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_catalogMake != null)
                        IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            maxWidth: 36,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.close_rounded,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          onPressed: _clearMakeSelection,
                        ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.38),
                      ),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey<String>(
                      'listings_filter_make_pick_trigger',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openMakeSheet,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _makeRowDisplay(l10n),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _catalogMake == null
                                ? scheme.onSurface.withValues(alpha: 0.45)
                                : scheme.onSurface.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_catalogMake == _brandOtherEnglish) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _customBrand,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDeco(
                    theme,
                    label: l10n.createListingBrandOther,
                    hint: l10n.filterMakeHint,
                  ),
                ),
              ],
              const SizedBox(height: 15),
              TextField(
                controller: _model,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDeco(
                  theme,
                  label: l10n.filterModel,
                  hint: l10n.filterModelHint,
                ),
              ),
            ],
          ),
        ),
        ListingsFilterSection(
          sectionIndex: '02',
          title: l10n.filtersSectionBudget,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListingsFilterBudgetPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.filterPriceBudgetHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: light ? 0.52 : 0.72,
                        ),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _filterPriceCompactField(
                          theme: theme,
                          scheme: scheme,
                          controller: _minPrice,
                          focusNode: _minPriceFocus,
                          boundLabel: l10n.filterPriceFrom,
                          errorText: _minPriceError,
                          isMin: true,
                        ),
                        const SizedBox(width: 12),
                        _filterPriceCompactField(
                          theme: theme,
                          scheme: scheme,
                          controller: _maxPrice,
                          focusNode: _maxPriceFocus,
                          boundLabel: l10n.filterPriceTo,
                          errorText: _maxPriceError,
                          isMin: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.filterPriceCurrencyLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.64),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListingsFilterSegmentedControl<ListingPriceCurrencyFilter>(
                      key: const ValueKey<String>(
                        'listings_filter_currency_segmented',
                      ),
                      variant: ListingsFilterSegmentedControlVariant.currency,
                      value: _priceCurrency,
                      onChanged: (v) {
                        setState(() => _priceCurrency = v);
                        _notifyDraftMutated();
                      },
                      entries: [
                        ListingsFilterSegmentEntry(
                          value: ListingPriceCurrencyFilter.any,
                          label: Text(l10n.filterPriceCurrencyAny),
                          isNeutralOption: true,
                          semanticsLabel: l10n.filterPriceCurrencyAny,
                        ),
                        ListingsFilterSegmentEntry(
                          value: ListingPriceCurrencyFilter.usd,
                          label: Text(l10n.filterPriceCurrencyUsd),
                          secondaryLabel: 'USD',
                          semanticsLabel: 'USD',
                        ),
                        ListingsFilterSegmentEntry(
                          value: ListingPriceCurrencyFilter.eur,
                          label: Text(l10n.filterPriceCurrencyEur),
                          secondaryLabel: 'EUR',
                          semanticsLabel: 'EUR',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.filterYearManufactureSection,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterYearCompactCell(
                    theme: theme,
                    scheme: scheme,
                    boundLabel: l10n.filterYearFromShort,
                    year: _minYearValue,
                    errorText: _minYearError,
                    isMin: true,
                  ),
                  const SizedBox(width: 12),
                  _filterYearCompactCell(
                    theme: theme,
                    scheme: scheme,
                    boundLabel: l10n.filterYearToShort,
                    year: _maxYearValue,
                    errorText: _maxYearError,
                    isMin: false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxMileage,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  if (_maxMileageError != null) {
                    setState(() => _maxMileageError = null);
                  }
                },
                decoration: _fieldDeco(
                  theme,
                  label: l10n.filterMaxMileage,
                  errorText: _maxMileageError,
                ),
              ),
            ],
          ),
        ),
        ListingsFilterSection(
          sectionIndex: '03',
          title: l10n.filtersSectionLocation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDeco(
                  theme,
                  label: l10n.filterCity,
                  hint: l10n.filterCityHint,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.regionFilterLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _regionSelector(l10n),
            ],
          ),
        ),
        ListingsFilterSection(
          sectionIndex: '04',
          title: l10n.filtersSectionVehicle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListingsFilterVehicleSpecSelectorField(
                fieldKey: const ValueKey<String>(
                  'listings_filter_body_type_pick_trigger',
                ),
                label: l10n.listingBodyTypeSectionTitle,
                valueText: _bodyType == null
                    ? l10n.listingsBodyChipAll
                    : listingFilterBodyTypeLabel(l10n, _bodyType!),
                onTap: _openBodyTypeSheet,
              ),
              const SizedBox(height: 16),
              ListingsFilterVehicleSpecSelectorField(
                fieldKey: const ValueKey<String>(
                  'listings_filter_fuel_type_pick_trigger',
                ),
                label: l10n.listingFuelType,
                valueText: _fuelType == null
                    ? l10n.listingsBodyChipAll
                    : formatListingFuelType(l10n, _fuelType!),
                onTap: _openFuelTypeSheet,
              ),
              const SizedBox(height: 16),
              ListingsFilterVehicleSpecSelectorField(
                fieldKey: const ValueKey<String>(
                  'listings_filter_transmission_type_pick_trigger',
                ),
                label: l10n.listingTransmission,
                valueText: _transmissionType == null
                    ? l10n.listingsBodyChipAll
                    : formatListingTransmissionType(l10n, _transmissionType!),
                onTap: _openTransmissionTypeSheet,
              ),
              const SizedBox(height: 16),
              ListingsFilterVehicleSpecSelectorField(
                fieldKey: const ValueKey<String>(
                  'listings_filter_drivetrain_pick_trigger',
                ),
                label: l10n.listingDrivetrain,
                valueText: _drivetrain == null
                    ? l10n.listingsBodyChipAll
                    : formatListingDrivetrain(l10n, _drivetrain!),
                onTap: _openDrivetrainSheet,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.filterType,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _listingTypeSelector(l10n),
            ],
          ),
        ),
        ListingsFilterSection(
          sectionIndex: '05',
          title: l10n.filterSortLabel,
          child: ListingVehicleSpecPickerRow(
            fieldKey: const ValueKey<String>(
              'listings_filter_sort_pick_trigger',
            ),
            valueText: listingFilterSortOptionLabel(l10n, _sort),
            enabled: true,
            onTap: _openSortSheet,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
