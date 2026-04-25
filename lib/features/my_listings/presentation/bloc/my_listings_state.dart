import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum MyListingsStatus { initial, loading, success, failure }

/// Classifies owner-action failures so the UI can pick the right
/// localized snackbar message without the cubit reaching into
/// `AppLocalizations`. Presentation code maps these to Russian strings
/// via `context.l10n`.
enum MyListingActionFailureKind {
  /// Owner is not allowed to perform a status change (auth/ownership).
  statusNotAllowed,

  /// Status transition value was rejected by the server enum check.
  statusInvalid,

  /// Generic fallback for status change failures.
  statusGeneric,

  /// Owner is not allowed to delete the listing (auth/ownership).
  deleteNotAllowed,

  /// Listing was already removed or does not exist.
  deleteNotFound,

  /// Generic fallback for delete failures.
  deleteGeneric,
}

class MyListingsState extends Equatable {
  const MyListingsState({
    this.status = MyListingsStatus.initial,
    this.items = const <Listing>[],
    this.loadFailure = false,
    this.pendingStatusIds = const <String>{},
    this.pendingDeleteIds = const <String>{},
    this.lastActionError,
  });

  final MyListingsStatus status;
  final List<Listing> items;

  /// True when the initial load failed. The actual localized message is
  /// resolved by the page.
  final bool loadFailure;

  /// Ids of listings whose status update is currently in flight. The UI
  /// uses this to show a per-row spinner and disable duplicate taps.
  final Set<String> pendingStatusIds;

  /// Ids of listings whose permanent delete RPC is currently in flight.
  /// Held separately from [pendingStatusIds] because the two operations
  /// do not stack (delete removes the row; status update replaces it in
  /// place) and the UI's per-row spinner should fire for either.
  final Set<String> pendingDeleteIds;

  /// One-shot error surfaced to the page as a snackbar when an owner
  /// status action fails. The page clears it via
  /// [MyListingsCubit.acknowledgeActionError] after showing the message.
  /// Holds a monotonic id so repeated identical errors still re-fire
  /// the page listener.
  final ActionError? lastActionError;

  const MyListingsState.initial() : this();
  const MyListingsState.loading() : this(status: MyListingsStatus.loading);
  const MyListingsState.success(List<Listing> items)
      : this(status: MyListingsStatus.success, items: items);
  const MyListingsState.failure()
      : this(status: MyListingsStatus.failure, loadFailure: true);

  MyListingsState copyWith({
    MyListingsStatus? status,
    List<Listing>? items,
    bool? loadFailure,
    Set<String>? pendingStatusIds,
    Set<String>? pendingDeleteIds,
    ActionError? lastActionError,
    bool clearLastActionError = false,
  }) {
    return MyListingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      loadFailure: loadFailure ?? this.loadFailure,
      pendingStatusIds: pendingStatusIds ?? this.pendingStatusIds,
      pendingDeleteIds: pendingDeleteIds ?? this.pendingDeleteIds,
      lastActionError:
          clearLastActionError ? null : (lastActionError ?? this.lastActionError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        loadFailure,
        pendingStatusIds,
        pendingDeleteIds,
        lastActionError,
      ];
}

/// Value-type wrapper so repeated identical error kinds still trigger
/// a `BlocListener` in the page (each emission gets a new id).
class ActionError extends Equatable {
  const ActionError({required this.id, required this.kind});

  final int id;
  final MyListingActionFailureKind kind;

  @override
  List<Object?> get props => [id, kind];
}
