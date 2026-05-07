import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:carzon/core/services/auth_deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockAuthUrlHandler extends Mock implements SupabaseAuthUrlHandler {}

class _FakeAppLinks extends Fake implements AppLinks {
  _FakeAppLinks({this.initialLink});

  Uri? initialLink;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  void emit(Uri uri) => _controller.add(uri);
  void emitError(Object error) => _controller.addError(error);

  @override
  Future<Uri?> getInitialLink() async => initialLink;

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  Future<void> dispose() => _controller.close();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('carzon://auth-callback'));
  });

  group('AuthDeepLinkService.isAuthCallback', () {
    test('accepts the custom carzon:// scheme regardless of host', () {
      expect(
        AuthDeepLinkService.isAuthCallback(
          Uri.parse('carzon://auth-callback#access_token=abc'),
        ),
        isTrue,
      );
      expect(
        AuthDeepLinkService.isAuthCallback(Uri.parse('carzon://anything')),
        isTrue,
      );
    });

    test('accepts URIs carrying Supabase auth tokens in query or fragment', () {
      expect(
        AuthDeepLinkService.isAuthCallback(
          Uri.parse('https://example.com/cb?code=xyz'),
        ),
        isTrue,
      );
      expect(
        AuthDeepLinkService.isAuthCallback(
          Uri.parse(
            'https://example.com/cb#access_token=abc&refresh_token=def',
          ),
        ),
        isTrue,
      );
      expect(
        AuthDeepLinkService.isAuthCallback(
          Uri.parse('https://example.com/cb?error_description=expired'),
        ),
        isTrue,
      );
    });

    test('rejects unrelated URIs', () {
      expect(
        AuthDeepLinkService.isAuthCallback(Uri.parse('https://example.com')),
        isFalse,
      );
      expect(
        AuthDeepLinkService.isAuthCallback(Uri.parse('myapp://other/path')),
        isFalse,
      );
    });
  });

  group('AuthDeepLinkService.handleUri', () {
    late _MockAuthUrlHandler parser;
    late AuthDeepLinkService service;

    setUp(() {
      parser = _MockAuthUrlHandler();
      service = AuthDeepLinkService(authUrlHandler: parser);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('forwards carzon:// auth-callback URIs to the parser', () async {
      when(() => parser.handleAuthUrl(any())).thenAnswer((_) async {});
      final uri = Uri.parse('carzon://auth-callback#access_token=abc');

      final handled = await service.handleUri(uri);

      expect(handled, isTrue);
      verify(() => parser.handleAuthUrl(uri)).called(1);
    });

    test('ignores unrelated URIs without invoking the parser', () async {
      final handled = await service.handleUri(Uri.parse('https://example.com'));

      expect(handled, isFalse);
      verifyNever(() => parser.handleAuthUrl(any()));
    });

    test('swallows AuthException from the parser without throwing', () async {
      when(
        () => parser.handleAuthUrl(any()),
      ).thenThrow(sb.AuthException('expired'));

      await expectLater(
        service.handleUri(Uri.parse('carzon://auth-callback')),
        completion(isTrue),
      );
    });

    test(
      'swallows unexpected errors from the parser without throwing',
      () async {
        when(() => parser.handleAuthUrl(any())).thenThrow(StateError('boom'));

        await expectLater(
          service.handleUri(Uri.parse('carzon://auth-callback')),
          completion(isTrue),
        );
      },
    );
  });

  group('AuthDeepLinkService.initialize', () {
    test('replays the cold-start initial link through the parser', () async {
      final parser = _MockAuthUrlHandler();
      when(() => parser.handleAuthUrl(any())).thenAnswer((_) async {});
      final initial = Uri.parse('carzon://auth-callback#access_token=abc');
      final appLinks = _FakeAppLinks(initialLink: initial);
      final service = AuthDeepLinkService(
        authUrlHandler: parser,
        appLinks: appLinks,
      );

      await service.initialize();

      verify(() => parser.handleAuthUrl(initial)).called(1);

      await service.dispose();
      await appLinks.dispose();
    });

    test(
      'forwards runtime stream emissions and ignores unrelated ones',
      () async {
        final parser = _MockAuthUrlHandler();
        when(() => parser.handleAuthUrl(any())).thenAnswer((_) async {});
        final appLinks = _FakeAppLinks();
        final service = AuthDeepLinkService(
          authUrlHandler: parser,
          appLinks: appLinks,
        );

        await service.initialize();

        appLinks.emit(Uri.parse('https://unrelated.example'));
        appLinks.emit(Uri.parse('carzon://auth-callback#access_token=abc'));

        // Let microtasks drain before asserting.
        await Future<void>.delayed(Duration.zero);

        verify(
          () => parser.handleAuthUrl(
            Uri.parse('carzon://auth-callback#access_token=abc'),
          ),
        ).called(1);
        verifyNoMoreInteractions(parser);

        await service.dispose();
        await appLinks.dispose();
      },
    );

    test('swallows stream errors without crashing the subscription', () async {
      final parser = _MockAuthUrlHandler();
      when(() => parser.handleAuthUrl(any())).thenAnswer((_) async {});
      final appLinks = _FakeAppLinks();
      final service = AuthDeepLinkService(
        authUrlHandler: parser,
        appLinks: appLinks,
      );

      await service.initialize();

      appLinks.emitError(Exception('platform boom'));
      await Future<void>.delayed(Duration.zero);
      appLinks.emit(Uri.parse('carzon://auth-callback'));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => parser.handleAuthUrl(Uri.parse('carzon://auth-callback')),
      ).called(1);

      await service.dispose();
      await appLinks.dispose();
    });

    test('initialize() is idempotent', () async {
      final parser = _MockAuthUrlHandler();
      final appLinks = _FakeAppLinks(initialLink: null);
      final service = AuthDeepLinkService(
        authUrlHandler: parser,
        appLinks: appLinks,
      );

      await service.initialize();
      await service.initialize();

      // Runtime emission should still be delivered exactly once.
      when(() => parser.handleAuthUrl(any())).thenAnswer((_) async {});
      appLinks.emit(Uri.parse('carzon://auth-callback'));
      await Future<void>.delayed(Duration.zero);

      verify(() => parser.handleAuthUrl(any())).called(1);

      await service.dispose();
      await appLinks.dispose();
    });
  });
}
