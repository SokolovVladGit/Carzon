import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/catalog/listing_brands.dart';

/// Opens searchable brand/make sheet aligned with listing create/edit flows.
Future<String?> showListingBrandPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
      ),
      child: ListingBrandPickSheet(appL10n: l10n),
    ),
  );
}

String localizedListingBrandCatalogLabel(
  AppLocalizations l10n,
  String catalogValue,
) =>
    catalogValue == kListingBrandCatalog.last
        ? l10n.createListingBrandOther
        : catalogValue;

class ListingBrandPickSheet extends StatefulWidget {
  const ListingBrandPickSheet({super.key, required this.appL10n});

  final AppLocalizations appL10n;

  @override
  State<ListingBrandPickSheet> createState() => _ListingBrandPickSheetState();
}

class _ListingBrandPickSheetState extends State<ListingBrandPickSheet> {
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
        .where(
          (b) =>
              q.isEmpty ||
              localizedListingBrandCatalogLabel(
                    l10n,
                    b,
                  ).toLowerCase().contains(q),
        )
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
                  prefixIcon: Icon(Icons.search_rounded),
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
                separatorBuilder: (context, index) =>
                    Divider(height: 1, thickness: .5, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final brandEnglish = filtered[index];
                  final label = localizedListingBrandCatalogLabel(l10n, brandEnglish);
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
