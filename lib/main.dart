import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'src/app_logger.dart';
import 'src/log_persistence.dart';

final _logger = appLogger;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    _logger.e('FlutterError', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  runZonedGuarded(() {
    _logger.i('Suhome app starting');
    runApp(const SuhomeApp());
  }, (error, stackTrace) {
    _logger.e('Uncaught error', error: error, stackTrace: stackTrace);
  });
}

class SuhomeApp extends StatelessWidget {
  const SuhomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suhome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      home: const NoxStyleHome(),
    );
  }
}

class ShortcutItem {
  final String? iconBase64;
  final String url;

  ShortcutItem({this.iconBase64, required this.url});

  Uint8List? get iconBytes =>
      iconBase64 != null ? base64Decode(iconBase64!) : null;

  /// DuckDuckGo favicon - CORS-friendly for web
  String get faviconUrl {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return 'https://icons.duckduckgo.com/ip3/${uri.host}.ico';
    } catch (e) {
      _logger.w('Favicon URL parse error: $e');
      return '';
    }
  }

  Map<String, dynamic> toJson() => {
        if (iconBase64 != null) 'icon': iconBase64,
        'url': url,
      };

  factory ShortcutItem.fromJson(Map<String, dynamic> json) => ShortcutItem(
        iconBase64: json['icon'] as String?,
        url: json['url'] as String? ?? '',
      );
}

class NoxStyleHome extends StatefulWidget {
  const NoxStyleHome({super.key});

  @override
  State<NoxStyleHome> createState() => _NoxStyleHomeState();
}

class _NoxStyleHomeState extends State<NoxStyleHome> {
  Uint8List? _wallpaperBytes;
  List<ShortcutItem> _shortcuts = [];
  static const _storageKey = 'suhome_shortcuts';
  DateTime _now = DateTime.now();
  Timer? _timer;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShortcuts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = (jsonDecode(json) as List)
            .map((e) => ShortcutItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _shortcuts = list);
        _logger.i('Loaded ${list.length} shortcuts');
      }
    } catch (e) {
      _logger.e('Load shortcuts failed', error: e);
    }
  }

  Future<void> _saveShortcuts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_shortcuts.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, json);
      _logger.d('Saved ${_shortcuts.length} shortcuts');
    } catch (e) {
      _logger.e('Save shortcuts failed', error: e);
    }
  }

  void _onAddPressed() {
    _logger.d('Add shortcut pressed');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddShortcutSheet(
        onSave: (item) {
          setState(() => _shortcuts.add(item));
          _saveShortcuts();
          Navigator.pop(context);
          _logger.i('Shortcut saved: ${item.url}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _onWallpaperPressed() async {
    _logger.d('Wallpaper picker opened');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _wallpaperBytes = result.files.single.bytes;
      });
      if (mounted) {
        _logger.i('Wallpaper changed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallpaper changed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    _logger.d('_openUrl START url=$url');
    try {
      Uri uri = Uri.tryParse(url) ?? Uri.parse('https://$url');
      if (!uri.hasScheme) {
        uri = Uri.parse('https://$url');
      }
      _logger.d('_openUrl launching: ${uri.toString()}');

      if (await canLaunchUrl(uri)) {
        _logger.d('_openUrl canLaunch=true, calling launchUrl inAppWebView');
        final ok = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(),
        );
        _logger.d('_openUrl launchUrl result=$ok');
        if (!ok && mounted) {
          _logger.w('_openUrl inAppWebView failed, trying external');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        _logger.w('_openUrl canLaunch=false for $uri');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: $uri')),
          );
        }
      }
    } catch (e, st) {
      _logger.e('_openUrl FAILED', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final uri = Uri.tryParse(q);
    final isUrl = uri != null && (uri.hasScheme || q.contains('.'));
    final url = isUrl
        ? (uri.hasScheme ? uri.toString() : 'https://$q')
        : 'https://www.google.com/search?q=${Uri.encodeComponent(q)}';
    _openUrl(url);
    _searchController.clear();
  }

  Widget _buildHeader() {
    final j = Jalali.fromDateTime(_now);
    final weekday = j.formatter.wN;
    final dateStr = j.formatter.d;
    final monthStr = j.formatter.mN;
    final yearStr = j.formatter.y;
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$weekday $dateStr $monthStr $yearStr',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.access_time_rounded,
                color: Colors.white.withValues(alpha: 0.15),
                size: 56,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search or enter URL...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 24,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.blue.shade300,
                  size: 22,
                ),
                onPressed: () => _onSearch(_searchController.text),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearch,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_wallpaperBytes != null)
            Positioned.fill(
              child: Image.memory(
                _wallpaperBytes!,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0C29),
                    Color(0xFF302B63),
                    Color(0xFF24243E),
                    Color(0xFF1A1A2E),
                  ],
                ),
              ),
            ),
          if (_wallpaperBytes == null)
            CustomPaint(
              painter: _CosmicPainter(),
              size: Size.infinite,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 32, right: 80, top: 24, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _shortcuts.isEmpty
                        ? Center(
                            child: Text(
                              'Tap + to add a website',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _shortcuts.length,
                      itemBuilder: (context, index) {
                        final item = _shortcuts[index];
                        return _ShortcutCard(
                          item: item,
                          onTap: () => _openUrl(item.url),
                          onLongPress: () {
                            setState(() => _shortcuts.removeAt(index));
                            _saveShortcuts();
                            _logger.d('Shortcut removed: ${item.url}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildRightToolbar(),
          ),
        ],
      ),
    );
  }

  void _showLogViewer() {
    _logger.d('Opening log viewer');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogViewerSheet(),
    );
  }

  Widget _buildRightToolbar() {
    return Container(
      width: 56,
      margin: const EdgeInsets.only(top: 40, bottom: 40, right: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ToolbarButton(
            icon: Icons.add,
            onPressed: _onAddPressed,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          _ToolbarButton(
            icon: Icons.wallpaper,
            onPressed: _onWallpaperPressed,
            tooltip: 'Change wallpaper',
          ),
          const SizedBox(height: 16),
          _ToolbarButton(
            icon: Icons.bug_report,
            onPressed: _showLogViewer,
            tooltip: 'View logs',
          ),
        ],
      ),
    );
  }
}

