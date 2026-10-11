import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/auth/data/social/google_sign_in_adapter.dart';
import 'package:carzon/features/auth/domain/social/social_auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  const iosClientId =
      '68189143516-ahrske7madnpca3jrqtl87sfl3npp2j2.apps.googleusercontent.com';
  const webClientId =
      '68189143516-o1l6ks0phe0fg6n429023b6k8pbugese.apps.googleusercontent.com';

  late _MockGoogleSignIn signIn;

  setUp(() {
    signIn = _MockGoogleSignIn();
  });

  test('blank web client id does not initialize Google Sign-In', () async {
    final adapter = GoogleSignInAdapter(
      webClientId: '   ',
      iosClientId: iosClientId,
      signIn: signIn,
    );

    await expectLater(
      adapter.authenticate(),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          SocialAuthMessages.googleNotConfigured,
        ),
      ),
    );
    verifyNever(
      () => signIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    );
  });

  test('initialize receives the iOS client id and web server client id', () async {
    when(
      () => signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
    ).thenAnswer((_) async {});
    when(
      () => signIn.authenticate(scopeHint: any(named: 'scopeHint')),
    ).thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));

    final adapter = GoogleSignInAdapter(
      webClientId: webClientId,
      iosClientId: iosClientId,
      signIn: signIn,
    );

    await expectLater(adapter.authenticate(), throwsA(isA<AuthCancelledException>()));
    verify(
      () => signIn.initialize(clientId: iosClientId, serverClientId: webClientId),
    ).called(1);
  });

  test('blank iOS client id is passed as null and still uses the web audience', () async {
    when(
      () => signIn.initialize(clientId: null, serverClientId: webClientId),
    ).thenAnswer((_) async {});
    when(
      () => signIn.authenticate(scopeHint: any(named: 'scopeHint')),
    ).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );

    final adapter = GoogleSignInAdapter(
      webClientId: webClientId,
      iosClientId: '  ',
      signIn: signIn,
    );

    await expectLater(
      adapter.authenticate(),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          SocialAuthMessages.googleFailed,
        ),
      ),
    );
  });
}
