import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const SuhomeApp());
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

  String get faviconUrl {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
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

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final list = (jsonDecode(json) as List)
          .map((e) => ShortcutItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _shortcuts = list);
    }
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_shortcuts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  void _onAddPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddShortcutSheet(
        onSave: (item) {
          setState(() => _shortcuts.add(item));
          _saveShortcuts();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ذخیره شد'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _onWallpaperPressed() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _wallpaperBytes = result.files.single.bytes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('والپیپر عوض شد'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openUrl(String url) {
    Uri uri = Uri.tryParse(url) ?? Uri.parse('https://$url');
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WebViewPage(
          url: uri.toString(),
          title: uri.host,
        ),
      ),
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
                  left: 32, right: 80, top: 40, bottom: 40),
              child: _shortcuts.isEmpty
                  ? Center(
                      child: Text(
                        'روی + بزن و سایت اضافه کن',
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
                          },
                        );
                      },
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

  Widget _buildRightToolbar() {
    return Container(
      width: 56,
      margin: const EdgeInsets.only(top: 40, bottom: 40),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
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
            tooltip: 'عوض کردن والپیپر',
          ),
        ],
      ),
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
    }
  }

  void _save() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('آدرس سایت رو وارد کن'),
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
                  'سایت جدید',
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
              'ایکن (اختیاری - از فایل)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'اگر ایکون نزاری، فاویکون سایت خودش نمایش داده میشه',
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
                            'اضافه کن',
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
                label: const Text('حذف ایکون'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'آدرس سایت',
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
                label: const Text('ذخیره'),
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
    return Image.network(
      item.faviconUrl,
      fit: BoxFit.contain,
      width: 48,
      height: 48,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.link, color: Colors.blue.shade300, size: 32),
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

class _WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const _WebViewPage({required this.url, required this.title});

  @override
  State<_WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<_WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
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
