import 'package:carzon/features/listings/data/local/anonymous_viewer_id_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'getOrCreate persists and reuses the same anonymous viewer id',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SharedPreferencesAnonymousViewerIdRepository();

      final first = await repo.getOrCreate();
      final second = await repo.getOrCreate();

      expect(first, isNotEmpty);
      expect(second, first);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          SharedPreferencesAnonymousViewerIdRepository.storageKey,
        ),
        first,
      );
    },
  );
}
