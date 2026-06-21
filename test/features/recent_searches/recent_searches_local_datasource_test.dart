import 'package:carzon/features/recent_searches/data/datasources/recent_searches_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesRecentSearchesLocalDataSource ds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRecentSearchesLocalDataSource.storageKey: '{not json',
    });
    ds = SharedPreferencesRecentSearchesLocalDataSource();
  });

  test('malformed JSON returns empty list', () async {
    expect(await ds.loadEntries(), isEmpty);
  });

  test('missing key returns empty list', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ds.loadEntries(), isEmpty);
  });

  test('clear removes storage key', () async {
    SharedPreferences.setMockInitialValues({});
    await ds.saveEntries(const []);
    await ds.clear();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(
        SharedPreferencesRecentSearchesLocalDataSource.storageKey,
      ),
      isFalse,
    );
  });
}
