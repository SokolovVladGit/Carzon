/// Kind of in-app messaging thread.
enum ConversationKind {
  listing,
  support;

  static ConversationKind fromDb(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'support' => ConversationKind.support,
      _ => ConversationKind.listing,
    };
  }

  String toDb() => switch (this) {
    ConversationKind.listing => 'listing',
    ConversationKind.support => 'support',
  };
}
