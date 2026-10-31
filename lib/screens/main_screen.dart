import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/materi_data.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_translations.dart';
import '../widgets/evaluation_tab_widget.dart';
import '../widgets/interactive_spotlight_overlay.dart';
import '../widgets/readiness_dialog.dart';
import '../widgets/simulation_3d_widget.dart';
import '../widgets/youtube_player_widget.dart';
import '../teacher_mode/teacher_content_helper.dart';

import 'locked_quiz_screen.dart';
import 'notification_screen.dart' as notif_screen;

class MainScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final double fontScale;
  final Function(bool) onToggleTheme;
  final Function(double) onChangeFontScale;

  const MainScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.isDarkMode,
    required this.fontScale,
    required this.onToggleTheme,
    required this.onChangeFontScale,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _activeTab = 'home';
  String? _customImagePath;
  late String _currentUserName;

  late bool _isDark;
  late double _fontScale;

  int? _openedMateriIndex;
  String _selectedSubMenu = 'penjelasan';
  Set<String> _completedSteps = {};

  List<dynamic> _dynamicTeacherMateri = [];

  bool _isPreTestCompleted = false;
  int _preTestScore = 0;
  bool _isPostTestCompleted = false;
  int _postTestScore = 0;

  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _academicStatusKey = GlobalKey();
  final GlobalKey _materiTabKey = GlobalKey();
  final GlobalKey _labTabKey = GlobalKey();
  final GlobalKey _evaluasiTabKey = GlobalKey();

  OverlayEntry? _spotlightOverlayEntry;

  Color get _scaffoldBg => _isDark ? const Color(0xFF060913) : const Color(0xFFF1F5F9);
  Color get _cardBg => _isDark ? const Color(0xFF0F172A) : Colors.white;
  Color get _boxInnerBg => _isDark ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _subTextColor => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color get _borderColor => _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  Color get _accentColor => _isDark ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_onLanguageChanged);
    _isDark = widget.isDarkMode;
    _fontScale = widget.fontScale;
    _currentUserName = widget.userName;
    _loadProfileData();
    _loadLearningProgress();
    _loadTeacherDynamicMateri();
    _initActivityTime();

    NotificationService.syncStudyReminder(studentName: _currentUserName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowSpotlightTutorial();
    });
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTeacherDynamicMateri() async {
    final list = await TeacherContentHelper.getMateriList();
    if (!mounted) return;
    setState(() {
      _dynamicTeacherMateri = list;
    });
  }

  Future<void> _checkAndShowSpotlightTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;

    if (!hasSeenTutorial && mounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _showSpotlightWalkthrough();
      });
    }
  }

  void _showSpotlightWalkthrough() {
    final isEn = LanguageController.instance.isEnglish;
    final overlayState = Overlay.of(context);
    _spotlightOverlayEntry = OverlayEntry(
      builder: (ctx) => InteractiveSpotlightOverlay(
        isDarkMode: _isDark,
        onFinish: () async {
          _removeSpotlightOverlay();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenTutorial', true);
        },
        steps: [
          SpotlightStep(
            key: _profileKey,
            title: isEn ? 'Profile & Account Settings' : 'Profil & Pengaturan Akun',
            desc: isEn
                ? 'Access the side menu to change profile photo, toggle dark/light theme, and adjust font sizes.'
                : 'Akses menu samping untuk mengganti foto profil, mengaktifkan tema gelap/terang, dan mengatur ukuran huruf aplikasi.',
            icon: Icons.person_pin_rounded,
            accentColor: const Color(0xFF00F0FF),
          ),
          SpotlightStep(
            key: _academicStatusKey,
            title: isEn ? 'Passing Standard 80 & Graduation' : 'Standar KKM 80 & Kelulusan',
            desc: isEn
                ? 'Track your academic requirements here. You must score at least 80 on every module assessment and final Post-Test.'
                : 'Pantau syarat akademikmu di sini. Kamu wajib meraih nilai minimal 80 pada setiap asesmen modul serta Post-Test akhir untuk lulus.',
            icon: Icons.verified_outlined,
            accentColor: const Color(0xFF10B981),
          ),
          SpotlightStep(
            key: _materiTabKey,
            title: isEn ? 'Learning Modules' : 'Menu Materi Pembelajaran',
            desc: isEn
                ? 'Sequential learning hub! Take the initial Pre-Test here to unlock Module 1 (Linked List).'
                : 'Pusat pembelajaran modul berurutan! Kerjakan Pre-Test awal di sini untuk membuka akses Modul 1 (Linked List).',
            icon: Icons.menu_book_rounded,
            accentColor: const Color(0xFF3B82F6),
          ),
          SpotlightStep(
            key: _labTabKey,
            title: isEn ? 'Interactive 3D Lab Simulation' : 'Simulasi Lab 3D Interaktif',
            desc: isEn
                ? 'Directly experiment with dynamic memory pointers, Stack LIFO, and Queue FIFO workflows.'
                : 'Eksperimen langsung cara kerja pointer, tumpukan LIFO pada Stack, dan antrean FIFO pada Queue secara visual bergerak.',
            icon: Icons.science_outlined,
            accentColor: const Color(0xFF8B5CF6),
          ),
          SpotlightStep(
            key: _evaluasiTabKey,
            title: isEn ? 'Evaluation & Analytics Dashboard' : 'Dashboard Evaluasi & Grafik',
            desc: isEn
                ? 'Monitor your score progression graph from the initial Pre-Test to module assessments and the final Post-Test.'
                : 'Pantau grafik peningkatan nilaimu dari awal Pre-Test, latihan modul, hingga hasil akhir Post-Test kurikulum.',
            icon: Icons.analytics_outlined,
            accentColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );

    overlayState.insert(_spotlightOverlayEntry!);
  }

  void _removeSpotlightOverlay() {
    _spotlightOverlayEntry?.remove();
    _spotlightOverlayEntry = null;
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    _removeSpotlightOverlay();
    super.dispose();
  }

  Future<void> _initActivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('lastActiveTimestamp')) {
      await prefs.setInt('lastActiveTimestamp', DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedName = prefs.getString('userName');
    if (savedName == null || savedName.trim().isEmpty || savedName.toLowerCase() == 'pengguna') {
      if (widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'pengguna') {
        savedName = widget.userName;
      } else if (widget.userEmail.contains('@')) {
        final prefix = widget.userEmail.split('@').first;
        savedName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }

    setState(() {
      _customImagePath = prefs.getString('userCustomImage');
      if (savedName != null && savedName.isNotEmpty) {
        _currentUserName = savedName;
      }
    });
  }

  Future<void> _pickImage() async {
    final isEn = LanguageController.instance.isEnglish;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userCustomImage', base64Image);

        setState(() {
          _customImagePath = base64Image;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn
                  ? 'Profile photo updated successfully!'
                  : 'Foto profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  Future<void> _loadLearningProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedSteps = (prefs.getStringList('completed_steps') ?? []).toSet();
      _isPreTestCompleted = prefs.getBool('isPreTestCompleted') ?? false;
      _preTestScore = prefs.getInt('preTestScore') ?? 0;
      _isPostTestCompleted = prefs.getBool('isPostTestCompleted') ?? false;
      _postTestScore = prefs.getInt('postTestScore') ?? 0;
    });
  }

  Future<void> _resetLearningProgress() async {
    final isEn = LanguageController.instance.isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completed_steps');
    await prefs.remove('isPreTestCompleted');
    await prefs.remove('preTestScore');
    await prefs.remove('isPostTestCompleted');
    await prefs.remove('postTestScore');
    for (var m in listModulMateri) {
      await prefs.remove('score_${m['id']}');
    }
    await prefs.remove('posttest_wrong_diagnostics');

    setState(() {
      _completedSteps.clear();
      _isPreTestCompleted = false;
      _preTestScore = 0;
      _isPostTestCompleted = false;
      _postTestScore = 0;
      _openedMateriIndex = null;
    });

    NotificationService.syncStudyReminder(studentName: _currentUserName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Learning progress has been reset!'
              : 'Progres belajar telah direset!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _recordStepProgress(String moduleId, String stepKey) async {
    final String stepId = '${moduleId}_$stepKey';
    if (!_completedSteps.contains(stepId)) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _completedSteps.add(stepId);
      });
      await prefs.setStringList('completed_steps', _completedSteps.toList());
      await prefs.setInt('lastActiveTimestamp', DateTime.now().millisecondsSinceEpoch);

      final userEmail = prefs.getString('userEmail') ?? widget.userEmail;
      final userName = prefs.getString('userName') ?? widget.userName;
      if (userEmail.isNotEmpty) {
        FirebaseService.saveStudentProgress(
          name: userName,
          email: userEmail,
          preTestScore: _isPreTestCompleted ? '$_preTestScore' : '-',
          postTestScore: _isPostTestCompleted ? '$_postTestScore' : '-',
          completedSteps: _completedSteps.toList(),
        );
      }
    }
  }

  double _getModuleProgressRatio(String moduleId) {
    const steps = ['penjelasan', 'video', 'asesmen'];
    int count = steps.where((s) => _completedSteps.contains('${moduleId}_$s')).length;
    return count / steps.length;
  }

  List<Map<String, dynamic>> get _learningModules {
    final list = _dynamicTeacherMateri.where((item) {
      final id = (item['id'] ?? '').toString().toLowerCase();
      return id != 'pretest' && id != 'posttest';
    }).toList();
    if (list.isNotEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    return listModulMateri;
  }

  int _getTotalCompletedPoints() {
    int points = 0;
    if (_isPreTestCompleted) points++;
    final modules = _learningModules;

    for (int i = 0; i < modules.length; i++) {
      final String mId = modules[i]['id'] ?? 'modul_${i + 1}';
      if (_completedSteps.contains('${mId}_penjelasan')) points++;
      if (_completedSteps.contains('${mId}_video')) points++;
      if (_completedSteps.contains('${mId}_asesmen')) points++;
    }
    if (_isPostTestCompleted) points++;
    return points;
  }

  int _getTotalTargetPoints() {
    final modules = _learningModules;
    return 1 + (modules.length * 3) + 1;
  }

  double _getOverallProgressRatio() {
    final total = _getTotalTargetPoints();
    return total == 0 ? 0.0 : (_getTotalCompletedPoints() / total).clamp(0.0, 1.0);
  }

  bool _isModuleUnlocked(int index) {
    if (!_isPreTestCompleted) return false;
    if (index == 0) return true;

    final prevIndex = index - 1;
    final modules = _learningModules;
    final String prevModuleId = prevIndex < modules.length
        ? (modules[prevIndex]['id'] ?? 'modul_${prevIndex + 1}')
        : listModulMateri[prevIndex]['id'];

    return _getModuleProgressRatio(prevModuleId) >= 1.0;
  }

  bool _isSubMenuUnlocked(String moduleId, String subKey) {
    if (subKey == 'penjelasan') return true;
    if (subKey == 'video') return _completedSteps.contains('${moduleId}_penjelasan');
    if (subKey == 'asesmen') return _completedSteps.contains('${moduleId}_video');
    return false;
  }

  bool _areAllModulesCompleted() {
    if (!_isPreTestCompleted) return false;
    final modules = _learningModules;

    for (int i = 0; i < modules.length; i++) {
      final String mId = modules[i]['id'] ?? 'modul_${i + 1}';
      if (_getModuleProgressRatio(mId) < 1.0) return false;
    }
    return true;
  }

  void _navigateToExam(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LockedQuizScreen(
          quizType: type,
          isDarkMode: _isDark,
          fontScale: _fontScale,
        ),
      ),
    );
    if (result == true) {
      _loadLearningProgress();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastActiveTimestamp', DateTime.now().millisecondsSinceEpoch);
    }
  }

  Widget _buildAvatarWidget({required double radius}) {
    if (_customImagePath != null && _customImagePath!.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(_customImagePath!);
        return CircleAvatar(
          radius: radius,
          backgroundColor: _accentColor.withValues(alpha: 0.2),
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        if (!kIsWeb) {
          final file = File(_customImagePath!);
          if (file.existsSync()) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: _accentColor.withValues(alpha: 0.2),
              backgroundImage: FileImage(file),
            );
          }
        }
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _accentColor.withValues(alpha: 0.2),
      child: Icon(Icons.person, size: radius * 1.1, color: _accentColor),
    );
  }

  String _getGreetingText(bool isEn) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return isEn ? 'Good Morning' : 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return isEn ? 'Good Afternoon' : 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return isEn ? 'Good Evening' : 'Selamat Sore';
    } else {
      return isEn ? 'Good Night' : 'Selamat Malam';
    }
  }

  Widget _buildGreetingCard() {
    final isEn = LanguageController.instance.isEnglish;
    final String greeting = _getGreetingText(isEn);
    final String cleanName = _currentUserName.trim();
    final String firstName = cleanName.isEmpty
        ? (isEn ? 'Student' : 'Siswa')
        : cleanName.split(' ').first;

    final bool isDemoUser = widget.userEmail.toLowerCase().contains('demo') ||
        cleanName.toLowerCase().contains('demo');
    final String roleBadgeText = isDemoUser
        ? (isEn ? 'Demo Student' : 'Siswa Demo')
        : (isEn ? 'Student' : 'Siswa');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isDark
              ? const Color(0xFF00F0FF).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [
            const Color(0xFF03163E),
            const Color(0xFF062C7A),
            const Color(0xFF034EB8),
          ]
              : [
            const Color(0xFF0242B3),
            const Color(0xFF0262E9),
            const Color(0xFF0084FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                : const Color(0xFF0262E9).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _isDark
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.9)
                        : Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isDark
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDemoUser ? Icons.flash_on_rounded : Icons.school_rounded,
                        size: 14,
                        color: _isDark ? const Color(0xFF00F0FF) : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        roleBadgeText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? const Color(0xFF00F0FF) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF00F0FF)
                    : Colors.white.withValues(alpha: 0.85),
                width: 2.2,
              ),
              boxShadow: _isDark
                  ? [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                )
              ]
                  : null,
            ),
            child: _buildAvatarWidget(radius: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildRightProfileDrawer() {
    final isEn = LanguageController.instance.isEnglish;
    return Drawer(
      backgroundColor: _cardBg,
      child: SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDrawerState) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? 'Profile Settings' : 'Pengaturan Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      _buildAvatarWidget(radius: 46),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () async {
                            await _pickImage();
                            setDrawerState(() {});
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: _accentColor,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _currentUserName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.userEmail,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: _subTextColor,
                    ),
                  ),
                ),
                Divider(color: _borderColor, height: 28),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.translate_rounded, color: _accentColor),
                  title: Text(
                    isEn ? 'Language' : 'Bahasa Aplikasi',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isEn ? 'English (Active)' : 'Bahasa Indonesia (Aktif)',
                    style: TextStyle(fontSize: 11, color: _subTextColor),
                  ),
                  trailing: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      LanguageController.instance.toggleLanguage();
                      setDrawerState(() {});
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _boxInnerBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accentColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEn ? 'EN' : 'ID',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.swap_horiz_rounded, size: 14, color: _accentColor),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _isDark
                        ? (isEn ? 'Dark Mode' : 'Mode Gelap')
                        : (isEn ? 'Light Mode' : 'Mode Terang'),
                    style: TextStyle(
                      fontSize: 13,
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _isDark
                        ? (isEn ? 'Dark theme active' : 'Tema gelap aktif')
                        : (isEn ? 'Light theme active' : 'Tema terang aktif'),
                    style: TextStyle(fontSize: 11, color: _subTextColor),
                  ),
                  value: _isDark,
                  activeTrackColor: _accentColor,
                  onChanged: (val) {
                    setState(() => _isDark = val);
                    setDrawerState(() {});
                    widget.onToggleTheme(val);
                  },
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEn ? 'Font Size' : 'Ukuran Font',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(_fontScale * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _accentColor,
                        thumbColor: _accentColor,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _fontScale,
                        min: 0.85,
                        max: 1.25,
                        divisions: 4,
                        onChanged: (val) {
                          setState(() => _fontScale = val);
                          setDrawerState(() {});
                          widget.onChangeFontScale(val);
                        },
                      ),
                    ),
                  ],
                ),
                Divider(color: _borderColor, height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt, color: Colors.orange),
                  title: Text(
                    isEn ? 'Reset Learning Progress' : 'Reset Progres Belajar',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isEn
                        ? 'Revert modules and quiz to starting point'
                        : 'Kembalikan modul & evaluasi ke awal',
                    style: TextStyle(fontSize: 10.5, color: _subTextColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _resetLearningProgress();
                  },
                ),
                Divider(color: _borderColor, height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    isEn ? 'Log Out' : 'Keluar Akun',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLogout();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
            Navigator.pop(context);
          } else if (_openedMateriIndex != null) {
            setState(() => _openedMateriIndex = null);
          } else if (_activeTab != 'home') {
            setState(() => _activeTab = 'home');
          } else {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _scaffoldBg,
          endDrawer: _buildRightProfileDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _activeTab == 'lab'
                      ? const Simulation3DWidget()
                      : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: _buildBodyContent(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Structora',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => notif_screen.NotificationScreen(
                        isDarkMode: _isDark,
                        fontScale: _fontScale,
                        userName: _currentUserName,
                        isPreTestCompleted: _isPreTestCompleted,
                        isPostTestCompleted: _isPostTestCompleted,
                        completedPoints: _getTotalCompletedPoints(),
                        totalPoints: _getTotalTargetPoints(),
                        completedSteps: _completedSteps,
                      ),
                    ),
                  );
                },
                icon: Stack(
                  children: [
                    Icon(Icons.notifications_outlined, color: _textColor, size: 22),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              InkWell(
                key: _profileKey,
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _boxInnerBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildAvatarWidget(radius: 12),
                      const SizedBox(width: 6),
                      Text(
                        _currentUserName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.menu_open_rounded, size: 16, color: _accentColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_activeTab == 'home') return _buildHomeTab();
    if (_activeTab == 'materi') return _buildMateriTab();
    return EvaluationTabWidget(
      isDarkMode: _isDark,
      isPreTestCompleted: _isPreTestCompleted,
      preTestScore: _preTestScore,
      isPostTestCompleted: _isPostTestCompleted,
      postTestScore: _postTestScore,
      completedSteps: _completedSteps,
      isModuleUnlocked: _isModuleUnlocked,
      getModuleProgressRatio: _getModuleProgressRatio,
    );
  }

  Widget _buildHomeTab() {
    final isEn = LanguageController.instance.isEnglish;
    final double overallRatio = _getOverallProgressRatio();
    final int overallPercent = (overallRatio * 100).toInt();
    final int completedPoints = _getTotalCompletedPoints();
    final int totalPoints = _getTotalTargetPoints();

    final bool isPassed = _isPostTestCompleted && _postTestScore >= 80;
    final String statusText = !_isPostTestCompleted
        ? (isEn ? 'Not Yet Tested' : 'Belum Ujian')
        : (isPassed ? (isEn ? 'Passed' : 'Lulus') : (isEn ? 'Remedial' : 'Remedial'));
    final Color statusColor = !_isPostTestCompleted
        ? _subTextColor
        : (isPassed ? Colors.green : const Color(0xFFE11D48));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreetingCard(),
        const SizedBox(height: 16),

        _cardContainer(
          borderColor: _accentColor.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? 'Overall Learning Progress' : 'Progress Keseluruhan Belajar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    '$overallPercent%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overallRatio,
                  minHeight: 8,
                  backgroundColor: _boxInnerBg,
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isEn
                    ? '$completedPoints of $totalPoints learning milestones completed'
                    : '$completedPoints dari $totalPoints langkah belajar telah diselesaikan',
                style: TextStyle(fontSize: 10.5, color: _subTextColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          key: _academicStatusKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn ? 'Study Status & Academic Standard' : 'Status Belajar & Ketentuan Akademik',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_outlined, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                isEn ? 'Standard KKM' : 'Standar KKM',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _subTextColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEn ? 'Score 80' : 'Nilai 80',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn ? 'Min. 4 correct answers' : 'Min. 4 benar per asesmen',
                            style: TextStyle(fontSize: 9.5, color: _subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.workspace_premium_outlined, size: 16, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                isEn ? 'Graduation' : 'Kelulusan',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _subTextColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusText,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: statusColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPostTestCompleted
                                ? (isEn ? 'Score: $_postTestScore/100' : 'Skor: $_postTestScore/100')
                                : (isEn ? 'Finish Post-Test' : 'Selesaikan Post-Test'),
                            style: TextStyle(fontSize: 9.5, color: _subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEn ? 'Learning Target Competencies' : 'Target Capaian Pembelajaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
            ),
            Text(
              isEn ? 'Student Goals' : 'Kompetensi Siswa',
              style: TextStyle(fontSize: 10.5, color: _accentColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              _buildTopicItem(
                badge: isEn ? 'COMPETENCY 1' : 'KOMPETENSI 1',
                title: isEn ? 'Linked List' : 'Linked List (Senarai Berkait)',
                desc: isEn
                    ? 'Understand dynamic pointer allocation and master node insertion and deletion.'
                    : 'Mampu memahami konsep pointer memori dinamis serta menganalisis operasi penambahan dan penghapusan node.',
                color: const Color(0xFF00F0FF),
              ),
              const SizedBox(height: 8),
              _buildTopicItem(
                badge: isEn ? 'COMPETENCY 2' : 'KOMPETENSI 2',
                title: isEn ? 'Stack (LIFO)' : 'Stack (Tumpukan Data)',
                desc: isEn
                    ? 'Analyze LIFO data flow utilizing Push, Pop, and Peek operations.'
                    : 'Mampu menganalisis alur eksekusi struktur data LIFO (Last In First Out) menggunakan operasi Push dan Pop.',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              _buildTopicItem(
                badge: isEn ? 'COMPETENCY 3' : 'KOMPETENSI 3',
                title: isEn ? 'Queue (FIFO)' : 'Queue (Antrean Terurut)',
                desc: isEn
                    ? 'Master queue scheduling FIFO mechanisms via Enqueue and Dequeue workflows.'
                    : 'Mampu menguasai mekanisme penjadwalan antrean FIFO (First In First Out) melalui operasi Enqueue dan Dequeue.',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              _buildTopicItem(
                badge: isEn ? 'COMPETENCY 4' : 'KOMPETENSI 4',
                title: isEn ? 'Searching & Sorting' : 'Searching & Sorting Algorithm',
                desc: isEn
                    ? 'Compare time complexity and efficiency of search algorithms and sorting arrays.'
                    : 'Mampu membandingkan efisiensi algoritma pencarian (Linear, Binary) serta pengurutan data terstruktur.',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEn
                      ? 'Open the "Lab" tab to observe dynamic pointer animations in an interactive 3D simulation.'
                      : 'Buka tab "Simulasi Lab" untuk melihat simulasi visual perpindahan pointer memori secara interaktif.',
                  style: TextStyle(fontSize: 10.5, color: _subTextColor, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicItem({
    required String badge,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _boxInnerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor),
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10.5, color: _subTextColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriTab() {
    final isEn = LanguageController.instance.isEnglish;
    final modules = _learningModules;

    // JIKA MODUL SEDANG DIBUKA (DETAIL MATERI, VIDEO, & ASESMEN)
    if (_openedMateriIndex != null) {
      final int idx = _openedMateriIndex!;
      final bool isBaseModule = idx < listModulMateri.length;
      final baseModul = isBaseModule ? listModulMateri[idx] : null;

      // 1. Ambil data dinamis modul pembelajaran saja (tanpa pretest/posttest)
      Map<String, dynamic>? teacherItem;
      if (idx < modules.length) {
        teacherItem = modules[idx];
      }

      final String currentModulId = teacherItem?['id'] ??
          (baseModul != null ? baseModul['id'].toString().toLowerCase() : 'modul_${idx + 1}');

      final String displayTitle = isEn
          ? (teacherItem?['title_en'] ?? baseModul?.getLocalizedTitle(true) ?? AppText.auto(teacherItem?['title'] ?? ''))
          : (teacherItem?['title'] ?? baseModul?.getLocalizedTitle(false) ?? 'Pertemuan ${idx + 1}');

      final String displayModulName = isEn
          ? (teacherItem?['modul_en'] ?? (teacherItem?['modul'] != null ? AppText.auto(teacherItem!['modul']) : null) ?? baseModul?.getLocalizedDesc(true) ?? 'Meeting ${idx + 1}')
          : (teacherItem?['modul'] ?? baseModul?.getLocalizedDesc(false) ?? 'Sesi Pertemuan');

      final String rawDescIndo = teacherItem?['desc'] ?? baseModul?.getFormattedExplanation(false) ?? '';
      final String rawDescEng = teacherItem?['desc_en'] ?? baseModul?.getFormattedExplanation(true) ?? '';

      final String displayDesc = isEn
          ? (rawDescEng.isNotEmpty ? rawDescEng : AppText.auto(rawDescIndo))
          : rawDescIndo;

      final String rawVideoUrl = teacherItem?['videoUrl'] ?? '';

      // Ekstraksi Video ID YouTube
      String ytVideoId = currentModulId.contains('linkedlist')
          ? 'uCC3Kg8ms-w'
          : (currentModulId.contains('stack')
          ? 'ZwSFBSkIdss'
          : (currentModulId.contains('queue') ? '9xpWSCEcMzc' : 'RN4wc9ClciM'));

      if (rawVideoUrl.isNotEmpty) {
        if (rawVideoUrl.contains('v=')) {
          ytVideoId = rawVideoUrl.split('v=').last.split('&').first;
        } else if (rawVideoUrl.contains('youtu.be/')) {
          ytVideoId = rawVideoUrl.split('youtu.be/').last.split('?').first;
        } else if (!rawVideoUrl.contains('http')) {
          ytVideoId = rawVideoUrl;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _openedMateriIndex = null),
            icon: Icon(Icons.arrow_back_ios, size: 14, color: _accentColor),
            label: Text(
              isEn ? 'Back to Material List' : 'Kembali ke Daftar Materi',
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
          ),
          Text(
            displayModulName,
            style: TextStyle(fontSize: 11, color: _subTextColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _subOptionBtn(currentModulId, 'penjelasan', isEn ? 'Content' : 'Materi', Icons.menu_book),
              const SizedBox(width: 6),
              _subOptionBtn(currentModulId, 'video', 'Video', Icons.play_circle_outline),
              const SizedBox(width: 6),
              _subOptionBtn(currentModulId, 'asesmen', isEn ? 'Assessment' : 'Asesmen', Icons.fact_check_outlined),
            ],
          ),
          const SizedBox(height: 16),

          // TAB 1: PENJELASAN MATERI (TERHUBUNG 100% DENGAN GURU)
          if (_selectedSubMenu == 'penjelasan') ...[
            _cardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    displayDesc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _textColor,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _recordStepProgress(currentModulId, 'penjelasan');
                        setState(() => _selectedSubMenu = 'video');
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      label: Text(
                        isEn ? 'Finish Reading & Continue to Video' : 'Selesai Baca & Lanjut ke Video',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                ],
              ),
            )
          ] else if (_selectedSubMenu == 'video') ...[
            _cardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YouTubeVideoPlayerWidget(
                    videoId: ytVideoId,
                    onPlayTriggered: () => _recordStepProgress(currentModulId, 'video'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    baseModul != null ? baseModul.getLocalizedVideoTitle(isEn) : 'Video Tutorial Pembelajaran',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textColor),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _recordStepProgress(currentModulId, 'video');
                        setState(() => _selectedSubMenu = 'asesmen');
                      },
                      icon: const Icon(Icons.fact_check, size: 16, color: Colors.white),
                      label: Text(
                        isEn ? 'Finish Watching & Open Assessment' : 'Selesai Nonton & Buka Asesmen',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                    ),
                  )
                ],
              ),
            )
          ] else if (_selectedSubMenu == 'asesmen') ...[
            _cardContainer(
              borderColor: const Color(0xFFD97706).withValues(alpha: 0.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFFD97706), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        isEn ? 'Module Assessment Exam' : 'Asesmen Ujian Modul',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? 'Assessment exam for this module. Students must achieve passing score 80 to unlock next module.'
                        : 'Ujian asesmen untuk modul ini. Siswa wajib mencapai KKM 80 untuk membuka modul berikutnya.',
                    style: TextStyle(fontSize: 11, color: _subTextColor),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToExam('asesmen_$currentModulId'),
                      icon: const Icon(Icons.lock, size: 16, color: Colors.white),
                      label: Text(
                        isEn ? 'Start Locked Assessment' : 'Mulai Asesmen Terkunci',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final bool allDone = _areAllModulesCompleted();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn ? 'Learning Modules' : 'Modul Pembelajaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Complete the Pre-Test first to unlock the learning modules:'
              : 'Selesaikan Pre-Test terlebih dahulu untuk membuka akses modul:',
          style: TextStyle(fontSize: 11, color: _subTextColor),
        ),
        const SizedBox(height: 16),
        _cardContainer(
          borderColor: const Color(0xFFD97706).withValues(alpha: 0.6),
          child: Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFD97706), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Initial Ability Pre-Test' : 'Pre-Test Kemampuan Awal',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    Text(
                      _isPreTestCompleted
                          ? (isEn ? 'Completed (Score: $_preTestScore)' : 'Selesai (Nilai: $_preTestScore)')
                          : (isEn ? 'Mandatory initial assessment.' : 'Wajib dikerjakan pertama kali.'),
                      style: TextStyle(fontSize: 10.5, color: _subTextColor),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateToExam('pretest'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                child: Text(
                  _isPreTestCompleted ? (isEn ? 'Retake' : 'Ulang') : (isEn ? 'Start' : 'Mulai'),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // DAFTAR KARTU MODUL DINAMIS (HANYA SIKLUS MODUL SESI PEMBELAJARAN)
        ...List.generate(modules.length, (idx) {
          final bool isBaseModule = idx < listModulMateri.length;
          final m = isBaseModule ? listModulMateri[idx] : null;

          final Map<String, dynamic> tItem = modules[idx];

          final String moduleId = tItem['id'] ?? (m != null ? m['id'] : 'modul_${idx + 1}');
          final String dynamicTitle = isEn
              ? (tItem['title_en'] ?? m?.getLocalizedTitle(true) ?? AppText.auto(tItem['title'] ?? ''))
              : (tItem['title'] ?? m?.getLocalizedTitle(false) ?? 'Pertemuan ${idx + 1}');
          final String dynamicDesc = isEn
              ? (tItem['desc_en'] ?? m?.getLocalizedDesc(true) ?? AppText.auto(tItem['desc'] ?? ''))
              : (tItem['desc'] ?? m?.getLocalizedDesc(false) ?? 'Materi Pembelajaran Baru');
          final Color color = m != null ? (m['color'] as Color) : const Color(0xFF00F0FF);
          final IconData icon = m != null ? m['icon'] : Icons.menu_book_rounded;

          final bool isUnlocked = idx == 0 || _isModuleUnlocked(idx);
          final double ratio = _getModuleProgressRatio(moduleId);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: isUnlocked
                  ? () {
                if (idx == 0) {
                  setState(() {
                    _openedMateriIndex = idx;
                    _selectedSubMenu = 'penjelasan';
                  });
                  return;
                }

                final prevName = idx - 1 < modules.length
                    ? (isEn ? (modules[idx - 1]['title_en'] ?? AppText.auto(modules[idx - 1]['title'] ?? '')) : (modules[idx - 1]['title'] ?? 'Pertemuan $idx'))
                    : listModulMateri[idx - 1].getLocalizedTitle(isEn);

                showDialog(
                  context: context,
                  builder: (ctx) => ReadinessDialog(
                    currentModuleName: prevName,
                    nextModuleName: dynamicTitle,
                    isDarkMode: _isDark,
                    onReady: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _openedMateriIndex = idx;
                        _selectedSubMenu = 'penjelasan';
                      });
                    },
                    onReview: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _openedMateriIndex = idx - 1;
                        _selectedSubMenu = 'penjelasan';
                      });
                    },
                  ),
                );
              }
                  : () {
                final reason = !_isPreTestCompleted
                    ? (isEn ? 'Complete the Pre-Test first!' : 'Kerjakan Pre-Test terlebih dahulu!')
                    : (isEn ? 'Complete previous module and reach score 80!' : 'Selesaikan modul sebelumnya dan capai nilai KKM 80!');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(reason), backgroundColor: Colors.redAccent),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked ? color.withValues(alpha: 0.5) : _borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUnlocked ? icon : Icons.lock_outline,
                      color: isUnlocked ? color : _subTextColor,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dynamicTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? _textColor : _subTextColor,
                            ),
                          ),
                          Text(
                            isUnlocked ? dynamicDesc : (isEn ? 'Locked' : 'Terkunci'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: _subTextColor),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      Text(
                        '${(ratio * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      )
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),

        _cardContainer(
          borderColor: allDone
              ? const Color(0xFFE11D48).withValues(alpha: 0.8)
              : _borderColor,
          child: Row(
            children: [
              Icon(
                allDone ? Icons.workspace_premium_outlined : Icons.lock_outline,
                color: allDone ? const Color(0xFFE11D48) : _subTextColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Post-Test Final Assessment' : 'Post-Test Evaluasi Akhir',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: allDone ? const Color(0xFFE11D48) : _subTextColor,
                      ),
                    ),
                    Text(
                      allDone
                          ? (_isPostTestCompleted
                          ? (_postTestScore >= 80
                          ? (isEn ? 'Passed ($_postTestScore)' : 'Lulus ($_postTestScore)')
                          : (isEn ? 'Requires Remedial ($_postTestScore / Target 80)' : 'Perlu Remedial ($_postTestScore / KKM 80)'))
                          : (isEn ? 'Ready to attempt.' : 'Siap dikerjakan.'))
                          : (isEn ? 'Locked. Complete all modules & pass standards.' : 'Terkunci. Selesaikan semua modul & KKM.'),
                      style: TextStyle(fontSize: 10.5, color: _subTextColor),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: allDone ? () => _navigateToExam('posttest') : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                child: Text(
                  _isPostTestCompleted ? (isEn ? 'Retake' : 'Ulang') : (isEn ? 'Exam' : 'Ujian'),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subOptionBtn(String moduleId, String key, String label, IconData icon) {
    bool isSel = _selectedSubMenu == key;
    bool isDone = _completedSteps.contains('${moduleId}_$key');
    bool isUnlocked = _isSubMenuUnlocked(moduleId, key);

    return Expanded(
      child: InkWell(
        onTap: isUnlocked ? () => setState(() => _selectedSubMenu = key) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: !isUnlocked
                ? (_isDark ? Colors.white10 : Colors.black12)
                : (isSel ? _accentColor.withValues(alpha: 0.18) : _cardBg),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? _accentColor : _borderColor),
          ),
          child: Column(
            children: [
              Icon(
                !isUnlocked ? Icons.lock : (isDone ? Icons.check_circle : icon),
                size: 16,
                color: !isUnlocked
                    ? _subTextColor
                    : (isDone ? Colors.green : (isSel ? _accentColor : _subTextColor)),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: !isUnlocked ? _subTextColor : (isSel ? _accentColor : _subTextColor),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardContainer({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? _borderColor),
      ),
      child: child,
    );
  }

  Widget _buildBottomNav() {
    final isEn = LanguageController.instance.isEnglish;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_outlined, 'Home', 'home', null),
              _navItem(Icons.menu_book, isEn ? 'Topics' : 'Materi', 'materi', _materiTabKey),
              _navItem(Icons.science_outlined, isEn ? '3D Lab' : 'Simulasi Lab', 'lab', _labTabKey),
              _navItem(Icons.analytics_outlined, isEn ? 'Evaluation' : 'Evaluasi', 'evaluasi', _evaluasiTabKey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String tabKey, Key? widgetKey) {
    final isSel = _activeTab == tabKey;
    final color = isSel ? _accentColor : (_isDark ? Colors.white38 : Colors.black38);
    return InkWell(
      key: widgetKey,
      onTap: () => setState(() {
        _activeTab = tabKey;
        if (tabKey == 'materi') {
          _openedMateriIndex = null;
          _loadTeacherDynamicMateri();
        }
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}