import 'package:get_it/get_it.dart';

import '../data/datasources/recent_searches_local_datasource.dart';
import '../data/repositories/recent_searches_repository_impl.dart';
import '../domain/repositories/recent_searches_repository.dart';
import '../domain/usecases/record_recent_search.dart';
import '../presentation/cubit/recent_searches_cubit.dart';

void registerRecentSearchesFeature(GetIt sl) {
  sl.registerLazySingleton<RecentSearchesLocalDataSource>(
    () => SharedPreferencesRecentSearchesLocalDataSource(),
  );
  sl.registerLazySingleton<RecentSearchesRepository>(
    () => RecentSearchesRepositoryImpl(sl<RecentSearchesLocalDataSource>()),
  );
  sl.registerLazySingleton<RecentSearchesCubit>(
    () => RecentSearchesCubit(repository: sl<RecentSearchesRepository>()),
  );
  sl.registerFactory(
    () => RecordRecentSearch(
      sl<RecentSearchesRepository>(),
      sl<RecentSearchesCubit>(),
    ),
  );
}
