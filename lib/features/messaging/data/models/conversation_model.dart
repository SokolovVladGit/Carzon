import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.listingId,
    required super.buyerId,
    required super.sellerId,
    required super.createdAt,
    required super.updatedAt,
    super.lastMessageAt,
    super.lastMessagePreview,
    super.listingTitle,
    super.listingMake,
    super.listingModel,
    super.listingCity,
    super.listingCoverImageUrl,
    super.listingPriceAmount,
    super.listingPriceCurrencyDb,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final listings = json['listings'];
    String? title;
    String? make;
    String? model;
    String? city;
    String? cover;
    num? price;
    String? priceCurrencyDb;
    if (listings is Map<String, dynamic>) {
      final t = listings['title'] as String?;
      title = (t != null && t.trim().isNotEmpty) ? t.trim() : null;
      final mk = listings['make'] as String?;
      make = (mk != null && mk.trim().isNotEmpty) ? mk.trim() : null;
      final md = listings['model'] as String?;
      model = (md != null && md.trim().isNotEmpty) ? md.trim() : null;
      final ct = listings['city'] as String?;
      city = (ct != null && ct.trim().isNotEmpty) ? ct.trim() : null;
      final cu = listings['cover_image_url'] as String?;
      cover = (cu != null && cu.trim().isNotEmpty) ? cu.trim() : null;
      price = listings['price_eur'] as num?;
      final pc = listings['price_currency'] as String?;
      priceCurrencyDb = (pc != null && pc.trim().isNotEmpty) ? pc.trim() : null;
    }

    return ConversationModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.tryParse(json['last_message_at'] as String),
      lastMessagePreview: json['last_message_preview'] as String?,
      listingTitle: title,
      listingMake: make,
      listingModel: model,
      listingCity: city,
      listingCoverImageUrl: cover,
      listingPriceAmount: price,
      listingPriceCurrencyDb: priceCurrencyDb,
    );
  }
}
