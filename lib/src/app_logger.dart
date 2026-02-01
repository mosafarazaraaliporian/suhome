import 'package:logger/logger.dart';

import 'log_persistence.dart';

/// Global log collector - stores all logs for debugging
class AppLogCollector {
  AppLogCollector._();
  static final AppLogCollector _instance = AppLogCollector._();
  static AppLogCollector get instance => _instance;

  final List<_LogEntry> _entries = [];
  static const _maxEntries = 2000;

  void add(Level level, String message, [Object? error, StackTrace? stackTrace]) {
    final entry = _LogEntry(
      DateTime.now(),
      level,
      message,
      error?.toString(),
      stackTrace?.toString(),
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    persistLog(entry.format().replaceAll('\n', ' | '));
  }

  String get allLogs {
    return _entries.map((e) => e.format()).join('\n');
  }

  List<String> get entries => _entries.map((e) => e.format()).toList();

  void clear() {
    _entries.clear();
  }
}

class _LogEntry {
  final DateTime time;
  final Level level;
  final String message;
  final String? error;
  final String? stackTrace;

  _LogEntry(this.time, this.level, this.message, this.error, this.stackTrace);

  String format() {
    final levelStr = level.name.toUpperCase().padRight(5);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${(time.millisecond ~/ 100)}';
    var out = '[$timeStr] $levelStr $message';
    if (error != null) out += '\n  Error: $error';
    if (stackTrace != null) out += '\n  $stackTrace';
    return out;
  }
}

/// Custom output that writes to AppLogCollector
class _CollectorOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final msg = event.lines.join(' ');
    AppLogCollector.instance.add(
      event.level,
      msg,
      event.origin.error,
      event.origin.stackTrace,
    );
  }
}

/// App logger - logs to console AND collector
Logger createAppLogger() {
  return Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true),
    output: MultiOutput([
      ConsoleOutput(),
      _CollectorOutput(),
    ]),
  );
}

/// Global app logger instance
final appLogger = createAppLogger();
