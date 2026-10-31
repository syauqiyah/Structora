import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  static final CollectionReference _usersRef = _db.collection('users');
  static final CollectionReference _materiRef = _db.collection('materi');
  static final CollectionReference _progressRef = _db.collection('student_progress');

  // ===========================================================================
  // 1. MANAJEMEN AUTENTIKASI, PERAN (ROLE: SISWA / GURU), & USER
  // ===========================================================================

  /// Menyimpan atau meng-update data profil dan peran (role) pengguna di Cloud Firestore
  static Future<void> saveUserRole({
    required String uid,
    required String email,
    required String name,
    required String role, // 'student' atau 'teacher'
    String? photoUrl,
  }) async {
    final bool isTeacher = role == 'teacher';
    final emailClean = email.toLowerCase().trim();

    // 1. Simpan ke SharedPreferences LOKAL terlepas dari koneksi jaringan (Seketika)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', emailClean);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setString('userRole', role);
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error local prefs saveUserRole: $e');
    }

    // 2. Sinkronkan ke Cloud Firestore di latar belakang dengan Timeout 2.5 Detik agar tidak menggantung
    try {
      final userData = {
        'uid': uid,
        'email': emailClean,
        'name': name,
        'role': role,
        'isTeacher': isTeacher,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersRef
          .doc(uid)
          .set(userData, SetOptions(merge: true))
          .timeout(const Duration(milliseconds: 2500));
    } catch (e) {
      debugPrint('Firestore saveUserRole sync timeout/note: $e');
    }
  }

  /// Mengambil data peran (role) pengguna dari Cloud Firestore dengan Timeout Safety
  static Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _usersRef
          .doc(uid)
          .get()
          .timeout(const Duration(milliseconds: 2000));
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role']?.toString();
        if (role != null && role.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isTeacher', role == 'teacher');
          await prefs.setString('userRole', role);
          return role;
        }
      }
    } catch (e) {
      debugPrint('Firestore getUserRole timeout fallback to local cache: $e');
    }

    // Fallback ke SharedPreferences lokal jika timeout/koneksi lambat
    final prefs = await SharedPreferences.getInstance();
    final bool isTeacher = prefs.getBool('isTeacher') ?? false;
    return isTeacher ? 'teacher' : 'student';
  }

  /// Meng-update timestamp aktivitas terakhir user di Firestore
  static Future<void> updateLastActive() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _usersRef.doc(user.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        }).timeout(const Duration(milliseconds: 2000));
      }
    } catch (e) {
      debugPrint('Error updateLastActive: $e');
    }
  }

  // ===========================================================================
  // 2. MANAJEMEN MATERI, VIDEO, & BANK SOAL (CLOUD FIRESTORE)
  // ===========================================================================

  /// Sinkronisasi materi default ke Firestore jika koleksi masih kosong
  static Future<void> syncDefaultMateriIfEmpty(List<dynamic> defaultList) async {
    try {
      final snapshot = await _materiRef.limit(1).get().timeout(const Duration(milliseconds: 2500));
      if (snapshot.docs.isEmpty) {
        debugPrint('Menginisialisasi koleksi materi di Firestore...');
        final WriteBatch batch = _db.batch();
        for (var item in defaultList) {
          final itemMap = Map<String, dynamic>.from(item as Map);
          final String id = itemMap['id'] ?? 'mat_${DateTime.now().millisecondsSinceEpoch}';
          batch.set(_materiRef.doc(id), itemMap);
        }
        await batch.commit().timeout(const Duration(milliseconds: 3000));
        debugPrint('Berhasil mengunggah materi default ke Firestore.');
      }
    } catch (e) {
      debugPrint('Error syncDefaultMateriIfEmpty: $e');
    }
  }

  /// Mengambil seluruh daftar materi dan bank soal dari Cloud Firestore
  static Future<List<Map<String, dynamic>>> getMateriList() async {
    try {
      final snapshot = await _materiRef.get().timeout(const Duration(milliseconds: 2500));
      if (snapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        const orderMap = {
          'pretest': 0,
          'linkedlist': 1,
          'stack': 2,
          'queue': 3,
          'searching_sorting': 4,
          'posttest': 5,
        };

        list.sort((a, b) {
          final int orderA = orderMap[a['id']] ?? 99;
          final int orderB = orderMap[b['id']] ?? 99;
          return orderA.compareTo(orderB);
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_teacher_materi_v10', jsonEncode(list));

        return list;
      }
    } catch (e) {
      debugPrint('Error getMateriList Firestore: $e');
    }
    return [];
  }

  /// Menyimpan atau memperbarui modul / paket soal ujian di Cloud Firestore
  static Future<void> saveOrUpdateMateri(Map<String, dynamic> materiData) async {
    try {
      final String id = materiData['id'] ?? 'mat_${DateTime.now().millisecondsSinceEpoch}';
      final Map<String, dynamic> firestoreData = Map<String, dynamic>.from(materiData);
      firestoreData['id'] = id;
      firestoreData['updatedAt'] = FieldValue.serverTimestamp();

      await _materiRef.doc(id).set(firestoreData, SetOptions(merge: true)).timeout(const Duration(milliseconds: 3000));
      debugPrint('Materi $id berhasil disimpan di Firestore.');
    } catch (e) {
      debugPrint('Error saveOrUpdateMateri Firestore: $e');
    }
  }

  /// Menghapus modul dari Cloud Firestore
  static Future<void> deleteMateri(String id) async {
    try {
      await _materiRef.doc(id).delete().timeout(const Duration(milliseconds: 2500));
      debugPrint('Materi $id berhasil dihapus dari Firestore.');
    } catch (e) {
      debugPrint('Error deleteMateri Firestore: $e');
    }
  }

  /// Mengambil bank soal untuk modul tertentu dari Cloud Firestore
  static Future<List<dynamic>?> getQuestionsForModule(String moduleId) async {
    try {
      final cleanId = moduleId.toLowerCase().trim();
      final list = await getMateriList();

      final found = list.firstWhere((m) {
        final mId = (m['id'] ?? '').toString().toLowerCase();
        final modul = (m['modul'] ?? '').toString().toLowerCase();
        final title = (m['title'] ?? '').toString().toLowerCase();

        if (cleanId == 'pretest' && (mId == 'pretest' || modul.contains('awal') || title.contains('pre-test'))) return true;
        if (cleanId == 'posttest' && (mId == 'posttest' || modul.contains('akhir') || title.contains('post-test'))) return true;
        if (cleanId == 'linkedlist' && (mId.contains('linkedlist') || modul.contains('1') || title.contains('linked list'))) return true;
        if (cleanId == 'stack' && (mId.contains('stack') || modul.contains('2') || title.contains('stack'))) return true;
        if (cleanId == 'queue' && (mId.contains('queue') || modul.contains('3') || title.contains('queue'))) return true;
        if (cleanId == 'searching_sorting' && (mId.contains('searching') || modul.contains('4') || title.contains('searching'))) return true;

        return mId == cleanId || modul.contains(cleanId);
      }, orElse: () => {});

      if (found.isNotEmpty && found['questions'] != null) {
        final qList = found['questions'] as List;
        if (qList.isNotEmpty) {
          return qList;
        }
      }
    } catch (e) {
      debugPrint('Error getQuestionsForModule Firestore: $e');
    }
    return null;
  }

  // ===========================================================================
  // 3. MANAJEMEN PROGRES SISWA & NILAI EVALUASI REALTIME (CLOUD FIRESTORE)
  // ===========================================================================

  /// Menyimpan nilai evaluasi & progres belajar siswa di Cloud Firestore secara Asinkron
  static Future<void> saveStudentProgress({
    required String name,
    required String email,
    required String preTestScore,
    String assessment1 = '-',
    String assessment2 = '-',
    String assessment3 = '-',
    String assessment4 = '-',
    String postTestScore = '-',
    String status = 'Belum Ujian',
    List<String>? completedSteps,
    Map<String, dynamic>? posttestDiagnostics,
  }) async {
    unawaited(_asyncSaveStudentProgress(
      name: name,
      email: email,
      preTestScore: preTestScore,
      assessment1: assessment1,
      assessment2: assessment2,
      assessment3: assessment3,
      assessment4: assessment4,
      postTestScore: postTestScore,
      status: status,
      completedSteps: completedSteps,
      posttestDiagnostics: posttestDiagnostics,
    ));
  }

  static Future<void> _asyncSaveStudentProgress({
    required String name,
    required String email,
    required String preTestScore,
    required String assessment1,
    required String assessment2,
    required String assessment3,
    required String assessment4,
    required String postTestScore,
    required String status,
    List<String>? completedSteps,
    Map<String, dynamic>? posttestDiagnostics,
  }) async {
    try {
      final String emailClean = email.toLowerCase().trim();
      final String docId = emailClean.replaceAll(RegExp(r'[^\w.-]'), '_');

      final docSnapshot = await _progressRef.doc(docId).get().timeout(const Duration(milliseconds: 2000));
      Map<String, dynamic> existing = {};
      if (docSnapshot.exists && docSnapshot.data() != null) {
        existing = docSnapshot.data() as Map<String, dynamic>;
      }

      final String finalPre = preTestScore != '-' ? preTestScore : (existing['preTest'] ?? '-');
      final String finalA1 = assessment1 != '-' ? assessment1 : (existing['assessment1'] ?? '-');
      final String finalA2 = assessment2 != '-' ? assessment2 : (existing['assessment2'] ?? '-');
      final String finalA3 = assessment3 != '-' ? assessment3 : (existing['assessment3'] ?? '-');
      final String finalA4 = assessment4 != '-' ? assessment4 : (existing['assessment4'] ?? '-');
      final String finalPost = postTestScore != '-' ? postTestScore : (existing['postTest'] ?? '-');
      final String finalStatus = status != 'Belum Ujian' ? status : (existing['status'] ?? 'Belum Ujian');

      final progressData = {
        'name': name,
        'email': emailClean,
        'preTest': finalPre,
        'assessment1': finalA1,
        'assessment2': finalA2,
        'assessment3': finalA3,
        'assessment4': finalA4,
        'postTest': finalPost,
        'status': finalStatus,
        if (completedSteps != null) 'completedSteps': completedSteps,
        if (posttestDiagnostics != null) 'posttestDiagnostics': posttestDiagnostics,
        'lastActive': FieldValue.serverTimestamp(),
      };

      await _progressRef.doc(docId).set(progressData, SetOptions(merge: true)).timeout(const Duration(milliseconds: 2500));
      debugPrint('Progres siswa $emailClean berhasil disimpan di Firestore.');
    } catch (e) {
      debugPrint('Error saveStudentProgress Firestore: $e');
    }
  }

  /// Stream Realtime Progres Seluruh Siswa untuk Dashboard Guru
  static Stream<List<Map<String, dynamic>>> streamStudentProgressList() {
    return _progressRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data;
      }).toList();
    });
  }

  /// Mengambil daftar progres seluruh siswa dari Firestore
  static Future<List<Map<String, dynamic>>> getStudentList() async {
    try {
      final snapshot = await _progressRef.get().timeout(const Duration(milliseconds: 2500));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error getStudentList Firestore: $e');
    }
    return [];
  }
}