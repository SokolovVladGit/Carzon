import 'package:get_it/get_it.dart';

import '../data/datasources/recently_viewed_local_datasource.dart';
import '../data/repositories/recently_viewed_repository_impl.dart';
import '../domain/repositories/recently_viewed_repository.dart';
import '../domain/usecases/record_recently_viewed.dart';
import '../presentation/cubit/recently_viewed_cubit.dart';

void registerRecentlyViewedFeature(GetIt sl) {
  sl.registerLazySingleton<RecentlyViewedLocalDataSource>(
    () => SharedPreferencesRecentlyViewedLocalDataSource(),
  );
  sl.registerLazySingleton<RecentlyViewedRepository>(
    () => RecentlyViewedRepositoryImpl(sl<RecentlyViewedLocalDataSource>()),
  );
  sl.registerLazySingleton<RecentlyViewedCubit>(
    () => RecentlyViewedCubit(repository: sl<RecentlyViewedRepository>()),
  );
  sl.registerFactory(
    () => RecordRecentlyViewed(
      sl<RecentlyViewedRepository>(),
      sl<RecentlyViewedCubit>(),
    ),
  );
}
