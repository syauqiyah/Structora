import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quiz_data.dart';
import '../services/notification_service.dart';
import '../teacher_mode/teacher_content_helper.dart';
import '../teacher_mode/teacher_data_helper.dart';
import '../utils/app_translations.dart';

class LockedQuizScreen extends StatefulWidget {
  final String quizType;
  final bool isDarkMode;
  final double fontScale;

  const LockedQuizScreen({
    super.key,
    required this.quizType,
    required this.isDarkMode,
    required this.fontScale,
  });

  @override
  State<LockedQuizScreen> createState() => _LockedQuizScreenState();
}

class _LockedQuizScreenState extends State<LockedQuizScreen>
    with WidgetsBindingObserver {
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};

  bool _isLoading = true;
  bool _isFinished = false;
  int _finalScore = 0;
  int _correctCount = 0;

  int _violationCount = 0;
  static const int _maxViolations = 3;

  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 menit

  Color get _scaffoldBg =>
      widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF1F5F9);
  Color get _cardBg =>
      widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  Color get _boxInnerBg =>
      widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
  Color get _textColor =>
      widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _subTextColor =>
      widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color get _borderColor =>
      widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  Color get _accentColor =>
      widget.isDarkMode ? const Color(0xFF00F0FF) : const Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndShuffleQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isFinished) {
        _handleAppSwitchViolation();
      }
    }
  }

  void _handleAppSwitchViolation() {
    setState(() {
      _violationCount++;
    });

    final isEn = LanguageController.instance.isEnglish;

    if (_violationCount >= _maxViolations) {
      _countdownTimer?.cancel();
      _finishQuiz(forcedByViolation: true);
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardBg,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 26),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Exam Violation!' : 'Peringatan Ujian!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
            ],
          ),
          content: Text(
            isEn
                ? 'Leaving or switching apps during locked exam is prohibited.\nViolation: $_violationCount of $_maxViolations.'
                : 'Dilarang keluar aplikasi atau berpindah layar saat ujian terkunci.\nPeringatan ke-$_violationCount dari maksimal $_maxViolations.',
            style: TextStyle(fontSize: 13, color: _subTextColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48)),
              child: Text(isEn ? 'Continue Exam' : 'Lanjutkan Ujian',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        _finishQuiz(forcedByTime: true);
      }
    });
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAndShuffleQuestions() async {
    List<dynamic> rawList = [];

    String targetId = widget.quizType;
    if (widget.quizType.startsWith('asesmen_')) {
      targetId = widget.quizType.replaceFirst('asesmen_', '');
    }

    // Mengambil bank soal dinamis guru untuk pretest, posttest, dan seluruh modul pertemuan
    final dynamicQuestions =
    await TeacherContentHelper.getQuestionsForModule(targetId);

    if (dynamicQuestions != null && dynamicQuestions.isNotEmpty) {
      rawList = dynamicQuestions.map((q) {
        final qMap = Map<String, dynamic>.from(q as Map);
        final List optionsList = (qMap['options'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        final List optionsEnList = (qMap['options_en'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        final String qIndo = (qMap['q'] ?? qMap['question'] ?? '').toString();
        final String qEng = (qMap['q_en'] ?? qMap['question_en'] ?? '').toString();

        final String finalQEn = qEng.isNotEmpty ? qEng : AppText.auto(qIndo);
        final List<String> finalOptsEn = optionsEnList.isNotEmpty
            ? optionsEnList.cast<String>()
            : optionsList.map((opt) => AppText.auto(opt.toString())).toList();

        final String expIndo = (qMap['explanation'] ?? 'Jawaban benar berdasarkan naskah materi yang disusun oleh guru.').toString();
        final String expEng = (qMap['explanation_en'] ?? 'Correct answer according to module material script.').toString();

        return {
          'moduleId': targetId,
          'question': qIndo,
          'question_en': finalQEn,
          'options': optionsList,
          'options_en': finalOptsEn,
          'answerIndex': qMap['answerIndex'] ?? qMap['answer'] ?? 0,
          'explanation': expIndo,
          'explanation_en': expEng,
        };
      }).toList();
    }

    // Fallback data default bawaan bila guru belum melakukan perubahan
    if (rawList.isEmpty) {
      rawList = List<dynamic>.from(getQuestionsForType(widget.quizType));
    }

    // DEDUPLIKASI KETAT BERDASARKAN TEKS SOAL (Pencegahan Soal Dobel)
    final Set<String> seenQuestions = {};
    final List<dynamic> uniqueRawList = [];

    for (var item in rawList) {
      final String qText = (item['question'] ?? item['q'] ?? '').toString().trim().toLowerCase();
      if (qText.isNotEmpty && !seenQuestions.contains(qText)) {
        seenQuestions.add(qText);
        uniqueRawList.add(item);
      }
    }

    uniqueRawList.shuffle();

    // Jumlah soal: Pre-test 5 soal acak unik, Post-test & Asesmen modul 5-10 soal unik
    final int questionLimit = widget.quizType == 'pretest'
        ? (uniqueRawList.length >= 5 ? 5 : uniqueRawList.length)
        : (uniqueRawList.length >= 5 && widget.quizType.startsWith('asesmen_') ? 5 : uniqueRawList.length);

    final selectedPool = uniqueRawList.take(questionLimit).toList();

    List<dynamic> finalQuestions = [];

    for (var item in selectedPool) {
      final originalOptions = List<String>.from(item['options']);
      final originalOptionsEn = item['options_en'] != null
          ? List<String>.from(item['options_en'])
          : originalOptions;

      final int originalAnswerIdx = item['answerIndex'] ?? item['answer'] ?? 0;
      final String correctAnswerText = originalOptions[originalAnswerIdx];

      List<int> indexes = List.generate(originalOptions.length, (i) => i)..shuffle();

      List<String> shuffledOptions =
      indexes.map((i) => originalOptions[i]).toList();
      List<String> shuffledOptionsEn =
      indexes.map((i) => originalOptionsEn[i]).toList();

      final int newAnswerIdx = shuffledOptions.indexOf(correctAnswerText);

      finalQuestions.add({
        'moduleId': item['moduleId'] ?? '',
        'question': item['question'],
        'question_en': item['question_en'] ?? item['question'],
        'options': shuffledOptions,
        'options_en': shuffledOptionsEn,
        'answer': newAnswerIdx,
        'explanation': item['explanation'] ?? '',
        'explanation_en': item['explanation_en'] ?? item['explanation'] ?? '',
      });
    }

    if (!mounted) return;
    setState(() {
      _questions = finalQuestions;
      _isLoading = false;
      _currentIndex = 0;
      _selectedAnswers.clear();
    });
  }

  Future<void> _finishQuiz({
    bool forcedByViolation = false,
    bool forcedByTime = false,
  }) async {
    _countdownTimer?.cancel();

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['answer']) {
        correct++;
      }
    }

    final int total = _questions.isEmpty ? 1 : _questions.length;
    final int score = ((correct / total) * 100).round();

    final prefs = await SharedPreferences.getInstance();

    if (widget.quizType == 'pretest') {
      await prefs.setBool('isPreTestCompleted', true);
      await prefs.setInt('preTestScore', score);
    } else if (widget.quizType == 'posttest') {
      await prefs.setBool('isPostTestCompleted', true);
      await prefs.setInt('postTestScore', score);
    } else if (widget.quizType.startsWith('asesmen_')) {
      final mId = widget.quizType.replaceFirst('asesmen_', '');
      await prefs.setInt('score_$mId', score);
      if (score >= 80) {
        final completed = prefs.getStringList('completed_steps') ?? [];
        if (!completed.contains('${mId}_asesmen')) {
          completed.add('${mId}_asesmen');
          await prefs.setStringList('completed_steps', completed);
        }
      }
    }

    final studentName = prefs.getString('userName') ?? 'Siswa';
    final studentEmail = prefs.getString('userEmail') ?? 'student@structora.app';

    final int preScore = prefs.getInt('preTestScore') ?? (widget.quizType == 'pretest' ? score : 0);
    final int postScore = prefs.getInt('postTestScore') ?? (widget.quizType == 'posttest' ? score : 0);
    final int a1Score = prefs.getInt('score_linkedlist') ?? 0;
    final int a2Score = prefs.getInt('score_stack') ?? 0;
    final int a3Score = prefs.getInt('score_queue') ?? 0;
    final int a4Score = prefs.getInt('score_searching_sorting') ?? 0;

    final bool hasPre = prefs.getBool('isPreTestCompleted') == true || widget.quizType == 'pretest' || prefs.containsKey('preTestScore');
    final bool hasPost = prefs.getBool('isPostTestCompleted') == true || widget.quizType == 'posttest' || prefs.containsKey('postTestScore');
    final bool hasA1 = widget.quizType == 'asesmen_linkedlist' || prefs.containsKey('score_linkedlist');
    final bool hasA2 = widget.quizType == 'asesmen_stack' || prefs.containsKey('score_stack');
    final bool hasA3 = widget.quizType == 'asesmen_queue' || prefs.containsKey('score_queue');
    final bool hasA4 = widget.quizType == 'asesmen_searching_sorting' || prefs.containsKey('score_searching_sorting');

    await TeacherDataHelper.recordStudentProgress(
      name: studentName,
      email: studentEmail,
      preTestScore: hasPre ? '$preScore' : '-',
      assessment1: hasA1 ? '$a1Score' : '-',
      assessment2: hasA2 ? '$a2Score' : '-',
      assessment3: hasA3 ? '$a3Score' : '-',
      assessment4: hasA4 ? '$a4Score' : '-',
      postTestScore: hasPost ? '$postScore' : '-',
      status: hasPost ? (postScore >= 80 ? 'Tuntas' : 'Belum Ujian') : 'Belum Ujian',
    );

    NotificationService.syncStudyReminder(studentName: studentName);

    setState(() {
      _isFinished = true;
      _finalScore = score;
      _correctCount = correct;
    });

    if (forcedByViolation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ujian dihentikan paksa karena melebihi batas pelanggaran.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (forcedByTime && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu ujian telah habis. Jawaban otomatis dikumpulkan.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LanguageController.instance.isEnglish;

    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(widget.fontScale)),
      child: PopScope(
        canPop: _isFinished,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _showExitConfirmDialog();
        },
        child: Scaffold(
          backgroundColor: _scaffoldBg,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: _isFinished
                ? IconButton(
              icon: Icon(Icons.arrow_back, color: _textColor),
              onPressed: () => Navigator.pop(context, true),
            )
                : null,
            title: Text(
              _getQuizTitle(isEn),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            actions: [
              if (!_isFinished) ...[
                Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _boxInnerBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _remainingSeconds <= 120
                          ? Colors.redAccent
                          : _borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _remainingSeconds <= 120
                            ? Colors.redAccent
                            : _accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimer(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: _remainingSeconds <= 120
                              ? Colors.redAccent
                              : _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: _accentColor))
              : _isFinished
              ? _buildResultView(isEn)
              : _buildExamView(isEn),
        ),
      ),
    );
  }

  String _getQuizTitle(bool isEn) {
    if (widget.quizType == 'pretest') {
      return isEn ? 'Pre-Test Assessment' : 'Pre-Test Kemampuan Awal';
    }
    if (widget.quizType == 'posttest') {
      return isEn ? 'Final Post-Test' : 'Post-Test Evaluasi Akhir';
    }
    return isEn ? 'Locked Module Exam' : 'Asesmen Ujian Terkunci';
  }

  void _showExitConfirmDialog() {
    final isEn = LanguageController.instance.isEnglish;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text(
          isEn ? 'Quit Exam?' : 'Batalkan Ujian?',
          style: TextStyle(color: _textColor),
        ),
        content: Text(
          isEn
              ? 'Leaving will count as a submission or forfeit your current progress.'
              : 'Meninggalkan sesi akan langsung mengumpulkan jawaban yang telah dipilih.',
          style: TextStyle(color: _subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Continue Exam' : 'Lanjut Ujian',
                style: TextStyle(color: _accentColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishQuiz();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48)),
            child: Text(isEn ? 'Submit & Leave' : 'Kumpulkan & Keluar',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamView(bool isEn) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          isEn ? 'No questions available.' : 'Belum ada butir soal tersedia.',
          style: TextStyle(color: _subTextColor),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final String qText = isEn ? q['question_en'] : q['question'];
    final List options = isEn ? q['options_en'] : q['options'];
    final int? selectedOption = _selectedAnswers[_currentIndex];
    final bool isLast = _currentIndex == _questions.length - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress nomor soal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isEn ? "Question" : "Soal"} ${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isEn ? "Violations" : "Pelanggaran"}: $_violationCount/$_maxViolations',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 6,
              backgroundColor: _boxInnerBg,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          const SizedBox(height: 18),

          // Kotak naskah soal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Text(
              qText,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: _textColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pilihan jawaban
          ...List.generate(options.length, (optIdx) {
            final isChosen = selectedOption == optIdx;
            final String letter = ['A', 'B', 'C', 'D'][optIdx];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAnswers[_currentIndex] = optIdx;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? _accentColor.withValues(alpha: 0.14)
                        : _cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChosen ? _accentColor : _borderColor,
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isChosen
                            ? _accentColor
                            : _boxInnerBg,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isChosen ? Colors.black : _subTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          options[optIdx].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isChosen ? _textColor : _subTextColor,
                            fontWeight: isChosen
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          // Tombol navigasi soal
          Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _borderColor),
                    ),
                    child: Text(
                      isEn ? 'Previous' : 'Sebelumnya',
                      style: TextStyle(color: _textColor),
                    ),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLast
                      ? () => _finishQuiz()
                      : () => setState(() => _currentIndex++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast
                        ? const Color(0xFF10B981)
                        : _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isLast
                        ? (isEn ? 'Submit Exam' : 'Selesai & Kumpulkan')
                        : (isEn ? 'Next' : 'Berikutnya'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(bool isEn) {
    final bool isPassed = _finalScore >= 80;
    final Color scoreColor = isPassed ? Colors.green : const Color(0xFFE11D48);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Icon(
            isPassed ? Icons.verified_rounded : Icons.cancel_outlined,
            size: 64,
            color: scoreColor,
          ),
          const SizedBox(height: 14),
          Text(
            isPassed
                ? (isEn ? 'Assessment Passed!' : 'Selamat! Kamu Tuntas KKM')
                : (isEn ? 'Need Remedial' : 'Perlu Remedial / Belum KKM'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEn
                ? 'Standard minimum passing grade is 80'
                : 'Standar KKM kelulusan materi ini adalah 80',
            style: TextStyle(fontSize: 12, color: _subTextColor),
          ),
          const SizedBox(height: 20),

          // Kartu skor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Text(
                  '$_finalScore',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '${isEn ? "Correct" : "Benar"} $_correctCount ${isEn ? "of" : "dari"} ${_questions.length} ${isEn ? "questions" : "soal"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _subTextColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEn ? 'Return to Modules' : 'Kembali ke Menu Modul',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}