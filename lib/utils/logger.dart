import 'package:logger/logger.dart';

class AppLogger {
  // singleton instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // number of stack frames to show
      errorMethodCount: 8, // when logging errors
      lineLength: 80, // wraps long messages
      colors: true, // color-coded output
      printEmojis: true, // emojis for log levels
      printTime: true, // each line has a timestamp
    ),
  );

  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.v(message, error, stackTrace);
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.d(message, error, stackTrace);
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.i(message, error, stackTrace);
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error, stackTrace);
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error, stackTrace);
  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.wtf(message, error, stackTrace);
}
