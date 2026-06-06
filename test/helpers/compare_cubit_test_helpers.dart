import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';

/// In-memory [CompareRepository] for widget tests.
///
/// Deterministic and side-effect free: no SharedPreferences, no platform
/// channels, always starts from an empty compare set. Mirrors the throwaway
/// repository several listing tests previously duplicated inline.
class InMemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> items) async {}
}

/// Builds a lightweight real [CompareCubit] backed by
/// [InMemoryCompareRepository].
///
/// The real cubit is safe to instantiate in widget tests; the caller owns
/// the lifecycle and should `close()` it in `tearDown`.
CompareCubit newInMemoryCompareCubit() =>
    CompareCubit(repository: InMemoryCompareRepository());
