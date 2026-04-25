import 'package:get_it/get_it.dart';

/// Legal / Terms & Privacy is a static surface: it does not talk to
/// Supabase, has no cubit, and owns no state. The registration hook is
/// kept to stay consistent with the existing per-feature DI convention
/// (`registerXFeature(sl)`) and to provide a place for future legal-
/// related dependencies (e.g. a remote legal-versions datasource).
void registerLegalFeature(GetIt sl) {
  // Intentionally empty for the MVP legal stub.
}
