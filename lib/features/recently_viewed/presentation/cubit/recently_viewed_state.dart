import 'package:equatable/equatable.dart';

import '../../domain/entities/recently_viewed_entry.dart';

enum RecentlyViewedStatus { initial, loading, ready, failure }

class RecentlyViewedState extends Equatable {
  const RecentlyViewedState({
    this.status = RecentlyViewedStatus.initial,
    this.entries = const [],
  });

  final RecentlyViewedStatus status;
  final List<RecentlyViewedEntry> entries;

  bool get isEmpty => entries.isEmpty;

  RecentlyViewedState copyWith({
    RecentlyViewedStatus? status,
    List<RecentlyViewedEntry>? entries,
  }) {
    return RecentlyViewedState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [status, entries];
}
