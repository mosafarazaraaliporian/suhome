import 'dart:io';

import 'package:path_provider/path_provider.dart';

const _logFileName = 'suhome_logs.txt';
const _maxLogSize = 100000;

Future<void> persistLog(String logLine) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_logFileName');
    final content = '${DateTime.now().toIso8601String()} $logLine\n';
    await file.writeAsString(content, mode: FileMode.append);
    final stat = await file.stat();
    if (stat.size > _maxLogSize) {
      final text = await file.readAsString();
      final lines = text.split('\n');
      final trimmed = lines.sublist(lines.length ~/ 2).join('\n');
      await file.writeAsString(trimmed);
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
