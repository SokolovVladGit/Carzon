/// Stable anonymous viewer identity for listing view deduplication RPCs.
abstract interface class AnonymousViewerIdRepository {
  Future<String> getOrCreate();
}
