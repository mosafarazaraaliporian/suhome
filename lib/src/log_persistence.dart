import 'log_persistence_io.dart'
    if (dart.library.html) 'log_persistence_stub.dart' as impl;

Future<void> persistLog(String logLine) => impl.persistLog(logLine);
Future<String?> loadPersistedLogs() => impl.loadPersistedLogs();
