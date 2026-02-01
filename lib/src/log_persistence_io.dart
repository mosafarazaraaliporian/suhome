import 'dart:io';

import 'package:path_provider/path_provider.dart';

const _logFileName = 'suhome_logs.txt';
const _maxLogSize = 100000;

Future<void> persistLog(String logLine) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_logFileName');
    final content = '${DateTime.now().toIso8601String()} $logLine\n';
    file.writeAsStringSync(content, mode: FileMode.append, flush: true);
    final stat = file.statSync();
    if (stat.size > _maxLogSize) {
      final text = file.readAsStringSync();
      final lines = text.split('\n');
      final trimmed = lines.sublist(lines.length ~/ 2).join('\n');
      file.writeAsStringSync(trimmed, flush: true);
    }
  } catch (_) {}
}

Future<String?> loadPersistedLogs() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_logFileName');
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}
