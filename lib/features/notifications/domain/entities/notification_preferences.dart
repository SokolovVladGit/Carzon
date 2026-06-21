import 'package:equatable/equatable.dart';

/// Server-backed notification toggles (Phase 1). Defaults false; delivery not live yet.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.userId,
    required this.globalEnabled,
    required this.messagesEnabled,
    required this.filterAlertsEnabled,
    required this.priceDropsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final bool globalEnabled;
  final bool messagesEnabled;
  final bool filterAlertsEnabled;
  final bool priceDropsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    userId,
    globalEnabled,
    messagesEnabled,
    filterAlertsEnabled,
    priceDropsEnabled,
    createdAt,
    updatedAt,
  ];
}
