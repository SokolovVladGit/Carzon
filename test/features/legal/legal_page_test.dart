import 'dart:io';

import 'package:carzon/features/legal/presentation/models/legal_document_content.dart';
import 'package:carzon/features/legal/presentation/pages/legal_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String allText(LegalDocumentContent document) => [
    document.title,
    document.intro,
    for (final section in document.sections) ...[
      section.heading,
      ...section.paragraphs,
      ...section.bullets,
    ],
  ].join(' ');

  Widget wrap(LegalDocumentKind kind, {Locale locale = const Locale('ru')}) {
    return MaterialApp(
      locale: locale,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LegalPage(kind: kind),
    );
  }

  test('RU and RO contain matching final legal document structures', () async {
    for (final kind in LegalDocumentKind.values) {
      final ru = await loadLegalDocumentContent(kind: kind, languageCode: 'ru');
      final ro = await loadLegalDocumentContent(kind: kind, languageCode: 'ro');
      expect(ru.title, isNotEmpty);
      expect(ro.title, isNotEmpty);
      expect(ro.sections.length, ru.sections.length, reason: kind.name);
      expect(ru.sections, isNotEmpty);
    }
  });

  test(
    'privacy policy covers deletion retention tracking and location',
    () async {
      for (final locale in ['ru', 'ro']) {
        final privacy = await loadLegalDocumentContent(
          kind: LegalDocumentKind.privacy,
          languageCode: locale,
        );
        final text = allText(privacy);
        expect(text, contains('CARZON'));
        expect(text, contains('Supabase'));
        expect(text, contains('Firebase'));
        expect(text, contains('NHTSA'));
        expect(text, contains('VIN'));
        expect(text, contains('IDFA'));
        expect(text, contains('GPS'));
        expect(
          text,
          anyOf(contains('псевдонимизирован'), contains('pseudonimiz')),
        );
        expect(
          text,
          anyOf(contains('Удалить аккаунт'), contains('Șterge contul')),
        );
        expect(text, isNot(contains('OWNER_CONFIGURATION_REQUIRED')));
      }
    },
  );

  test(
    'terms preserve ownership and grant only an operational UGC license',
    () async {
      for (final locale in ['ru', 'ro']) {
        final terms = await loadLegalDocumentContent(
          kind: LegalDocumentKind.terms,
          languageCode: locale,
        );
        final text = allText(terms);
        expect(text, anyOf(contains('неисключитель'), contains('neexclusiv')));
        expect(
          text,
          anyOf(
            contains('Вы сохраняете права'),
            contains('Vă păstrați drepturile'),
          ),
        );
        expect(text, anyOf(contains('сжимать'), contains('comprima')));
        expect(text, anyOf(contains('модерац'), contains('moder')));
        expect(text, contains('WhatsApp'));
        expect(text, contains('NHTSA'));
        expect(text, isNot(contains('OWNER_CONFIGURATION_REQUIRED')));
      }
    },
  );

  test('portable public routes and App Store documents exist', () {
    const routes = [
      'web/ru/privacy/index.html',
      'web/ro/privacy/index.html',
      'web/ru/terms/index.html',
      'web/ro/terms/index.html',
      'web/ru/support/index.html',
      'web/ro/support/index.html',
      'web/ru/privacy-choices/index.html',
      'web/ro/privacy-choices/index.html',
    ];
    for (final route in routes) {
      expect(File(route).existsSync(), isTrue, reason: route);
    }
    expect(File('web/legal/legal_content.json').existsSync(), isTrue);
    expect(File('docs/app_store/app_privacy_answers.md').existsSync(), isTrue);
    expect(File('docs/app_store/legal_url_readiness.md').existsSync(), isTrue);
  });

  test('App Store answers remain consistent with key code facts', () {
    final answers = File(
      'docs/app_store/app_privacy_answers.md',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final viewer = File(
      'lib/features/listings/data/local/anonymous_viewer_id_repository.dart',
    ).readAsStringSync();
    expect(answers, contains('Data Used to Track You: NO'));
    expect(answers, contains('Identifiers — Device ID'));
    expect(answers, contains('Usage Data — Product Interaction'));
    expect(pubspec, contains('firebase_messaging:'));
    expect(pubspec, isNot(contains('firebase_analytics:')));
    expect(viewer, contains('carzon.analytics_viewer_id'));
  });

  testWidgets('privacy and terms surfaces mount in RU and RO', (tester) async {
    await tester.pumpWidget(wrap(LegalDocumentKind.privacy));
    await tester.pump();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      wrap(LegalDocumentKind.terms, locale: const Locale('ro')),
    );
    await tester.pump();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
