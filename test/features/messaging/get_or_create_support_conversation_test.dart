import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:carzon/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MessagingRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late MessagingRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = MessagingRepositoryImpl(remote);
  });

  test('getOrCreateSupportConversation returns conversation id on success', () async {
    when(() => remote.getOrCreateSupportConversation())
        .thenAnswer((_) async => 'conv-support-1');

    final result = await repository.getOrCreateSupportConversation();

    expect(result, isA<Success<String>>());
    expect((result as Success<String>).value, 'conv-support-1');
    verify(() => remote.getOrCreateSupportConversation()).called(1);
  });

  test('getOrCreateSupportConversation maps ServerException to failure', () async {
    when(() => remote.getOrCreateSupportConversation()).thenThrow(
      ServerException('support account is not configured'),
    );

    final result = await repository.getOrCreateSupportConversation();

    expect(result, isA<FailureResult<String>>());
    final failure = (result as FailureResult<String>).failure;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, contains('support account is not configured'));
  });
}
