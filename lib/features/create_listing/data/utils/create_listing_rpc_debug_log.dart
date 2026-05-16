import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Debug-only helpers for `create_listing_v2` diagnostics.
///
/// Never prints full VIN values — strips 17-character VIN-shaped tokens from
/// wire blobs before [debugPrint].
class CreateListingRpcDebugLog {
  CreateListingRpcDebugLog._();

  static final RegExp _vinLike17 = RegExp(
    r'\b[A-HJ-NPR-Z0-9]{17}\b',
    caseSensitive: false,
  );

  /// Removes VIN-shaped tokens so PostgREST `message` / `details` lines stay safe.
  static String sanitizeWireText(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll(_vinLike17, '<vin>');
  }

  /// Logs a failed `create_listing_v2` RPC — [kDebugMode] only.
  static void logCreateListingV2RpcFailure({
    required sb.PostgrestException exception,
    required List<String> sortedParamKeys,
    required bool vinProvided,
    required int? vinLength,
  }) {
    if (!kDebugMode) return;
    final code = exception.code ?? '';
    final msg = sanitizeWireText(exception.message);
    final details = sanitizeWireText(exception.details?.toString());
    final hint = sanitizeWireText(exception.hint);
    debugPrint(
      '[CreateListing][RPC:create_listing_v2] failed '
      'code=$code message=$msg details=$details hint=$hint '
      'argsKeys=${sortedParamKeys.join(',')} '
      'vinProvided=$vinProvided vinLength=$vinLength',
    );
  }
}
