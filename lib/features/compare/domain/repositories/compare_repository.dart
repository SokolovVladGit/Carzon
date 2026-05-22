import '../entities/compare_item.dart';

/// Local compare-set persistence (device-only, Phase 1).
abstract interface class CompareRepository {
  Future<List<CompareItem>> loadItems();

  Future<void> saveItems(List<CompareItem> items);

  Future<void> clear();
}
