import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_screen.dart';
import 'utils/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi pengaturan bahasa
  await LanguageController.instance.init();

  // Inisialisasi Firebase yang aman untuk Web & Android/Mobile
  try {
    if (kIsWeb) {
      // Di Web, lewati atau tangani inisialisasi agar tidak error assertion options != null
      debugPrint('Menjalankan di Web - Inisialisasi Firebase standar dilewati.');
    } else {
      // Di Android/iOS akan membaca konfigurasi native (google-services.json) secara otomatis
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Error init Firebase: $e');
  }

  runApp(const StructuraApp());
}

class StructuraApp extends StatefulWidget {
  const StructuraApp({super.key});

  @override
  State<StructuraApp> createState() => _StructuraAppState();
}

class _StructuraAppState extends State<StructuraApp> {
  bool _isDarkMode = true;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _fontScale = prefs.getDouble('fontScale') ?? 1.0;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> _changeFontScale(double scale) async {
    setState(() {
      _fontScale = scale;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', scale);
  }

  void _toggleLanguage() {
    LanguageController.instance.toggleLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Structora',
          debugShowCheckedModeBanner: false,
          locale: LanguageController.instance.currentLocale,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: _isDarkMode
              ? ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF060913),
            primaryColor: const Color(0xFF00F0FF),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F0FF),
              surface: Color(0xFF0F172A),
            ),
            cardColor: const Color(0xFF0F172A),
          )
              : ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            primaryColor: const Color(0xFF0284C7),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              surface: Colors.white,
            ),
            cardColor: Colors.white,
          ),
          home: SplashScreen(
            isDarkMode: _isDarkMode,
            fontScale: _fontScale,
            onToggleTheme: _toggleTheme,
            onChangeFontScale: _changeFontScale,
          ),
        );
      },
    );
  }
}