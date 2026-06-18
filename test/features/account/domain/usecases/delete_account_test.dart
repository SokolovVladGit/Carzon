import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/account/domain/repositories/account_privacy_repository.dart';
import 'package:carzon/features/account/domain/usecases/delete_account.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountPrivacyRepository extends Mock
    implements AccountPrivacyRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPushRegistration extends Mock
    implements PushNotificationRegistrationService {}

void main() {
  late _MockAccountPrivacyRepository accountRepo;
  late _MockAuthRepository authRepo;
  late _MockPushRegistration pushRegistration;
  late DeleteAccount sut;

  setUp(() {
    accountRepo = _MockAccountPrivacyRepository();
    authRepo = _MockAuthRepository();
    pushRegistration = _MockPushRegistration();
    sut = DeleteAccount(accountRepo, authRepo, pushRegistration);

    when(() => pushRegistration.beforeSignOut()).thenAnswer((_) async {});
    when(() => accountRepo.deleteOwnAccount()).thenAnswer(
      (_) async => const Success(null),
    );
    when(() => authRepo.signOut()).thenAnswer(
      (_) async => const Success(null),
    );
  });

  test('calls push cleanup before account deletion', () async {
    await sut();

    verifyInOrder([
      () => pushRegistration.beforeSignOut(),
      () => accountRepo.deleteOwnAccount(),
      () => authRepo.signOut(),
    ]);
  });

  test('skips signOut when deletion fails', () async {
    when(() => accountRepo.deleteOwnAccount()).thenAnswer(
      (_) async => const FailureResult(ServerFailure('fail')),
    );

    final result = await sut();

    expect(result, isA<FailureResult<void>>());
    verifyNever(() => authRepo.signOut());
  });
}
