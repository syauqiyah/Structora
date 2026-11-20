import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quiz_data.dart';
import '../models/materi_model.dart';
import '../services/auto_translate_service.dart';
import '../services/firebase_service.dart';
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
  final bool _isTranslating = false;
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

  DateTime? _lastViolationTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final now = DateTime.now();
      if (_lastViolationTime != null &&
          now.difference(_lastViolationTime!) < const Duration(seconds: 3)) {
        return; // Debounce double lifecycle triggers within 3 seconds
      }
      _lastViolationTime = now;

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

        final master = findMasterQuizQuestion(qIndo);

        String finalQEn = qEng;
        if (finalQEn.isEmpty || finalQEn.trim().toLowerCase() == qIndo.trim().toLowerCase()) {
          if (master != null) {
            finalQEn = (master['question_en'] ?? master['q_en'] ?? '').toString();
          }
        }
        if (finalQEn.isEmpty) {
          finalQEn = qIndo;
        }

        List<String> finalOptsEn = [];
        if (optionsEnList.isNotEmpty) {
          finalOptsEn = optionsEnList.cast<String>();
        }
        if (finalOptsEn.isEmpty || finalOptsEn.join('') == optionsList.join('')) {
          if (master != null && master['options_en'] != null) {
            final mOpts = List<String>.from(master['options']);
            final mOptsEn = List<String>.from(master['options_en']);
            finalOptsEn = optionsList.map((opt) {
              final idx = mOpts.indexOf(opt.toString());
              return (idx != -1 && idx < mOptsEn.length) ? mOptsEn[idx] : opt.toString();
            }).toList();
          } else {
            finalOptsEn = optionsList.map((opt) => opt.toString()).toList();
          }
        }

        final String expIndo = (qMap['explanation'] ?? 'Jawaban benar berdasarkan naskah materi yang disusun oleh guru.').toString();
        String expEng = (qMap['explanation_en'] ?? '').toString();
        if (expEng.isEmpty || expEng.trim().toLowerCase() == expIndo.trim().toLowerCase()) {
          if (master != null) {
            expEng = (master['explanation_en'] ?? '').toString();
          }
        }
        if (expEng.isEmpty) {
          expEng = 'Correct answer according to module material script.';
        }

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

    int customDurationMinutes = 30;
    int? customDisplayQuestionCount;

    try {
      final moduleData = await TeacherContentHelper.getModuleData(targetId);
      if (moduleData != null) {
        final parsedDur = int.tryParse(
            (moduleData['durationMinutes'] ?? moduleData['duration'] ?? '')
                .toString());
        if (parsedDur != null && parsedDur > 0) {
          customDurationMinutes = parsedDur;
        }

        final parsedCount = int.tryParse((moduleData['displayQuestionCount'] ??
            moduleData['questionCount'] ??
            '')
            .toString());
        if (parsedCount != null && parsedCount > 0) {
          customDisplayQuestionCount = parsedCount;
        }
      }
      if (mounted) {
        setState(() {
          _remainingSeconds = customDurationMinutes * 60;
        });
      }
    } catch (_) {}

    // Fallback data default bawaan bila guru belum melakukan perubahan
    if (rawList.isEmpty) {
      rawList = List<dynamic>.from(getQuestionsForType(widget.quizType));
    }

    final List<dynamic> poolForPersist = List<dynamic>.from(rawList);

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

    // Target jumlah soal yang ditampilkan ke siswa (diatur oleh guru):
    // Jika guru menentukan displayQuestionCount (misal 30 / 35 / dll), gunakan itu.
    // Default: Post-Test = 35 soal, Pre-Test & Asesmen Modul = 30 soal.
    final int defaultTarget = widget.quizType == 'posttest' ? 35 : 30;
    final int targetCount = customDisplayQuestionCount ?? defaultTarget;

    final int questionLimit = uniqueRawList.length >= targetCount
        ? targetCount
        : uniqueRawList.length;

    final selectedPool = uniqueRawList.take(questionLimit).toList();

    List<dynamic> finalQuestions = [];

    for (var item in selectedPool) {
      final List<String> originalOptions = List<String>.from(item['options']);
      final String itemQIndo = (item['question'] ?? item['q'] ?? '').toString();
      final master = findMasterQuizQuestion(itemQIndo);

      List<String> originalOptionsEn = [];
      if (item['options_en'] != null && (item['options_en'] as List).isNotEmpty) {
        originalOptionsEn = List<String>.from(item['options_en']);
      }
      if (originalOptionsEn.isEmpty || originalOptionsEn.join('') == originalOptions.join('')) {
        if (master != null && master['options_en'] != null) {
          final mOpts = List<String>.from(master['options']);
          final mOptsEn = List<String>.from(master['options_en']);
          originalOptionsEn = originalOptions.map((opt) {
            final idx = mOpts.indexOf(opt);
            return (idx != -1 && idx < mOptsEn.length) ? mOptsEn[idx] : opt;
          }).toList();
        } else {
          originalOptionsEn = List<String>.from(originalOptions);
        }
      }

      final int originalAnswerIdx = item['answerIndex'] ?? item['answer'] ?? 0;
      final String correctAnswerText = originalOptions[originalAnswerIdx];

      List<int> indexes = List.generate(originalOptions.length, (i) => i)..shuffle();

      List<String> shuffledOptions =
      indexes.map((i) => originalOptions[i]).toList();
      List<String> shuffledOptionsEn =
      indexes.map((i) => originalOptionsEn[i]).toList();

      final int newAnswerIdx = shuffledOptions.indexOf(correctAnswerText);

      String qEn = (item['question_en'] ?? item['q_en'] ?? '').toString();
      if (qEn.isEmpty || qEn.trim().toLowerCase() == itemQIndo.trim().toLowerCase()) {
        if (master != null) {
          qEn = (master['question_en'] ?? master['q_en'] ?? '').toString();
        }
      }
      if (qEn.isEmpty) {
        qEn = itemQIndo;
      }

      final String expIndo = (item['explanation'] ?? '').toString();
      String expEn = (item['explanation_en'] ?? '').toString();
      if (expEn.isEmpty || expEn.trim().toLowerCase() == expIndo.trim().toLowerCase()) {
        if (master != null) {
          expEn = (master['explanation_en'] ?? '').toString();
        }
      }
      if (expEn.isEmpty) {
        expEn = 'Correct answer according to module material script.';
      }

      finalQuestions.add({
        'moduleId': item['moduleId'] ?? '',
        'question': itemQIndo,
        'question_en': qEn,
        'options': shuffledOptions,
        'options_en': shuffledOptionsEn,
        'answer': newAnswerIdx,
        'explanation': expIndo,
        'explanation_en': expEn,
      });
    }

    if (!mounted) return;
    setState(() {
      _questions = finalQuestions;
      _isLoading = false;
      _currentIndex = 0;
      _selectedAnswers.clear();
    });

    if (LanguageController.instance.isEnglish) {
      _translateInBackground(poolForPersist, targetId);
    }
  }

  bool _bgTranslating = false;

  /// Translates displayed questions (batches of 5) without blocking the exam;
  /// the UI is refreshed after every batch. Afterwards the full pool is
  /// translated and persisted so the next session is instant.
  Future<void> _translateInBackground(
      List<dynamic> fullPool, String targetId) async {
    if (_bgTranslating) return;
    _bgTranslating = true;
    if (mounted) setState(() {});
    try {
      await AutoTranslateService.instance.translatePending(
        _questions,
        batchSize: 5,
        onBatch: (updates) {
          if (!mounted) return;
          setState(() {
            updates.forEach((i, v) {
              if (i < _questions.length) _questions[i] = v;
            });
          });
        },
      );

      // Persist full translated pool (existing behaviour, now off the UI path).
      final List<Map<String, dynamic>> translatedPool =
      await AutoTranslateService.instance
          .translatePending(fullPool, batchSize: 5);
      final Map<String, dynamic>? moduleData =
      await TeacherContentHelper.getModuleData(targetId);
      if (moduleData != null && moduleData['id'] != null) {
        final Map<String, dynamic> updatedModule =
        Map<String, dynamic>.from(moduleData);
        updatedModule['questions'] = translatedPool;
        await FirebaseService.saveOrUpdateMateri(updatedModule);
        await TeacherContentHelper.updateMateriModel(
          MateriModel.fromMap(updatedModule),
        );
      }
    } catch (e) {
      debugPrint('Background quiz translation notice: $e');
    } finally {
      _bgTranslating = false;
      if (mounted) setState(() {});
    }
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

    final studentName = prefs.getString('userName') ?? 'Siswa';
    final studentEmail = prefs.getString('userEmail') ?? 'student@structora.app';

    final String kPre = FirebaseService.getUserKey(studentEmail, 'preTestScore');
    final String kPost = FirebaseService.getUserKey(studentEmail, 'postTestScore');
    final String kA1 = FirebaseService.getUserKey(studentEmail, 'score_linkedlist');
    final String kA2 = FirebaseService.getUserKey(studentEmail, 'score_stack');
    final String kA3 = FirebaseService.getUserKey(studentEmail, 'score_queue');
    final String kA4 = FirebaseService.getUserKey(studentEmail, 'score_searching_sorting');

    final String kPreBool = FirebaseService.getUserKey(studentEmail, 'isPreTestCompleted');
    final String kPostBool = FirebaseService.getUserKey(studentEmail, 'isPostTestCompleted');

    if (widget.quizType == 'pretest') {
      await prefs.setBool(kPreBool, true);
      await prefs.setInt(kPre, score);
    } else if (widget.quizType == 'posttest') {
      await prefs.setBool(kPostBool, true);
      await prefs.setInt(kPost, score);
    } else if (widget.quizType.startsWith('asesmen_')) {
      final mId = widget.quizType.replaceFirst('asesmen_', '');
      final String kAScore = FirebaseService.getUserKey(studentEmail, 'score_$mId');
      await prefs.setInt(kAScore, score);
      if (score >= 75) {
        final String kSteps = FirebaseService.getUserKey(studentEmail, 'completed_steps');
        final completed = prefs.getStringList(kSteps) ?? [];
        if (!completed.contains('${mId}_asesmen')) {
          completed.add('${mId}_asesmen');
          await prefs.setStringList(kSteps, completed);
        }
      }
    }

    final int preScore = (widget.quizType == 'pretest') ? score : (prefs.getInt(kPre) ?? 0);
    final int postScore = (widget.quizType == 'posttest') ? score : (prefs.getInt(kPost) ?? 0);
    final int a1Score = (widget.quizType == 'asesmen_linkedlist') ? score : (prefs.getInt(kA1) ?? 0);
    final int a2Score = (widget.quizType == 'asesmen_stack') ? score : (prefs.getInt(kA2) ?? 0);
    final int a3Score = (widget.quizType == 'asesmen_queue') ? score : (prefs.getInt(kA3) ?? 0);
    final int a4Score = (widget.quizType == 'asesmen_searching_sorting') ? score : (prefs.getInt(kA4) ?? 0);

    final bool hasPre = widget.quizType == 'pretest' || (prefs.getBool(kPreBool) == true) || prefs.containsKey(kPre);
    final bool hasPost = widget.quizType == 'posttest' || (prefs.getBool(kPostBool) == true) || prefs.containsKey(kPost);
    final bool hasA1 = widget.quizType == 'asesmen_linkedlist' || a1Score > 0 || prefs.containsKey(kA1);
    final bool hasA2 = widget.quizType == 'asesmen_stack' || a2Score > 0 || prefs.containsKey(kA2);
    final bool hasA3 = widget.quizType == 'asesmen_queue' || a3Score > 0 || prefs.containsKey(kA3);
    final bool hasA4 = widget.quizType == 'asesmen_searching_sorting' || a4Score > 0 || prefs.containsKey(kA4);

    final String finalStatus = hasPost
        ? (postScore >= 75 ? 'Tuntas' : 'Perlu Remedial')
        : (hasPre ? 'Sedang Belajar' : 'Belum Ujian');

    await TeacherDataHelper.recordStudentProgress(
      name: studentName,
      email: studentEmail,
      preTestScore: hasPre ? '$preScore' : '-',
      assessment1: hasA1 ? '$a1Score' : '-',
      assessment2: hasA2 ? '$a2Score' : '-',
      assessment3: hasA3 ? '$a3Score' : '-',
      assessment4: hasA4 ? '$a4Score' : '-',
      postTestScore: hasPost ? '$postScore' : '-',
      status: finalStatus,
      violations: _violationCount,
    );

    NotificationService.syncStudyReminder(studentName: studentName);

    setState(() {
      _isFinished = true;
      _finalScore = score;
      _correctCount = correct;
    });

    if (forcedByViolation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageController.instance.isEnglish
              ? 'Exam was force-stopped because the violation limit was exceeded.'
              : 'Ujian dihentikan paksa karena melebihi batas pelanggaran.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (forcedByTime && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageController.instance.isEnglish
              ? 'Time is up. Your answers were submitted automatically.'
              : 'Waktu ujian telah habis. Jawaban otomatis dikumpulkan.'),
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
          body: (_isLoading || _isTranslating)
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: _accentColor),
                const SizedBox(height: 16),
                Text(
                  isEn
                      ? 'Translating questions...'
                      : 'Menerjemahkan butir soal...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          )
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

  void _onTapNextOrSubmit(bool isEn) {
    final int? selectedOption = _selectedAnswers[_currentIndex];
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Please select an answer choice for this question before proceeding! *'
                : 'Wajib memilih salah satu jawaban pada soal ini terlebih dahulu sebelum lanjut! *',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final bool isLast = _currentIndex == _questions.length - 1;
    if (!isLast) {
      setState(() => _currentIndex++);
    } else {
      // Cek apakah seluruh soal dari awal hingga akhir sudah dijawab
      int unansweredIndex = -1;
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == null) {
          unansweredIndex = i;
          break;
        }
      }

      if (unansweredIndex != -1) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  isEn ? 'Incomplete Exam! *' : 'Ujian Belum Lengkap! *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
            content: Text(
              isEn
                  ? 'There are still unanswered questions (Question No. ${unansweredIndex + 1}). You must answer all ${_questions.length} questions before submitting the exam.'
                  : 'Masih ada soal yang belum dijawab (Soal No. ${unansweredIndex + 1}). Kamu wajib menjawab seluruh ${_questions.length} butir soal sebelum mengumpulkan ujian.',
              style: TextStyle(fontSize: 13, color: _subTextColor, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _currentIndex = unansweredIndex;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isEn ? 'Complete Answer' : 'Lengkapi Jawaban',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return;
      }

      _finishQuiz();
    }
  }

  Widget _buildExamView(bool isEn) {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          isEn ? 'No questions available.' : 'Belum ada putir soal tersedia.',
          style: TextStyle(color: _subTextColor),
        ),
      );
    }

    final q = Map<String, dynamic>.from(_questions[_currentIndex]);
    final String qText = q.getLocalizedQuestion(isEn);
    final List options = q.getLocalizedOptions(isEn);
    final int? selectedOption = _selectedAnswers[_currentIndex];
    final bool isLast = _currentIndex == _questions.length - 1;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress nomor soal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${isEn ? "Question" : "Soal"} ${_currentIndex + 1} / ${_questions.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isEn ? 'Required' : 'Wajib Diisi',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
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
          if (_bgTranslating && isEn) ...[
            const SizedBox(height: 6),
            Text(
              'Translating remaining questions...',
              style: TextStyle(fontSize: 10.5, color: _subTextColor),
            ),
          ],
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
            const prefixes = ['A', 'B', 'C', 'D', 'E'];
            final String letter = optIdx < prefixes.length ? prefixes[optIdx] : '${optIdx + 1}';

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
                  onPressed: () => _onTapNextOrSubmit(isEn),
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
    final bool isPassed = _finalScore >= 75;
    final Color scoreColor = isPassed ? Colors.green : const Color(0xFFE11D48);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
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
                ? 'Standard minimum passing grade is 75'
                : 'Standar KKM kelulusan materi ini adalah 75',
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