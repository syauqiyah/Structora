import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/material.dart';
import '../data/quiz_data.dart';
import '../models/materi_model.dart';
import '../utils/app_translations.dart';

class AutoTranslateService {
  static final AutoTranslateService instance = AutoTranslateService._internal();
  factory AutoTranslateService() => instance;
  AutoTranslateService._internal();

  OnDeviceTranslator? _translator;
  final OnDeviceTranslatorModelManager _modelManager =
  OnDeviceTranslatorModelManager();

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isModelDownloaded = false;
  bool get isModelDownloaded => _isModelDownloaded;

  /// Ensures ML Kit language models for Indonesian & English are checked and downloaded.
  Future<bool> ensureModelsDownloaded() async {
    try {
      final bool isIdDownloaded = await _modelManager
          .isModelDownloaded(TranslateLanguage.indonesian.bcpCode);
      final bool isEnDownloaded = await _modelManager
          .isModelDownloaded(TranslateLanguage.english.bcpCode);

      if (!isIdDownloaded) {
        _isDownloading = true;
        await _modelManager
            .downloadModel(TranslateLanguage.indonesian.bcpCode);
      }
      if (!isEnDownloaded) {
        _isDownloading = true;
        await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
      }
      _isModelDownloaded = true;
      _isDownloading = false;
      return true;
    } catch (e) {
      debugPrint('AutoTranslateService ML Kit model download notice: $e');
      _isDownloading = false;
      return false;
    }
  }

  static final Map<String, String> _cache = {};
  static final Map<String, Future<String>> _inflight = {};

  /// Synchronous cache lookup (0 ms). Returns null when not translated yet.
  String? cached(String text) => _cache[text.trim()];

  /// Translates full sentences with in-memory cache first (0 ms), then the
  /// Google Translate HTTP API. No word-by-word dictionary is used for the
  /// primary result; ALL segments of the API response are concatenated so long
  /// sentences are never truncated.
  Future<String> toEnglish(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final String? hit = _cache[trimmed];
    if (hit != null) return hit;

    final Future<String>? running = _inflight[trimmed];
    if (running != null) return running;

    final Future<String> task = _fetchEnglish(trimmed);
    _inflight[trimmed] = task;
    try {
      return await task;
    } finally {
      _inflight.remove(trimmed);
    }
  }

