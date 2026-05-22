import 'package:equatable/equatable.dart';

import '../../domain/entities/compare_item.dart';

/// Local compare-set state (device-only, not synced to Supabase).
class CompareState extends Equatable {
  const CompareState({this.items = const []});

  static const int maxItems = 3;

  final List<CompareItem> items;

  int get count => items.length;

  bool get isEmpty => items.isEmpty;

  bool get hasOneItem => count == 1;

  bool get hasMinimumForCompare => count >= 2;

  bool get isFull => count >= maxItems;

  bool containsListing(String listingId) =>
      items.any((i) => i.listingId == listingId);

  CompareState copyWith({List<CompareItem>? items}) {
    return CompareState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
