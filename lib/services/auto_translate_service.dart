import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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
      final isIdDownloaded = await _modelManager
          .isModelDownloaded(TranslateLanguage.indonesian.bcp47);
      final isEnDownloaded = await _modelManager
          .isModelDownloaded(TranslateLanguage.english.bcp47);

      if (!isIdDownloaded) {
        _isDownloading = true;
        await _modelManager
            .downloadModel(TranslateLanguage.indonesian.bcp47);
      }
      if (!isEnDownloaded) {
        _isDownloading = true;
        await _modelManager.downloadModel(TranslateLanguage.english.bcp47);
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

  /// Translates Indonesian input text to English automatically using google_mlkit_translation.
  Future<String> translateText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    try {
      _translator ??= OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.indonesian,
        targetLanguage: TranslateLanguage.english,
      );

      final String mlKitResult = await _translator!.translateText(trimmed);
      if (mlKitResult.trim().isNotEmpty &&
          mlKitResult.trim().toLowerCase() != trimmed.toLowerCase()) {
        return mlKitResult.trim();
      }
    } catch (e) {
      debugPrint('AutoTranslateService fallback translation notice: $e');
    }

    // Fallback to pattern-based translation helper
    return AppText.translateDirect(trimmed);
  }

  /// Automatically translates a list of question items dynamically (question stem, options, explanation).
  Future<List<Map<String, dynamic>>> translateQuestions(
      List questionsList) async {
    final List<Map<String, dynamic>> result = [];

    for (var item in questionsList) {
      if (item is! Map) continue;
      final qMap = Map<String, dynamic>.from(item);

      final String qIndo =
          (qMap['q'] ?? qMap['question'] ?? '').toString().trim();
      if (qIndo.isEmpty) continue;

      String qEng =
          (qMap['q_en'] ?? qMap['question_en'] ?? '').toString().trim();
      if (qEng.isEmpty ||
          qEng.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
              qIndo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
        qEng = await translateText(qIndo);
      }

      final List rawOptsIndo = (qMap['options'] as List? ?? []);
      final List<String> optsIndo =
          rawOptsIndo.map((o) => o.toString().trim()).toList();

      final List rawOptsEng = (qMap['options_en'] as List? ?? []);
      List<String> optsEng =
          rawOptsEng.map((o) => o.toString().trim()).toList();

      if (optsEng.isEmpty || optsEng.join('') == optsIndo.join('')) {
        optsEng = [];
        for (var opt in optsIndo) {
          final translatedOpt = await translateText(opt);
          optsEng.add(translatedOpt);
        }
      }

      final String expIndo = (qMap['explanation'] ??
              'Jawaban benar berdasarkan naskah materi yang disusun oleh guru.')
          .toString()
          .trim();

      String expEng = (qMap['explanation_en'] ?? '').toString().trim();
      if (expEng.isEmpty ||
          expEng.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
              expIndo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
        expEng = await translateText(expIndo);
      }

      final int ansIdx = qMap['answerIndex'] ?? qMap['answer'] ?? 0;

      result.add({
        'q': qIndo,
        'question': qIndo,
        'q_en': qEng,
        'question_en': qEng,
        'options': optsIndo,
        'options_en': optsEng,
        'answerIndex': ansIdx,
        'answer': ansIdx,
        'explanation': expIndo,
        'explanation_en': expEng,
      });
    }

    return result;
  }

  /// Automatically translates full Materi data into a populated [MateriModel] with ID and EN fields.
  Future<MateriModel> translateAndCreateMateriModel({
    required String id,
    required String judulId,
    required String deskripsiId,
    String modulId = '',
    String videoUrl = '',
    List questions = const [],
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
        await translateQuestions(questions);

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
      createdAt: createdAt ??
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  /// Clean up translator resources
  void dispose() {
    _translator?.close();
    _translator = null;
  }
}
