import '../../../listings/domain/validation/listing_vin.dart';

/// Decision for trailing `p_vin` on `update_listing_details_v2`.
///
/// Mirrors [EditListingPage] submit behavior — keep in sync when changing rules.
class EditListingVinRpcSubmission {
  const EditListingVinRpcSubmission({
    required this.submitVinParameterToRpc,
    this.vinParameter,
  });

  /// When false, `p_vin` must be omitted so the server preserves identity.
  final bool submitVinParameterToRpc;

  /// Interpreted only when [submitVinParameterToRpc] is true.
  /// Use `''` to clear VIN server-side.
  final String? vinParameter;
}

/// Resolves VIN RPC parameters from the raw edit field and owner preload state.
EditListingVinRpcSubmission resolveEditListingVinRpcSubmission({
  required String? rawVinFieldText,
  required String? ownerVinNormalizedForEdit,
  required bool ownerVinLookupFailed,
}) {
  final currentNorm = ListingVin.normalizeOptional(rawVinFieldText);
  final initial = ownerVinNormalizedForEdit;

  if (!ownerVinLookupFailed) {
    if (initial == null) {
      if (currentNorm == null) {
        return const EditListingVinRpcSubmission(
          submitVinParameterToRpc: false,
        );
      }
      return EditListingVinRpcSubmission(
        submitVinParameterToRpc: true,
        vinParameter: currentNorm,
      );
    }
    if (currentNorm == null) {
      return const EditListingVinRpcSubmission(
        submitVinParameterToRpc: true,
        vinParameter: '',
      );
    }
    if (currentNorm == initial) {
      return const EditListingVinRpcSubmission(submitVinParameterToRpc: false);
    }
    return EditListingVinRpcSubmission(
      submitVinParameterToRpc: true,
      vinParameter: currentNorm,
    );
  }

  if (currentNorm == null) {
    return const EditListingVinRpcSubmission(submitVinParameterToRpc: false);
  }
  return EditListingVinRpcSubmission(
    submitVinParameterToRpc: true,
    vinParameter: currentNorm,
  );
}
