import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Static Terms & Privacy surface for the Carzon MVP.
///
/// This page is intentionally a plain scrollable list of Material
/// sections. It does not render Markdown, does not embed a WebView,
/// does not fetch remote content, and does not depend on Supabase.
/// The copy here is an honest product-stage placeholder and is not a
/// substitute for lawyer-reviewed terms; it exists so the app can be
/// distributed to early users and reviewers with a baseline legal/
/// privacy notice that reflects what Carzon actually does today.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: AppRoutes.listings),
        title: Text(l10n.legalTitle),
      ),
      body: const _LegalBody(),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _LegalDisclaimer(),
        const SizedBox(height: 16),
        _LegalSection(
          title: l10n.legalSectionAboutHeading,
          paragraphs: [l10n.legalSectionAboutP1, l10n.legalSectionAboutP2],
        ),
        _LegalSection(
          title: l10n.legalSectionListingsHeading,
          paragraphs: [
            l10n.legalSectionListingsP1,
            l10n.legalSectionListingsP2,
            l10n.legalSectionListingsP3,
          ],
        ),
        _LegalSection(
          title: l10n.legalSectionContactHeading,
          paragraphs: [
            l10n.legalSectionContactP1,
            l10n.legalSectionContactP2,
            l10n.legalSectionContactP3,
          ],
        ),
        _LegalSection(
          title: l10n.legalSectionPhotosHeading,
          paragraphs: [l10n.legalSectionPhotosP1, l10n.legalSectionPhotosP2],
        ),
        _LegalSection(
          title: l10n.legalSectionAccountHeading,
          paragraphs: [l10n.legalSectionAccountP1, l10n.legalSectionAccountP2],
        ),
        _LegalSection(
          title: l10n.legalSectionFavoritesHeading,
          paragraphs: [l10n.legalSectionFavoritesP1],
        ),
        _LegalSection(
          title: l10n.legalSectionSafetyHeading,
          paragraphs: [
            l10n.legalSectionSafetyP1,
            l10n.legalSectionSafetyP2,
            l10n.legalSectionSafetyP3,
          ],
        ),
        _LegalSection(
          title: l10n.legalSectionContactUsHeading,
          paragraphs: [
            l10n.legalSectionContactUsP1,
            l10n.legalSectionContactUsP2,
          ],
        ),
      ],
    );
  }
}

class _LegalDisclaimer extends StatelessWidget {
  const _LegalDisclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(l10n.legalDisclaimer, style: theme.textTheme.bodySmall),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in paragraphs) ...[
            Text(p, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
