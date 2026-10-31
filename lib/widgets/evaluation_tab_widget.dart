import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/materi_data.dart';
import '../data/quiz_data.dart';
import '../utils/app_translations.dart';
import 'learning_progress_chart.dart';

class EvaluationTabWidget extends StatefulWidget {
  final bool isDarkMode;
  final bool isPreTestCompleted;
  final int preTestScore;
  final bool isPostTestCompleted;
  final int postTestScore;
  final Set<String> completedSteps;
  final bool Function(int) isModuleUnlocked;
  final double Function(String) getModuleProgressRatio;

  const EvaluationTabWidget({
    super.key,
    required this.isDarkMode,
    required this.isPreTestCompleted,
    required this.preTestScore,
    required this.isPostTestCompleted,
    required this.postTestScore,
    required this.completedSteps,
    required this.isModuleUnlocked,
    required this.getModuleProgressRatio,
  });

  @override
  State<EvaluationTabWidget> createState() => _EvaluationTabWidgetState();
}

class _EvaluationTabWidgetState extends State<EvaluationTabWidget> {
  Map<String, int> _moduleScores = {};
  Map<String, int> _postTestDiagnostics = {};

  @override
  void initState() {
    super.initState();
    _loadEvaluationData();
  }

  Future<void> _loadEvaluationData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> scores = {};
    for (var m in listModulMateri) {
      final mId = m['id'];
      scores[mId] = prefs.getInt('score_$mId') ?? 0;
    }

