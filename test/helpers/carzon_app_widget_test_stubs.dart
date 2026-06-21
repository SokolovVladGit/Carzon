import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:carzon/features/recent_searches/domain/repositories/recent_searches_repository.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:carzon/features/recently_viewed/domain/repositories/recently_viewed_repository.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import 'package:get_it/get_it.dart';

class _EmptyRecentlyViewedRepository implements RecentlyViewedRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<RecentlyViewedEntry>> load() async => const [];

  @override
  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry) async =>
      [entry];
}

class _EmptyRecentSearchesRepository implements RecentSearchesRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<RecentSearchEntry>> load() async => const [];

  @override
  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry) async =>
      [entry];

  @override
  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry) async =>
      const [];
}

/// Registers device-local history cubits required by [CarzonApp] widget tests.
void registerCarzonAppLocalHistoryCubitStubs(GetIt getIt) {
  getIt.registerSingleton<RecentlyViewedCubit>(
    RecentlyViewedCubit(repository: _EmptyRecentlyViewedRepository()),
  );
  getIt.registerSingleton<RecentSearchesCubit>(
    RecentSearchesCubit(repository: _EmptyRecentSearchesRepository()),
  );
}
