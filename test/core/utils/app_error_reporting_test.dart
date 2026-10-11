import 'dart:async';
import 'dart:ui';

import 'package:carzon/core/utils/app_error_reporting.dart';
import 'package:carzon/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingLogger extends AppLogger {
  _RecordingLogger() : super('test');

  final messages = <String>[];
  final errors = <Object?>[];
  final stacks = <StackTrace?>[];

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    messages.add(message);
    errors.add(error);
    stacks.add(stackTrace);
  }
}

void main() {
  late FlutterExceptionHandler? previousFlutter;
  late ErrorCallback? previousPlatform;
  late DebugPrintCallback previousDebugPrint;

  setUp(() {
    previousFlutter = FlutterError.onError;
    previousPlatform = PlatformDispatcher.instance.onError;
    previousDebugPrint = debugPrint;
  });

  tearDown(() {
    FlutterError.onError = previousFlutter;
    PlatformDispatcher.instance.onError = previousPlatform;
    debugPrint = previousDebugPrint;
  });

  test('framework errors are presented and logged once', () {
    final logger = _RecordingLogger();
    final printed = <String>[];
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    installAppErrorHandlers(logger);

    final stack = StackTrace.current;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('framework-boom'),
        stack: stack,
        library: 'carzon test',
        context: ErrorDescription('while painting the feed'),
      ),
    );

    expect(logger.messages, hasLength(1));
    expect(logger.messages.single, contains('Flutter framework error'));
    expect(logger.messages.single, contains('StateError'));
    expect(logger.messages.single, contains('carzon test'));
    expect(logger.messages.single, contains('while painting the feed'));
    expect(logger.errors.single, contains('framework-boom'));
    expect(logger.stacks.single, stack);
    expect(printed.join('\n'), contains('framework-boom'));
  });

  test('platform errors are logged with the stack and marked handled', () {
    final logger = _RecordingLogger();
    installAppErrorHandlers(logger);
    final stack = StackTrace.current;

    final handled = PlatformDispatcher.instance.onError!(
      StateError('platform-boom'),
      stack,
    );

    expect(handled, isTrue);
    expect(logger.messages, hasLength(1));
    expect(logger.messages.single, contains('Uncaught platform error'));
    expect(logger.messages.single, contains('StateError'));
    expect(logger.errors.single, contains('platform-boom'));
    expect(logger.stacks.single, stack);
  });

  test('diagnostic text drops urls, secrets, and VINs', () {
    final logger = _RecordingLogger();
    installAppErrorHandlers(logger);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError(
          'callback carzon://auth-callback?code=secret '
          'token=supersecret VIN 1HGBH41JXMN109186',
        ),
        stack: StackTrace.current,
      ),
    );

    final recorded = '${logger.messages.single} ${logger.errors.single}';
    expect(recorded, contains('[url]'));
    expect(recorded, contains('[redacted]'));
    expect(recorded, contains('[vin]'));
    expect(recorded, isNot(contains('code=secret')));
    expect(recorded, isNot(contains('supersecret')));
    expect(recorded, isNot(contains('1HGBH41JXMN109186')));
    expect(recorded, isNot(contains('carzon://')));
  });

  test('zone errors still reach the zone handler once', () async {
    final logger = _RecordingLogger();
    installAppErrorHandlers(logger);
    final caught = <Object>[];

    await runZonedGuarded(
      () async {
        Future<void>.error(StateError('zone-boom'));
        await Future<void>.delayed(Duration.zero);
      },
      (error, stackTrace) {
        caught.add(error);
        reportZoneError(logger, error, stackTrace);
      },
    );

    expect(caught, hasLength(1));
    expect(caught.single, isA<StateError>());
    expect(logger.messages, hasLength(1));
    expect(logger.messages.single, contains('Uncaught zone error'));
    expect(logger.stacks.single, isNotNull);
  });

  test('a logging failure does not recurse', () {
    final logger = _ThrowingLogger();
    installAppErrorHandlers(logger);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('log-fail'),
        stack: StackTrace.current,
      ),
    );

    expect(logger.calls, 1);
  });
}

class _ThrowingLogger extends AppLogger {
  _ThrowingLogger() : super('test');

  var calls = 0;

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    calls += 1;
    throw StateError('log failed');
  }
}
