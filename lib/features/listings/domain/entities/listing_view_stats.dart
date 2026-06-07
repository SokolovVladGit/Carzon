import 'package:equatable/equatable.dart';

/// Fresh view aggregates returned by `record_listing_view`.
class ListingViewStats extends Equatable {
  const ListingViewStats({required this.totalViews, required this.todayViews});

  final int totalViews;
  final int todayViews;

  @override
  List<Object?> get props => [totalViews, todayViews];
}