    final diagRaw = prefs.getString('posttest_wrong_diagnostics');
    Map<String, int> diagnostics = {};
    if (diagRaw != null) {
      final decoded = jsonDecode(diagRaw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        diagnostics[key] = value as int;
      });
    }

    if (mounted) {
      setState(() {
        _moduleScores = scores;
        _postTestDiagnostics = diagnostics;
      });
    }
  }

  void _showReviewDialog(
      BuildContext context, String quizType, String title) async {
    final isEn = LanguageController.instance.isEnglish;
    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final boxInnerBg =
    widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
    widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor =
    widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final accentColor =
    widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);

    final prefs = await SharedPreferences.getInstance();
    final rawAnswers = prefs.getString('answers_$quizType');

    if (rawAnswers == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'No quiz attempt history found for this test.'
              : 'Belum ada riwayat pengerjaan untuk tes ini.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Map<String, dynamic> userAnswers = jsonDecode(rawAnswers);

    final rawShuffledQuestions =
    prefs.getString('shuffled_questions_$quizType');
    final List<dynamic> questions = rawShuffledQuestions != null
        ? jsonDecode(rawShuffledQuestions)
        : getQuestionsForType(quizType);

    const prefixes = ['A', 'B', 'C', 'D', 'E'];

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEn ? 'Discussion: $title' : 'Pembahasan: $title',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Divider(color: borderColor),
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, qIdx) {
                      final q = Map<String, dynamic>.from(questions[qIdx]);
                      final int? chosen = userAnswers[qIdx.toString()];
                      final int correct = q['answer'];
                      final bool isCorrect = chosen == correct;
                      final options = q.getLocalizedOptions(isEn);
                      final String explanation = q.getLocalizedExplanation(isEn);
                      final String questionText = q.getLocalizedQuestion(isEn);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: boxInnerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  size: 18,
                                  color: isCorrect
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${qIdx + 1}. $questionText',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(options.length, (optIdx) {
                              final isUserChoice = chosen == optIdx;
                              final isKeyAnswer = correct == optIdx;

                              Color optColor = subTextColor;
                              FontWeight optWeight = FontWeight.normal;
                              String note = '';

                              if (isKeyAnswer) {
                                optColor = Colors.green;
                                optWeight = FontWeight.bold;
                                note = isEn
                                    ? ' ✓ (Answer Key)'
                                    : ' ✓ (Kunci Jawaban)';
                              }
                              if (isUserChoice && !isCorrect) {
                                optColor = Colors.redAccent;
                                optWeight = FontWeight.bold;
                                note = isEn
                                    ? ' ✗ (Your Answer)'
                                    : ' ✗ (Jawaban Kamu)';
                              } else if (isUserChoice && isCorrect) {
                                note = isEn
                                    ? ' (Your Answer - Correct)'
                                    : ' (Jawaban Kamu - Benar)';
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  '${prefixes[optIdx]}. ${options[optIdx]}$note',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: optColor,
                                    fontWeight: optWeight,
                                  ),
                                ),
                              );
                            }),
                            if (explanation.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 14,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: textColor,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: isEn
                                                  ? 'Explanation: '
                                                  : 'Pembahasan: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: accentColor,
                                              ),
                                            ),
                                            TextSpan(text: explanation),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;
    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
    widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final borderColor =
    widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final accentColor =
    widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);

    final int scoreDiff = widget.postTestScore - widget.preTestScore;

    // Menentukan Status & Badge Kelulusan berdasarkan KKM 80
    String badgeTitle = isEn ? 'Not Yet Graduated' : 'Belum Lulus';
    String badgeDesc = isEn
        ? 'Complete all learning modules and score at least 80 on the Post-Test.'
        : 'Selesaikan seluruh materi modul dan capai nilai minimal 80 pada Post-Test.';
    Color badgeColor = subTextColor;
    IconData badgeIcon = Icons.hourglass_empty;

    if (widget.isPostTestCompleted) {
      if (widget.postTestScore >= 90) {
        badgeTitle = isEn
            ? 'Outstanding Mastery (Score ≥ 90)'
            : 'Sangat Memuaskan (Mastery)';
        badgeDesc = isEn
            ? 'Phenomenal! Your understanding of data structures is exceptionally comprehensive.'
            : 'Luar biasa! Pemahaman konsep struktur data kamu telah sangat tuntas.';
        badgeColor = const Color(0xFF10B981);
        badgeIcon = Icons.emoji_events;
      } else if (widget.postTestScore >= 80) {
        badgeTitle = isEn
            ? 'Competent (Passed Standard 80)'
            : 'Kompeten (Lulus KKM)';
        badgeDesc = isEn
            ? 'Congratulations! You achieved the academic passing standard (KKM 80).'
            : 'Selamat! Kamu telah mencapai standar kompetensi kelulusan (KKM 80).';
        badgeColor = const Color(0xFF0284C7);
        badgeIcon = Icons.verified;
      } else {
        badgeTitle = isEn
            ? 'Needs Remedial (Below 80)'
            : 'Perlu Remedial (Belum Capai KKM 80)';
        badgeDesc = isEn
            ? 'Your score is below 80. Review the suggested modules below.'
            : 'Skor kamu belum memenuhi KKM 80. Pelajari materi yang disarankan di bawah.';
        badgeColor = const Color(0xFFD97706);
        badgeIcon = Icons.school;
      }
    }

    // Ekstraksi Materi Terlemah dari Hasil Post-Test
    List<MapEntry<String, int>> weakModules = [];
    if (widget.isPostTestCompleted &&
        widget.postTestScore < 80 &&
        _postTestDiagnostics.isNotEmpty) {
      weakModules = _postTestDiagnostics.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn ? 'Evaluation & Diagnostics' : 'Evaluasi & Diagnostik Belajar',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Track score progress, knowledge gains, and personalized study diagnostics:'
              : 'Pantau hasil belajar, selisih peningkatan, dan catatan evaluasi materi kamu:',
          style: TextStyle(fontSize: 11, color: subTextColor),
        ),
        const SizedBox(height: 16),

        // 1. KARTU PERBANDINGAN NILAI (PRE-TEST VS POST-TEST DENGAN GAIN SCORE)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreTile(
                      'Pre-Test',
                      widget.isPreTestCompleted
                          ? '${widget.preTestScore}'
                          : (isEn ? 'Pending' : 'Belum'),
                      const Color(0xFFD97706),
                      subTextColor),
                  Column(
                    children: [
                      Icon(Icons.trending_up,
                          color: widget.isPostTestCompleted
                              ? Colors.green
                              : subTextColor,
                          size: 28),
                      const SizedBox(height: 2),
                      if (widget.isPostTestCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (scoreDiff >= 0
                                ? Colors.green
                                : Colors.redAccent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scoreDiff >= 0
                                ? (isEn ? '+$scoreDiff Pts' : '+$scoreDiff Poin')
                                : (isEn ? '$scoreDiff Pts' : '$scoreDiff Poin'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scoreDiff >= 0
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                        )
                      else
                        Text(isEn ? 'Progress' : 'Progress',
                            style: TextStyle(
                                fontSize: 10, color: subTextColor)),
                    ],
                  ),
                  _scoreTile(
                      'Post-Test',
                      widget.isPostTestCompleted
                          ? '${widget.postTestScore}'
                          : (isEn ? 'Locked' : 'Terkunci'),
                      const Color(0xFFE11D48),
                      subTextColor),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),

              // 2. BADGE STATUS KELULUSAN
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: badgeColor.withValues(alpha: 0.15),
                    child: Icon(badgeIcon, size: 20, color: badgeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgeTitle,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: badgeColor),
                        ),
                        Text(
                          badgeDesc,
                          style: TextStyle(
                              fontSize: 10.5, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. KOTAK DIAGNOSTIK KELEMAHAN
              if (weakModules.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            isEn
                                ? 'Diagnostic Note: Topics Needing Revision'
                                : 'Catatan Evaluasi: Topik yang Perlu Kamu Pelajari Ulang',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'Based on Post-Test analysis, the most incorrect answers occurred in:'
                            : 'Berdasarkan Post-Test, kamu paling banyak melakukan kesalahan pada materi berikut:',
                        style: TextStyle(fontSize: 10.5, color: subTextColor),
                      ),
                      const SizedBox(height: 6),
                      ...weakModules.map((entry) {
                        String modTitle = entry.key;
                        if (entry.key == 'linkedlist') modTitle = 'Linked List';
                        if (entry.key == 'stack') modTitle = 'Stack';
                        if (entry.key == 'queue') modTitle = 'Queue';
                        if (entry.key == 'searching_sorting') {
                          modTitle = 'Searching & Sorting';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right,
                                  color: Colors.orange, size: 16),
                              Text(
                                '$modTitle ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                isEn
                                    ? '(${entry.value} mistakes)'
                                    : '(${entry.value} kesalahan)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Text(
                        isEn
                            ? '💡 Tip: Revisit the "Topics" tab or watch video tutorials before reattempting the Post-Test.'
                            : '💡 Saran: Buka kembali tab "Materi" atau tonton video animasinya sebelum mengulang ujian Post-Test.',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. WIDGET GRAFIK CAPAIAN BELAJAR LENGKAP
        LearningProgressChart(
          isDarkMode: widget.isDarkMode,
          completedSteps: widget.completedSteps,
          moduleScores: _moduleScores,
        ),
        const SizedBox(height: 24),

        // 5. DAFTAR REVIEW LEMBAR JAWABAN & PEMBAHASAN
        Text(
          isEn
              ? 'Answer Key & Discussion Review'
              : 'Review Lembar Jawaban & Pembahasan',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),

        // Pre-test
        _buildReviewRow(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: isEn
              ? 'Pre-Test: Initial Knowledge'
              : 'Pre-Test Kemampuan Awal',
          isDone: widget.isPreTestCompleted,
          isPassed: true,
          kkmTarget: 0,
          color: const Color(0xFFD97706),
          onTap: () => _showReviewDialog(
              context,
              'pretest',
              isEn ? 'Pre-Test: Initial Knowledge' : 'Pre-Test Kemampuan Awal'),
        ),

        // Asesmen Modul
        ...List.generate(listModulMateri.length, (idx) {
          final m = listModulMateri[idx];
          final String mId = m['id'];
          final int score = _moduleScores[mId] ?? 0;
          final bool isDone =
              widget.completedSteps.contains('${mId}_asesmen') || score > 0;
          final bool isPassed = score >= 80;
          final String moduleTitle = m.getLocalizedTitle(isEn);

          return _buildReviewRow(
            context: context,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            subTextColor: subTextColor,
            title: isEn ? 'Assessment: $moduleTitle' : 'Asesmen: $moduleTitle',
            isDone: isDone,
            isPassed: isPassed,
            kkmTarget: 80,
            score: score,
            color: m['color'],
            onTap: () => _showReviewDialog(
                context,
                'asesmen_$mId',
                isEn
                    ? 'Assessment: $moduleTitle'
                    : 'Asesmen: $moduleTitle'),
          );
        }),

        // Post-Test
        _buildReviewRow(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
          subTextColor: subTextColor,
          title: isEn
              ? 'Post-Test Final Assessment'
              : 'Post-Test Evaluasi Akhir',
          isDone: widget.isPostTestCompleted,
          isPassed: widget.postTestScore >= 80,
          kkmTarget: 80,
          score: widget.postTestScore,
          color: const Color(0xFFE11D48),
          onTap: () => _showReviewDialog(
              context,
              'posttest',
              isEn ? 'Post-Test Final Assessment' : 'Post-Test Evaluasi Akhir'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewRow({
    required BuildContext context,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    required String title,
    required bool isDone,
    required bool isPassed,
    required int kkmTarget,
    int? score,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isEn = LanguageController.instance.isEnglish;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDone
              ? (isPassed
              ? color.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.4))
              : borderColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isDone
                      ? (isPassed
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded)
                      : Icons.lock_clock,
                  size: 18,
                  color: isDone
                      ? (isPassed ? color : Colors.orange)
                      : subTextColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDone ? textColor : subTextColor,
                        ),
                      ),
                      if (isDone && score != null && kkmTarget > 0)
                        Text(
                          isPassed
                              ? (isEn
                              ? 'Score: $score (Passed standard $kkmTarget)'
                              : 'Skor: $score (Lulus KKM $kkmTarget)')
                              : (isEn
                              ? 'Score: $score (Below standard $kkmTarget)'
                              : 'Skor: $score (Belum Capai KKM $kkmTarget)'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPassed ? Colors.green : Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isDone && isPassed)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                isEn ? 'Review Discussion' : 'Lihat Jawaban',
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            )
          else if (isDone && !isPassed)
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? 'Reach score of at least $kkmTarget to unlock the discussion review!'
                          : 'Capai nilai minimal $kkmTarget untuk membuka lembar pembahasan jawaban!',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              child: Text(
                isEn ? 'Locked (< $kkmTarget)' : 'Terkunci (Belum KKM)',
                style:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(
              isEn ? 'Not Attempted' : 'Belum Dikerjakan',
              style: TextStyle(fontSize: 10.5, color: subTextColor),
            ),
        ],
      ),
    );
  }

  Widget _scoreTile(
      String label, String value, Color color, Color subTextColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: subTextColor)),
      ],
    );
  }
}