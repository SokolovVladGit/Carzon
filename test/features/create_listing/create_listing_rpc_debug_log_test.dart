import 'package:carzon/features/create_listing/data/utils/create_listing_rpc_debug_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateListingRpcDebugLog.sanitizeWireText', () {
    test('passes through text without VIN-shaped tokens', () {
      expect(
        CreateListingRpcDebugLog.sanitizeWireText('invalid vin'),
        'invalid vin',
      );
    });

    test('redacts 17-char VIN-shaped tokens case-insensitively', () {
      expect(
        CreateListingRpcDebugLog.sanitizeWireText(
          'error detail 1hgbh41jxmn109186 trailing',
        ),
        'error detail <vin> trailing',
      );
    });

    test('does not redact short alphanumeric spans', () {
      expect(
        CreateListingRpcDebugLog.sanitizeWireText('short abc123456789012'),
        'short abc123456789012',
      );
    });
  });
}
