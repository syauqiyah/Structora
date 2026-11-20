import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../teacher_mode/teacher_content_helper.dart';
import '../utils/app_translations.dart';

class NotificationScreen extends StatefulWidget {
  final bool isDarkMode;
  final double fontScale;
  final String userName;
  final bool isPreTestCompleted;
  final bool isPostTestCompleted;
  final int completedPoints;
  final int totalPoints;
  final Set<String> completedSteps;

  const NotificationScreen({
    super.key,
    required this.isDarkMode,
    required this.fontScale,
    required this.userName,
    required this.isPreTestCompleted,
    required this.isPostTestCompleted,
    required this.completedPoints,
    required this.totalPoints,
    required this.completedSteps,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _materiList = [];
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
    if (mounted) setState(() {});
  }

  Future<void> _loadNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = FirebaseService.getUserKey(
          widget.userName, 'dismissed_student_notif_ids');
      final savedDismissed = prefs.getStringList(userKey) ?? [];

      final list = await TeacherContentHelper.getMateriList();
      if (mounted) {
        setState(() {
          _dismissedIds = savedDismissed.toSet();
          _materiList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _dismissSingleNotif(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = FirebaseService.getUserKey(
        widget.userName, 'dismissed_student_notif_ids');
    setState(() {
      _dismissedIds.add(id);
    });
    await prefs.setStringList(userKey, _dismissedIds.toList());
  }

  Future<void> _clearAllNotifications(List<String> allIds) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = FirebaseService.getUserKey(
        widget.userName, 'dismissed_student_notif_ids');
    setState(() {
      _dismissedIds.addAll(allIds);
    });
    await prefs.setStringList(userKey, _dismissedIds.toList());
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
              ? 'This will remove old notifications so they don\'t pile up.'
              : 'Semua notifikasi lama akan dibersihkan agar tidak menumpuk di pusat notifikasi.',
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

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;

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

    final cleanName = widget.userName.trim().isEmpty
        ? (isEn ? 'Student' : 'Siswa')
        : widget.userName.trim();

    final List<Map<String, dynamic>> allNotifications = [];

    // =========================================================================
    // 1. NOTIFIKASI DINAMIS DARI GURU (PEMBERITAHUAN UPLOAD MATERI & ASESMEN)
    // =========================================================================
    for (var m in _materiList) {
      final String id = (m['id'] ?? '').toString().toLowerCase();
      if (id == 'pretest' || id == 'posttest') continue;

      final String notifId = 'materi_$id';
      final String title = isEn
          ? (m['title_en'] ?? m['title'] ?? 'Module')
          : (m['title'] ?? 'Modul');
      final String modul = isEn
          ? (m['modul_en'] ?? m['modul'] ?? 'Session')
          : (m['modul'] ?? 'Sesi');
      final int qCount = (m['questions'] as List? ?? []).length;
      final int dur = int.tryParse((m['durationMinutes'] ?? 30).toString()) ?? 30;

      allNotifications.add({
        'id': notifId,
        'title': isEn
            ? 'New Material & Assessment Published! 📚'
            : 'Materi & Asesmen Baru Diterbitkan! 📚',
        'message': isEn
            ? 'Teacher published/updated "$title" ($modul) with $qCount assessment questions ($dur mins). Study now!'
            : 'Guru telah menerbitkan/memperbarui modul "$title" ($modul) dengan $qCount butir soal ujian ($dur menit). Pelajari sekarang!',
        'tag': isEn ? 'New Material' : 'Materi Baru',
        'tagColor': const Color(0xFF00F0FF),
        'icon': Icons.menu_book_rounded,
        'iconColor': const Color(0xFF00F0FF),
      });
    }

    // =========================================================================
    // 2. NOTIFIKASI SESI & PROGRES SISWA
    // =========================================================================
    allNotifications.add({
      'id': 'session_login',
      'title': isEn
          ? 'Login Successful, Ready to Learn! 🚀'
          : 'Login Berhasil, Siap Belajar! 🚀',
      'message': isEn
          ? 'Welcome to Structora, $cleanName! Your study session is active and progress syncs automatically.'
          : 'Selamat datang di Structora, $cleanName! Sesi belajarmu aktif dan seluruh catatan progres tersinkronisasi otomatis.',
      'tag': isEn ? 'Active Session' : 'Sesi Aktif',
      'tagColor': const Color(0xFF00F0FF),
      'icon': Icons.check_circle_rounded,
      'iconColor': const Color(0xFF00F0FF),
    });

    if (!widget.isPreTestCompleted) {
      allNotifications.add({
        'id': 'pretest_pending',
        'title': isEn
            ? 'First Step: Pre-Test Awaits You ✍️'
            : 'Langkah Awal: Pre-Test Menunggumu ✍️',
        'message': isEn
            ? 'Module materials are locked. Complete the Pre-Test first so the system can unlock your learning path.'
            : 'Materi modul masih terkunci. Kerjakan Pre-Test terlebih dahulu agar sistem dapat membuka jalur belajarmu.',
        'tag': isEn ? 'Required' : 'Wajib',
        'tagColor': const Color(0xFFF59E0B),
        'icon': Icons.warning_amber_rounded,
        'iconColor': const Color(0xFFF59E0B),
      });
    } else {
      allNotifications.add({
        'id': 'pretest_done',
        'title': isEn ? 'Pre-Test Completed ✅' : 'Pre-Test Selesai ✅',
        'message': isEn
            ? 'Great job completing the Pre-Test! Continue your learning through the sequential modules.'
            : 'Hebat, kamu sudah menyelesaikan Pre-Test! Lanjutkan perjalanan belajarmu melalui modul materi.',
        'tag': isEn ? 'Completed' : 'Tuntas',
        'tagColor': Colors.green,
        'icon': Icons.task_alt_rounded,
        'iconColor': Colors.green,
      });
    }

    allNotifications.add({
      'id': 'concept_tip',
      'title': isEn ? 'Concept Exploration Tip 💡' : 'Tips Eksplorasi Konsep 💡',
      'message': isEn
          ? 'Use the 3D Lab Simulation to visualize how nodes link together in Linked Lists or how element stacks operate in a Stack.'
          : 'Gunakan fitur Simulasi Lab 3D untuk memvisualisasikan bagaimana Node saling terhubung pada Linked List atau cara tumpukan elemen pada Stack bekerja.',
      'tag': isEn ? 'Education' : 'Edukasi',
      'tagColor': const Color(0xFFF59E0B),
      'icon': Icons.lightbulb_outline_rounded,
      'iconColor': const Color(0xFFF59E0B),
    });

    if (widget.completedPoints > 0) {
      allNotifications.add({
        'id': 'progress_points',
        'title': isEn
            ? 'Learning Progress Update 📈'
            : 'Progres Belajar Terkini 📈',
        'message': isEn
            ? 'You have completed ${widget.completedPoints} of ${widget.totalPoints} learning milestones. Keep up the great work!'
            : 'Kamu telah menyelesaikan ${widget.completedPoints} dari ${widget.totalPoints} langkah pembelajaran. Terus tingkatkan!',
        'tag': isEn ? 'Progress' : 'Progres',
        'tagColor': const Color(0xFF8B5CF6),
        'icon': Icons.trending_up_rounded,
        'iconColor': const Color(0xFF8B5CF6),
      });
    }

    final activeNotifications = allNotifications
        .where((n) => !_dismissedIds.contains(n['id']))
        .toList();
    final List<String> activeIds =
        activeNotifications.map((n) => n['id'].toString()).toList();

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
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: textColor, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEn ? 'Notification & Reminder Hub' : 'Pusat Notifikasi & Pengingat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            if (activeNotifications.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent, size: 22),
                tooltip:
                    isEn ? 'Clear Old Notifications' : 'Hapus Notifikasi Lama',
                onPressed: () => _showClearConfirmDialog(activeIds),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
            : activeNotifications.isEmpty
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
                                ? 'No new notifications'
                                : 'Semua notifikasi lama telah dibersihkan',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEn
                                ? 'New updates will appear here when available.'
                                : 'Pemberitahuan baru akan otomatis muncul di sini.',
                            style:
                                TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    itemCount: activeNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = activeNotifications[index];
                      final String notifId = item['id'].toString();
                      final Color tagColor = item['tagColor'] as Color;
                      final Color iconColor = item['iconColor'] as Color;

                      return Dismissible(
                        key: Key(notifId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _dismissSingleNotif(notifId),
                        background: Container(
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 24),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: iconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color:
                                                tagColor.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: tagColor.withValues(
                                                    alpha: 0.3)),
                                          ),
                                          child: Text(
                                            item['tag'] as String,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: tagColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['message'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subTextColor,
                                        height: 1.45,
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
                                onPressed: () => _dismissSingleNotif(notifId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
