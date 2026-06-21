import 'package:equatable/equatable.dart';

import '../../domain/entities/recent_search_entry.dart';

enum RecentSearchesStatus { initial, loading, ready, failure }

class RecentSearchesState extends Equatable {
  const RecentSearchesState({
    this.status = RecentSearchesStatus.initial,
    this.entries = const [],
  });

  final RecentSearchesStatus status;
  final List<RecentSearchEntry> entries;

  RecentSearchesState copyWith({
    RecentSearchesStatus? status,
    List<RecentSearchEntry>? entries,
  }) {
    return RecentSearchesState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [status, entries];
}
