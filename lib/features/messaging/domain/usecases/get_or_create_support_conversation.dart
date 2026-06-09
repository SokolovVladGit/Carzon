import '../../../../core/utils/result.dart';
import '../repositories/messaging_repository.dart';

/// Invokes RPC `get_or_create_support_conversation` — returns conversation id.
class GetOrCreateSupportConversation {
  const GetOrCreateSupportConversation(this._repository);

  final MessagingRepository _repository;

  Future<Result<String>> call() => _repository.getOrCreateSupportConversation();
}
