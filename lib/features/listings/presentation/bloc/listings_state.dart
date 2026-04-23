import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';

enum ListingsStatus { initial, loading, loadingMore, success, failure }

class ListingsState extends Equatable {
  const ListingsState({
    this.status = ListingsStatus.initial,
    this.items = const [],
    this.page = 0,
    this.hasReachedEnd = false,
    this.search,
    this.make,
    this.errorMessage,
  });

  final ListingsStatus status;
  final List<Listing> items;
  final int page;
  final bool hasReachedEnd;
  final String? search;
  final String? make;
  final String? errorMessage;

  ListingsState copyWith({
    ListingsStatus? status,
    List<Listing>? items,
    int? page,
    bool? hasReachedEnd,
    String? search,
    String? make,
    String? errorMessage,
  }) {
    return ListingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      search: search ?? this.search,
      make: make ?? this.make,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasReachedEnd, search, make, errorMessage];
}
