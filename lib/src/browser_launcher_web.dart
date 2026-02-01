// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void openInPhoneSizedWindow(String url) {
  html.window.open(
    url,
    '_blank',
    'width=390,height=844,scrollbars=yes,resizable=yes',
  );
}
