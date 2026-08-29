import 'failures.dart';

/// Stable database rejection code emitted by the server-authoritative UGC
/// filter. Raw rejected content is deliberately absent from the error.
const String kContentRejectedCode = 'carzon_content_rejected';

bool isContentRejectedFailure(Failure failure) {
  if (failure is! ServerFailure) return false;
  return failure.message.toLowerCase().contains(kContentRejectedCode) ||
      (failure.diagnosticsDetails?.toLowerCase().contains(
            kContentRejectedCode,
          ) ??
          false);
}
