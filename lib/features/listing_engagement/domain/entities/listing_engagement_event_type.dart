/// Wire values must match `record_listing_engagement_event` taxonomy.
enum ListingEngagementEventType {
  impression('impression'),
  phone('phone'),
  whatsapp('whatsapp'),
  telegram('telegram'),
  share('share');

  const ListingEngagementEventType(this.wireValue);

  final String wireValue;
}
