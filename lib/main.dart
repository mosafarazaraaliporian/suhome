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

  void _onAddPressed() {
    setState(() => _addCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('دکمه + زده شد! (${_addCount}x)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cosmic wallpaper gradient
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
          // Subtle star-like overlay
          CustomPaint(
            painter: _CosmicPainter(),
            size: Size.infinite,
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),
                const SizedBox(height: 16),
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 24),
                // App grid
                Expanded(child: _buildAppGrid()),
                const SizedBox(height: 8),
                // Page indicator
                _buildPageIndicator(),
                const SizedBox(height: 12),
                // Bottom dock
                _buildDock(),
              ],
            ),
          ),
          // Right toolbar
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400, size: 20),
          const SizedBox(width: 8),
          Text(
            'SUHOME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.play_circle_outline, color: Colors.white54, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search Game, App...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
            Icon(Icons.search, color: Colors.white54, size: 22),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAppGrid() {
    final apps = [
      _AppItem('Browser', Icons.explore, Colors.blue),
      _AppItem('Google', Icons.folder, Colors.grey),
      _AppItem('People', Icons.person, Colors.lightBlue),
      _AppItem('Camera', Icons.camera_alt, Colors.grey),
      _AppItem('Help', Icons.help_outline, Colors.teal),
      _AppItem('ES File', Icons.folder_open, Colors.blue),
      _AppItem('Lite', Icons.facebook, Colors.blue.shade700),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return _AppIcon(
            label: app.label,
            icon: app.icon,
            color: app.color,
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildDock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DockIcon(Icons.folder, 'File Manager', Colors.amber),
          _DockIcon(Icons.download, 'Downloads', Colors.green),
          // دکمه + بزرگ در وسط
          _AddButton(onPressed: _onAddPressed),
          _DockIcon(Icons.gamepad, 'Game', Colors.purple),
          _DockIcon(Icons.photo_library, 'Gallery', Colors.green.shade300),
          _DockIcon(Icons.settings, 'Settings', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRightToolbar() {
    final icons = [
      Icons.more_vert,
      Icons.phone_android,
      Icons.keyboard,
      Icons.content_cut,
      Icons.location_on,
      Icons.apps,
      Icons.fullscreen,
      Icons.volume_up,
      Icons.volume_down,
      Icons.install_mobile,
      Icons.arrow_back,
      Icons.home,
      Icons.recent_actors,
    ];

    return Container(
      width: 48,
      margin: const EdgeInsets.only(top: 60, bottom: 100),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: icons
            .map((icon) => IconButton(
                  icon: Icon(icon, color: Colors.white70, size: 22),
                  onPressed: () {},
                ))
            .toList(),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _AppIcon({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DockIcon(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AppItem {
  final String label;
  final IconData icon;
  final Color color;

  _AppItem(this.label, this.icon, this.color);
}

class _CosmicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
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
