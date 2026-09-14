import 'package:get_it/get_it.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/services/supabase_service.dart';
import '../../listings/domain/repositories/anonymous_viewer_id_repository.dart';
import '../data/datasources/listing_engagement_remote_datasource.dart';
import '../data/datasources/supabase_listing_engagement_remote_datasource.dart';
import '../data/repositories/listing_engagement_repository_impl.dart';
import '../domain/repositories/listing_engagement_repository.dart';
import '../domain/usecases/record_listing_engagement.dart';
import '../presentation/listing_impression_session_guard.dart';

void registerListingEngagementFeature(GetIt sl) {
  VisibilityDetectorController.instance.updateInterval = const Duration(
    milliseconds: 100,
  );
  sl.registerLazySingleton<ListingEngagementRemoteDataSource>(
    () => SupabaseListingEngagementRemoteDataSource(sl<SupabaseService>()),
  );
  sl.registerLazySingleton<ListingEngagementRepository>(
    () => ListingEngagementRepositoryImpl(
      sl<ListingEngagementRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ListingImpressionSessionGuard>(
    ListingImpressionSessionGuard.new,
  );
  sl.registerLazySingleton<RecordListingEngagement>(
    () => RecordListingEngagement(
      sl<ListingEngagementRepository>(),
      sl<AnonymousViewerIdRepository>(),
    ),
  );
}
