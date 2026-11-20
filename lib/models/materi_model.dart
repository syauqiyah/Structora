class MateriModel {
  final String id;
  final String judulId;
  final String judulEn;
  final String deskripsiId;
  final String deskripsiEn;
  final String modulId;
  final String modulEn;
  final String videoUrl;
  final List<Map<String, dynamic>> questions;
  final int? displayQuestionCount;
  final int? durationMinutes;
  final String createdAt;
  final String updatedAt;

  MateriModel({
    required this.id,
    required this.judulId,
    required this.judulEn,
    required this.deskripsiId,
    required this.deskripsiEn,
    this.modulId = '',
    this.modulEn = '',
    this.videoUrl = '',
    this.questions = const [],
    this.displayQuestionCount,
    this.durationMinutes,
    this.createdAt = '',
    this.updatedAt = '',
  });

  /// Factory method to construct [MateriModel] from a Map (e.g., Firestore or SharedPreferences).
  factory MateriModel.fromMap(Map<String, dynamic> map) {
    final String idStr = (map['id'] ?? '').toString();
    final String judulIdStr = (map['judulId'] ?? map['title'] ?? '').toString();
    final String judulEnStr =
        (map['judulEn'] ?? map['title_en'] ?? map['titleEn'] ?? '').toString();
    final String deskripsiIdStr =
        (map['deskripsiId'] ?? map['desc'] ?? '').toString();
    final String deskripsiEnStr =
        (map['deskripsiEn'] ?? map['desc_en'] ?? map['descEn'] ?? '').toString();
    final String modulIdStr = (map['modulId'] ?? map['modul'] ?? '').toString();
    final String modulEnStr =
        (map['modulEn'] ?? map['modul_en'] ?? '').toString();
    final String videoUrlStr = (map['videoUrl'] ?? '').toString();

    List<Map<String, dynamic>> qList = [];
    if (map['questions'] is List) {
      qList = (map['questions'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    int? displayCount;
    if (map['displayQuestionCount'] != null) {
      displayCount = int.tryParse(map['displayQuestionCount'].toString());
    }
    int? durationMins;
    if (map['durationMinutes'] != null) {
      durationMins = int.tryParse(map['durationMinutes'].toString());
    }

    final String createdStr = (map['createdAt'] ?? '').toString();
    final String updatedStr = (map['updatedAt'] ?? '').toString();

    return MateriModel(
      id: idStr,
      judulId: judulIdStr,
      judulEn: judulEnStr,
      deskripsiId: deskripsiIdStr,
      deskripsiEn: deskripsiEnStr,
      modulId: modulIdStr,
      modulEn: modulEnStr,
      videoUrl: videoUrlStr,
      questions: qList,
      displayQuestionCount: displayCount,
      durationMinutes: durationMins,
      createdAt: createdStr,
      updatedAt: updatedStr,
    );
  }

  /// Converts this [MateriModel] instance into a Map for Database persistence.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'id': id,
      'judulId': judulId,
      'judulEn': judulEn,
      'deskripsiId': deskripsiId,
      'deskripsiEn': deskripsiEn,
      // Backwards-compatibility keys for Firestore & UI components
      'title': judulId,
      'title_en': judulEn,
      'desc': deskripsiId,
      'desc_en': deskripsiEn,
      'modulId': modulId,
      'modul': modulId,
      'modulEn': modulEn,
      'modul_en': modulEn,
      'videoUrl': videoUrl,
      'questions': questions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
    if (displayQuestionCount != null) {
      data['displayQuestionCount'] = displayQuestionCount;
    }
    if (durationMinutes != null) {
      data['durationMinutes'] = durationMinutes;
    }
    return data;
  }

  /// Convenience helper to retrieve localized Title
  String getJudul([bool? isEnglish]) {
    final bool en = isEnglish ?? false;
    return en ? (judulEn.isNotEmpty ? judulEn : judulId) : judulId;
  }

  /// Convenience helper to retrieve localized Description
  String getDeskripsi([bool? isEnglish]) {
    final bool en = isEnglish ?? false;
    return en ? (deskripsiEn.isNotEmpty ? deskripsiEn : deskripsiId) : deskripsiId;
  }

  /// Convenience helper to retrieve localized Module Name
  String getModul([bool? isEnglish]) {
    final bool en = isEnglish ?? false;
    return en ? (modulEn.isNotEmpty ? modulEn : modulId) : modulId;
  }

  MateriModel copyWith({
    String? id,
    String? judulId,
    String? judulEn,
    String? deskripsiId,
    String? deskripsiEn,
    String? modulId,
    String? modulEn,
    String? videoUrl,
    List<Map<String, dynamic>>? questions,
    String? createdAt,
    String? updatedAt,
  }) {
    return MateriModel(
      id: id ?? this.id,
      judulId: judulId ?? this.judulId,
      judulEn: judulEn ?? this.judulEn,
      deskripsiId: deskripsiId ?? this.deskripsiId,
      deskripsiEn: deskripsiEn ?? this.deskripsiEn,
      modulId: modulId ?? this.modulId,
      modulEn: modulEn ?? this.modulEn,
      videoUrl: videoUrl ?? this.videoUrl,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
