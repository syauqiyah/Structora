import 'package:flutter/foundation.dart';
import '../utils/app_translations.dart';

class NotificationService {
  /// Mensinkronkan pengingat belajar dan ucapan selamat datang secara bilingual
  static Future<void> syncStudyReminder({required String studentName}) async {
    final isEn = LanguageController.instance.isEnglish;

    final title = isEn
        ? 'Welcome to Structora, $studentName! 🚀'
        : 'Selamat datang di Structora, $studentName! 🚀';

    final body = isEn
        ? 'Your study session is active. Let\'s master Data Structures today!'
        : 'Sesi belajarmu aktif. Mari kuasai Struktur Data hari ini!';

    if (kDebugMode) {
      debugPrint('[NotificationService] Synced: $title - $body');
    }
  }

  /// Trigger notifikasi saat kursus/post-test selesai dengan skor KKM bilingual
  static Future<void> triggerCourseCompletion({
    required String studentName,
    required int finalScore,
  }) async {
    final isEn = LanguageController.instance.isEnglish;

    final title = isEn
        ? 'Congratulations, $studentName! 🎉'
        : 'Selamat, $studentName! 🎉';

    final body = isEn
        ? 'You have successfully passed the final Post-Test with a score of $finalScore!'
        : 'Kamu telah berhasil lulus Post-Test akhir dengan perolehan skor $finalScore!';

    if (kDebugMode) {
      debugPrint('[NotificationService] Completion Triggered: $title - $body');
    }
  }
}