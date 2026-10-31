import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../utils/app_translations.dart';

class TeacherDataHelper {
  // Helper penerjemah status sesuai bahasa aktif tanpa mengubah database asli
  static String getLocalizedStatus(String? rawStatus) {
    final status = rawStatus ?? 'Belum Ujian';
    final isEn = LanguageController.instance.isEnglish;

    if (isEn) {
      if (status.toLowerCase().contains('tuntas') ||
          status.toLowerCase().contains('completed')) {
        return 'Completed';
      }
      return 'Not Tested';
    } else {
      if (status.toLowerCase().contains('completed') ||
          status.toLowerCase().contains('tuntas')) {
        return 'Tuntas';
      }
      return 'Belum Ujian';
    }
  }

  // Menyimpan atau memperbarui progres mahasiswa ke Cloud Firestore & Lokal
  static Future<void> recordStudentProgress({
    required String name,
    required String email,
    required String preTestScore,
    String assessment1 = '-',
    String assessment2 = '-',
    String assessment3 = '-',
    String assessment4 = '-',
    String postTestScore = '-',
    String status = 'Belum Ujian',
  }) async {
    // 1. Simpan ke Cloud Firestore
    await FirebaseService.saveStudentProgress(
      name: name,
      email: email,
      preTestScore: preTestScore,
      assessment1: assessment1,
      assessment2: assessment2,
      assessment3: assessment3,
      assessment4: assessment4,
      postTestScore: postTestScore,
      status: status,
    );

    // 2. Simpan ke SharedPreferences lokal
    final prefs = await SharedPreferences.getInstance();

    List<String> rawList =
        prefs.getStringList('real_student_progress_list') ?? [];

    Map<String, dynamic> studentData = {
      'name': name,
      'email': email,
      'preTest': preTestScore,
      'assessment1': assessment1,
      'assessment2': assessment2,
      'assessment3': assessment3,
      'assessment4': assessment4,
      'postTest': postTestScore,
      'status': status,
      'lastActive': DateTime.now().toIso8601String(),
    };

    bool found = false;

    for (int i = 0; i < rawList.length; i++) {
      final Map<String, dynamic> existing =
      jsonDecode(rawList[i]) as Map<String, dynamic>;

      if (existing['email'] == email) {
        studentData['assessment1'] = assessment1 != '-'
            ? assessment1
            : (existing['assessment1'] ?? '-');

        studentData['assessment2'] = assessment2 != '-'
            ? assessment2
            : (existing['assessment2'] ?? '-');

        studentData['assessment3'] = assessment3 != '-'
            ? assessment3
            : (existing['assessment3'] ?? '-');

        studentData['assessment4'] = assessment4 != '-'
            ? assessment4
            : (existing['assessment4'] ?? '-');

        studentData['postTest'] = postTestScore != '-'
            ? postTestScore
            : (existing['postTest'] ?? '-');

        studentData['status'] = status != 'Belum Ujian'
            ? status
            : (existing['status'] ?? 'Belum Ujian');

        studentData['preTest'] = preTestScore != '-'
            ? preTestScore
            : (existing['preTest'] ?? '-');

        rawList[i] = jsonEncode(studentData);
        found = true;
        break;
      }
    }

    if (!found) {
      rawList.add(jsonEncode(studentData));
    }

    await prefs.setStringList('real_student_progress_list', rawList);
  }

  // Mengambil seluruh data progres mahasiswa dari Firestore atau cache lokal
  static Future<List<dynamic>> getRealStudentList() async {
    // 1. Coba dari Firestore
    final firestoreList = await FirebaseService.getStudentList();
    if (firestoreList.isNotEmpty) {
      return firestoreList;
    }

    // 2. Fallback ke SharedPreferences lokal
    final prefs = await SharedPreferences.getInstance();

    final List<String> rawList =
        prefs.getStringList('real_student_progress_list') ?? [];

    if (rawList.isEmpty) {
      return [];
    }

    return rawList.map((item) {
      return jsonDecode(item) as Map<String, dynamic>;
    }).toList();
  }

  // Menghapus seluruh data progres mahasiswa
  static Future<void> clearAllStudentData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('real_student_progress_list');
  }
}