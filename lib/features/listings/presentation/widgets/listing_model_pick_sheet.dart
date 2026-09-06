import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<String>(
      key: formFieldKey,
      validator: (_) {
        if (!requiredWhenEnabled || !enabled || manualMode) return null;
        return canonicalModel == null ? l10n.validationRequired : null;
      },
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: decoration.copyWith(errorText: field.errorText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  manualMode
                      ? l10n.listingModelNotListed
                      : canonicalModel ??
                            (placeholder ?? l10n.listingModelSelectPlaceholder),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: !enabled || (canonicalModel == null && !manualMode)
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
