import 'package:get_it/get_it.dart';

import '../../../core/services/supabase_service.dart';
import '../data/datasources/seller_analytics_remote_datasource.dart';
import '../data/datasources/supabase_seller_analytics_remote_datasource.dart';
import '../data/repositories/seller_analytics_repository_impl.dart';
import '../domain/repositories/seller_analytics_repository.dart';
import '../domain/usecases/get_seller_analytics.dart';
import '../domain/usecases/get_seller_demand.dart';
import '../domain/usecases/get_seller_engagement.dart';
import '../presentation/bloc/seller_analytics_cubit.dart';

void registerSellerAnalyticsFeature(GetIt sl) {
  sl.registerLazySingleton<SellerAnalyticsRemoteDataSource>(
    () => SupabaseSellerAnalyticsRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<SellerAnalyticsRepository>(
    () => SellerAnalyticsRepositoryImpl(sl<SellerAnalyticsRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetSellerAnalytics>(
    () => GetSellerAnalytics(sl<SellerAnalyticsRepository>()),
  );
  sl.registerLazySingleton<GetSellerEngagement>(
    () => GetSellerEngagement(sl<SellerAnalyticsRepository>()),
  );
  sl.registerLazySingleton<GetSellerDemand>(
    () => GetSellerDemand(sl<SellerAnalyticsRepository>()),
  );
  sl.registerFactory<SellerAnalyticsCubit>(
    () => SellerAnalyticsCubit(
      getSellerAnalytics: sl<GetSellerAnalytics>(),
      getSellerEngagement: sl<GetSellerEngagement>(),
      getSellerDemand: sl<GetSellerDemand>(),
    ),
  );
}