  Future<String> _fetchEnglish(String trimmed) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final String? result = await _requestTranslation(trimmed);
        if (result != null && result.isNotEmpty) {
          _cache[trimmed] = result;
          return result;
        }
      } catch (e) {
        debugPrint('AutoTranslateService toEnglish HTTP notice: $e');
      }
    }
    // Offline fallback only (NOT cached so a later retry can still reach the API).
    return AppText.auto(trimmed);
  }

  Future<String?> _requestTranslation(String text) async {
    const String base =
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=id&tl=en&dt=t';
    final String encoded = Uri.encodeComponent(text);
    http.Response response;
    if (encoded.length > 1500) {
      // Long text: POST body avoids URL length limits.
      response = await http
          .post(Uri.parse(base), body: {'q': text})
          .timeout(const Duration(seconds: 12));
    } else {
      response = await http
          .get(Uri.parse('$base&q=$encoded'))
          .timeout(const Duration(seconds: 8));
    }
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List || decoded.isEmpty || decoded[0] is! List) return null;

    // Concatenate ALL segments of data[0] so long sentences are never cut.
    final StringBuffer sb = StringBuffer();
    for (final seg in decoded[0] as List) {
      if (seg is List && seg.isNotEmpty && seg[0] != null) {
        sb.write(seg[0].toString());
      }
    }
    return sb.toString().trim();
  }

  /// Translates Indonesian input text to English automatically using toEnglish.
  Future<String> translateText(String text) async {
    return toEnglish(text);
  }

  /// True when this question already carries a complete English version.
  bool isQuestionTranslated(Map<String, dynamic> qMap) {
    final String qIndo =
    (qMap['q'] ?? qMap['question'] ?? '').toString().trim();
    if (qIndo.isEmpty) return true;
    final List optsIndo = (qMap['options'] as List? ?? []);
    final List optsEn = (qMap['options_en'] as List? ?? []);
    final String qEn =
    (qMap['q_en'] ?? qMap['question_en'] ?? '').toString().trim();
    final String exp = (qMap['explanation'] ?? '').toString().trim();
    final String expEn = (qMap['explanation_en'] ?? '').toString().trim();

    if (qMap['en_ok'] == true &&
        qEn.isNotEmpty &&
        optsEn.length == optsIndo.length &&
        (exp.isEmpty || expEn.isNotEmpty)) {
      return true;
    }
    // Curated English from the built-in master bank is complete as well.
    final master = findMasterQuizQuestion(qIndo);
    if (master != null &&
        qEn.isNotEmpty &&
        _cleanNorm(qEn) != _cleanNorm(qIndo) &&
        optsEn.length == optsIndo.length &&
        expEn.isNotEmpty &&
        qMap['en_ok'] != false) {
      final mQEn =
      (master['question_en'] ?? master['q_en'] ?? '').toString().trim();
      if (mQEn.isNotEmpty && _cleanNorm(mQEn) == _cleanNorm(qEn)) return true;
    }
    return false;
  }

  /// Translates stem + all options + explanation in ONE HTTP call separated by
  /// ' ||| ', then splits back into q_en / options_en / explanation_en.
  /// Falls back to parallel per-item translation when the split count differs.
  Future<Map<String, dynamic>> translateQuestionItem(
      Map<String, dynamic> qMap) async {
    final Map<String, dynamic> updatedMap = Map<String, dynamic>.from(qMap);

    final String qIndo =
    (updatedMap['q'] ?? updatedMap['question'] ?? '').toString().trim();
    if (qIndo.isEmpty) return updatedMap;
    if (isQuestionTranslated(updatedMap)) return updatedMap;

    final List<String> optsIndo = (updatedMap['options'] as List? ?? [])
        .map((e) => e.toString().trim())
        .toList();
    final String expIndo = (updatedMap['explanation'] ?? '').toString().trim();
    final int ansIdx = updatedMap['answerIndex'] ?? updatedMap['answer'] ?? 0;

    void apply(String qEng, List<String> optsEng, String expEng) {
      updatedMap['q'] = qIndo;
      updatedMap['question'] = qIndo;
      updatedMap['q_en'] = qEng;
      updatedMap['question_en'] = qEng;
      updatedMap['options'] = optsIndo;
      updatedMap['options_en'] = optsEng;
      updatedMap['answerIndex'] = ansIdx;
      updatedMap['answer'] = ansIdx;
      updatedMap['explanation'] = expIndo;
      updatedMap['explanation_en'] = expEng;
      updatedMap['en_ok'] = true;
    }

    final int expectedCount = 1 + optsIndo.length + 1;
    final String combinedInput =
    [qIndo, ...optsIndo, expIndo.isEmpty ? '-' : expIndo].join(' ||| ');

    try {
      final String combinedOutput = await toEnglish(combinedInput);
      final List<String> parts =
      combinedOutput.split('|||').map((s) => s.trim()).toList();
      if (parts.length == expectedCount && parts.every((p) => p.isNotEmpty)) {
        apply(
          parts[0],
          parts.sublist(1, 1 + optsIndo.length),
          expIndo.isEmpty ? '' : parts.last,
        );
        return updatedMap;
      }
    } catch (e) {
      debugPrint('Combined translation notice: $e');
    }

    // Fallback: translate every piece in parallel.
    try {
      final results = await Future.wait<dynamic>([
        toEnglish(qIndo),
        Future.wait<String>(optsIndo.map((opt) => toEnglish(opt))),
        expIndo.isEmpty ? Future<String>.value('') : toEnglish(expIndo),
      ]);
      apply(results[0] as String, results[1] as List<String>,
          results[2] as String);
    } catch (e) {
      debugPrint('Error translateQuestionItem fallback: $e');
    }
    return updatedMap;
  }

  /// Translates only the questions that are not yet fully English, in batches
  /// of [batchSize]. [onBatch] fires after each batch with the indices and the
  /// translated maps so UIs can call setState progressively.
  Future<List<Map<String, dynamic>>> translatePending(
      List<dynamic> questions, {
        int batchSize = 5,
        void Function(Map<int, Map<String, dynamic>> updates)? onBatch,
      }) async {
    final List<Map<String, dynamic>> list = questions
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    for (int i = 0; i < list.length; i += batchSize) {
      final int end = (i + batchSize < list.length) ? i + batchSize : list.length;
      final Map<int, Map<String, dynamic>> updates = {};
      final List<int> idxs = [
        for (int k = i; k < end; k++)
          if (!isQuestionTranslated(list[k])) k
      ];
      if (idxs.isEmpty) continue;
      final done =
      await Future.wait(idxs.map((k) => translateQuestionItem(list[k])));
      for (int j = 0; j < idxs.length; j++) {
        list[idxs[j]] = done[j];
        updates[idxs[j]] = done[j];
      }
      onBatch?.call(updates);
    }
    return list;
  }

  /// Translates ALL question items (100%) in sequential batches of 5, no timeout.
  Future<List<Map<String, dynamic>>> translateAllQuestions(
      List<dynamic> allQuestions) {
    return translatePending(allQuestions, batchSize: 5);
  }

  /// Legacy helper for translating questions list
  Future<List<Map<String, dynamic>>> translateQuestions(
      List<dynamic> questionsList) async {
    return translateAllQuestions(questionsList);
  }

  /// Automatically translates full Materi data into a populated [MateriModel] with ID and EN fields.
  Future<MateriModel> translateAndCreateMateriModel({
    required String id,
    required String judulId,
    required String deskripsiId,
    String modulId = '',
    String videoUrl = '',
    List<dynamic> questions = const <dynamic>[],
    int? displayQuestionCount,
    int? durationMinutes,
    String? judulEn,
    String? deskripsiEn,
    String? modulEn,
    String? createdAt,
    String? updatedAt,
  }) async {
    final String finalJudulEn = (judulEn != null && judulEn.trim().isNotEmpty)
        ? judulEn
        : await translateText(judulId);

    final String finalDeskripsiEn =
    (deskripsiEn != null && deskripsiEn.trim().isNotEmpty)
        ? deskripsiEn
        : await translateText(deskripsiId);

    final String finalModulEn = (modulEn != null && modulEn.trim().isNotEmpty)
        ? modulEn
        : (modulId.isNotEmpty ? await translateText(modulId) : '');

    final List<Map<String, dynamic>> finalQuestions =
    await translateAllQuestions(questions);

    return MateriModel(
      id: id,
      judulId: judulId,
      judulEn: finalJudulEn,
      deskripsiId: deskripsiId,
      deskripsiEn: finalDeskripsiEn,
      modulId: modulId,
      modulEn: finalModulEn,
      videoUrl: videoUrl,
      questions: finalQuestions,
      displayQuestionCount: displayQuestionCount,
      durationMinutes: durationMinutes,
      createdAt: createdAt ??
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  String _cleanNorm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  /// Clean up translator resources
  void dispose() {
    _translator?.close();
    _translator = null;
  }
}

/// Renders [text] in English when [LanguageController.isEnglish] is true by
/// translating the whole sentence through [AutoTranslateService] (in-memory
/// cache => instant for repeated text). Shows the original text while loading.
class AutoTranslateText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String prefix;
  final String suffix;

  const AutoTranslateText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.prefix = '',
        this.suffix = '',
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        Widget build(String value) => Text('$prefix$value$suffix',
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow);

        if (!LanguageController.instance.isEnglish || text.trim().isEmpty) {
          return build(text);
        }
        final String? hit = AutoTranslateService.instance.cached(text);
        if (hit != null) return build(hit);
        return FutureBuilder<String>(
          future: AutoTranslateService.instance.toEnglish(text),
          initialData: text,
          builder: (context, snap) => build(snap.data ?? text),
        );
      },
    );
  }
}
