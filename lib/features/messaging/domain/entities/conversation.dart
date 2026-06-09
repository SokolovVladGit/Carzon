import 'package:equatable/equatable.dart';

import 'conversation_kind.dart';

/// In-app thread between participants (listing-scoped or support).
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.createdAt,
    required this.updatedAt,
    this.conversationKind = ConversationKind.listing,
    this.listingId,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.listingTitle,
    this.listingMake,
    this.listingModel,
    this.listingCity,
    this.listingCoverImageUrl,
    this.listingPriceAmount,
    this.listingPriceCurrencyDb,
    this.hasUnread = false,
  });

  final String id;
  final ConversationKind conversationKind;

  /// Null for [ConversationKind.support] threads.
  final String? listingId;
  final String buyerId;
  final String sellerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  /// Title from joined `listings` row when RLS allows; otherwise null.
  final String? listingTitle;

  /// Listing fields from embedded `listings` select when RLS/join succeeds.
  final String? listingMake;
  final String? listingModel;
  final String? listingCity;
  final String? listingCoverImageUrl;

  /// Mirrors `listings.price_eur` (amount for [listingPriceCurrencyDb]).
  final num? listingPriceAmount;

  /// Raw DB `price_currency` (`eur` | `usd`) for display formatting.
  final String? listingPriceCurrencyDb;

  /// True when the current user has inbound messages after their read cursor
  /// (see `list_inbox_conversations`; single-conversation loads omit this).
  final bool hasUnread;

  bool get isSupportConversation => conversationKind == ConversationKind.support;

  bool get isListingConversation => conversationKind == ConversationKind.listing;

  @override
  List<Object?> get props => [
    id,
    conversationKind,
    listingId,
    buyerId,
    sellerId,
    createdAt,
    updatedAt,
    lastMessageAt,
    lastMessagePreview,
    listingTitle,
    listingMake,
    listingModel,
    listingCity,
    listingCoverImageUrl,
    listingPriceAmount,
    listingPriceCurrencyDb,
    hasUnread,
  ];
}
