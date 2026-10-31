import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class AppTutorialDialog extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onFinish;

  const AppTutorialDialog({
    super.key,
    required this.isDarkMode,
    required this.onFinish,
  });

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;

    final List<Map<String, dynamic>> features = [
      {
        'tag': isEn ? 'FEATURE 1' : 'FITUR 1',
        'title': isEn ? 'Interactive Modules & Video 📚' : 'Modul Interaktif & Video 📚',
        'desc': isEn
            ? 'Learn data structure concepts from Linked Lists to Sorting. Includes real-life analogies and animated video concepts for effortless understanding.'
            : 'Pelajari konsep struktur data mulai dari Linked List hingga Sorting. Dilengkapi analogi kehidupan nyata serta video animasi konsep agar materi mudah dipahami.',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF00F0FF),
      },
      {
        'tag': isEn ? 'FEATURE 2' : 'FITUR 2',
        'title': isEn ? 'Virtual 3D Lab Simulation 🧪' : 'Simulasi Lab 3D Virtual 🧪',
        'desc': isEn
            ? 'Interactive 3D visualization feature on the bottom nav tab. Experiment with dynamic pointers, Stack LIFO, and Queue FIFO in real time.'
            : 'Fitur visualisasi interaktif di tab navigasi bawah. Kamu dapat bereksperimen melihat jalannya pointer, tumpukan LIFO pada Stack, dan antrean FIFO pada Queue secara langsung.',
        'icon': Icons.science_outlined,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'tag': isEn ? 'FEATURE 3' : 'FITUR 3',
        'title': isEn ? 'Assessment & Standard KKM 80 🔒' : 'Asesmen & Standar KKM 80 🔒',
        'desc': isEn
            ? 'Test your understanding on each module. Assessments enforce sequential unlocking, and you must score at least 80 to unlock the next module.'
            : 'Uji pemahamanmu pada setiap modul. Asesmen menerapkan sistem terkunci berurutan dan kamu wajib meraih nilai KKM minimal 80 untuk membuka modul berikutnya.',
        'icon': Icons.security_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'tag': isEn ? 'FEATURE 4' : 'FITUR 4',
        'title': isEn ? 'Evaluation Score Dashboard 📊' : 'Dashboard Evaluasi Nilai 📊',
        'desc': isEn
            ? 'Track your score progression graph on the Evaluation tab. Compare initial Pre-Test scores with module assessments and final Post-Test graduation.'
            : 'Pantau grafik perkembangan belajarmu di tab Evaluasi. Bandingkan skor Pre-Test awal dengan capaian asesmen hingga kelulusan Post-Test akhir.',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF10B981),
      },
    ];

    final bgColor = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final currentItem = features[_currentPage];
    final Color activeColor = currentItem['color'] as Color;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: widget.isDarkMode
              ? activeColor.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Dialog
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentItem['tag'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: activeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Feature Overview' : 'Pengenalan Fitur',
                      style: TextStyle(
                        fontSize: 11,
                        color: subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_currentPage + 1} / ${features.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Konten Slide PageView
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: features.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final item = features[idx];
                  final col = item['color'] as Color;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: col.withValues(alpha: 0.15),
                        child: Icon(item['icon'] as IconData, size: 36, color: col),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Indikator Titik (Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(features.length, (idx) {
                final isCurrent = idx == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent ? activeColor : subTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Tombol Navigasi / Lewati
            Row(
              children: [
                if (_currentPage < features.length - 1)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onFinish();
                      },
                      child: Text(
                        isEn ? 'Skip' : 'Lewati',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < features.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                        widget.onFinish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == features.length - 1
                          ? (isEn ? 'Start Exploring! 🚀' : 'Mulai Eksplorasi! 🚀')
                          : (isEn ? 'Next ➔' : 'Lanjut ➔'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}