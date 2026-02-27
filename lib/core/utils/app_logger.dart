import 'package:logger/logger.dart';

/// Centralized logging utility for the app.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 5, // Number of method calls if stacktrace is provided
      lineLength: 80, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat: DateTimeFormat
          .dateAndTime, // Should each log print contain a timestamp
    ),
  );

  /// Log a message at level [Level.trace].
  static void t(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.debug].
  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.info].
  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.warning].
  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.error].
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a message at level [Level.fatal].
  static void f(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
