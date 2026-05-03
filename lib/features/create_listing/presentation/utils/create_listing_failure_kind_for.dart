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
  final code = (f.postgrestCode ?? '').toUpperCase().trim();
  final blob = '${f.message}\n${f.diagnosticsDetails ?? ''}'.toLowerCase();

  if (code.startsWith('PGRST30') ||
      code == '42501' ||
      code.contains('JWT') ||
      blob.contains('not authenticated') ||
      blob.contains('jwt expired') ||
      blob.contains('invalid jwt')) {
    return CreateListingFailureKind.sessionExpired;
  }

  if (blob.contains('22023') ||
      blob.contains('p0001') ||
      blob.contains('violates check constraint') ||
      blob.contains('is required')) {
    return CreateListingFailureKind.validationRejected;
  }

  return CreateListingFailureKind.genericCreate;
}
