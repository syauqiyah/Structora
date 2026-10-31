import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/materi_data.dart';
import '../utils/app_translations.dart';

class LearningProgressChart extends StatelessWidget {
  final bool isDarkMode;
  final Set<String> completedSteps;
  final Map<String, int> moduleScores;

  const LearningProgressChart({
    super.key,
    required this.isDarkMode,
    required this.completedSteps,
    required this.moduleScores,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;
    final cardBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    const colorMateri = Color(0xFF00F0FF); // Cyan
    const colorVideo = Color(0xFFA855F7);  // Ungu
    const colorKkmLine = Color(0xFFEF4444); // Garis KKM 80

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEn ? 'Learning Progress per Module' : 'Grafik Capaian Belajar per Modul',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorKkmLine.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isEn ? 'Passing Standard: 80' : 'Batas KKM: 80',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorKkmLine,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legenda Warna (Dwibahasa)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(
                isEn ? 'Material (Read)' : 'Materi (Baca)',
                colorMateri,
                textColor,
              ),
              _buildLegendItem(
                isEn ? 'Video (Watched)' : 'Video (Tonton)',
                colorVideo,
                textColor,
              ),
              _buildLegendItem(
                isEn ? 'Quiz Passed (≥80)' : 'Kuis Lulus (≥80)',
                const Color(0xFF10B981),
                textColor,
              ),
              _buildLegendItem(
                isEn ? 'Quiz Below Standard' : 'Kuis Belum KKM',
                const Color(0xFFF59E0B),
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Area Chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String category = '';
                      if (rodIndex == 0) category = isEn ? 'Read Material' : 'Baca Materi';
                      if (rodIndex == 1) category = isEn ? 'Simulation Video' : 'Video Simulasi';
                      if (rodIndex == 2) category = isEn ? 'Assessment Score' : 'Skor Asesmen';

                      return BarTooltipItem(
                        '$category\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 9.5, color: subTextColor),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= listModulMateri.length) {
                          return const SizedBox.shrink();
                        }
                        final labels = ['Linked', 'Stack', 'Queue', 'Sort/Srch'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    if (value == 80) {
                      return FlLine(
                        color: colorKkmLine.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                      );
                    }
                    return FlLine(
                      color: borderColor.withValues(alpha: 0.5),
                      strokeWidth: 0.8,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(listModulMateri.length, (idx) {
                  final mId = listModulMateri[idx]['id'];

                  final bool readDone = completedSteps.contains('${mId}_penjelasan');
                  final bool videoDone = completedSteps.contains('${mId}_video');
                  final int quizScore = moduleScores[mId] ?? 0;

                  final double materiVal = readDone ? 100.0 : 0.0;
                  final double videoVal = videoDone ? 100.0 : 0.0;
                  final double quizVal = quizScore.toDouble();

                  final Color colorQuizBar = quizVal >= 80
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B);

                  return BarChartGroupData(
                    x: idx,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: materiVal,
                        color: colorMateri,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: videoVal,
                        color: colorVideo,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      BarChartRodData(
                        toY: quizVal,
                        color: colorQuizBar,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}