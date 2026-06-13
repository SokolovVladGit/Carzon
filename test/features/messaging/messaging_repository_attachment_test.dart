import 'dart:typed_data';

import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/data/datasources/chat_attachment_remote_datasource.dart';
import 'package:carzon/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:carzon/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:carzon/features/messaging/domain/constants/chat_attachment_limits.dart';
import 'package:carzon/features/messaging/domain/entities/chat_attachment_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements MessagingRemoteDataSource {}

class _MockAttachments extends Mock implements ChatAttachmentRemoteDataSource {}

ChatAttachmentUpload _upload({
  Uint8List? bytes,
  String mimeType = 'image/jpeg',
  String? caption,
}) {
  return ChatAttachmentUpload(
    conversationId: 'conv-1',
    bytes: bytes ?? Uint8List.fromList([1, 2, 3]),
    mimeType: mimeType,
    caption: caption,
  );
}

void main() {
  late _MockRemote remote;
  late _MockAttachments attachments;
  late MessagingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_upload());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    remote = _MockRemote();
    attachments = _MockAttachments();
    repository = MessagingRepositoryImpl(remote, attachments);
  });

  group('validateChatAttachmentUpload via repository', () {
    test('rejects empty bytes', () async {
      final result = await repository.sendMessageWithAttachment(
        _upload(bytes: Uint8List(0)),
      );

      expect(result, isA<FailureResult<String>>());
      expect(
        (result as FailureResult<String>).failure.message,
        contains('empty'),
      );
      verifyNever(() => attachments.uploadChatAttachment(
            conversationId: any(named: 'conversationId'),
            uploaderId: any(named: 'uploaderId'),
            bytes: any(named: 'bytes'),
            mimeType: any(named: 'mimeType'),
          ));
    });

    test('rejects unsupported MIME', () async {
      final result = await repository.sendMessageWithAttachment(
        _upload(mimeType: 'image/webp'),
      );

      expect(result, isA<FailureResult<String>>());
      expect(
        (result as FailureResult<String>).failure.message,
        contains('Unsupported attachment mime type'),
      );
    });

    test('rejects size above 10 MiB', () async {
      final result = await repository.sendMessageWithAttachment(
        ChatAttachmentUpload(
          conversationId: 'conv-1',
          bytes: Uint8List(ChatAttachmentLimits.maxBytes + 1),
          mimeType: 'image/png',
        ),
      );

      expect(result, isA<FailureResult<String>>());
      expect(
        (result as FailureResult<String>).failure.message,
        contains('exceeds limit'),
      );
    });

    test('rejects caption longer than 4000 chars', () async {
      final result = await repository.sendMessageWithAttachment(
        _upload(caption: 'x' * 4001),
      );

      expect(result, isA<FailureResult<String>>());
      expect(
        (result as FailureResult<String>).failure.message,
        contains('Caption is too long'),
      );
    });
  });

  group('sendMessageWithAttachment', () {
    test('uploads then calls RPC with required params', () async {
      when(() => attachments.currentUserIdOrThrow()).thenReturn('user-1');
      when(
        () => attachments.uploadChatAttachment(
          conversationId: any(named: 'conversationId'),
          uploaderId: any(named: 'uploaderId'),
          bytes: any(named: 'bytes'),
          mimeType: any(named: 'mimeType'),
          originalFileName: any(named: 'originalFileName'),
        ),
      ).thenAnswer((_) async => 'conversations/conv-1/user-1/file.jpg');
      when(
        () => remote.sendMessageWithAttachment(
          conversationId: any(named: 'conversationId'),
          storagePath: any(named: 'storagePath'),
          mimeType: any(named: 'mimeType'),
          sizeBytes: any(named: 'sizeBytes'),
          caption: any(named: 'caption'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        ),
      ).thenAnswer((_) async => 'msg-1');

      final upload = _upload(caption: '  look  ');
      final result = await repository.sendMessageWithAttachment(upload);

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, 'msg-1');
      verify(
        () => attachments.uploadChatAttachment(
          conversationId: 'conv-1',
          uploaderId: 'user-1',
          bytes: upload.bytes,
          mimeType: 'image/jpeg',
          originalFileName: null,
        ),
      ).called(1);
      verify(
        () => remote.sendMessageWithAttachment(
          conversationId: 'conv-1',
          storagePath: 'conversations/conv-1/user-1/file.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 3,
          caption: '  look  ',
          width: null,
          height: null,
        ),
      ).called(1);
      verifyNever(() => attachments.deleteByStoragePathBestEffort(any()));
    });

    test('cleans up uploaded object when RPC fails', () async {
      when(() => attachments.currentUserIdOrThrow()).thenReturn('user-1');
      when(
        () => attachments.uploadChatAttachment(
          conversationId: any(named: 'conversationId'),
          uploaderId: any(named: 'uploaderId'),
          bytes: any(named: 'bytes'),
          mimeType: any(named: 'mimeType'),
          originalFileName: any(named: 'originalFileName'),
        ),
      ).thenAnswer((_) async => 'conversations/conv-1/user-1/file.jpg');
      when(
        () => remote.sendMessageWithAttachment(
          conversationId: any(named: 'conversationId'),
          storagePath: any(named: 'storagePath'),
          mimeType: any(named: 'mimeType'),
          sizeBytes: any(named: 'sizeBytes'),
          caption: any(named: 'caption'),
          width: any(named: 'width'),
          height: any(named: 'height'),
        ),
      ).thenThrow(ServerException('rpc failed'));
      when(
        () => attachments.deleteByStoragePathBestEffort(any()),
      ).thenAnswer((_) async {});

      final result = await repository.sendMessageWithAttachment(_upload());

      expect(result, isA<FailureResult<String>>());
      verify(
        () => attachments.deleteByStoragePathBestEffort(
          'conversations/conv-1/user-1/file.jpg',
        ),
      ).called(1);
    });
  });

  group('sendMessage text-only', () {
    test('still delegates to remote send_message RPC', () async {
      when(
        () => remote.sendMessage('conv-1', 'hello'),
      ).thenAnswer((_) async => 'msg-text');

      final result = await repository.sendMessage('conv-1', 'hello');

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, 'msg-text');
      verify(() => remote.sendMessage('conv-1', 'hello')).called(1);
    });
  });

  group('downloadChatAttachmentBytes', () {
    test('returns bytes from attachment datasource', () async {
      when(
        () => attachments.downloadBytes('conversations/c/u/f.jpg'),
      ).thenAnswer((_) async => Uint8List.fromList([9, 8]));

      final result = await repository.downloadChatAttachmentBytes(
        'conversations/c/u/f.jpg',
      );

      expect(result, isA<Success<List<int>>>());
      expect((result as Success<List<int>>).value, [9, 8]);
    });
  });
}
