import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';

/// Remote account privacy operations (Edge Function orchestration).
abstract interface class AccountPrivacyRemoteDataSource {
  Future<void> deleteOwnAccount();
}

class SupabaseAccountPrivacyRemoteDataSource
    implements AccountPrivacyRemoteDataSource {
  SupabaseAccountPrivacyRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const _deleteOwnAccountFunction = 'delete-own-account';

  @override
  Future<void> deleteOwnAccount() async {
    try {
      final response = await _supabase.client.functions.invoke(
        _deleteOwnAccountFunction,
      );
      final status = response.status;
      if (status < 200 || status >= 300) {
        throw ServerException(
          'Account deletion failed (HTTP $status).',
        );
      }
    } on sb.FunctionException catch (e, st) {
      throw ServerException(
        e.reasonPhrase ?? 'Account deletion failed.',
        cause: e,
        stackTrace: st,
      );
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException || e is AuthException) {
        rethrow;
      }
      throw ServerException(
        'Unexpected account deletion error',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
