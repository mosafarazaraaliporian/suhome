// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openInPhoneSizedWindow(String url, {bool isolated = false}) {
  final features = 'width=390,height=844,scrollbars=yes,resizable=yes';
  // isolated: هر بار پنجره جدید. مشترک: ممکنه همون پنجره رو استفاده کنه
  final name = isolated ? 'suhome_${DateTime.now().millisecondsSinceEpoch}' : 'suhome_shared';
  html.window.open(url, name, features);
}
