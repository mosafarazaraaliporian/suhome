import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_windows/webview_windows.dart';

import 'app_logger.dart';

final _logger = appLogger;

const _phoneWidth = 390.0;
const _phoneHeight = 844.0;

const _mobileUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

const _viewportScript = '''
(function() {
  function inject() {
    if (!document.head) { requestAnimationFrame(inject); return; }
    var v = document.querySelector('meta[name="viewport"]');
    if (!v) { v = document.createElement('meta'); v.name = 'viewport'; document.head.appendChild(v); }
    v.content = 'width=390, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
    var s = document.createElement('style');
    s.textContent = 'html,body{margin:0!important;padding:0!important;width:100%!important;height:100%!important;overflow-x:hidden!important}';
    document.head.appendChild(s);
    if (document.body) { document.body.style.margin = '0'; document.body.style.padding = '0'; }
    document.documentElement.style.margin = '0';
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', inject);
  else inject();
})();
''';

Widget buildPhoneWebView({
  required String url,
  required String title,
  required VoidCallback onBack,
}) {
  return _WindowsPhoneWebView(url: url, title: title, onBack: onBack);
}

class _WindowsPhoneWebView extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback onBack;

  const _WindowsPhoneWebView({
    required this.url,
    required this.title,
    required this.onBack,
  });

  @override
  State<_WindowsPhoneWebView> createState() => _WindowsPhoneWebViewState();
}

class _WindowsPhoneWebViewState extends State<_WindowsPhoneWebView> {
  final _controller = WebviewController();
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _initFailed = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _logger.d('WebView initState: ${widget.url}');
    _init();
  }

  Future<void> _init() async {
    try {
      _logger.d('WebView initialize()');
      await _controller.initialize();

      _logger.d('WebView setUserAgent');
      await _controller.setUserAgent(_mobileUserAgent);

      _logger.d('WebView addScriptToExecuteOnDocumentCreated');
      await _controller.addScriptToExecuteOnDocumentCreated(_viewportScript);

      await _controller.setBackgroundColor(const Color(0xFFFFFFFF));
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      _logger.d('WebView loadUrl: ${widget.url}');
      await _controller.loadUrl(widget.url);

      _subs.add(_controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted && mounted) {
          _controller.executeScript(_viewportScript).catchError((_) {});
        }
      }));

      if (mounted) setState(() {});
      _logger.d('WebView init done');
    } catch (e, st) {
      _logger.e('WebView init failed', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _initFailed = true;
          _errorMsg = e.toString();
        });
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
    if (_initFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Could not load in-app',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMsg!,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(widget.url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                      widget.onBack();
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open in browser'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
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
