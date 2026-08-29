import 'dart:convert';

import 'package:flutter/services.dart';

import 'legal_section_content.dart';

enum LegalDocumentKind { privacy, terms, notices }

extension LegalDocumentKindKey on LegalDocumentKind {
  String get contentKey => switch (this) {
    LegalDocumentKind.privacy => 'privacy',
    LegalDocumentKind.terms => 'terms',
    LegalDocumentKind.notices => 'notices',
  };
}

class LegalDocumentContent {
  const LegalDocumentContent({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String intro;
  final List<LegalSectionContent> sections;
}

Future<LegalDocumentContent> loadLegalDocumentContent({
  required LegalDocumentKind kind,
  required String languageCode,
  AssetBundle? bundle,
}) async {
  final raw = await (bundle ?? rootBundle).loadString(
    'web/legal/legal_content.json',
  );
  final root = jsonDecode(raw) as Map<String, dynamic>;
  final locales = root['locales'] as Map<String, dynamic>;
  final locale =
      (locales[languageCode] ?? locales['ru']) as Map<String, dynamic>;
  final document = locale[kind.contentKey] as Map<String, dynamic>;
  final sections = (document['sections'] as List<dynamic>)
      .map((rawSection) {
        final section = rawSection as Map<String, dynamic>;
        List<String> strings(String key) =>
            (section[key] as List<dynamic>? ?? const <dynamic>[])
                .cast<String>();

        return LegalSectionContent(
          heading: section['heading'] as String,
          paragraphs: strings('paragraphs'),
          bullets: strings('bullets'),
        );
      })
      .toList(growable: false);

  return LegalDocumentContent(
    title: document['title'] as String,
    intro: document['intro'] as String,
    sections: sections,
  );
}
