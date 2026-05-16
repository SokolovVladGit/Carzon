import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/log_redaction.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/new_listing_input.dart';
import '../../domain/repositories/create_listing_repository.dart';
import '../datasources/create_listing_remote_datasource.dart';
import '../utils/create_listing_rpc_debug_log.dart';

class CreateListingRepositoryImpl implements CreateListingRepository {
  CreateListingRepositoryImpl(this._remote)
    : _logger = AppLogger('CreateListingRepository');

  final CreateListingRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<Listing>> create(NewListingInput input) async {
    try {
      final listing = await _remote.insert(input);
      return Success(listing);
    } on ServerException catch (e) {
      _logger.debug(
        'create_listing_rpc server error '
        'code=${e.postgrestCode ?? '-'} '
        'details=${redactLikelyDigitsInLogs(e.diagnosticsDetails ?? '-')} '
        'message=${redactLikelyDigitsInLogs(e.message)}',
      );
      return FailureResult(
        ServerFailure(
          e.message,
          postgrestCode: e.postgrestCode,
          diagnosticsDetails: e.diagnosticsDetails,
        ),
      );
    } catch (e, st) {
      _logger.error('create unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to create listing.'));
    }
  }

  @override
  Future<Result<Listing>> createV2(NewListingInput input) async {
    if (!isUploadedListingGalleryWithinLimit(input.uploadedGallery)) {
      _logger.debug(
        'create_listing_v2 rejected: gallery exceeds allowed count',
      );
      return const FailureResult(UnknownFailure('Failed to create listing.'));
    }
    try {
      final listing = await _remote.insertV2(input);
      return Success(listing);
    } on ServerException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CreateListing][repository:createV2] mapped ServerFailure '
          'code=${e.postgrestCode ?? '-'}',
        );
      }
      _logger.debug(
        'create_listing_v2 server error '
        'code=${e.postgrestCode ?? '-'} '
        'details=${redactLikelyDigitsInLogs(CreateListingRpcDebugLog.sanitizeWireText(e.diagnosticsDetails ?? '-'))} '
        'message=${redactLikelyDigitsInLogs(CreateListingRpcDebugLog.sanitizeWireText(e.message))}',
      );
      return FailureResult(
        ServerFailure(
          e.message,
          postgrestCode: e.postgrestCode,
          diagnosticsDetails: e.diagnosticsDetails,
        ),
      );
    } catch (e, st) {
      _logger.error('createV2 unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to create listing.'));
    }
  }
}
