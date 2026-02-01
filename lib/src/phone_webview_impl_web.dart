// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const _phoneWidth = 390.0;
const _phoneHeight = 844.0;

/// Web: iframe in-app (limited control due to cross-origin)
Widget buildPhoneWebView({
  required String url,
  required String title,
  required bool useIsolatedStorage,
  required VoidCallback onBack,
  required void Function(bool isClone) onCloneOrOpen,
}) {
  return _WebPhoneWebView(
    url: url,
    title: title,
    onBack: onBack,
    onCloneOrOpen: onCloneOrOpen,
  );
}

class _WebPhoneWebView extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback onBack;
  final void Function(bool isClone) onCloneOrOpen;

  const _WebPhoneWebView({
    required this.url,
    required this.title,
    required this.onBack,
    required this.onCloneOrOpen,
  });

  @override
  State<_WebPhoneWebView> createState() => _WebPhoneWebViewState();
}

class _WebPhoneWebViewState extends State<_WebPhoneWebView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'suhome-iframe-${DateTime.now().millisecondsSinceEpoch}';
    _registerIframe();
  }

  void _registerIframe() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..attributes['sandbox'] =
              'allow-scripts allow-same-origin allow-forms allow-popups';
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _phoneWidth,
        height: _phoneHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
