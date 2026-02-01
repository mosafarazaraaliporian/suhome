import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

class NoxStyleHome extends StatefulWidget {
  const NoxStyleHome({super.key});

  @override
  State<NoxStyleHome> createState() => _NoxStyleHomeState();
}

class _NoxStyleHomeState extends State<NoxStyleHome> {
  int _addCount = 0;
  Uint8List? _wallpaperBytes;

  void _onAddPressed() {
    setState(() => _addCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('دکمه + زده شد! (${_addCount}x)'),
        behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background: custom image or cosmic gradient
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
          // Right toolbar - فقط دکمه + و والپیپر
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
          // دکمه +
          _ToolbarButton(
            icon: Icons.add,
            onPressed: _onAddPressed,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          // دکمه عوض کردن والپیپر
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