class _LogViewerSheet extends StatefulWidget {
  @override
  State<_LogViewerSheet> createState() => _LogViewerSheetState();
}

class _LogViewerSheetState extends State<_LogViewerSheet> {
  String _persistedLogs = '';

  @override
  void initState() {
    super.initState();
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final persisted = await loadPersistedLogs();
    if (mounted) {
      setState(() => _persistedLogs = persisted ?? '');
    }
  }

  String get _allLogs {
    final current = AppLogCollector.instance.allLogs;
    if (_persistedLogs.isEmpty) return current;
    return '--- Previous run ---\n$_persistedLogs\n\n--- Current run ---\n$current';
  }

  @override
  Widget build(BuildContext context) {
    final logs = _allLogs;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          tooltip: 'Copy logs',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: logs),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logs copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    logs.isEmpty ? '(no logs yet)' : logs,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddShortcutSheet extends StatefulWidget {
  final void Function(ShortcutItem) onSave;

  const _AddShortcutSheet({required this.onSave});

  @override
  State<_AddShortcutSheet> createState() => _AddShortcutSheetState();
}

class _AddShortcutSheetState extends State<_AddShortcutSheet> {
  Uint8List? _customIconBytes;
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() => _customIconBytes = result.files.single.bytes);
      _logger.d('Custom icon selected');
    }
  }

  void _save() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _logger.w('Save attempted with empty URL');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the website URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onSave(ShortcutItem(
      iconBase64: _customIconBytes != null
          ? base64Encode(_customIconBytes!)
          : null,
      url: url,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.blue.shade400, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'New website',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Icon (optional - from file)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'If you don\'t add an icon, the site favicon will be shown',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickIcon,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: _customIconBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _customIconBytes!,
                          fit: BoxFit.cover,
                          width: 76,
                          height: 76,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_customIconBytes != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _customIconBytes = null),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove icon'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Website URL',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://example.com',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.link,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 22),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final ShortcutItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ShortcutCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName(item.url);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.iconBytes != null
                ? Image.memory(
                    item.iconBytes!,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFaviconFallback(),
                  )
                : _buildFaviconFallback(),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFaviconFallback() {
    if (item.faviconUrl.isEmpty) {
      return Icon(Icons.link, color: Colors.blue.shade300, size: 32);
    }
    // On web, Image.network for favicon can hit CORS - use link icon
    if (kIsWeb) {
      return Icon(Icons.link, color: Colors.blue.shade300, size: 32);
    }
    return Image.network(
      item.faviconUrl,
      fit: BoxFit.contain,
      width: 48,
      height: 48,
      errorBuilder: (context, error, stackTrace) {
        _logger.d('Favicon load failed for ${item.url}: $error');
        return Icon(Icons.link, color: Colors.blue.shade300, size: 32);
      },
    );
  }

  String _getDisplayName(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url.length > 15 ? '${url.substring(0, 15)}...' : url;
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final String? tooltip;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                  ],
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isPrimary ? 28 : 24,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: child,
      );
    }
    return child;
  }
}

class _CosmicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final random = _SeededRandom(42);
    for (var i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 1.0 + random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
