import 'dart:async';

import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_last_applied_listing_discovery_repository.dart';
import '../../helpers/noop_record_recent_search.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

final class _PendingRequest {
  _PendingRequest(this.query);

  final ListingsQuery query;
  final completer = Completer<Result<List<Listing>>>();

  void succeed(List<Listing> listings) {
    completer.complete(Success(listings));
  }

  void fail(String message) {
    completer.complete(FailureResult(ServerFailure(message)));
  }
}

final class _ControlledListingsRequests {
  _ControlledListingsRequests(this.repository) {
    when(() => repository.getListings(any())).thenAnswer((invocation) {
      callCount++;
      final request = _PendingRequest(
        invocation.positionalArguments.single as ListingsQuery,
      );
      _pending.add(request);
      _requestAvailable?.complete();
      _requestAvailable = null;
      return request.completer.future;
    });
  }

  final _MockListingsRepository repository;
  final List<_PendingRequest> _pending = [];
  Completer<void>? _requestAvailable;
  int callCount = 0;

  Future<_PendingRequest> take() async {
    if (_pending.isEmpty) {
      _requestAvailable = Completer<void>();
      await _requestAvailable!.future;
    }
    return _pending.removeAt(0);
  }
}

Listing _listing(String id) => Listing(
  id: id,
  title: 'Listing $id',
  make: 'Volkswagen',
  model: 'Golf',
  year: 2020,
  priceEur: 10000,
  mileageKm: 80000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
);

List<Listing> _fullPage(String prefix) => List.generate(
  AppConstants.defaultPageSize,
  (index) => _listing('$prefix-$index'),
);

