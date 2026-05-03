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

  test('validation-related SQLSTATE hints map to validationRejected', () {
    expect(
      createListingFailureKindFor(
        ServerFailure('x', diagnosticsDetails: 'DETAIL : errcode = 22023'),
      ),
      CreateListingFailureKind.validationRejected,
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
