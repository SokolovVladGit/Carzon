import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum MyListingsStatus { initial, loading, success, failure }

class MyListingsState extends Equatable {
  const MyListingsState({
    this.status = MyListingsStatus.initial,
    this.items = const <Listing>[],
    this.errorMessage,
  });

  final MyListingsStatus status;
  final List<Listing> items;
  final String? errorMessage;

  const MyListingsState.initial() : this();
  const MyListingsState.loading() : this(status: MyListingsStatus.loading);
  const MyListingsState.success(List<Listing> items)
      : this(status: MyListingsStatus.success, items: items);
  const MyListingsState.failure(String message)
      : this(status: MyListingsStatus.failure, errorMessage: message);

  @override
  List<Object?> get props => [status, items, errorMessage];
}
