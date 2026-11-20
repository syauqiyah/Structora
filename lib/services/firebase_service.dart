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

  /// Validasi dan pengambil data peran (role) terdaftar dari Cloud Firestore berdasarkan UID atau Email
  static Future<String?> getUserRoleByUidOrEmail(String uid, String email) async {
    final String cleanEmail = email.toLowerCase().trim();

    try {
      // 1. Cek dokumen Firestore berdasarkan UID
      if (uid.isNotEmpty) {
        final doc = await _usersRef
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 3));
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final role = (data['role'] ?? (data['isTeacher'] == true ? 'teacher' : 'student'))
              .toString()
              .toLowerCase()
              .trim();
          if (role.isNotEmpty) return role;
        }
      }

      // 2. Cek dokumen Firestore berdasarkan Query Email jika UID tidak ditemukan
      if (cleanEmail.isNotEmpty) {
        final query = await _usersRef
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 3));
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data() as Map<String, dynamic>;
          final role = (data['role'] ?? (data['isTeacher'] == true ? 'teacher' : 'student'))
              .toString()
              .toLowerCase()
              .trim();
          if (role.isNotEmpty) return role;
        }
      }
    } catch (e) {
      debugPrint('Error getUserRoleByUidOrEmail: $e');
    }

    // 3. Fallback: Cek akhiran domain email institusi guru
    if (cleanEmail.endsWith('@structora.app')) {
      return 'teacher';
    }

    return null;
  }

  /// Memperbarui kata sandi baru pengguna (Guru & Siswa) di Cloud Firestore & local cache
  static Future<bool> updateUserPassword({
    required String email,
    required String newPassword,
  }) async {
    final String cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty || newPassword.length < 6) return false;

    bool updatedInFirestore = false;

    // 1. Simpan ke SharedPreferences lokal terlepas dari koneksi
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_password_$cleanEmail', newPassword);
    } catch (e) {
      debugPrint('Error local prefs updateUserPassword: $e');
    }

    // 2. Cari dokumen user di Firestore koleksi 'users' berdasarkan email
    try {
      final query = await _usersRef
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;
        await docRef.set({
          'password': newPassword,
          'custom_password': newPassword,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        updatedInFirestore = true;
      } else {
        final safeId = cleanEmail.replaceAll(RegExp(r'[^\w.-]'), '_');
        await _usersRef.doc(safeId).set({
          'email': cleanEmail,
          'password': newPassword,
          'custom_password': newPassword,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        updatedInFirestore = true;
      }
    } catch (e) {
      debugPrint('Firestore updateUserPassword notice: $e');
    }

    return updatedInFirestore || true;
  }

  /// Memverifikasi kata sandi kustom pengguna jika login FirebaseAuth mengembalikan wrong-password
  static Future<bool> verifyCustomUserPassword({
    required String email,
    required String inputPassword,
  }) async {
    final String cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty || inputPassword.isEmpty) return false;

    // 1. Cek SharedPreferences lokal
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localPass = prefs.getString('custom_password_$cleanEmail');
      if (localPass != null && localPass.isNotEmpty && localPass == inputPassword) {
        return true;
      }
    } catch (_) {}

    // 2. Cek Cloud Firestore koleksi 'users'
    try {
      final query = await _usersRef
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data() as Map<String, dynamic>;
        final String? savedPass = (data['custom_password'] ?? data['password'])?.toString();
        if (savedPass != null && savedPass.isNotEmpty && savedPass == inputPassword) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('custom_password_$cleanEmail', savedPass);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firestore verifyCustomUserPassword notice: $e');
    }

    return false;
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

  /// Mengambil seluruh daftar materi dan bank soal dari Cloud Firestore secara real-time / server-first
  static Future<List<Map<String, dynamic>>> getMateriList() async {
    try {
      QuerySnapshot snapshot;
      try {
        // Selalu tarik data terbaru dari server Cloud Firestore terlebih dahulu (Source.serverAndCache)
        snapshot = await _materiRef
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Notice serverAndCache getMateriList: $e');
        snapshot = await _materiRef.get();
      }

      if (snapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> list = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final cleanData = Map<String, dynamic>.from(data);
          cleanData['id'] = doc.id;
          cleanData.forEach((key, value) {
            if (value is Timestamp) {
              cleanData[key] = value.toDate().toIso8601String();
            } else if (value != null && (value is FieldValue || value.runtimeType.toString().contains('FieldValue'))) {
              cleanData[key] = DateTime.now().toIso8601String();
            }
          });
          return cleanData;

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
        await prefs.setString(
          'custom_teacher_materi_v13',
          jsonEncode(list, toEncodable: (nonEncodable) {
            if (nonEncodable is Timestamp) return nonEncodable.toDate().toIso8601String();
            if (nonEncodable is DateTime) return nonEncodable.toIso8601String();
            return nonEncodable.toString();
          }),
        );

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
      firestoreData['updatedAt'] = DateTime.now().toIso8601String();

      await _materiRef.doc(id).set(firestoreData, SetOptions(merge: true)).timeout(const Duration(seconds: 15));
      debugPrint('Materi $id berhasil disimpan di Firestore.');
    } catch (e) {
      debugPrint('Error saveOrUpdateMateri Firestore: $e');
      rethrow;
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
    int violations = 0,
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
      violations: violations,
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
    required int violations,
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
      final int existViolations = int.tryParse((existing['violations'] ?? '0').toString()) ?? 0;
      final int finalViolations = violations > 0 ? violations : existViolations;

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
        'violations': finalViolations,
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

  /// Menghasilkan kunci SharedPreferences spesifik per email pengguna (User-Scoped Key)
  static String getUserKey(String email, String baseKey) {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return baseKey;
    final safeEmail = cleanEmail.replaceAll(RegExp(r'[^\w.-]'), '_');
    return '${baseKey}_$safeEmail';
  }

  /// Melakukan sinkronisasi progres belajar siswa berbasis akun (Scoped User Key).
  /// Setiap akun memiliki kunci penyimpanan terpisah di perangkat tanpa menghapus data akun lain.
  static Future<void> syncUserProgressOnLogin(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cleanEmail = email.toLowerCase().trim();
      if (cleanEmail.isEmpty) return;

      final String userKeySteps = getUserKey(cleanEmail, 'completed_steps');
      final String userKeyPreBool = getUserKey(cleanEmail, 'isPreTestCompleted');
      final String userKeyPreInt = getUserKey(cleanEmail, 'preTestScore');
      final String userKeyPostBool = getUserKey(cleanEmail, 'isPostTestCompleted');
      final String userKeyPostInt = getUserKey(cleanEmail, 'postTestScore');

      await prefs.setString('last_logged_in_user_email', cleanEmail);
      await prefs.setString('userEmail', cleanEmail);

      final String docId = cleanEmail.replaceAll(RegExp(r'[^\w.-]'), '_');
      final docSnapshot = await _progressRef.doc(docId).get().timeout(const Duration(milliseconds: 2500));

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        if (!prefs.containsKey(userKeySteps) && data['completedSteps'] != null && data['completedSteps'] is List) {
          final List<String> steps =
              (data['completedSteps'] as List).map((e) => e.toString()).toList();
          await prefs.setStringList(userKeySteps, steps);
        }

        final String preStr = (data['preTest'] ?? '-').toString();
        if (preStr != '-' && !prefs.containsKey(userKeyPreInt)) {
          final int pVal = int.tryParse(preStr) ?? 0;
          await prefs.setBool(userKeyPreBool, true);
          await prefs.setInt(userKeyPreInt, pVal);
        }

        final String postStr = (data['postTest'] ?? '-').toString();
        if (postStr != '-' && !prefs.containsKey(userKeyPostInt)) {
          final int poVal = int.tryParse(postStr) ?? 0;
          await prefs.setBool(userKeyPostBool, true);
          await prefs.setInt(userKeyPostInt, poVal);
        }

        final String a1 = (data['assessment1'] ?? '-').toString();
        final String kA1 = getUserKey(cleanEmail, 'score_linkedlist');
        if (a1 != '-' && !prefs.containsKey(kA1)) await prefs.setInt(kA1, int.tryParse(a1) ?? 0);

        final String a2 = (data['assessment2'] ?? '-').toString();
        final String kA2 = getUserKey(cleanEmail, 'score_stack');
        if (a2 != '-' && !prefs.containsKey(kA2)) await prefs.setInt(kA2, int.tryParse(a2) ?? 0);

        final String a3 = (data['assessment3'] ?? '-').toString();
        final String kA3 = getUserKey(cleanEmail, 'score_queue');
        if (a3 != '-' && !prefs.containsKey(kA3)) await prefs.setInt(kA3, int.tryParse(a3) ?? 0);

        final String a4 = (data['assessment4'] ?? '-').toString();
        final String kA4 = getUserKey(cleanEmail, 'score_searching_sorting');
        if (a4 != '-' && !prefs.containsKey(kA4)) await prefs.setInt(kA4, int.tryParse(a4) ?? 0);
      }
    } catch (e) {
      debugPrint('Error syncUserProgressOnLogin: $e');
    }
  }
}