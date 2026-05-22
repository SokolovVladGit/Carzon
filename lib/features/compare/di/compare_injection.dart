import 'package:get_it/get_it.dart';

import '../../listings/domain/usecases/get_listing_by_id.dart';
import '../../listings/domain/usecases/get_listing_images.dart';
import '../data/datasources/compare_local_datasource.dart';
import '../data/repositories/compare_repository_impl.dart';
import '../domain/repositories/compare_repository.dart';
import '../presentation/cubit/compare_cubit.dart';
import '../presentation/cubit/compare_page_cubit.dart';
import '../presentation/widgets/compare_fly_to_tray_controller.dart';
import '../presentation/widgets/compare_tray_feedback_controller.dart';

void registerCompareFeature(GetIt sl) {
  sl.registerLazySingleton<CompareLocalDataSource>(
    () => SharedPreferencesCompareLocalDataSource(),
  );
  sl.registerLazySingleton<CompareRepository>(
    () => CompareRepositoryImpl(sl<CompareLocalDataSource>()),
  );
  sl.registerLazySingleton<CompareCubit>(
    () => CompareCubit(repository: sl<CompareRepository>()),
  );
  sl.registerFactory<ComparePageCubit>(
    () => ComparePageCubit(
      getListingById: sl<GetListingById>(),
      getListingImages: sl<GetListingImages>(),
    ),
  );
  sl.registerLazySingleton<CompareFlyToTrayController>(
    CompareFlyToTrayController.new,
  );
  sl.registerLazySingleton<CompareTrayFeedbackController>(
    CompareTrayFeedbackController.new,
  );
}
