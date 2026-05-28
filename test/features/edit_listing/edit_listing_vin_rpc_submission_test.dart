import 'package:carzon/features/edit_listing/domain/utils/edit_listing_vin_rpc_submission.dart';
import 'package:carzon/features/listings/domain/validation/listing_vin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validVin = '1HGBH41JXMN109186';

  group('resolveEditListingVinRpcSubmission', () {
    test('A: preload succeeded + field unchanged omits p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: validVin,
        ownerVinNormalizedForEdit: validVin,
        ownerVinLookupFailed: false,
      );
      expect(d.submitVinParameterToRpc, isFalse);
      expect(d.vinParameter, isNull);
    });

    test('B: preload succeeded + field cleared sends empty p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: '',
        ownerVinNormalizedForEdit: validVin,
        ownerVinLookupFailed: false,
      );
      expect(d.submitVinParameterToRpc, isTrue);
      expect(d.vinParameter, '');
    });

    test('C: preload failed + empty field omits p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: '  \n',
        ownerVinNormalizedForEdit: null,
        ownerVinLookupFailed: true,
      );
      expect(d.submitVinParameterToRpc, isFalse);
      expect(d.vinParameter, isNull);
    });

    test('D: preload failed + valid messy VIN sends normalized p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: '  1hgbh41-jx mn109186  ',
        ownerVinNormalizedForEdit: null,
        ownerVinLookupFailed: true,
      );
      expect(d.submitVinParameterToRpc, isTrue);
      expect(d.vinParameter, validVin);
    });

    test('preload succeeded + no prior VIN + empty field omits p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: '',
        ownerVinNormalizedForEdit: null,
        ownerVinLookupFailed: false,
      );
      expect(d.submitVinParameterToRpc, isFalse);
    });

    test('preload succeeded + no prior VIN + new VIN sends p_vin', () {
      final d = resolveEditListingVinRpcSubmission(
        rawVinFieldText: validVin,
        ownerVinNormalizedForEdit: null,
        ownerVinLookupFailed: false,
      );
      expect(d.submitVinParameterToRpc, isTrue);
      expect(d.vinParameter, validVin);
    });

    test(
      'preload succeeded + VIN changed to different valid value sends update',
      () {
        const other = '5YJSA1E14HF123456';
        final d = resolveEditListingVinRpcSubmission(
          rawVinFieldText: other,
          ownerVinNormalizedForEdit: validVin,
          ownerVinLookupFailed: false,
        );
        expect(d.submitVinParameterToRpc, isTrue);
        expect(d.vinParameter, other);
      },
    );
  });

  group('edit listing invalid-VIN gate (mirrors edit_listing_page)', () {
    test('non-empty invalid VIN fails isOptionalInputValid before submit', () {
      expect(ListingVin.isOptionalInputValid('1HGBH41JXON109186'), isFalse);
    });
  });
}
