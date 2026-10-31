import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentDetailScreen({super.key, required this.studentData});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
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

  int _parseScore(dynamic val) {
    if (val == null || val == '-' || val.toString().trim().isEmpty) return -1;
    return int.tryParse(val.toString()) ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = LanguageController.instance.isEnglish;
    final studentData = widget.studentData;

    final String name = studentData['name'] ?? (isEn ? 'Unnamed Student' : 'Tanpa Nama');
    final String email = studentData['email'] ?? '-';
    final String preTest = studentData['preTest'] ?? '-';
    final String a1 = studentData['assessment1'] ?? '-';
    final String a2 = studentData['assessment2'] ?? '-';
    final String a3 = studentData['assessment3'] ?? '-';
    final String a4 = studentData['assessment4'] ?? '-';
    final String postTest = studentData['postTest'] ?? '-';

    // Status ketuntasan bilingual
    final String rawStatus = studentData['status'] ?? 'Belum Ujian';
    String displayStatus = rawStatus;
    if (isEn) {
      if (rawStatus.toLowerCase().contains('tuntas') || rawStatus.toLowerCase().contains('completed')) {
        displayStatus = 'Completed';
      } else {
        displayStatus = 'Not Tested';
      }
    } else {
      if (rawStatus.toLowerCase().contains('completed') || rawStatus.toLowerCase().contains('tuntas')) {
        displayStatus = 'Tuntas';
      } else {
        displayStatus = 'Belum Ujian';
      }
    }

    // Logika Analisis Skor Riil
    final bool isCompleted = postTest != '-';
    final int preVal = _parseScore(preTest);
    final int postVal = _parseScore(postTest);
    final bool isImproving = isCompleted && postVal >= preVal;

    // Evaluasi Asesmen mana yang perlu remedial (di bawah KKM 80)
    final List<String> weakModules = [];
    if (int.tryParse(a1) != null && int.parse(a1) < 80) {
      weakModules.add(isEn ? 'Module 1 (Linked List)' : 'Modul 1 (Linked List)');
    }
    if (int.tryParse(a2) != null && int.parse(a2) < 80) {
      weakModules.add(isEn ? 'Module 2 (Stack)' : 'Modul 2 (Stack)');
    }
    if (int.tryParse(a3) != null && int.parse(a3) < 80) {
      weakModules.add(isEn ? 'Module 3 (Queue)' : 'Modul 3 (Queue)');
    }
    if (int.tryParse(a4) != null && int.parse(a4) < 80) {
      weakModules.add(isEn ? 'Module 4 (Searching & Sorting)' : 'Modul 4 (Searching & Sorting)');
    }

    // Data Sumber Diagram Batang
    final chartData = [
      {'label': 'Pre-Test', 'score': _parseScore(preTest), 'color': const Color(0xFF00F0FF)},
      {'label': isEn ? 'Asses 1' : 'Ases 1', 'score': _parseScore(a1), 'color': const Color(0xFFD946EF)},
      {'label': isEn ? 'Asses 2' : 'Ases 2', 'score': _parseScore(a2), 'color': const Color(0xFFC084FC)},
      {'label': isEn ? 'Asses 3' : 'Ases 3', 'score': _parseScore(a3), 'color': const Color(0xFFA855F7)},
      {'label': isEn ? 'Asses 4' : 'Ases 4', 'score': _parseScore(a4), 'color': const Color(0xFF9333EA)},
      {'label': 'Post-Test', 'score': _parseScore(postTest), 'color': const Color(0xFF10B981)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      appBar: AppBar(
        title: Text(
          isEn ? 'Evaluation Details: $name' : 'Detail Evaluasi: $name',
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Profil Siswa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isCompleted ? Colors.green : Colors.orange),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grafik Perkembangan Nilai Siswa
            Text(
              isEn ? 'Student Score Progression Chart' : 'Grafik Perkembangan Nilai Siswa',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: chartData.map((item) {
                        final int score = item['score'] as int;
                        final bool hasDone = score >= 0;
                        final double barHeightRatio = hasDone ? (score / 100).clamp(0.06, 1.0) : 0.04;
                        final Color barColor = item['color'] as Color;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              hasDone ? '$score' : '-',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: hasDone ? barColor : Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 130 * barHeightRatio,
                              decoration: BoxDecoration(
                                color: hasDone
                                    ? barColor.withValues(alpha: 0.85)
                                    : Colors.white10,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                border: Border.all(
                                  color: hasDone ? barColor : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: chartData.map((item) {
                      return SizedBox(
                        width: 50,
                        child: Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Analisis Apa yang Bagus & Mana yang Kurang
            Text(
              isEn ? 'Comparative Analysis & Evaluation' : 'Analisis Perbandingan & Evaluasi',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isImproving ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: isImproving ? Colors.greenAccent : Colors.orangeAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isImproving
                            ? (isEn ? 'Good & Improving Performance' : 'Performa Baik & Meningkat')
                            : (isEn ? 'Assessment In Progress' : 'Proses Pengerjaan Berlangsung'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isImproving ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isImproving
                        ? (isEn
                        ? '• Strengths: Student shows an improvement trend from Pre-Test ($preTest) to Post-Test ($postTest).\nOverall concept mastery is thoroughly completed.'
                        : '• Yang Bagus: Siswa menunjukkan grafik peningkatan dari nilai Pre-Test ($preTest) menuju Post-Test ($postTest).\nPemahaman materi secara keseluruhan sudah tuntas dengan baik.')
                        : (isEn
                        ? '• Strengths: Student actively participates in early module exercises.\n• Notes: Subsequent modules and examinations are currently in progress.'
                        : '• Yang Bagus: Siswa aktif berpartisipasi dalam pengerjaan modul awal.\nCatatan: Modul dan ujian lanjutan sedang dalam proses.'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                  ),
                  if (weakModules.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      isEn
                          ? '• Areas for Improvement: Needs reinforcement/remedial on ${weakModules.join(", ")} as assessment score is below standard (Passing Grade: 80).'
                          : '• Bagian yang Kurang: Perlu penguatan/remedial pada ${weakModules.join(", ")} karena skor asesmen di bawah standar (KKM 80).',
                      style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KARTU REKOMENDASI MITIGASI & TINDAK LANJUT
            Text(
              isEn ? 'Teacher Mitigation & Follow-up Recommendations' : 'Rekomendasi Mitigasi & Tindak Lanjut Guru',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: weakModules.isNotEmpty
                      ? Colors.orangeAccent.withValues(alpha: 0.4)
                      : const Color(0xFF00F0FF).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        weakModules.isNotEmpty
                            ? Icons.healing_rounded
                            : Icons.lightbulb_outline_rounded,
                        color: weakModules.isNotEmpty ? Colors.orangeAccent : const Color(0xFF00F0FF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weakModules.isNotEmpty
                            ? (isEn ? 'Intervention & Remedial Steps' : 'Langkah Intervensi & Remedial')
                            : (isEn ? 'Learning Mentorship Guide' : 'Panduan Pendampingan Belajar'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: weakModules.isNotEmpty ? Colors.orangeAccent : const Color(0xFF00F0FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (weakModules.isNotEmpty) ...[
                    Text(
                      isEn
                          ? '1. Targeted Remedial Assignment: Student is advised to review algorithm simulation videos on ${weakModules.join(" and ")} before retaking the assessment.'
                          : '1. Penugasan Remedial Terarah: Siswa disarankan mengulas video simulasi algoritma pada ${weakModules.join(" serta ")} sebelum membuka asesmen ulang.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn
                          ? '2. Key Concept Consultation: The teacher can provide focused reinforcement on understanding pointers, node structures, or traversal logic.'
                          : '2. Konsultasi Konsep Kunci: Guru dapat memberikan penekanan khusus pada pemahaman pointer, struktur simpul (node), atau logika traversal.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                    ),
                  ] else if (!isCompleted) ...[
                    Text(
                      isEn
                          ? '1. Self-Paced Encouragement: Remind students through class announcements to complete subsequent modules sequentially.'
                          : '1. Dorongan Belajar Mandiri: Mengingatkan siswa melalui pengumuman kelas untuk melanjutkan modul berikutnya secara berurutan.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEn
                          ? '2. Progress Monitoring: Recheck student score progression once the next module assignments are submitted.'
                          : '2. Pemantauan Progres: Cek kembali perkembangan nilai siswa setelah modul berikutnya dikumpulkan.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                    ),
                  ] else ...[
                    Text(
                      isEn
                          ? '1. Material Enrichment: Student has completed all evaluations successfully. Provide advanced case studies to deepen data structure logic.'
                          : '1. Pengayaan Materi: Siswa telah menyelesaikan seluruh evaluasi dengan baik. Berikan materi studi kasus lanjutan untuk memperdalam logika struktur data.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}