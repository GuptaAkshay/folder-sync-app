import 'dart:developer' as developer;
import 'package:logging/logging.dart';

/// Centralized logging utility for the app.
class AppLogger {
  static final Logger _logger = Logger('FolderSyncLogger');
  static bool _initialized = false;

  /// Initializes the logging system. Must be called before any logs are emitted.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Print to standard console
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');

      // Also send structured data to Dart DevTools / system log
      developer.log(
        record.message,
        time: record.time,
        sequenceNumber: record.sequenceNumber,
        level: record.level.value,
        name: record.loggerName,
        zone: record.zone,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  /// Log a message at finest level (trace).
  static void t(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.finest(message, error, stackTrace);
  }

  /// Log a message at fine level (debug).
  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.fine(message, error, stackTrace);
  }

  /// Log a message at info level.
  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.info(message, error, stackTrace);
  }

  /// Log a message at warning level.
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.warning(message, error, stackTrace);
  }

  /// Log a message at severe level (error).
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.severe(message, error, stackTrace);
  }

  /// Log a message at shout level (fatal).
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.shout(message, error, stackTrace);
  }
}