void main() {
  late _MockListingsRepository repository;
  late _ControlledListingsRequests requests;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repository = _MockListingsRepository();
    requests = _ControlledListingsRequests(repository);
  });

  ListingsBloc buildBloc() => ListingsBloc(
    getListings: GetListings(repository),
    lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    recordRecentSearch: NoopRecordRecentSearch(),
  );

  Future<void> completeInitialPage(ListingsBloc bloc, {String? search}) async {
    if (search == null) {
      bloc.add(const ListingsRequested());
    } else {
      bloc.add(ListingsSearchChanged(search));
    }
    final request = await requests.take();
    final settled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success &&
          state.page == 0 &&
          state.search == search,
    );
    request.succeed(_fullPage(search ?? 'initial'));
    await settled;
  }

  test('older replacement success cannot overwrite newer success', () async {
    final bloc = buildBloc();
    bloc.add(const ListingsSearchChanged('older'));
    final older = await requests.take();
    bloc.add(const ListingsSearchChanged('newer'));
    final newer = await requests.take();

    final newerSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success && state.search == 'newer',
    );
    newer.succeed([_listing('newer')]);
    await newerSettled;
    older.succeed([_listing('older')]);
    await bloc.close();

    expect(bloc.state.search, 'newer');
    expect(bloc.state.items.map((item) => item.id), ['newer']);
  });

  test('older replacement failure cannot replace newer success', () async {
    final bloc = buildBloc();
    bloc.add(const ListingsSearchChanged('older'));
    final older = await requests.take();
    bloc.add(const ListingsSearchChanged('newer'));
    final newer = await requests.take();

    final newerSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success && state.search == 'newer',
    );
    newer.succeed([_listing('newer')]);
    await newerSettled;
    older.fail('obsolete');
    await bloc.close();

    expect(bloc.state.status, ListingsStatus.success);
    expect(bloc.state.items.map((item) => item.id), ['newer']);
    expect(bloc.state.loadFailure, isNull);
  });

  test('older success cannot replace authoritative newer failure', () async {
    final bloc = buildBloc();
    bloc.add(const ListingsSearchChanged('older'));
    final older = await requests.take();
    bloc.add(const ListingsSearchChanged('newer'));
    final newer = await requests.take();

    final newerSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.failure && state.search == 'newer',
    );
    newer.fail('authoritative');
    await newerSettled;
    older.succeed([_listing('older')]);
    await bloc.close();

    expect(bloc.state.status, ListingsStatus.failure);
    expect(bloc.state.search, 'newer');
    expect(bloc.state.loadFailure, const ServerFailure('authoritative'));
    expect(bloc.state.items, isEmpty);
  });

  test('newer same-criteria refresh remains authoritative', () async {
    final bloc = buildBloc();
    await completeInitialPage(bloc, search: 'same');

    bloc.add(const ListingsRefreshed());
    final olderRefresh = await requests.take();
    bloc.add(const ListingsRefreshed());
    final newerRefresh = await requests.take();

    final newerSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success &&
          state.items.single.id == 'refresh-newer',
    );
    newerRefresh.succeed([_listing('refresh-newer')]);
    await newerSettled;
    olderRefresh.succeed([_listing('refresh-older')]);
    await bloc.close();

    expect(bloc.state.search, 'same');
    expect(bloc.state.items.map((item) => item.id), ['refresh-newer']);
  });

  test('duplicate pagination triggers issue one next-page request', () async {
    final bloc = buildBloc();
    await completeInitialPage(bloc, search: 'catalog');

    bloc
      ..add(const ListingsNextPageRequested())
      ..add(const ListingsNextPageRequested());
    final nextPage = await requests.take();
    expect(nextPage.query.page, 1);
    final settled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success &&
          state.page == 1 &&
          state.items.length == AppConstants.defaultPageSize + 1,
    );
    nextPage.succeed([_listing('page-1')]);
    await settled;
    await bloc.close();

    expect(requests.callCount, 2);
    expect(bloc.state.items.where((item) => item.id == 'page-1').length, 1);
  });

  test(
    'pagination completion cannot append after criteria replacement',
    () async {
      final bloc = buildBloc();
      await completeInitialPage(bloc, search: 'older');

      bloc.add(const ListingsNextPageRequested());
      final olderNextPage = await requests.take();
      bloc.add(const ListingsSearchChanged('newer'));
      final replacement = await requests.take();

      final replacementSettled = bloc.stream.firstWhere(
        (state) =>
            state.status == ListingsStatus.success && state.search == 'newer',
      );
      replacement.succeed([_listing('newer')]);
      await replacementSettled;
      olderNextPage.succeed([_listing('obsolete-page')]);
      await bloc.close();

      expect(bloc.state.search, 'newer');
      expect(bloc.state.page, 0);
      expect(bloc.state.items.map((item) => item.id), ['newer']);
    },
  );

  test('stale pagination failure cannot affect replacement result', () async {
    final bloc = buildBloc();
    await completeInitialPage(bloc, search: 'older');

    bloc.add(const ListingsNextPageRequested());
    final olderNextPage = await requests.take();
    bloc.add(const ListingsSearchChanged('newer'));
    final replacement = await requests.take();

    final replacementSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success && state.search == 'newer',
    );
    replacement.succeed([_listing('newer')]);
    await replacementSettled;
    olderNextPage.fail('obsolete pagination');
    await bloc.close();

    expect(bloc.state.status, ListingsStatus.success);
    expect(bloc.state.items.map((item) => item.id), ['newer']);
    expect(bloc.state.loadFailure, isNull);
  });

  test('criteria replacement supersedes a pending initial request', () async {
    final bloc = buildBloc();
    bloc.add(const ListingsRequested());
    final initial = await requests.take();
    bloc.add(const ListingsSearchChanged('newer'));
    final replacement = await requests.take();

    final replacementSettled = bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success && state.search == 'newer',
    );
    replacement.succeed([_listing('newer')]);
    await replacementSettled;
    initial.succeed([_listing('initial')]);
    await bloc.close();

    expect(bloc.state.search, 'newer');
    expect(bloc.state.items.map((item) => item.id), ['newer']);
  });

  test('closing with a pending request suppresses its completion', () async {
    final bloc = buildBloc();
    bloc.add(const ListingsRequested());
    final pending = await requests.take();

    final closeFuture = bloc.close();
    pending.succeed([_listing('late')]);

    await expectLater(closeFuture, completes);
    expect(bloc.state.status, ListingsStatus.loading);
    expect(bloc.state.items, isEmpty);
  });
}
