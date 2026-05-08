import '../../../../core/utils/result.dart';
import '../repositories/messaging_repository.dart';

/// Invokes RPC `get_or_create_conversation` — returns conversation id for a listing.
///
/// Guards (authenticated buyer vs seller self-chat, etc.) stay in presentation.
class GetOrCreateConversation {
  GetOrCreateConversation(this._repository);

  final MessagingRepository _repository;

  Future<Result<String>> call(String listingId) =>
      _repository.getOrCreateConversation(listingId);
}
