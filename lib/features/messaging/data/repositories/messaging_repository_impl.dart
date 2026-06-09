import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  MessagingRepositoryImpl(this._remote)
    : _logger = AppLogger('MessagingRepository');

  final MessagingRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<String>> getOrCreateConversation(String listingId) async {
    try {
      final id = await _remote.getOrCreateConversation(listingId);
      return Success(id);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getOrCreateConversation unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to open conversation.'),
      );
    }
  }

  @override
  Future<Result<String>> getOrCreateSupportConversation() async {
    try {
      final id = await _remote.getOrCreateSupportConversation();
      return Success(id);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getOrCreateSupportConversation unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to open support conversation.'),
      );
    }
  }

  @override
  Future<Result<List<Conversation>>> getConversations() async {
    try {
      final list = await _remote.fetchConversations();
      return Success(list);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getConversations unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load conversations.'),
      );
    }
  }

  @override
  Future<Result<Conversation>> getConversation(String conversationId) async {
    try {
      final row = await _remote.fetchConversation(conversationId);
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getConversation unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load conversation.'),
      );
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final list = await _remote.fetchMessages(conversationId);
      return Success(list);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getMessages unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load messages.'));
    }
  }

  @override
  Future<Result<String>> sendMessage(String conversationId, String body) async {
    try {
      final id = await _remote.sendMessage(conversationId, body);
      return Success(id);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('sendMessage unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to send message.'));
    }
  }

  @override
  Future<Result<bool>> markConversationRead(String conversationId) async {
    try {
      await _remote.markConversationReadRpc(conversationId);
      return const Success(true);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('markConversationRead unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to sync read receipt.'),
      );
    }
  }

  @override
  Future<Result<int>> getUnreadConversationCount() async {
    try {
      final n = await _remote.fetchUnreadConversationCountRpc();
      return Success(n);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getUnreadConversationCount unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load unread count.'),
      );
    }
  }
}
