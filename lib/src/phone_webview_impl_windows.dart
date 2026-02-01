import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'app_logger.dart';

final _logger = appLogger;

const _phoneWidth = 390.0;
const _phoneHeight = 844.0;

const _mobileUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

/// Viewport + CSS injection - runs when DOM is ready (before page scripts)
const _viewportScript = '''
(function() {
  function inject() {
    if (!document.head) { requestAnimationFrame(inject); return; }
    var v = document.querySelector('meta[name="viewport"]');
    if (!v) { v = document.createElement('meta'); v.name = 'viewport'; document.head.appendChild(v); }
    v.content = 'width=390, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
    var s = document.createElement('style');
    s.textContent = 'html,body{margin:0!important;padding:0!important;width:100%!important;max-width:100vw!important;height:100%!important;min-height:100vh!important;overflow-x:hidden!important;box-sizing:border-box!important}html{overflow-x:hidden!important}body{min-width:0!important}*{box-sizing:border-box}';
    document.head.appendChild(s);
    if (document.body) {
      document.body.style.margin = '0';
      document.body.style.padding = '0';
    }
    document.documentElement.style.margin = '0';
    document.documentElement.style.padding = '0';
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', inject);
  } else {
    inject();
  }
})();
''';

Widget buildPhoneWebView({
  required String url,
  required String title,
  required bool useIsolatedStorage,
  required VoidCallback onBack,
  required void Function(bool isClone) onCloneOrOpen,
}) {
  return _WindowsPhoneWebView(
    url: url,
    title: title,
    useIsolatedStorage: useIsolatedStorage,
    onBack: onBack,
    onCloneOrOpen: onCloneOrOpen,
  );
}

class _WindowsPhoneWebView extends StatefulWidget {
  final String url;
  final String title;
  final bool useIsolatedStorage;
  final VoidCallback onBack;
  final void Function(bool isClone) onCloneOrOpen;

  const _WindowsPhoneWebView({
    required this.url,
    required this.title,
    required this.useIsolatedStorage,
    required this.onBack,
    required this.onCloneOrOpen,
  });

  @override
  State<_WindowsPhoneWebView> createState() => _WindowsPhoneWebViewState();
}

class _WindowsPhoneWebViewState extends State<_WindowsPhoneWebView> {
  final _controller = WebviewController();
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _logger.d('WebView initState, url: ${widget.url}');
    _init();
  }

  Future<void> _init() async {
    _logger.d('WebView _init starting for ${widget.url}');
    try {
      _logger.d('WebView calling initialize()');
      await _controller.initialize();
      _logger.d('WebView initialize() done');

      _logger.d('WebView setUserAgent');
      await _controller.setUserAgent(_mobileUserAgent);

      _logger.d('WebView addScriptToExecuteOnDocumentCreated');
      await _controller.addScriptToExecuteOnDocumentCreated(_viewportScript);

      _logger.d('WebView setBackgroundColor');
      await _controller.setBackgroundColor(const Color(0xFFFFFFFF));

      _logger.d('WebView setPopupWindowPolicy');
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      _logger.d('WebView loadUrl: ${widget.url}');
      await _controller.loadUrl(widget.url);
      _logger.d('WebView loadUrl returned');

      _subs.add(_controller.loadingState.listen((state) {
        _logger.d('WebView loadingState: $state');
        if (state == LoadingState.navigationCompleted && mounted) {
          _controller.executeScript(_viewportScript).catchError((e) {
            _logger.w('Post-load viewport inject: $e');
          });
        }
      }));

      if (mounted) setState(() {});
      _logger.d('WebView _init completed successfully');
    } catch (e, st) {
      _logger.e('WebView init failed', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
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
        child: Webview(
          _controller,
          width: _phoneWidth,
          height: _phoneHeight,
        ),
      ),
    );
  }
}
