import '../../../../l10n/app_localizations.dart';
import '../models/legal_section_content.dart';

/// Builds the ordered legal document sections from localized strings.
List<LegalSectionContent> buildLegalSections(AppLocalizations l10n) {
  return [
    LegalSectionContent(
      heading: l10n.legalSectionAboutHeading,
      paragraphs: [l10n.legalSectionAboutP1, l10n.legalSectionAboutP2],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionListingsHeading,
      paragraphs: [
        l10n.legalSectionListingsP1,
        l10n.legalSectionListingsP2,
        l10n.legalSectionListingsP3,
      ],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionContactHeading,
      paragraphs: [l10n.legalSectionContactP1],
      bullets: [
        l10n.legalSectionContactB1,
        l10n.legalSectionContactB2,
        l10n.legalSectionContactB3,
      ],
      trailingParagraphs: [l10n.legalSectionContactP3],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionPhotosHeading,
      paragraphs: [l10n.legalSectionPhotosP1, l10n.legalSectionPhotosP2],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionAccountHeading,
      paragraphs: [
        l10n.legalSectionAccountP1,
        l10n.legalSectionAccountP2,
        l10n.legalSectionAccountP3,
      ],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionFavoritesHeading,
      paragraphs: [l10n.legalSectionFavoritesP1],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionDataSourcesHeading,
      paragraphs: [l10n.legalSectionDataSourcesP1],
      bullets: [
        l10n.legalSectionDataSourcesB1,
        l10n.legalSectionDataSourcesB2,
        l10n.legalSectionDataSourcesB3,
        l10n.legalSectionDataSourcesB4,
        l10n.legalSectionDataSourcesB5,
      ],
      trailingParagraphs: [l10n.legalSectionDataSourcesP2],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionTrademarksHeading,
      paragraphs: [l10n.legalSectionTrademarksP1],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionSafetyHeading,
      paragraphs: [
        l10n.legalSectionSafetyP1,
        l10n.legalSectionSafetyP2,
        l10n.legalSectionSafetyP3,
        l10n.legalSectionSafetyP4,
        l10n.legalSectionSafetyP5,
      ],
    ),
    LegalSectionContent(
      heading: l10n.legalSectionContactUsHeading,
      paragraphs: [l10n.legalSectionContactUsP1],
      trailingParagraphs: [l10n.legalSectionContactUsP2],
    ),
  ];
}
