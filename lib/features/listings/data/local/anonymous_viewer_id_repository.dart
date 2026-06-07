import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/anonymous_viewer_id_repository.dart';

final class SharedPreferencesAnonymousViewerIdRepository
    implements AnonymousViewerIdRepository {
  static const String storageKey = 'carzon.analytics_viewer_id';

  @override
  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(storageKey)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = _generateViewerId();
    await prefs.setString(storageKey, id);
    return id;
  }
}

String _generateViewerId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
      '${hex(bytes[4])}${hex(bytes[5])}-'
      '${hex(bytes[6])}${hex(bytes[7])}-'
      '${hex(bytes[8])}${hex(bytes[9])}-'
      '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}'
      '${hex(bytes[14])}${hex(bytes[15])}';
}
