class ListingContact {
  const ListingContact({
    this.phone,
    this.telegramUsername,
    this.whatsappEnabled = false,
  });

  final String? phone;
  final String? telegramUsername;
  final bool whatsappEnabled;

  bool get hasAnyContact =>
      phone != null || telegramUsername != null || whatsappEnabled;
}
