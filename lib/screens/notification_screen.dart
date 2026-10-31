import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class NotificationScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Mengecek langsung bahasa yang aktif
    final isEn = LanguageController.instance.isEnglish;

    final bgColor = isDarkMode ? const Color(0xFF060913) : const Color(0xFFF1F5F9);
    final cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final cleanName = userName.trim().isEmpty
        ? (isEn ? 'Student' : 'Siswa')
        : userName.trim();

    // Daftar Notifikasi dengan teks bilingual dinamis
    final List<Map<String, dynamic>> notifications = [
      {
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
      },
      if (!isPreTestCompleted)
        {
          'title': isEn
              ? 'First Step: Pre-Test Awaits You ✍️'
              : 'Langkah Awal: Pre-Test Menunggumu ✍️',
          'message': isEn
              ? 'Module materials are still locked. Complete the Pre-Test first so the system can unlock your learning path.'
              : 'Materi modul masih terkunci. Kerjakan Pre-Test terlebih dahulu agar sistem dapat membuka jalur belajarmu.',
          'tag': isEn ? 'Required' : 'Wajib',
          'tagColor': const Color(0xFFF59E0B),
          'icon': Icons.warning_amber_rounded,
          'iconColor': const Color(0xFFF59E0B),
        }
      else
        {
          'title': isEn
              ? 'Pre-Test Completed ✅'
              : 'Pre-Test Selesai ✅',
          'message': isEn
              ? 'Great job completing the Pre-Test! Continue your learning through the sequential modules.'
              : 'Hebat, kamu sudah menyelesaikan Pre-Test! Lanjutkan perjalanan belajarmu melalui modul materi.',
          'tag': isEn ? 'Completed' : 'Tuntas',
          'tagColor': Colors.green,
          'icon': Icons.task_alt_rounded,
          'iconColor': Colors.green,
        },
      {
        'title': isEn
            ? 'Concept Exploration Tip 💡'
            : 'Tips Eksplorasi Konsep 💡',
        'message': isEn
            ? 'Use the 3D Lab Simulation to visualize how nodes link together in Linked Lists or how element stacks operate in a Stack.'
            : 'Gunakan fitur Simulasi Lab 3D untuk memvisualisasikan bagaimana Node saling terhubung pada Linked List atau cara tumpukan elemen pada Stack bekerja.',
        'tag': isEn ? 'Education' : 'Edukasi',
        'tagColor': const Color(0xFFF59E0B),
        'icon': Icons.lightbulb_outline_rounded,
        'iconColor': const Color(0xFFF59E0B),
      },
      if (completedPoints > 0)
        {
          'title': isEn
              ? 'Learning Progress Update 📈'
              : 'Progres Belajar Terkini 📈',
          'message': isEn
              ? 'You have completed $completedPoints of $totalPoints learning milestones. Keep up the great work!'
              : 'Kamu telah menyelesaikan $completedPoints dari $totalPoints langkah pembelajaran. Terus tingkatkan!',
          'tag': isEn ? 'Progress' : 'Progres',
          'tagColor': const Color(0xFF8B5CF6),
          'icon': Icons.trending_up_rounded,
          'iconColor': const Color(0xFF8B5CF6),
        },
    ];

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontScale),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = notifications[index];
            final Color tagColor = item['tagColor'] as Color;
            final Color iconColor = item['iconColor'] as Color;

            return Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text(
                              item['tag'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tagColor,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}