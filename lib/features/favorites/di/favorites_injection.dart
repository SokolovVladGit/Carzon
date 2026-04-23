import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/favorites_remote_datasource.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/usecases/add_favorite.dart';
import '../domain/usecases/get_favorite_ids.dart';
import '../domain/usecases/get_favorite_listings.dart';
import '../domain/usecases/remove_favorite.dart';
import '../presentation/bloc/favorites_cubit.dart';

void registerFavoritesFeature(GetIt sl) {
  sl.registerLazySingleton<FavoritesRemoteDataSource>(
    () => SupabaseFavoritesRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl<FavoritesRemoteDataSource>()),
  );
  sl.registerFactory(() => GetFavoriteIds(sl<FavoritesRepository>()));
  sl.registerFactory(() => GetFavoriteListings(sl<FavoritesRepository>()));
  sl.registerFactory(() => AddFavorite(sl<FavoritesRepository>()));
  sl.registerFactory(() => RemoveFavorite(sl<FavoritesRepository>()));

  // Global session-scoped cubit. Single instance shared by feed, details,
  // favorites page, and the toggle widget.
  sl.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(
      getFavoriteIds: sl<GetFavoriteIds>(),
      getFavoriteListings: sl<GetFavoriteListings>(),
      addFavorite: sl<AddFavorite>(),
      removeFavorite: sl<RemoveFavorite>(),
    ),
  );
}
