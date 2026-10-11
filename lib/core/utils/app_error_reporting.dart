import 'package:flutter/foundation.dart';

import 'logger.dart';

/// Installs framework and platform error hooks.
///
/// Framework errors stay on [FlutterError.presentError] and are also written
/// once through [AppLogger]. Isolate errors that reach
/// [PlatformDispatcher.onError] are logged and marked handled so the embedder
/// does not print them again. They are a different channel from
/// [runZonedGuarded]: a zone-handled error does not also arrive here.
///
/// This is local diagnostics only. It does not upload stack traces.
void installAppErrorHandlers(AppLogger logger) {
  FlutterError.onError = (details) {
    try {
      FlutterError.presentError(details);
    } catch (_) {
      // Presentation must not block the diagnostic record.
    }
    String? context;
    try {
      context = _frameworkContext(details);
    } catch (_) {
      context = null;
    }
    reportUncaughtError(
      logger,
      'Flutter framework error',
      details.exception,
      details.stack,
      context: context,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reportUncaughtError(logger, 'Uncaught platform error', error, stack);
    return true;
  };
}

/// Zone callback used by bootstrap. Kept separate from the platform hook so
/// the same error is not recorded twice.
void reportZoneError(AppLogger logger, Object error, StackTrace stackTrace) {
  reportUncaughtError(logger, 'Uncaught zone error', error, stackTrace);
}

var _reporting = false;

void reportUncaughtError(
  AppLogger logger,
  String channel,
  Object error,
  StackTrace? stackTrace, {
  String? context,
}) {
  if (_reporting) return;
  _reporting = true;
  try {
    final where = context == null || context.isEmpty ? '' : ' ($context)';
    logger.error(
      '$channel$where: ${error.runtimeType}',
      _sanitizeDiagnostic(error.toString()),
      stackTrace,
    );
  } catch (_) {
    // A failing log call must not re-enter this hook.
  } finally {
    _reporting = false;
  }
}

String? _frameworkContext(FlutterErrorDetails details) {
  final library = details.library?.trim();
  final description = details.context?.toDescription().trim();
  final parts = <String>[
    if (library != null && library.isNotEmpty) library,
    if (description != null && description.isNotEmpty) description,
  ];
  if (parts.isEmpty) return null;
  return _sanitizeDiagnostic(parts.join(': '));
}

String _sanitizeDiagnostic(String raw) {
  var text = raw.replaceAll(
    RegExp(r'[a-z][a-z0-9+.-]*://\S+', caseSensitive: false),
    '[url]',
  );
  text = text.replaceAll(
    RegExp(
      r'\b(bearer|token|password|secret|authorization|api[_-]?key)\b\s*[:=]?\s*\S+',
      caseSensitive: false,
    ),
    '[redacted]',
  );
  text = text.replaceAll(RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b'), '[vin]');
  if (text.length > 400) {
    text = '${text.substring(0, 400)}…';
  }
  return text;
}
