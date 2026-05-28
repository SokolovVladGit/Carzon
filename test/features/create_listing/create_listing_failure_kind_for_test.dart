import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/utils/create_listing_failure_kind_for.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps AuthFailure to sessionExpired', () {
    expect(
      createListingFailureKindFor(AuthFailure('x')),
      CreateListingFailureKind.sessionExpired,
    );
  });

  test('maps NetworkFailure to serviceUnavailable', () {
    expect(
      createListingFailureKindFor(NetworkFailure('x')),
      CreateListingFailureKind.serviceUnavailable,
    );
  });

  test('JWT-style PostgREST codes map to sessionExpired', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('x', postgrestCode: 'PGRST301'),
      ),
      CreateListingFailureKind.sessionExpired,
    );
  });

  test('invalid vin message maps to invalidVin before generic 22023', () {
    expect(
      createListingFailureKindFor(
        ServerFailure(
          'invalid vin',
          postgrestCode: '22023',
          diagnosticsDetails: 'SQLSTATE 22023',
        ),
      ),
      CreateListingFailureKind.invalidVin,
    );
  });

  test('PGRST202 maps to rpcSchemaNotReady', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('Could not find function', postgrestCode: 'PGRST202'),
      ),
      CreateListingFailureKind.rpcSchemaNotReady,
    );
  });

  test('SQLSTATE 42883 maps to rpcSchemaNotReady', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('undefined_function', postgrestCode: '42883'),
      ),
      CreateListingFailureKind.rpcSchemaNotReady,
    );
  });

  test('42501 maps to permissionDenied', () {
    expect(
      createListingFailureKindFor(
        ServerFailure(
          'permission denied for schema public',
          postgrestCode: '42501',
        ),
      ),
      CreateListingFailureKind.permissionDenied,
    );
  });

  test('check constraint violation maps to checkConstraintViolation', () {
    expect(
      createListingFailureKindFor(
        ServerFailure(
          'new row violates check constraint listings_vin_status_chk',
          diagnosticsDetails: 'Detail: Failing row contains',
        ),
      ),
      CreateListingFailureKind.checkConstraintViolation,
    );
  });

  test('23514 in diagnostics maps to checkConstraintViolation', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('check constraint', diagnosticsDetails: 'SQLSTATE 23514'),
      ),
      CreateListingFailureKind.checkConstraintViolation,
    );
  });

  test('validation-related SQLSTATE hints map to validationRejected', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('x', diagnosticsDetails: 'DETAIL : errcode = 22023'),
      ),
      CreateListingFailureKind.validationRejected,
    );
  });

  test('not authenticated maps to sessionExpired', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('JWT', diagnosticsDetails: 'not authenticated'),
      ),
      CreateListingFailureKind.sessionExpired,
    );
  });

  test('ambiguous ServerFailure maps to genericCreate', () {
    expect(
      createListingFailureKindFor(ServerFailure('db down')),
      CreateListingFailureKind.genericCreate,
    );
  });

  test('UnknownFailure maps to genericCreate', () {
    expect(
      createListingFailureKindFor(const UnknownFailure('boom')),
      CreateListingFailureKind.genericCreate,
    );
  });
}
