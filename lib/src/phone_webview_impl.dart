import 'package:flutter/material.dart';

import 'phone_webview_impl_windows.dart'
    if (dart.library.html) 'phone_webview_impl_web.dart' as impl;

Widget buildPhoneWebView({
  required String url,
  required String title,
  required VoidCallback onBack,
}) {
  return impl.buildPhoneWebView(
    url: url,
    title: title,
    onBack: onBack,
  );
}
