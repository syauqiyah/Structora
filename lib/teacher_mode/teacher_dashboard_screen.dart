import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth_screen.dart';
import '../services/firebase_service.dart';
import '../utils/app_translations.dart';
import 'teacher_data_helper.dart';
import 'student_progress_screen.dart';
import 'teacher_manage_content_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final VoidCallback? onLogout;
  final Function(bool)? onToggleTheme;
  final Function(double)? onChangeFontScale;

  const TeacherDashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    this.onLogout,
    this.onToggleTheme,
    this.onChangeFontScale,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0;
  String _teacherName = 'Ibu Guru';
  String _teacherEmail = 'teacher@structora.app';
  String? _customProfileImage;

  late bool _isDark;
  late double _fontScale;

  List<dynamic> _studentList = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
    _fontScale = widget.fontScale;
    _loadTeacherAndStudentData();

    // Hubungkan listener bahasa global
    LanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant TeacherDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() => _isDark = widget.isDarkMode);
    }
    if (oldWidget.fontScale != widget.fontScale) {
      setState(() => _fontScale = widget.fontScale);
    }
  }

  Future<void> _loadTeacherAndStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? 'Ibu Guru';
    final email = prefs.getString('userEmail') ?? 'teacher@structora.app';
    final img = prefs.getString('teacherCustomImage');

    final students = await TeacherDataHelper.getRealStudentList();

    if (!mounted) return;
    setState(() {
      _teacherName = name;
      _teacherEmail = email;
      _customProfileImage = img;
      _studentList = students;
      _isLoadingData = false;
    });
  }

  Future<void> _updateTheme(bool val, StateSetter? setModalState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', val);

    setState(() {
      _isDark = val;
    });

    if (setModalState != null) {
      setModalState(() {});
    }

    widget.onToggleTheme?.call(val);
  }

  Future<void> _updateFontScale(double val, StateSetter? setModalState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', val);

    setState(() {
      _fontScale = val;
    });

    if (setModalState != null) {
      setModalState(() {});
    }

    widget.onChangeFontScale?.call(val);
  }

  Future<void> _pickImage(StateSetter setModalState) async {
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
        await prefs.setString('teacherCustomImage', base64Image);

        if (!mounted) return;
        setState(() {
          _customProfileImage = base64Image;
        });
        setModalState(() {});
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isTeacher', false);
    await prefs.remove('userRole');

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(
          isDarkMode: true,
          onLoginSuccess: _dummyOnLoginSuccess,
        ),
      ),
      (route) => false,
    );
  }

  static void _dummyOnLoginSuccess(String name, String email, bool isTeacher) {}

  void _openProfileSettingsSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              final sheetBg = _isDark ? const Color(0xFF0D1527) : Colors.white;
              final textColor =
              _isDark ? Colors.white : const Color(0xFF0F172A);
              final subTextColor =
              _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
              const accentCyan = Color(0xFF00F0FF);
              final bool isEn = LanguageController.instance.isEnglish;

              return Scaffold(
                backgroundColor: sheetBg,
                body: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 18),
                    children: [
                      // 1. Header: Judul & Tombol Silang (X)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppText.tr('profile_settings'),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: textColor, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 2. Foto Profil bundar berbingkai + badge kamera
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentCyan.withValues(alpha: 0.5),
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                accentCyan.withValues(alpha: 0.15),
                                backgroundImage: _customProfileImage != null
                                    ? MemoryImage(base64Decode(
                                    _customProfileImage!))
                                    : null,
                                child: _customProfileImage == null
                                    ? const Icon(Icons.person,
                                    size: 52, color: accentCyan)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => _pickImage(setModalState),
                                borderRadius: BorderRadius.circular(20),
                                child: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: accentCyan,
                                  child: Icon(Icons.camera_alt,
                                      size: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Nama & Email
                      Center(
                        child: Text(
                          _teacherName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          _teacherEmail,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: subTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. Bahasa Aplikasi (Menggunakan LanguageController bawaan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.translate_rounded,
                                  color: accentCyan, size: 22),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppText.tr('app_language'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    AppText.tr('app_language_active'),
                                    style: TextStyle(
                                        fontSize: 11.5, color: subTextColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () async {
                              await LanguageController.instance.toggleLanguage();
                              setModalState(() {});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: accentCyan.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                isEn ? 'EN ⇄ ID' : 'ID ⇄ EN',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accentCyan,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 5. Mode Gelap Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppText.tr('dark_mode'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _isDark
                                    ? AppText.tr('dark_mode_active')
                                    : AppText.tr('light_mode_active'),
                                style: TextStyle(
                                    fontSize: 11.5, color: subTextColor),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isDark,
                            activeThumbColor: Colors.black,
                            activeTrackColor: accentCyan,
                            onChanged: (val) => _updateTheme(val, setModalState),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 6. Slider Ukuran Font + Persentase
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppText.tr('font_size'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${(_fontScale * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: accentCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accentCyan,
                          thumbColor: accentCyan,
                          inactiveTrackColor: accentCyan.withValues(alpha: 0.2),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _fontScale,
                          min: 0.85,
                          max: 1.25,
                          divisions: 4,
                          onChanged: (val) =>
                              _updateFontScale(val, setModalState),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 8. Keluar Akun
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded,
                                color: Color(0xFFE11D48), size: 22),
                            const SizedBox(width: 14),
                            Text(
                              AppText.tr('logout'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildScoreBadge(
    String label,
    String value,
    Color color,
    Color textColor,
    Color subTextColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: subTextColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
    _isDark ? const Color(0xFF060913) : const Color(0xFFF1F5F9);
    final cardBg = _isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor =
    _isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
    _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
    _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF00F0FF);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontScale),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                AppText.tr('teacher_portal'),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
            ],
          ),
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : IndexedStack(
          index: _currentIndex,
          children: [
            // TAB 0: BERANDA / RINGKASAN KELAS
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.tr('welcome_back'),
                          style: TextStyle(
                              fontSize: 12, color: subTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(_teacherName,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text(_teacherEmail,
                            style: const TextStyle(
                                fontSize: 11,
                                color: accentColor,
                                fontFamily: 'monospace')),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  size: 14, color: Colors.orangeAccent),
                              const SizedBox(width: 6),
                              Text(
                                AppText.tr('teacher_mode_active'),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppText.tr('stats_summary'),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            AppText.tr('active_students'),
                            '${_studentList.length}',
                            Icons.group_rounded,
                            Colors.blue,
                            cardBg,
                            textColor,
                            subTextColor,
                            borderColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                            AppText.tr('lms_status'),
                            AppText.tr('status_active'),
                            Icons.cloud_done_rounded,
                            Colors.green,
                            cardBg,
                            textColor,
                            subTextColor,
                            borderColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // TAB 1: PROGRES & NILAI SISWA RIIL
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppText.tr('student_list_title'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppText.tr('student_list_subtitle'),
                            style: TextStyle(
                                fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: accentColor),
                        tooltip: AppText.tr('reload_data'),
                        onPressed: _loadTeacherAndStudentData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: FirebaseService.streamStudentProgressList(),
                        builder: (context, snapshot) {
                          final List students = (snapshot.hasData && snapshot.data!.isNotEmpty)
                              ? snapshot.data!
                              : _studentList;

                          if (students.isEmpty) {
                            return Center(
                              child: Text(
                                AppText.tr('no_student_data'),
                                style: TextStyle(
                                    color: subTextColor, fontSize: 13),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: students.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final student = students[index]
                              as Map<String, dynamic>;
                              final String status =
                                  student['status'] ?? 'Belum Ujian';
                              final bool isTuntas = status.toLowerCase().contains('tuntas') || status.toLowerCase().contains('completed');
                              final bool isEn = LanguageController.instance.isEnglish;
                              final String displayStatus = isEn
                                  ? (isTuntas ? 'Completed' : 'Not Tested')
                                  : (isTuntas ? 'Tuntas' : 'Belum Ujian');

                              final String pre = student['preTest'] ?? '-';
                              final String a1 = student['assessment1'] ?? '-';
                              final String a2 = student['assessment2'] ?? '-';
                              final String a3 = student['assessment3'] ?? '-';
                              final String a4 = student['assessment4'] ?? '-';
                              final String post = student['postTest'] ?? '-';

                              List<String> finishedAses = [];
                              if (a1 != '-') finishedAses.add(a1);
                              if (a2 != '-') finishedAses.add(a2);
                              if (a3 != '-') finishedAses.add(a3);
                              if (a4 != '-') finishedAses.add(a4);

                              final String asesmenSummary = finishedAses.isEmpty
                                  ? '-'
                                  : finishedAses.join(', ');

                              return Card(
                                elevation: 0,
                                color: cardBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: borderColor),
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentDetailScreen(
                                                studentData: student),
                                      ),
                                    ).then((_) =>
                                        _loadTeacherAndStudentData());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: accentColor
                                                  .withValues(alpha: 0.15),
                                              child: Text('${index + 1}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: accentColor,
                                                      fontSize: 11)),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student['name'] ??
                                                        (isEn ? 'Unnamed Student' : 'Tanpa Nama'),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: textColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    student['email'] ?? '-',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: subTextColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isTuntas
                                                    ? Colors.green
                                                        .withValues(alpha: 0.15)
                                                    : Colors.orange
                                                        .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isTuntas
                                                      ? Colors.green
                                                          .withValues(alpha: 0.4)
                                                      : Colors.orange
                                                          .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                displayStatus,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isTuntas
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Divider(height: 1, color: borderColor),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _buildScoreBadge('Pre-Test', pre, const Color(0xFF0284C7), textColor, subTextColor),
                                            const SizedBox(width: 6),
                                            _buildScoreBadge('Asesmen Modul', asesmenSummary, const Color(0xFFD97706), textColor, subTextColor),
                                            const SizedBox(width: 6),
                                            _buildScoreBadge('Post-Test', post, const Color(0xFF8B5CF6), textColor, subTextColor),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TAB 2: FITUR UPLOAD & KELOLA MATERI (LMS)
            TeacherManageContentScreen(isDarkMode: _isDark),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 3) {
              _openProfileSettingsSheet();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          backgroundColor: cardBg,
          selectedItemColor: accentColor,
          unselectedItemColor: subTextColor,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: AppText.tr('teacher_nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_alt_rounded),
              label: AppText.tr('teacher_nav_progress'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.upload_file_rounded),
              label: AppText.tr('teacher_nav_upload'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: AppText.tr('teacher_nav_profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color iconColor,
      Color cardBg,
      Color textColor,
      Color subTextColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: subTextColor)),
        ],
      ),
    );
  }
}