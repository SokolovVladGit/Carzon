import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation.dart';
import 'thread_listing_copy.dart';

/// Inbox/thread primary line for any conversation kind.
String conversationPrimaryLine(
  Conversation conversation,
  String listingIdFallback,
  AppLocalizations l10n,
) {
  if (conversation.isSupportConversation) {
    return l10n.supportConversationTitle;
  }
  return threadListingPrimaryLine(conversation, listingIdFallback);
}

/// Inbox preview line when the thread has no last-message preview yet.
String conversationEmptyPreviewLine(
  Conversation conversation,
  AppLocalizations l10n,
) {
  if (conversation.isSupportConversation) {
    return l10n.contactSupportSubtitle;
  }
  return l10n.messagingNoPreview;
}
