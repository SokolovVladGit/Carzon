import 'package:equatable/equatable.dart';

/// One Moldova-local day of listing views.
class SellerAnalyticsDailyPoint extends Equatable {
  const SellerAnalyticsDailyPoint({required this.date, required this.views});

  final DateTime date;
  final int views;

  @override
  List<Object?> get props => [date, views];
}
