import 'package:flutter/foundation.dart';

class AppLogger {
  static final AppLogger instance = AppLogger._();
  AppLogger._();

  final List<String> _buffer = [];
  static const int _maxBufferLines = 500;

  void info(String message, {bool noFile = false}) {
    _log('INFO', message);
  }

  void warn(String message, {bool noFile = false}) {
    _log('WARN', message);
  }

  void error(String message, {bool noFile = false}) {
    _log('ERROR', message);
  }

  void _log(String level, String message) {
    final String now = DateTime.now().toIso8601String().substring(0, 23);
    final String line = '[$now] [$level] $message';

    debugPrint(line);

    _buffer.add(line);
    while (_buffer.length > _maxBufferLines) {
      _buffer.removeAt(0);
    }
  }

  List<String> get recentLines => List<String>.unmodifiable(_buffer);

  String export() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('=== MathMate 调试日志 (Web) ===');
    sb.writeln('导出时间: ${DateTime.now().toIso8601String()}');
    sb.writeln();
    for (final String line in _buffer) {
      sb.writeln(line);
    }
    return sb.toString();
  }

  void clear() {
    _buffer.clear();
  }
}
