import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:carzon/features/auth/data/models/auth_user_model.dart';
import 'package:carzon/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/social/apple_native_auth.dart';
import 'package:carzon/features/auth/domain/social/google_native_auth.dart';
import 'package:carzon/features/auth/domain/social/social_auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockGoogle extends Mock implements GoogleNativeAuth {}

class _MockApple extends Mock implements AppleNativeAuth {}

void main() {
  late _MockRemote remote;
  late _MockGoogle google;
  late _MockApple apple;
  late AuthRepositoryImpl repo;

  const user = AuthUserModel(id: 'u1', email: 'a@b.c');

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    remote = _MockRemote();
    google = _MockGoogle();
    apple = _MockApple();
    repo = AuthRepositoryImpl(
      remote,
      googleNativeAuth: google,
      appleNativeAuth: apple,
    );
  });

  group('signInWithGoogle', () {
    test('success returns authenticated user', () async {
      when(() => google.authenticate()).thenAnswer(
        (_) async =>
            const GoogleNativeTokens(idToken: 'id', accessToken: 'access'),
      );
      when(
        () => remote.signInWithGoogleIdToken(
          idToken: 'id',
          accessToken: 'access',
        ),
      ).thenAnswer((_) async => user);

      final result = await repo.signInWithGoogle();
      expect(result, isA<Success<AuthUser>>());
      expect((result as Success<AuthUser>).value, user);
    });

    test('cancellation is a silent AuthCancelledFailure', () async {
      when(() => google.authenticate()).thenThrow(AuthCancelledException());

      final result = await repo.signInWithGoogle();
      expect(result, isA<FailureResult<AuthUser>>());
      expect(
        (result as FailureResult<AuthUser>).failure,
        isA<AuthCancelledFailure>(),
      );
      verifyNever(
        () => remote.signInWithGoogleIdToken(
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      );
    });

    test('missing token is mapped', () async {
      when(() => google.authenticate()).thenAnswer(
        (_) async => const GoogleNativeTokens(idToken: '', accessToken: ''),
      );

      final result = await repo.signInWithGoogle();
      expect(
        (result as FailureResult<AuthUser>).failure.message,
        SocialAuthMessages.googleMissingToken,
      );
    });

    test('provider failure is mapped', () async {
      when(
        () => google.authenticate(),
      ).thenThrow(AuthException(SocialAuthMessages.googleFailed));

      final result = await repo.signInWithGoogle();
      expect(
        (result as FailureResult<AuthUser>).failure.message,
        SocialAuthMessages.googleFailed,
      );
    });

    test('identity collision is mapped', () async {
      when(() => google.authenticate()).thenAnswer(
        (_) async =>
            const GoogleNativeTokens(idToken: 'id', accessToken: 'access'),
      );
      when(
        () => remote.signInWithGoogleIdToken(
          idToken: 'id',
          accessToken: 'access',
        ),
      ).thenThrow(
        AuthException(
          'A user with this email address has already been registered',
        ),
      );

      final result = await repo.signInWithGoogle();
      expect(
        (result as FailureResult<AuthUser>).failure.message,
        SocialAuthMessages.identityAlreadyExists,
      );
    });
  });

  group('signInWithApple', () {
    test('success uses raw nonce and becomes authenticated', () async {
      when(() => apple.authenticate()).thenAnswer(
        (_) async => const AppleNativeAuthResult(
          idToken: 'apple-id',
          rawNonce: 'raw-nonce',
        ),
      );
      when(
        () => remote.signInWithAppleIdToken(
          idToken: 'apple-id',
          nonce: 'raw-nonce',
        ),
      ).thenAnswer((_) async => user);

      final result = await repo.signInWithApple();
      expect((result as Success<AuthUser>).value, user);
      verifyNever(
        () => remote.seedAuthFullNameIfAbsent(
          givenName: any(named: 'givenName'),
          familyName: any(named: 'familyName'),
        ),
      );
    });

    test('first sign-in name is seeded after session exists', () async {
      const named = AuthUserModel(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'Ion Popescu',
      );
      when(() => apple.authenticate()).thenAnswer(
        (_) async => const AppleNativeAuthResult(
          idToken: 'apple-id',
          rawNonce: 'raw-nonce',
          givenName: 'Ion',
          familyName: 'Popescu',
        ),
      );
      when(
        () => remote.signInWithAppleIdToken(
          idToken: 'apple-id',
          nonce: 'raw-nonce',
        ),
      ).thenAnswer((_) async => user);
      when(
        () => remote.seedAuthFullNameIfAbsent(
          givenName: 'Ion',
          familyName: 'Popescu',
        ),
      ).thenAnswer((_) async => named);

      final result = await repo.signInWithApple();
      expect((result as Success<AuthUser>).value.fullName, 'Ion Popescu');
    });

    test('cancellation is silent', () async {
      when(() => apple.authenticate()).thenThrow(AuthCancelledException());
      final result = await repo.signInWithApple();
      expect(
        (result as FailureResult<AuthUser>).failure,
        isA<AuthCancelledFailure>(),
      );
    });

    test('missing identity token is mapped', () async {
      when(() => apple.authenticate()).thenAnswer(
        (_) async => const AppleNativeAuthResult(idToken: '', rawNonce: 'n'),
      );
      final result = await repo.signInWithApple();
      expect(
        (result as FailureResult<AuthUser>).failure.message,
        SocialAuthMessages.appleMissingToken,
      );
    });
  });
}
