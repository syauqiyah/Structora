import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';
import 'teacher_content_helper.dart';

class TeacherNotificationScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final List<dynamic> studentList;

  const TeacherNotificationScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.studentList,
  });

  @override
  State<TeacherNotificationScreen> createState() =>
      _TeacherNotificationScreenState();
}

class _TeacherNotificationScreenState
    extends State<TeacherNotificationScreen> {
  String _selectedFilter = 'all'; // 'all', 'upload', 'warning', 'report'
  List<Map<String, dynamic>> _notifications = [];
  Set<String> _dismissedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
    LanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      _generateTeacherNotifications();
    }
  }

  Future<void> _loadNotificationData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDismissed = prefs.getStringList('dismissed_teacher_notif_ids') ?? [];
    _dismissedIds = savedDismissed.toSet();
    await _generateTeacherNotifications();
  }

  Future<void> _dismissSingleNotif(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedIds.add(id);
    });
    await prefs.setStringList('dismissed_teacher_notif_ids', _dismissedIds.toList());
  }

  Future<void> _clearAllNotifications(List<String> allIds) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedIds.addAll(allIds);
    });
    await prefs.setStringList('dismissed_teacher_notif_ids', _dismissedIds.toList());
  }

  void _showClearConfirmDialog(List<String> currentIds) {
    final bool isEn = LanguageController.instance.isEnglish;
    final cardBg =
        widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
        widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded,
                color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Clear Old Notifications?' : 'Bersihkan Notifikasi Lama?',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'This will remove old teacher notifications so they don\'t pile up.'
              : 'Semua notifikasi lama guru akan dibersihkan agar tidak menumpuk di pusat peringatan.',
          style: TextStyle(fontSize: 12.5, color: subTextColor, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'Batal',
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllNotifications(currentIds);
            },
            child: Text(
              isEn ? 'Clear All' : 'Hapus Semua',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTeacherNotifications() async {
    final bool isEn = LanguageController.instance.isEnglish;
    final List<Map<String, dynamic>> list = [];

    // =========================================================================
    // 1. NOTIFIKASI STATUS UPLOAD & PUBLIKASI MATERI/ASESMEN
    // =========================================================================
    try {
      final materiList = await TeacherContentHelper.getMateriList();
      for (var m in materiList) {
        final String mId = (m['id'] ?? 'm').toString().toLowerCase();
        final String notifId = 'upload_$mId';
        final String title = isEn
            ? (m['title_en'] ?? m['title'] ?? 'Module')
            : (m['title'] ?? 'Modul');
        final String modul = isEn
            ? (m['modul_en'] ?? m['modul'] ?? 'Session')
            : (m['modul'] ?? 'Sesi');
        final int qCount = (m['questions'] as List? ?? []).length;
        final int dur = int.tryParse((m['durationMinutes'] ?? 30).toString()) ?? 30;

        list.add({
          'id': notifId,
          'category': 'upload',
          'title': isEn
              ? 'Material & Assessment Published 🚀'
              : 'Materi & Asesmen Terpublikasi 🚀',
          'message': isEn
              ? 'Module "$title" ($modul) successfully uploaded & active with $qCount exam questions ($dur mins).'
              : 'Modul "$title" ($modul) berhasil ter-upload & aktif digunakan dengan $qCount butir soal ujian ($dur menit).',
          'tag': isEn ? 'Uploaded' : 'Ter-Upload',
          'tagColor': const Color(0xFF00F0FF),
          'icon': Icons.cloud_done_rounded,
          'iconColor': const Color(0xFF00F0FF),
          'timestamp': m['updatedAt'] ?? m['createdAt'] ?? 'Terbaru',
        });
      }
    } catch (_) {}

    // =========================================================================
    // 2. PERINGATAN DINI AKADEMIK (EARLY WARNING SYSTEM: REMEDIAL & PASIF)
    // =========================================================================
    final students = widget.studentList;

    int totalPre = 0;
    int countPre = 0;
    int totalPost = 0;
    int countPost = 0;
    int passedPost = 0;

    for (var s in students) {
      final String name = s['name'] ?? (isEn ? 'Student' : 'Siswa');
      final String email = s['email'] ?? '-';
      final String safeEmail = email.toLowerCase().replaceAll(RegExp(r'[^\w.-]'), '_');
      final String preStr = s['preTest'] ?? '-';
      final String postStr = s['postTest'] ?? '-';
      final String a1 = s['assessment1'] ?? '-';
      final String a2 = s['assessment2'] ?? '-';
      final String a3 = s['assessment3'] ?? '-';
      final String a4 = s['assessment4'] ?? '-';
      final int violations =
          int.tryParse((s['violations'] ?? s['violationCount'] ?? '0').toString()) ?? 0;

      // Hitung Statistik Kelas
      if (preStr != '-') {
        final p = int.tryParse(preStr);
        if (p != null) {
          totalPre += p;
          countPre++;
        }
      }
      if (postStr != '-') {
        final po = int.tryParse(postStr);
        if (po != null) {
          totalPost += po;
          countPost++;
          if (po >= 75) passedPost++;
        }
      }

      // Deteksi Pelanggaran Ujian
      if (violations > 0) {
        list.add({
          'id': 'violation_$safeEmail',
          'category': 'warning',
          'title': isEn
              ? 'Exam Violation Record 🚨'
              : 'Peringatan Pelanggaran Ujian 🚨',
          'message': isEn
              ? 'Student $name ($email) detected switching screens/apps $violations time(s) during exam.'
              : 'Siswa $name ($email) terdeteksi berpindah layar/keluar aplikasi sebanyak $violations kali saat ujian.',
          'tag': isEn ? 'Violation' : 'Pelanggaran',
          'tagColor': const Color(0xFFE11D48),
          'icon': Icons.warning_amber_rounded,
          'iconColor': const Color(0xFFE11D48),
          'timestamp': isEn ? 'Attention Required' : 'Perlu Perhatian',
        });
      }

      // Deteksi Remedial (< KKM 75)
      final List<String> weakModules = [];
      if (int.tryParse(a1) != null && int.parse(a1) < 75) {
        weakModules.add('Modul 1 ($a1)');
      }
      if (int.tryParse(a2) != null && int.parse(a2) < 75) {
        weakModules.add('Modul 2 ($a2)');
      }
      if (int.tryParse(a3) != null && int.parse(a3) < 75) {
        weakModules.add('Modul 3 ($a3)');
      }
      if (int.tryParse(a4) != null && int.parse(a4) < 75) {
        weakModules.add('Modul 4 ($a4)');
      }
      if (int.tryParse(postStr) != null && int.parse(postStr) < 75) {
        weakModules.add('Post-Test ($postStr)');
      }

      if (weakModules.isNotEmpty) {
        list.add({
          'id': 'remedial_$safeEmail',
          'category': 'warning',
          'title': isEn
              ? 'Academic Early Warning: Remedial Needed ⚠️'
              : 'Peringatan Dini Akademik: Remedial ⚠️',
          'message': isEn
              ? 'Student $name ($email) scores below KKM 75 in: ${weakModules.join(", ")}. Needs remedial guidance.'
              : 'Siswa $name ($email) butuh bimbingan remedial pada: ${weakModules.join(", ")} karena nilai di bawah KKM 75.',
          'tag': isEn ? 'Remedial' : 'Remedial',
          'tagColor': Colors.orangeAccent,
          'icon': Icons.report_problem_rounded,
          'iconColor': Colors.orangeAccent,
          'timestamp': isEn ? 'Academic Alert' : 'Peringatan Dini',
        });
      }

      // Deteksi Siswa Pasif
      if (preStr == '-' || s['status'] == 'Belum Ujian') {
        list.add({
          'id': 'passive_$safeEmail',
          'category': 'warning',
          'title': isEn
              ? 'Passive Student Detected ⏳'
              : 'Deteksi Siswa Pasif ⏳',
          'message': isEn
              ? 'Student $name ($email) has not started the Pre-Test or module assessments yet.'
              : 'Siswa $name ($email) terdeteksi belum mulai mengerjakan Pre-Test atau asesmen modul.',
          'tag': isEn ? 'Passive' : 'Siswa Pasif',
          'tagColor': const Color(0xFFF59E0B),
          'icon': Icons.hourglass_top_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'timestamp': isEn ? 'Follow Up Needed' : 'Perlu Dihubungi',
        });
      }
    }

    // =========================================================================
    // 3. RINGKASAN & LAPORAN BERKALA (PERIODIC ACADEMIC SUMMARY & REKAP DATA)
    // =========================================================================
    final double avgPre = countPre > 0 ? (totalPre / countPre) : 0.0;
    final double avgPost = countPost > 0 ? (totalPost / countPost) : 0.0;
    final double passRate = countPost > 0 ? ((passedPost / countPost) * 100) : 0.0;

    list.add({
      'id': 'report_class_summary',
      'category': 'report',
      'title': isEn
          ? 'Class Score Summary Report 📊'
          : 'Laporan Ringkasan Nilai Kelas 📊',
      'message': isEn
          ? 'Class Average: Pre-Test ${avgPre.toStringAsFixed(1)} | Post-Test ${avgPost.toStringAsFixed(1)}. $passedPost of ${students.length} students passed KKM 75 (${passRate.toStringAsFixed(0)}%).'
          : 'Rata-Rata Kelas: Pre-Test ${avgPre.toStringAsFixed(1)} | Post-Test ${avgPost.toStringAsFixed(1)}. Total $passedPost dari ${students.length} siswa telah lulus KKM 75 (${passRate.toStringAsFixed(0)}%).',
      'tag': isEn ? 'Class Summary' : 'Ringkasan Kelas',
      'tagColor': const Color(0xFF8B5CF6),
      'icon': Icons.analytics_rounded,
      'iconColor': const Color(0xFF8B5CF6),
      'timestamp': isEn ? 'Periodic Report' : 'Laporan Berkala',
    });

    list.add({
      'id': 'report_data_ready',
      'category': 'report',
      'title': isEn
          ? 'Evaluation Data Recap Readiness 📁'
          : 'Kesiapan Rekap Data Evaluasi 📁',
      'message': isEn
          ? 'Full evaluation records & Pre vs Post score progress charts are synchronized and ready for academic export.'
          : 'Seluruh rekap data evaluasi & grafik komparasi nilai Pre-Test vs Post-Test siswa telah tersinkronisasi dan siap direkap untuk laporan akademik.',
      'tag': isEn ? 'Data Ready' : 'Siap Rekap',
      'tagColor': Colors.greenAccent,
      'icon': Icons.folder_special_rounded,
      'iconColor': Colors.greenAccent,
      'timestamp': isEn ? 'System Ready' : 'Data Siap',
    });

    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;
    final bgColor =
        widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF1F5F9);
    final cardBg =
        widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
        widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor =
        widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF00F0FF);

    final filteredList = _notifications.where((n) {
      final String id = n['id'].toString();
      if (_dismissedIds.contains(id)) return false;
      if (_selectedFilter == 'all') return true;
      return n['category'] == _selectedFilter;
    }).toList();

    final List<String> activeCategoryIds = filteredList
        .map((n) => n['id'].toString())
        .toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(widget.fontScale),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEn
                ? 'Teacher Notifications & Early Warning'
                : 'Notifikasi & Peringatan Dini Guru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            if (activeCategoryIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent, size: 22),
                tooltip:
                    isEn ? 'Clear Old Notifications' : 'Hapus Notifikasi Lama',
                onPressed: () => _showClearConfirmDialog(activeCategoryIds),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : Column(
                children: [
                  // Filter Segment Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    color: cardBg,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            id: 'all',
                            label: isEn ? 'All Notifs' : 'Semua',
                            icon: Icons.notifications_rounded,
                            activeColor: accentColor,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            id: 'warning',
                            label: isEn
                                ? 'Early Warning System'
                                : 'Peringatan Dini Akademik',
                            icon: Icons.warning_amber_rounded,
                            activeColor: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            id: 'upload',
                            label: isEn ? 'Material Uploads' : 'Upload Materi',
                            icon: Icons.cloud_done_rounded,
                            activeColor: const Color(0xFF00F0FF),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            id: 'report',
                            label: isEn
                                ? 'Summary & Reports'
                                : 'Ringkasan & Laporan',
                            icon: Icons.analytics_rounded,
                            activeColor: const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.mark_email_read_rounded,
                                      size: 52, color: Color(0xFF00F0FF)),
                                  const SizedBox(height: 14),
                                  Text(
                                    isEn
                                        ? 'No notifications in this category'
                                        : 'Notifikasi lama telah dibersihkan',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEn
                                        ? 'New alerts will appear automatically when available.'
                                        : 'Pemberitahuan baru akan muncul secara otomatis.',
                                    style: TextStyle(
                                        color: subTextColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final String notifId = item['id'].toString();
                              final Color tagColor = item['tagColor'] as Color;
                              final Color iconColor =
                                  item['iconColor'] as Color;

                              return Dismissible(
                                key: Key(notifId),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _dismissSingleNotif(notifId),
                                background: Container(
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 24),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color:
                                              iconColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: tagColor.withValues(
                                                        alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                    border: Border.all(
                                                        color: tagColor.withValues(
                                                            alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    item['tag'].toString(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: tagColor,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  item['timestamp'].toString(),
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: subTextColor),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['title'].toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['message'].toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subTextColor,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            size: 16, color: subTextColor),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: isEn ? 'Dismiss' : 'Hapus',
                                        onPressed: () =>
                                            _dismissSingleNotif(notifId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isSelected = _selectedFilter == id;
    final borderColor = widget.isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () => setState(() => _selectedFilter = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (widget.isDarkMode ? Colors.white : activeColor)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
