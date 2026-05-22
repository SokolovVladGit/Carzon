import '../../domain/entities/compare_item.dart';
import '../../domain/repositories/compare_repository.dart';
import '../datasources/compare_local_datasource.dart';

final class CompareRepositoryImpl implements CompareRepository {
  CompareRepositoryImpl(this._local);

  final CompareLocalDataSource _local;

  @override
  Future<List<CompareItem>> loadItems() => _local.loadItems();

  @override
  Future<void> saveItems(List<CompareItem> items) => _local.saveItems(items);

  @override
  Future<void> clear() => _local.clear();
}
