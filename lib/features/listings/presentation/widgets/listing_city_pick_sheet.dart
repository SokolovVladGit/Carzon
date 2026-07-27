import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/catalog/listing_city_catalog.dart';
import '../../domain/entities/listing.dart';

class ListingCityPickResult {
  const ListingCityPickResult.known(this.canonicalValue) : manual = false;
  const ListingCityPickResult.manual() : canonicalValue = null, manual = true;

  final String? canonicalValue;
  final bool manual;
}

Future<ListingCityPickResult?> showListingCityPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required MarketRegion region,
  String? selectedCanonicalCity,
}) {
  return showModalBottomSheet<ListingCityPickResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ListingCityPickSheet(
      l10n: l10n,
      region: region,
      selectedCanonicalCity: selectedCanonicalCity,
    ),
  );
}

class ListingCityPickSheet extends StatefulWidget {
  const ListingCityPickSheet({
    super.key,
    required this.l10n,
    required this.region,
    this.selectedCanonicalCity,
  });

  final AppLocalizations l10n;
  final MarketRegion region;
  final String? selectedCanonicalCity;

  @override
  State<ListingCityPickSheet> createState() => _ListingCityPickSheetState();
}

class _ListingCityPickSheetState extends State<ListingCityPickSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cities = searchListingCities(widget.region, _query.text);

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
                        l10n.listingCityPickerTitle,
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
                  key: const ValueKey('listing_city_search_field'),
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: l10n.listingCitySearchHint,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: cities.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.listingCityNoResults,
                            key: const ValueKey('listing_city_empty_state'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey('listing_city_results'),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: cities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final selected =
                              city.canonicalValue ==
                              widget.selectedCanonicalCity;
                          return Semantics(
                            selected: selected,
                            button: true,
                            child: ListTile(
                              key: ValueKey(
                                'listing_city_${city.canonicalValue}',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              selected: selected,
                              selectedTileColor: scheme.primary.withValues(
                                alpha: theme.brightness == Brightness.light
                                    ? 0.08
                                    : 0.16,
                              ),
                              title: Text(
                                city.canonicalValue,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_rounded)
                                  : null,
                              onTap: () => Navigator.pop(
                                context,
                                ListingCityPickResult.known(
                                  city.canonicalValue,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Material(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    key: const ValueKey('listing_city_manual_option'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.edit_location_alt_outlined),
                    title: Text(
                      l10n.listingCityOtherLocality,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.listingCityManualHelper,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      const ListingCityPickResult.manual(),
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
}

/// Form-integrated closed selector. Manual text validation stays on the
/// separately rendered manual field, so only one city error is shown.
class ListingCitySelectorField extends StatelessWidget {
  const ListingCitySelectorField({
    super.key,
    required this.l10n,
    required this.enabled,
    required this.manualMode,
    required this.canonicalCity,
    required this.onTap,
    required this.decoration,
    this.formFieldKey,
  });

  final AppLocalizations l10n;
  final bool enabled;
  final bool manualMode;
  final String? canonicalCity;
  final VoidCallback onTap;
  final InputDecoration decoration;
  final GlobalKey<FormFieldState<String>>? formFieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<String>(
      key: formFieldKey,
      validator: (_) =>
          !manualMode && canonicalCity == null ? l10n.validationRequired : null,
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: decoration.copyWith(errorText: field.errorText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  manualMode
                      ? l10n.listingCityOtherLocality
                      : canonicalCity ?? l10n.listingCitySelectPlaceholder,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: canonicalCity == null && !manualMode
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
