import '../../../../core/errors/failures.dart';
import '../bloc/create_listing_state.dart';

/// Maps domain [Failure]s to localized UI buckets — no raw wire text surfaced.
CreateListingFailureKind createListingFailureKindFor(Failure failure) {
  if (failure is AuthFailure) {
    return CreateListingFailureKind.sessionExpired;
  }
  if (failure is NetworkFailure) {
    return CreateListingFailureKind.serviceUnavailable;
  }
  if (failure is ServerFailure) {
    return _kindForServerFailure(failure);
  }
  return CreateListingFailureKind.genericCreate;
}

CreateListingFailureKind _kindForServerFailure(ServerFailure f) {
  final code = (f.postgrestCode ?? '').trim();
  final codeUpper = code.toUpperCase();
  final blob = '${f.message}\n${f.diagnosticsDetails ?? ''}'.toLowerCase();

  // Server-side `raise exception 'invalid vin'` uses SQLSTATE 22023 — prefer a
  // dedicated bucket before generic 22023 validation mapping.
  if (blob.contains('invalid vin')) {
    return CreateListingFailureKind.invalidVin;
  }

  // Hosted Supabase: stale schema cache / missing new RPC signature.
  if (codeUpper == 'PGRST202' ||
      codeUpper == '42883' ||
      blob.contains('schema cache') ||
      blob.contains('could not find the function') ||
      blob.contains('could not find function') ||
      (blob.contains('function') && blob.contains('does not exist'))) {
    return CreateListingFailureKind.rpcSchemaNotReady;
  }

  // JWT / session loss — keep distinct from generic privilege errors.
  if (codeUpper.startsWith('PGRST30') ||
      codeUpper.contains('JWT') ||
      blob.contains('jwt expired') ||
      blob.contains('invalid jwt') ||
      blob.contains('not authenticated')) {
    return CreateListingFailureKind.sessionExpired;
  }

  if (codeUpper == '42501' || blob.contains('permission denied')) {
    return CreateListingFailureKind.permissionDenied;
  }

  if (blob.contains('23514') ||
      blob.contains('violates check constraint')) {
    return CreateListingFailureKind.checkConstraintViolation;
  }

  if (blob.contains('22023') ||
      blob.contains('p0001') ||
      blob.contains('is required')) {
    return CreateListingFailureKind.validationRejected;
  }

  return CreateListingFailureKind.genericCreate;
}
