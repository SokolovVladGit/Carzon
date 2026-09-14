import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/listing_engagement_event_type.dart';
import '../../domain/entities/listing_engagement_record_result.dart';
import '../mappers/listing_engagement_mapper.dart';
import 'listing_engagement_remote_datasource.dart';

class SupabaseListingEngagementRemoteDataSource
    implements ListingEngagementRemoteDataSource {
  SupabaseListingEngagementRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String rpcRecord = 'record_listing_engagement_event';

  @override
  Future<ListingEngagementRecordResult> recordEvent({
    required String listingId,
    required ListingEngagementEventType eventType,
    required String anonymousViewerId,
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        rpcRecord,
        params: <String, dynamic>{
          'p_listing_id': listingId,
          'p_event_type': eventType.wireValue,
          'p_anonymous_viewer_id': anonymousViewerId,
        },
      );
      return listingEngagementRecordResultFromRow(
        listingEngagementRpcRow(data),
      );
    } on ServerException {
      rethrow;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to record listing engagement for $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
