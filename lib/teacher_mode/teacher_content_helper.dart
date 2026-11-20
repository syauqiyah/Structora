import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/materi_model.dart';
import '../services/auto_translate_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_translations.dart';
import '../data/quiz_data.dart';

class TeacherContentHelper {
  // Key v13 agar data Pre-Test, Post-Test, & Modul default KKM 75 terpasang penuh
  static const String _materiKey = 'custom_teacher_materi_v13';
  static bool _hasSyncedFirestore = false;

  static List get _defaultMateriList => [
    // EVALUASI 1: PRE-TEST (30 Soal Lengkap)
    {
      'id': 'pretest',
      'modul': 'Evaluasi Awal',
      'modul_en': 'Initial Evaluation',
      'title': 'Pre-Test: Uji Kemampuan Awal',
      'title_en': 'Pre-Test: Initial Skill Assessment',
      'displayQuestionCount': 30,
      'desc':
      '''Petunjuk Ujian Pre-Test:
Pre-Test ini bertujuan untuk mengukur pemahaman awal peserta didik terkait dasar-dasar struktur data (Linked List, Stack, Queue, Searching & Sorting) sebelum memulai pembelajaran bertahap.

Ketentuan:
1. Kerjakan secara mandiri dengan teliti.
2. Hasil nilai Pre-Test akan menjadi tolak ukur awal kompetensi siswa sebelum mempelajari modul kurikulum.''',
      'desc_en':
      '''Pre-Test Instructions:
This Pre-Test aims to measure students' initial understanding of data structure fundamentals (Linked List, Stack, Queue, Searching & Sorting) before beginning the step-by-step learning modules.

Rules:
1. Complete independently and thoroughly.
2. Pre-Test results serve as a baseline for student competency before taking curriculum modules.''',
      'videoUrl': '',
      'questions': preTestQuestions,
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 1: LINKED LIST (30 Soal Lengkap)
    {
      'id': 'linkedlist',
      'modul': 'Pertemuan 1',
      'modul_en': 'Meeting 1',
      'title': 'Modul 1: Linked List',
      'title_en': 'Module 1: Linked List',
      'displayQuestionCount': 30,
      'desc':
      '''A. Pengertian:
Linked List adalah struktur data linier yang tersusun dari kumpulan elemen bernama Node. Berbeda dengan Array statis yang ukurannya kaku dan harus berurutan di memori komputer, Linked List bersifat dinamis sehingga penambahan atau pengurangan elemen dapat dilakukan secara fleksibel tanpa perlu menggeser posisi data lainnya.

B. Komponen Utama Node:
1. Data atau Value: Nilai atau informasi aktual yang tersimpan di dalam node.
2. Next Pointer: Penunjuk alamat memori yang menghubungkan node saat ini ke node berikutnya.
3. Head: Pintu masuk utama atau node pertama di dalam linked list.
4. NULL Pointer: Penunjuk khusus di node paling akhir yang menandakan ujung dari rantai data.

C. Jenis-Jenis Linked List:
1. Singly Linked List: Setiap node hanya memiliki satu pointer yang mengarah ke depan. Penelusuran hanya bisa dilakukan satu arah dari Head ke belakang.
2. Doubly Linked List: Setiap node memiliki dua pointer, yaitu penunjuk ke node sebelumnya (Prev) dan ke node berikutnya (Next). Data dapat dijelajahi dua arah, baik maju maupun mundur.
3. Circular Linked List: Node terakhir tidak mengarah ke NULL, melainkan tersambung kembali ke node pertama sehingga membentuk siklus melingkar.

D. Operasi Dasar dan Cara Kerja:
1. Traversal: Mengunjungi setiap node satu demi satu untuk membaca atau menampilkan isi data.
2. Insertion: Menyisipkan node baru.
3. Deletion: Menghapus node tertentu dengan cara menyambungkan pointer node sebelumnya langsung ke node sesudahnya.
4. Searching: Mencari keberadaan nilai data tertentu di dalam untaian node.

E. Analogi Nyata:
Bayangkan rangkaian gerbong kereta api atau permainan berburu harta karun.''',
      'desc_en':
      '''A. Definition:
A Linked List is a linear data structure composed of a collection of elements called Nodes. Unlike a static Array whose size is fixed and contiguous in memory, a Linked List is dynamic, allowing elements to be inserted or removed flexibly without shifting existing items.

B. Main Components of a Node:
1. Data or Value: The actual data or value stored within the node.
2. Next Pointer: Memory address reference linking the current node to the next node.
3. Head: The main entry point or first node of the linked list.
4. NULL Pointer: Special pointer at the last node signaling the end of the chain.

C. Types of Linked Lists:
1. Singly Linked List: Each node contains one pointer pointing forward.
2. Doubly Linked List: Each node contains two pointers (Prev and Next) for bidirectional navigation.
3. Circular Linked List: The last node points back to the Head node, forming a closed loop.

D. Basic Operations:
1. Traversal: Visiting each node sequentially.
2. Insertion: Adding a new node.
3. Deletion: Removing a node by updating neighboring pointers.
4. Searching: Finding a target value.

E. Real-Life Analogy:
Think of train carriages connected in sequence or a treasure hunt game.''',
      'videoUrl': 'https://www.youtube.com/watch?v=uCC3Kg8ms-w',
      'questions': asesmenModulQuestions['linkedlist'] ?? [],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 2: STACK (30 Soal Lengkap)
    {
      'id': 'stack',
      'modul': 'Pertemuan 2',
      'modul_en': 'Meeting 2',
      'title': 'Modul 2: Stack (Tumpukan Data)',
      'title_en': 'Module 2: Stack',
      'displayQuestionCount': 30,
      'desc':
      '''A. Pengertian:
Stack adalah struktur data linier yang mengikuti prinsip LIFO (Last In First Out), di mana elemen data yang terakhir dimasukkan ke dalam tumpukan akan menjadi elemen pertama yang dikeluarkan.

B. Operasi Utama Stack:
1. Push: Menambahkan elemen baru ke posisi paling atas (Top) dari tumpukan.
2. Pop: Mengambil dan menghapus elemen yang berada di posisi paling atas (Top).
3. Peek / Top: Melihat data pada posisi teratas tanpa menghapusnya dari tumpukan.
4. IsEmpty: Memeriksa apakah tumpukan data dalam keadaan kosong.

C. Kondisi Khusus:
1. Stack Overflow: Terjadi ketika mencoba melakukan Push pada memori tumpukan yang sudah penuh.
2. Stack Underflow: Terjadi ketika mencoba melakukan Pop pada tumpukan yang kosong.

D. Analogi Nyata:
Bayangkan tumpukan piring di meja makan prasmanan atau tumpukan buku di dalam kardus sempit.''',
      'desc_en':
      '''A. Definition:
Stack is a linear data structure adhering to the LIFO (Last In First Out) principle, where the last item inserted is the first removed.

B. Key Operations:
1. Push: Inserts a new element at the Top.
2. Pop: Removes and retrieves the top element.
3. Peek / Top: Inspects the top element without removing it.
4. IsEmpty: Checks if the stack is empty.

C. Boundary Conditions:
1. Stack Overflow: Triggered when pushing to a full stack.
2. Stack Underflow: Triggered when popping from an empty stack.

D. Real-Life Analogy:
A stack of clean plates at a buffet or books in a box.''',
      'videoUrl': 'https://www.youtube.com/watch?v=ZwSFBSkIdss',
      'questions': asesmenModulQuestions['stack'] ?? [],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 3: QUEUE (30 Soal Lengkap)
    {
      'id': 'queue',
      'modul': 'Pertemuan 3',
      'modul_en': 'Meeting 3',
      'title': 'Modul 3: Queue (Antrean Terurut)',
      'title_en': 'Module 3: Queue',
      'displayQuestionCount': 30,
      'desc':
      '''A. Pengertian:
Queue adalah struktur data linier yang beroperasi dengan prinsip FIFO (First In First Out), artinya elemen yang masuk pertama kali ke dalam antrean akan menjadi yang pertama kali diproses atau keluar.

B. Penunjuk dan Operasi Queue:
1. Front: Penunjuk (pointer) ke posisi terdepan antrean untuk proses pengeluaran data.
2. Rear / Tail: Penunjuk (pointer) ke posisi paling belakang antrean untuk penambahan data.
3. Enqueue: Operasi memasukkan elemen baru ke bagian belakang (Rear) antrean.
4. Dequeue: Operasi mengeluarkan elemen dari posisi terdepan (Front) antrean.

C. Contoh Penerapan:
Antrean pencetakan dokumen pada printer (Print Spooler), sistem antrean layanan pelanggan, dan penjadwalan proses CPU.

D. Analogi Nyata:
Bayangkan barisan antrean pembeli karcis bioskop atau antrean kasir supermarket.''',
      'desc_en':
      '''A. Definition:
Queue is a linear data structure using the FIFO (First In First Out) principle, where the earliest arrival is processed first.

B. Pointers and Operations:
1. Front: Pointer referencing the front end.
2. Rear / Tail: Pointer referencing the rear end.
3. Enqueue: Appends new elements at the rear.
4. Dequeue: Removes leading elements from the front.

C. Practical Applications:
Print Spooler, customer service queueing, and CPU process scheduling.''',
      'videoUrl': 'https://www.youtube.com/watch?v=9xpWSCEcMzc',
      'questions': asesmenModulQuestions['queue'] ?? [],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 4: SEARCHING & SORTING (30 Soal Lengkap)
    {
      'id': 'searching_sorting',
      'modul': 'Pertemuan 4',
      'modul_en': 'Meeting 4',
      'title': 'Modul 4: Searching & Sorting Algorithm',
      'title_en': 'Module 4: Searching & Sorting Algorithm',
      'displayQuestionCount': 30,
      'desc':
      '''A. Algoritma Pencarian (Searching):
1. Linear Search: Memeriksa elemen array satu per satu secara berurutan dari awal hingga akhir.
2. Binary Search: Mencari data dengan cara membagi ruang pencarian menjadi dua secara berulang (wajib terurut).

B. Algoritma Pengurutan (Sorting):
1. Bubble Sort: Mengurutkan data dengan membandingkan pasangan elemen yang bersebelahan.
2. Selection Sort: Mengurutkan data dengan mencari nilai terkecil/terbesar dan menukarnya ke posisi tujuan.

C. Karakteristik Kompleksitas:
Linear Search O(n), Binary Search O(log n), Bubble/Selection Sort O(n^2).''',
      'desc_en':
      '''A. Searching Algorithms:
1. Linear Search: Sequentially verifies array elements from start to end.
2. Binary Search: Repeatedly splits search range in half (strictly requires pre-sorted arrays).

B. Sorting Algorithms:
1. Bubble Sort: Repeatedly compares and swaps adjacent out-of-order pairs.
2. Selection Sort: Isolates minimum/maximum elements and places them in target positions.

C. Complexity Highlights:
Linear Search O(n), Binary Search O(log n), Bubble/Selection Sort O(n^2).''',
      'videoUrl': 'https://www.youtube.com/watch?v=RN4wc9ClciM',
      'questions': asesmenModulQuestions['searching_sorting'] ?? [],
      'createdAt': '30/10/2026',
    },

    // EVALUASI 2: POST-TEST (35 Soal Lengkap)
    {
      'id': 'posttest',
      'modul': 'Evaluasi Akhir',
      'modul_en': 'Final Evaluation',
      'title': 'Post-Test: Evaluasi Akhir Kelulusan',
      'title_en': 'Post-Test: Final Graduation Evaluation',
      'displayQuestionCount': 35,
      'desc':
      '''Petunjuk Ujian Post-Test:
Post-Test merupakan evaluasi komprehensif akhir untuk seluruh modul pembelajaran struktur data (Linked List, Stack, Queue, Searching & Sorting).

Ketentuan Kelulusan:
1. Standar KKM adalah nilai 75.
2. Siswa yang lulus akan membuka sertifikasi ketuntasan belajar. Siswa yang belum mencapai nilai 75 dapat mengulang ujian remedial.''',
      'desc_en':
      '''Post-Test Exam Instructions:
Post-Test is the final comprehensive evaluation covering all data structure learning modules (Linked List, Stack, Queue, Searching & Sorting).

Graduation Requirements:
1. Passing standard is score 75.
2. Students who pass will earn competency certification. Students scoring below 75 may retake the remedial exam.''',
      'videoUrl': '',
      'questions': postTestQuestions,
      'createdAt': '30/10/2026',
    },
  ];

  static String _cleanNorm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  static Map<String, dynamic> sanitizeMateriItem(Map rawItem) {
    final Map<String, dynamic> item = Map<String, dynamic>.from(rawItem);

    final String titleIndo = (item['title'] ?? item['judulId'] ?? '').toString();
    final String titleEng = (item['title_en'] ?? item['titleEn'] ?? item['judulEn'] ?? '').toString();
    final String finalTitleEn = (titleEng.isNotEmpty && _cleanNorm(titleEng) != _cleanNorm(titleIndo))
        ? titleEng
        : AppText.auto(titleIndo);
    item['title'] = titleIndo;
    item['title_en'] = finalTitleEn;
    item['judulId'] = titleIndo;
    item['judulEn'] = finalTitleEn;

    final String modulIndo = (item['modul'] ?? item['modulId'] ?? '').toString();
    final String modulEng = (item['modul_en'] ?? item['modulEn'] ?? '').toString();
    final String finalModulEn = (modulEng.isNotEmpty && _cleanNorm(modulEng) != _cleanNorm(modulIndo))
        ? modulEng
        : AppText.auto(modulIndo);
    item['modul'] = modulIndo;
    item['modul_en'] = finalModulEn;
    item['modulId'] = modulIndo;
    item['modulEn'] = finalModulEn;

    final String descIndo = (item['desc'] ?? item['deskripsiId'] ?? '').toString();
    final String descEng = (item['desc_en'] ?? item['descEn'] ?? item['deskripsiEn'] ?? '').toString();
    final String finalDescEn = (descEng.isNotEmpty && _cleanNorm(descEng) != _cleanNorm(descIndo))
        ? descEng
        : AppText.auto(descIndo);
    item['desc'] = descIndo;
    item['desc_en'] = finalDescEn;
    item['deskripsiId'] = descIndo;
    item['deskripsiEn'] = finalDescEn;

    if (item['questions'] != null && item['questions'] is List) {
      item['questions'] = sanitizeQuestionList(item['questions'] as List);
    }

    if (item['displayQuestionCount'] != null) {
      final parsedCount = int.tryParse(item['displayQuestionCount'].toString());
      if (parsedCount != null) {
        item['displayQuestionCount'] = parsedCount;
      }
    }
    if (item['durationMinutes'] != null) {
      final parsedDur = int.tryParse(item['durationMinutes'].toString());
      if (parsedDur != null) {
        item['durationMinutes'] = parsedDur;
      }
    }

    return item;
  }

  /// Sinkronisasi aman materi default ke Firestore:
  /// Hanya mengisi dokumen default jika dokumen tersebut BELUM ADA di Firestore (!docSnapshot.exists),
  /// atau jika sudah ada, hanya melengkapi field dwibahasa (_en) yang masih kosong TANPA menimpa / mengurangi array questions,
  /// displayQuestionCount, dan durationMinutes yang telah disimpan atau di-import oleh Guru.
  static Future<void> syncDefaultMateriToFirestore() async {
    if (_hasSyncedFirestore) return;
    _hasSyncedFirestore = true;

    try {
      debugPrint('Memeriksa dan menyinkronkan materi default ke Firestore tanpa menimpa data kustom guru...');

      for (var rawItem in _defaultMateriList) {
        if (rawItem is! Map) continue;
        final Map<String, dynamic> defaultItemMap = sanitizeMateriItem(rawItem);
        final String id = (defaultItemMap['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final DocumentReference docRef =
        FirebaseFirestore.instance.collection('materi').doc(id);

        try {
          final docSnapshot = await docRef.get().timeout(const Duration(seconds: 4));

          if (!docSnapshot.exists) {
            // Dokumen belum ada di Firestore -> Tulis seluruh dokumen default
            await docRef.set(defaultItemMap, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
          } else {
            // Dokumen sudah ada di Firestore -> HANYA lengkapi field dwibahasa yang kosong, TANPA menimpa questions / displayQuestionCount / durationMinutes milik Guru
            final Map<String, dynamic> existingData =
            Map<String, dynamic>.from(docSnapshot.data() as Map? ?? {});

            final Map<String, dynamic> updateFields = {};

            if ((existingData['title_en'] ?? '').toString().trim().isEmpty) {
              updateFields['title_en'] = defaultItemMap['title_en'];
              updateFields['judulEn'] = defaultItemMap['judulEn'];
            }
            if ((existingData['desc_en'] ?? '').toString().trim().isEmpty) {
              updateFields['desc_en'] = defaultItemMap['desc_en'];
              updateFields['deskripsiEn'] = defaultItemMap['deskripsiEn'];
            }
            if ((existingData['modul_en'] ?? '').toString().trim().isEmpty) {
              updateFields['modul_en'] = defaultItemMap['modul_en'];
              updateFields['modulEn'] = defaultItemMap['modulEn'];
            }

            // Jika array questions di Firestore masih null atau kosong, baru diisi dari default
            if (existingData['questions'] == null ||
                (existingData['questions'] is List && (existingData['questions'] as List).isEmpty)) {
              updateFields['questions'] = defaultItemMap['questions'];
            }

            if (existingData['displayQuestionCount'] == null && defaultItemMap['displayQuestionCount'] != null) {
              updateFields['displayQuestionCount'] = defaultItemMap['displayQuestionCount'];
            }
            if (existingData['durationMinutes'] == null && defaultItemMap['durationMinutes'] != null) {
              updateFields['durationMinutes'] = defaultItemMap['durationMinutes'];
            }

            if (updateFields.isNotEmpty) {
              await docRef.set(updateFields, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
            }
          }
        } catch (e) {
          debugPrint('Notice check doc $id: $e');
        }
      }
      debugPrint('Berhasil menyinkronkan materi default tanpa merusak data kustom guru.');
    } catch (e) {
      debugPrint('Notice syncDefaultMateriToFirestore: $e');
    }
  }

  static Future<List<dynamic>> getMateriList() async {
    await syncDefaultMateriToFirestore();
    await FirebaseService.syncDefaultMateriIfEmpty(_defaultMateriList);

    List<dynamic> listToProcess = [];
    final firestoreList = await FirebaseService.getMateriList();
    if (firestoreList.isNotEmpty) {
      listToProcess = firestoreList;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? rawJson = prefs.getString(_materiKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson);
          if (decoded is List && decoded.isNotEmpty) {
            listToProcess = decoded;
          }
        } catch (_) {}
      }
      if (listToProcess.isEmpty) {
        listToProcess = _defaultMateriList;
      }
    }

    return listToProcess.map((item) {
      if (item is Map) {
        return sanitizeMateriItem(item);
      }
      return item;
    }).toList();
  }

  static List<Map<String, dynamic>> sanitizeQuestionList(List rawQuestions) {
    final List<Map<String, dynamic>> result = [];
    for (var item in rawQuestions) {
      if (item is! Map) continue;
      final Map qMap = item;

      final String qIndo = (qMap['q'] ?? qMap['question'] ?? '').toString().trim();
      if (qIndo.isEmpty) continue;

      final master = findMasterQuizQuestion(qIndo);

      String qEng = (qMap['q_en'] ?? qMap['question_en'] ?? '').toString().trim();
      if (qEng.isEmpty || _cleanNorm(qEng) == _cleanNorm(qIndo)) {
        if (master != null) {
          qEng = (master['question_en'] ?? master['q_en'] ?? '').toString().trim();
        }
      }
      if (qEng.isEmpty || _cleanNorm(qEng) == _cleanNorm(qIndo)) {
        qEng = AppText.auto(qIndo);
      }

      final List rawOpts = (qMap['options'] as List? ?? []);
      final List<String> optsIndo = rawOpts.map((e) => e.toString().trim()).toList();

      final List rawOptsEn = (qMap['options_en'] as List? ?? []);
      List<String> optsEng = rawOptsEn.map((e) => e.toString().trim()).toList();

      if (optsEng.isEmpty || optsEng.join('') == optsIndo.join('')) {
        if (master != null && master['options_en'] != null) {
          final mOpts = List<String>.from(master['options']);
          final mOptsEn = List<String>.from(master['options_en']);
          optsEng = optsIndo.map((opt) {
            final idx = mOpts.indexOf(opt);
            return (idx != -1 && idx < mOptsEn.length) ? mOptsEn[idx] : AppText.auto(opt);
          }).toList();
        } else {
          optsEng = optsIndo.map((o) => AppText.auto(o)).toList();
        }
      }

      final String expIndo = (qMap['explanation'] ?? 'Jawaban benar berdasarkan naskah materi yang disusun oleh guru.').toString().trim();
      String expEng = (qMap['explanation_en'] ?? '').toString().trim();
      if (expEng.isEmpty || _cleanNorm(expEng) == _cleanNorm(expIndo)) {
        if (master != null) {
          expEng = (master['explanation_en'] ?? '').toString().trim();
        }
      }
      if (expEng.isEmpty || _cleanNorm(expEng) == _cleanNorm(expIndo)) {
        expEng = AppText.auto(expIndo);
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
        // Only true when the English text came from the API / curated bank,
        // never from the offline fallback above.
        'en_ok': qMap['en_ok'] == true,
      });
    }
    return result;
  }

  static Future<void> saveMateriModel(MateriModel model) async {
    final Map<String, dynamic> data = model.toMap();
    await FirebaseService.saveOrUpdateMateri(data);

    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();
    list.removeWhere((item) => item['id'] == model.id);
    list.add(data);
    await prefs.setString(_materiKey, _safeJsonEncode(list));
  }

  static Future<void> updateMateriModel(MateriModel model) async {
    final Map<String, dynamic> data = model.toMap();
    await FirebaseService.saveOrUpdateMateri(data);

    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();

    final int index = list.indexWhere((item) => item['id'] == model.id);
    if (index != -1) {
      list[index] = data;
      await prefs.setString(_materiKey, _safeJsonEncode(list));
    } else {
      list.add(data);
      await prefs.setString(_materiKey, _safeJsonEncode(list));
    }
  }

  static Future<void> saveMateri({
    required String title,
    required String modul,
    required String desc,
    required String videoUrl,
    required List questions,
    String? titleEn,
    String? modulEn,
    String? descEn,
  }) async {
    final String id = 'mat_${DateTime.now().millisecondsSinceEpoch}';

    final model = await AutoTranslateService.instance.translateAndCreateMateriModel(
      id: id,
      judulId: title,
      judulEn: titleEn,
      deskripsiId: desc,
      deskripsiEn: descEn,
      modulId: modul,
      modulEn: modulEn,
      videoUrl: videoUrl,
      questions: questions,
    );

    await saveMateriModel(model);
  }

  static Future<void> updateMateri({
    required String id,
    required String title,
    required String modul,
    required String desc,
    required String videoUrl,
    required List questions,
    String? titleEn,
    String? modulEn,
    String? descEn,
  }) async {
    final model = await AutoTranslateService.instance.translateAndCreateMateriModel(
      id: id,
      judulId: title,
      judulEn: titleEn,
      deskripsiId: desc,
      deskripsiEn: descEn,
      modulId: modul,
      modulEn: modulEn,
      videoUrl: videoUrl,
      questions: questions,
    );

    await updateMateriModel(model);
  }

  static Future<void> deleteMateri(String id) async {
    await FirebaseService.deleteMateri(id);

    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();
    list.removeWhere((item) => item['id'] == id);
    await prefs.setString(_materiKey, _safeJsonEncode(list));
  }

  static String _safeJsonEncode(List list) {
    return jsonEncode(list, toEncodable: (nonEncodable) {
      if (nonEncodable is DateTime) {
        return nonEncodable.toIso8601String();
      }
      return nonEncodable.toString();
    });
  }

  static Future<List<dynamic>?> getQuestionsForModule(String moduleId) async {
    final firestoreQ = await FirebaseService.getQuestionsForModule(moduleId);
    if (firestoreQ != null && firestoreQ.isNotEmpty) {
      return firestoreQ;
    }

    final list = await getMateriList();
    final cleanId = moduleId.toLowerCase().trim();

    final found = list.firstWhere(
          (m) {
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
      },
      orElse: () => null,
    );

    if (found != null && found['questions'] != null) {
      final qList = found['questions'] as List;
      if (qList.isNotEmpty) {
        return qList;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getModuleData(String moduleId) async {
    final list = await getMateriList();
    final cleanId = moduleId.toLowerCase().trim();

    final found = list.firstWhere(
          (m) {
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
      },
      orElse: () => null,
    );

    if (found != null) {
      return Map<String, dynamic>.from(found as Map);
    }
    return null;
  }
}
