import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/conversation.dart';
import 'thread_listing_copy.dart';

/// Contextual AppBar title for a conversation thread.
String threadAppBarTitle(
  Conversation conversation,
  String listingIdFallback,
  AppLocalizations l10n,
) {
  if (conversation.isSupportConversation) {
    return l10n.supportConversationTitle;
  }

  final hasListingHeadline =
      (conversation.listingMake?.trim().isNotEmpty ?? false) ||
      (conversation.listingModel?.trim().isNotEmpty ?? false) ||
      (conversation.listingTitle?.trim().isNotEmpty ?? false);
  if (hasListingHeadline) {
    return threadListingPrimaryLine(conversation, listingIdFallback);
  }

  return l10n.messagingThreadTitle;
}
