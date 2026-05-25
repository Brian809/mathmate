import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final AppLogger instance = AppLogger._();
  AppLogger._();

  final List<String> _buffer = [];
  File? _logFile;
  bool _initialized = false;

  static const int _maxBufferLines = 500;
  static const int _maxFileBytes = 500 * 1024;

  Future<void> _init() async {
    if (_initialized) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/mathmate_debug.log');
      _initialized = true;
    } catch (e) {
      debugPrint('[AppLogger] 初始化失败: $e');
    }
  }

  void info(String message, {bool noFile = false}) {
    _log('INFO', message, noFile: noFile);
  }

  void warn(String message, {bool noFile = false}) {
    _log('WARN', message, noFile: noFile);
  }

  void error(String message, {bool noFile = false}) {
    _log('ERROR', message, noFile: noFile);
  }

  void _log(String level, String message, {bool noFile = false}) {
    final String now = DateTime.now().toIso8601String().substring(0, 23);
    final String line = '[$now] [$level] $message';

    debugPrint(line);

    _buffer.add(line);
    while (_buffer.length > _maxBufferLines) {
      _buffer.removeAt(0);
    }

    if (!noFile) {
      _writeToFile(line);
    }
  }

  void _writeToFile(String line) {
    if (_logFile == null) {
      if (_initialized) return;
      _init().then((_) {
        _appendLine(line);
      });
      return;
    }
    _appendLine(line);
  }

  void _appendLine(String line) {
    try {
      if (!_logFile!.existsSync()) {
        _logFile!.writeAsStringSync('=== MathMate 调试日志 ===\n');
      }
      _logFile!.writeAsStringSync('$line\n', mode: FileMode.append);
      _trimFileIfNeeded();
    } catch (_) {}
  }

  void _trimFileIfNeeded() {
    try {
      final int size = _logFile!.lengthSync();
      if (size > _maxFileBytes) {
        final String content = _logFile!.readAsStringSync();
        final int keepStart = content.length - (_maxFileBytes ~/ 2);
        final String trimmed = content.substring(keepStart > 0 ? keepStart : 0);
        final int newlineIdx = trimmed.indexOf('\n');
        _logFile!.writeAsStringSync(
          newlineIdx > 0 ? trimmed.substring(newlineIdx + 1) : trimmed,
        );
      }
    } catch (_) {}
  }

  List<String> get recentLines => List<String>.unmodifiable(_buffer);

  String export() {
    final StringBuffer sb = StringBuffer();
    sb.writeln('=== MathMate 调试日志 ===');
    sb.writeln('导出时间: ${DateTime.now().toIso8601String()}');
    sb.writeln();

    if (_logFile != null && _logFile!.existsSync()) {
      try {
        sb.write(_logFile!.readAsStringSync());
      } catch (_) {
        sb.writeln('(无法读取日志文件)');
      }
    }

    if (sb.length < 100) {
      for (final String line in _buffer) {
        sb.writeln(line);
      }
    }

    return sb.toString();
  }

  Future<void> clear() async {
    _buffer.clear();
    if (_logFile != null) {
      try {
        if (_logFile!.existsSync()) {
          await _logFile!.delete();
        }
      } catch (_) {}
    }
  }
}
