import 'package:equatable/equatable.dart';

sealed class ListingsEvent extends Equatable {
  const ListingsEvent();

  @override
  List<Object?> get props => [];
}

class ListingsRequested extends ListingsEvent {
  const ListingsRequested({this.search, this.make});
  final String? search;
  final String? make;

  @override
  List<Object?> get props => [search, make];
}

class ListingsRefreshed extends ListingsEvent {
  const ListingsRefreshed();
}

class ListingsNextPageRequested extends ListingsEvent {
  const ListingsNextPageRequested();
}
