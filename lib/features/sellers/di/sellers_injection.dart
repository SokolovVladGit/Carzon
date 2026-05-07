import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/seller_avatar_remote_datasource.dart';
import '../data/datasources/sellers_remote_datasource.dart';
import '../data/repositories/sellers_repository_impl.dart';
import '../domain/repositories/sellers_repository.dart';
import '../domain/usecases/clear_seller_avatar.dart';
import '../domain/usecases/get_my_seller_profile.dart';
import '../domain/usecases/get_seller_public_profile.dart';
import '../domain/usecases/update_my_seller_display_name.dart';
import '../domain/usecases/upload_seller_avatar.dart';
import '../presentation/bloc/public_seller_identity_cubit.dart';

void registerSellersFeature(GetIt sl) {
  sl.registerLazySingleton<SellersRemoteDataSource>(
    () => SupabaseSellersRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<SellerAvatarRemoteDataSource>(
    () => SupabaseSellerAvatarRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<SellersRepository>(
    () => SellersRepositoryImpl(
      sl<SellersRemoteDataSource>(),
      sl<SellerAvatarRemoteDataSource>(),
    ),
  );
  sl.registerFactory(() => GetSellerPublicProfile(sl<SellersRepository>()));
  sl.registerFactory(() => GetMySellerProfile(sl<SellersRepository>()));
  sl.registerFactory(() => UpdateMySellerDisplayName(sl<SellersRepository>()));
  sl.registerFactory(() => UploadSellerAvatar(sl<SellersRepository>()));
  sl.registerFactory(() => ClearSellerAvatar(sl<SellersRepository>()));
  sl.registerFactory(
    () => PublicSellerIdentityCubit(
      getMySellerProfile: sl<GetMySellerProfile>(),
      updateMySellerDisplayName: sl<UpdateMySellerDisplayName>(),
      uploadSellerAvatar: sl<UploadSellerAvatar>(),
      clearSellerAvatar: sl<ClearSellerAvatar>(),
    ),
  );
}
