/// Implementation of phone-sized WebView.
/// Windows: webview_windows (full control)
/// Web: iframe (in-app, limited control)
library;

import 'package:flutter/material.dart';

import 'phone_webview_impl_windows.dart'
    if (dart.library.html) 'phone_webview_impl_web.dart' as impl;

/// Phone-sized browser content - platform-specific implementation
Widget buildPhoneWebView({
  required String url,
  required String title,
  required bool useIsolatedStorage,
  required VoidCallback onBack,
  required void Function(bool isClone) onCloneOrOpen,
}) {
  return impl.buildPhoneWebView(
    url: url,
    title: title,
    useIsolatedStorage: useIsolatedStorage,
    onBack: onBack,
    onCloneOrOpen: onCloneOrOpen,
  );
}
