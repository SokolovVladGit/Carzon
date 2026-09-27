import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../app/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/vehicle_model_catalog_repository.dart';

class ListingModelPickResult {
  const ListingModelPickResult.known(this.canonicalValue) : manual = false;
  const ListingModelPickResult.manual() : canonicalValue = null, manual = true;

  final String? canonicalValue;
  final bool manual;
}

Future<ListingModelPickResult?> showListingModelPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required String make,
  String? selectedCanonicalModel,
  VehicleModelCatalogRepository? catalog,
}) {
  return showModalBottomSheet<ListingModelPickResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ListingModelPickSheet(
      l10n: l10n,
      make: make,
      selectedCanonicalModel: selectedCanonicalModel,
      catalog: catalog,
    ),
  );
}

class ListingModelPickSheet extends StatefulWidget {
  const ListingModelPickSheet({
    super.key,
    required this.l10n,
    required this.make,
    this.selectedCanonicalModel,
    this.catalog,
  });

  final AppLocalizations l10n;
  final String make;
  final String? selectedCanonicalModel;
  final VehicleModelCatalogRepository? catalog;

  @override
  State<ListingModelPickSheet> createState() => _ListingModelPickSheetState();
}

class _ListingModelPickSheetState extends State<ListingModelPickSheet> {
  final TextEditingController _query = TextEditingController();
  List<String>? _models;
  Object? _error;
  bool _loading = true;
  int _loadEpoch = 0;

  VehicleModelCatalogRepository get _catalog =>
      widget.catalog ?? sl<VehicleModelCatalogRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final epoch = ++_loadEpoch;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _catalog.listVehicleModelsForMake(widget.make);
    if (!mounted || epoch != _loadEpoch) return;
    result.fold(
      (failure) {
        setState(() {
          _loading = false;
          _error = failure;
          _models = null;
        });
      },
      (models) {
        setState(() {
          _loading = false;
          _error = null;
          _models = models;
        });
      },
    );
  }

  List<String> get _visible {
    final all = _models ?? const <String>[];
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final model in all)
        if (model.toLowerCase().contains(q)) model,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: AnimatedPadding(
        duration: Duration.zero,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.listingModelPickerTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.commonCancel,
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  key: const ValueKey('listing_model_search_field'),
                  controller: _query,
                  enabled: !_loading && _error == null,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: l10n.listingModelSearchHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Expanded(child: _body(theme, scheme, l10n)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Material(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    key: const ValueKey('listing_model_manual_option'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(
                      l10n.listingModelNotListed,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.listingModelManualHelper,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      const ListingModelPickResult.manual(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, ColorScheme scheme, AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          key: ValueKey('listing_model_loading'),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.listingModelLoadFailed,
                key: const ValueKey('listing_model_error_state'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('listing_model_retry'),
                onPressed: _load,
                child: Text(l10n.listingModelRetry),
              ),
            ],
          ),
        ),
      );
    }

    final models = _visible;
    if (models.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.listingModelNoResults,
            key: const ValueKey('listing_model_empty_state'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('listing_model_results'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: models.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final model = models[index];
        final selected = model == widget.selectedCanonicalModel;
        return Semantics(
          selected: selected,
          button: true,
          child: ListTile(
            key: ValueKey('listing_model_$model'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            selected: selected,
            selectedTileColor: scheme.primary.withValues(
              alpha: theme.brightness == Brightness.light ? 0.08 : 0.16,
            ),
            title: Text(model, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: selected ? const Icon(Icons.check_rounded) : null,
            onTap: () =>
                Navigator.pop(context, ListingModelPickResult.known(model)),
          ),
        );
      },
    );
  }
}

/// Closed selector used by create/edit/filter forms.
class ListingModelSelectorField extends StatelessWidget {
  const ListingModelSelectorField({
    super.key,
    required this.l10n,
    required this.enabled,
    required this.manualMode,
    required this.canonicalModel,
    required this.onTap,
    required this.decoration,
    this.placeholder,
    this.formFieldKey,
    this.requiredWhenEnabled = true,
    this.borderRadius = 16,
    this.dense = false,
    this.caption,
    this.denseSurface,
  });

  final AppLocalizations l10n;
  final bool enabled;
  final bool manualMode;
  final String? canonicalModel;
  final VoidCallback onTap;
  final InputDecoration decoration;
  final String? placeholder;
  final GlobalKey<FormFieldState<String>>? formFieldKey;
  final bool requiredWhenEnabled;
  final double borderRadius;

  /// One-line caption + value. Create Listing MMY only.
  final bool dense;
  final String? caption;

  /// Surface for [dense]. Matches the Brand / Year picker when provided.
  final BoxDecoration Function({
    required bool hasValue,
    required bool hasError,
  })?
  denseSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<String>(
      key: formFieldKey,
      validator: (_) {
        if (!requiredWhenEnabled || !enabled || manualMode) return null;
        return canonicalModel == null ? l10n.validationRequired : null;
      },
      builder: (field) {
        final valueText = manualMode
            ? l10n.listingModelNotListed
            : canonicalModel ??
                  (placeholder ?? l10n.listingModelSelectPlaceholder);
        final muted = !enabled || (canonicalModel == null && !manualMode);
        final hasError = field.errorText != null && field.errorText!.isNotEmpty;
        if (dense) {
          return _DenseModelControl(
            enabled: enabled,
            caption: caption,
            valueText: valueText,
            muted: muted,
            hasValue: canonicalModel != null || manualMode,
            errorText: hasError ? field.errorText : null,
            onTap: enabled ? onTap : null,
            surface: denseSurface,
            fallback: decoration,
            borderRadius: borderRadius,
          );
        }
        return InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: decoration.copyWith(errorText: field.errorText),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: muted ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded, size: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fixed 56px cell. Same box as the Create Listing Brand / Year pickers.
class _DenseModelControl extends StatelessWidget {
  const _DenseModelControl({
    required this.enabled,
    required this.caption,
    required this.valueText,
    required this.muted,
    required this.hasValue,
    required this.errorText,
    required this.onTap,
    required this.surface,
    required this.fallback,
    required this.borderRadius,
  });

  final bool enabled;
  final String? caption;
  final String valueText;
  final bool muted;
  final bool hasValue;
  final String? errorText;
  final VoidCallback? onTap;
  final BoxDecoration Function({
    required bool hasValue,
    required bool hasError,
  })?
  surface;
  final InputDecoration fallback;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final decoration =
        surface?.call(hasValue: hasValue, hasError: hasError) ??
        BoxDecoration(
          color: fallback.fillColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color:
                (hasError ? fallback.errorBorder : fallback.enabledBorder)
                    ?.borderSide
                    .color ??
                cs.outline,
            width: 0.7,
          ),
        );
    final captionStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 1.1,
    );
    final valueColor = muted
        ? cs.onSurface.withValues(alpha: light ? 0.64 : 0.74)
        : cs.onSurface.withValues(alpha: light ? 0.92 : 0.96);
    final chevron = !enabled
        ? cs.onSurface.withValues(alpha: 0.24)
        : muted
        ? cs.onSurface.withValues(alpha: 0.38)
        : cs.onSurface.withValues(alpha: 0.56);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              child: Ink(
                height: 56,
                decoration: decoration,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (caption != null)
                        Text(
                          caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: captionStyle,
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              valueText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: -0.2,
                                height: 1.15,
                                color: valueColor,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 18,
                            color: chevron,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w500,
              height: 1.2,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
