/// One editorial block on the legal / privacy page.
class LegalSectionContent {
  const LegalSectionContent({
    required this.heading,
    this.paragraphs = const [],
    this.bullets = const [],
    this.trailingParagraphs = const [],
  });

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> trailingParagraphs;
}
