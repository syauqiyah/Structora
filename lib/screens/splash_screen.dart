import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import '../teacher_mode/teacher_dashboard_screen.dart'; // <-- Tambahan import untuk Portal Guru

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final Function(bool) onToggleTheme;
  final Function(double) onChangeFontScale;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.onToggleTheme,
    required this.onChangeFontScale,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _flightController;
  late AnimationController _pulseController;
  late AnimationController _gridController;

  late Animation<double> _assemblyAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;

  final List<Map<String, double>> _particles = [];
  final Random _rng = Random(99);

  @override
  void initState() {
    super.initState();

    // Inisialisasi partikel cyber
    for (int i = 0; i < 40; i++) {
      final angle = (i / 40) * 2 * pi + (_rng.nextDouble() * 0.4);
      final distance = 160.0 + _rng.nextDouble() * 180.0;
      _particles.add({
        'startX': cos(angle) * distance,
        'startY': sin(angle) * distance,
        'curveSpeed': (_rng.nextBool() ? 1.0 : -1.0) * (2.0 + _rng.nextDouble() * 3.0),
        'size': 4.0 + _rng.nextDouble() * 6.0,
      });
    }

    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _assemblyAnim = CurvedAnimation(
      parent: _flightController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeInOutCubic),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flightController,
        curve: const Interval(0.55, 0.85, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnim = CurvedAnimation(
      parent: _flightController,
      curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _flightController,
      curve: const Interval(0.70, 0.95, curve: Curves.easeIn),
    );

    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _flightController,
        curve: const Interval(0.70, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _flightController.forward();

    // Timer transisi ke RootGate setelah animasi selesai
    Timer(const Duration(milliseconds: 4800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RootGate(
              isDarkMode: widget.isDarkMode,
              fontScale: widget.fontScale,
              onToggleTheme: widget.onToggleTheme,
              onChangeFontScale: widget.onChangeFontScale,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _flightController.dispose();
    _pulseController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);
    final bgColor = widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFF0B1329);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Grid Background Animasi Perspective Cyber
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, _) {
                return CustomPaint(
                  painter: CyberGridPainter(
                    progress: _gridController.value,
                    isDarkMode: widget.isDarkMode,
                  ),
                );
              },
            ),
          ),

          // 2. Radial Gradient Flare Tengah
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulseVal = _pulseController.value;
                return Container(
                  width: 320 + (pulseVal * 40),
                  height: 320 + (pulseVal * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: widget.isDarkMode ? 0.28 : 0.18),
                        const Color(0xFFFF007F).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Konten Utama: Partikel, Logo Asli, dan Teks
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_flightController, _pulseController]),
              builder: (context, child) {
                final t = _assemblyAnim.value;
                final pulseVal = _pulseController.value;

                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Partikel Neon Mengumpul
                    if (t < 0.98)
                      ..._particles.map((p) {
                        final wave = sin(t * pi * p['curveSpeed']!) * 30.0 * (1.0 - t);
                        final curX = (p['startX']! * (1.0 - t)) + (cos(t * pi) * wave);
                        final curY = (p['startY']! * (1.0 - t)) + (sin(t * pi) * wave) - 40;
                        final rot = t * 2 * pi * p['curveSpeed']!;
                        final size = p['size']! * (1.0 - (t * 0.3));
                        final opacity = (1.0 - (t * 0.2)).clamp(0.0, 1.0);

                        return Transform.translate(
                          offset: Offset(curX, curY),
                          child: Transform.rotate(
                            angle: rot,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    // Kolom Logo & Judul
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _logoFadeAnim,
                          child: ScaleTransition(
                            scale: _logoScaleAnim,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F0FF).withValues(
                                      alpha: 0.25 + (pulseVal * 0.2),
                                    ),
                                    blurRadius: 30 + (pulseVal * 15),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF007F).withValues(
                                      alpha: 0.2 + (pulseVal * 0.15),
                                    ),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/logo.jpg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        SlideTransition(
                          position: _textSlideAnim,
                          child: FadeTransition(
                            opacity: _textFadeAnim,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF00F0FF), Color(0xFFFF007F), Color(0xFFFFD700)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'STRUCTORA',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'INTERACTIVE DATA STRUCTURE LEARNING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: accentColor.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (idx) {
                                    final waveDot = sin((pulseVal * pi) + (idx * 0.8)).abs();
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 6 + (waveDot * 4),
                                      height: 6 + (waveDot * 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor.withValues(alpha: 0.4 + (waveDot * 0.6)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withValues(alpha: 0.5),
                                            blurRadius: 6,
                                          )
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cyber Grid Background Painter
class CyberGridPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  CyberGridPainter({required this.progress, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? const Color(0xFF00F0FF).withValues(alpha: 0.07)
          : const Color(0xFF0284C7).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final horizonY = size.height * 0.65;
    final vanishingPoint = Offset(size.width / 2, horizonY);

    for (double x = -size.width; x <= size.width * 2; x += 40) {
      canvas.drawLine(vanishingPoint, Offset(x, size.height), paint);
    }

    final gridOffset = (progress * 30) % 30;
    for (double y = horizonY; y <= size.height; y += 12 + ((y - horizonY) * 0.12)) {
      final lineY = y + gridOffset;
      if (lineY <= size.height) {
        canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CyberGridPainter oldDelegate) => true;
}

/// Class RootGate
class RootGate extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final Function(bool) onToggleTheme;
  final Function(double) onChangeFontScale;

  const RootGate({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.onToggleTheme,
    required this.onChangeFontScale,
  });

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isTeacher = false; // Penanda status role guru
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isTeacherRole = prefs.getBool('isTeacher') ?? false;

    if (prefs.getBool('isLoggedIn') == true) {
      setState(() {
        _isLoggedIn = true;
        _isTeacher = isTeacherRole;
        _userName = prefs.getString('userName') ?? 'Pengguna';
        _userEmail = prefs.getString('userEmail') ?? '';
        _isLoading = false;
      });
      return;
    }

    if (kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.reload();
        } catch (_) {}
        if (user.emailVerified) {
          final emailClean = user.email?.toLowerCase().trim() ?? '';
          final savedName = prefs.getString('saved_name_$emailClean');

          String finalName = user.displayName ?? savedName ?? prefs.getString('userName') ?? '';
          if (finalName.isEmpty) {
            String fallbackName = user.email?.split('@').first ?? 'Pengguna';
            if (fallbackName.isNotEmpty) {
              fallbackName = fallbackName[0].toUpperCase() + fallbackName.substring(1);
            }
            finalName = fallbackName;
          }

          setState(() {
            _isLoggedIn = true;
            _isTeacher = isTeacherRole;
            _userName = finalName;
            _userEmail = user.email ?? '';
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error auth check: $e');
    }
    setState(() => _isLoading = false);
  }

  void _onLoginSuccess(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isTeacherRole = prefs.getBool('isTeacher') ?? false;
    setState(() {
      _userName = name;
      _userEmail = email;
      _isLoggedIn = true;
      _isTeacher = isTeacherRole;
    });
  }

  void _onLogout() async {
    if (!kIsWeb) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isTeacher', false);
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    setState(() {
      _isLoggedIn = false;
      _isTeacher = false;
      _userName = '';
      _userEmail = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return AuthScreen(
        isDarkMode: widget.isDarkMode,
        onLoginSuccess: _onLoginSuccess,
      );
    }

    // Jika berstatus guru, langsung arahkan ke TeacherDashboardScreen
    if (_isTeacher) {
      return TeacherDashboardScreen(
        isDarkMode: widget.isDarkMode,
        fontScale: widget.fontScale,
      );
    }

    // Jika siswa, arahkan ke MainScreen seperti biasa
    return MainScreen(
      userName: _userName,
      userEmail: _userEmail,
      onLogout: _onLogout,
      isDarkMode: widget.isDarkMode,
      fontScale: widget.fontScale,
      onToggleTheme: widget.onToggleTheme,
      onChangeFontScale: widget.onChangeFontScale,
    );
  }
}