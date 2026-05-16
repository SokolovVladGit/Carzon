/// Applies optional `p_vin` for `create_listing_v2` RPC params.
///
/// When [vin] is null, the key is omitted (server default / no identity row).
void applyOptionalVinToCreateListingV2Params(
  Map<String, dynamic> params,
  String? vin,
) {
  if (vin != null) {
    params['p_vin'] = vin;
  }
}
