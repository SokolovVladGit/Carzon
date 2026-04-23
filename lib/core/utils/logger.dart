import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Minimal logger wrapper. Replace internals with a real logger
/// (e.g. `logger` package) without changing call sites.
class AppLogger {
  AppLogger(this.tag);

  final String tag;

  void debug(String message) => _log('DEBUG', message);
  void info(String message) => _log('INFO', message);
  void warn(String message) => _log('WARN', message);
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode && level == 'DEBUG') return;
    developer.log(
      message,
      name: '$tag/$level',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
