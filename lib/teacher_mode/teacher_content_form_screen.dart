import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/materi_model.dart';
import '../services/auto_translate_service.dart';
import '../utils/app_translations.dart';
import 'teacher_content_helper.dart';

class TeacherContentFormScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic>? existingMateri;
  final int nextPertemuanNumber;
  final String? forcedType;
  final String? language;

  const TeacherContentFormScreen({
    super.key,
    required this.isDarkMode,
    this.existingMateri,
    this.nextPertemuanNumber = 5,
    this.forcedType,
    this.language,
  });

  @override
  State<TeacherContentFormScreen> createState() =>
      _TeacherContentFormScreenState();
}

class _TeacherContentFormScreenState extends State<TeacherContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _modulCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _videoCtrl;
  late TextEditingController _displayQuestionCountCtrl;
  late TextEditingController _durationMinutesCtrl;

  List _questionsList = [];
  String _currentLanguage = 'id';

  bool get _isEdit => widget.existingMateri != null;

  bool get _isExamOnly {
    final id = (widget.existingMateri?['id'] ?? widget.forcedType ?? '')
        .toString()
        .toLowerCase();
    return id == 'pretest' || id == 'posttest';
  }

  // Kamus terjemahan otomatis untuk teks penjelasan dan butir soal
  final Map<String, String> _translations = {
    // Label & Sesi
    'Pertemuan': 'Meeting',
    'Modul': 'Module',
    'Evaluasi Awal': 'Initial Assessment',
    'Evaluasi Akhir': 'Final Evaluation',
    'Uji Kemampuan Awal': 'Initial Skill Assessment',
    'Evaluasi Akhir Kelulusan': 'Final Graduation Evaluation',

    // Judul Topik Materi
    'Modul 1: Linked List': 'Module 1: Linked List',
    'Modul 2: Stack': 'Module 2: Stack',
    'Modul 3: Queue': 'Module 3: Queue',
    'Modul 4: Searching & Sorting': 'Module 4: Searching & Sorting',

    // Bagian Rangkuman Materi (Linked List)
    'A. Pengertian:': 'A. Definition:',
    'Linked List adalah struktur data linier yang tersusun dari kumpulan elemen bernama Node. Berbeda dengan Array statis yang ukurannya kaku dan harus berurutan di memori komputer, Linked List bersifat dinamis sehingga penambahan atau pengurangan elemen dapat dilakukan secara fleksibel tanpa perlu menggeser posisi data lainnya.':
    'Linked List is a linear data structure composed of a collection of elements called Nodes. Unlike a static Array whose size is fixed and contiguous in computer memory, a Linked List is dynamic, allowing elements to be inserted or removed flexibly without shifting other elements.',
    'B. Komponen Utama Node:': 'B. Main Node Components:',
    '1. Data atau Value: Nilai atau informasi aktual yang tersimpan di dalam node.':
    '1. Data or Value: The actual value or information stored within the node.',
    '2. Next Pointer: Penunjuk alamat memori yang menghubungkan node saat ini ke node berikutnya.':
    '2. Next Pointer: The memory address pointer connecting the current node to the next node.',

    // Bagian Rangkuman Materi (Stack)
    'Stack adalah struktur data linier yang mengikuti prinsip LIFO (Last In First Out), di mana elemen data yang terakhir dimasukkan ke dalam tumpukan akan menjadi elemen pertama yang dikeluarkan.':
    'Stack is a linear data structure that follows the LIFO (Last In First Out) principle, where the last data element inserted into the stack will be the first element to be removed.',
    'B. Operasi Utama Stack:': 'B. Main Stack Operations:',
    '1. Push: Menambahkan elemen baru ke posisi paling atas (Top) dari tumpukan.':
    '1. Push: Adds a new element to the top position (Top) of the stack.',
    '2. Pop: Mengambil dan menghapus elemen yang berada di posisi paling atas (Top).':
    '2. Pop: Removes and retrieves the element at the top position (Top).',
    '3. Peek / Top: Melihat data pada posisi teratas tanpa menghapusnya dari tumpukan.':
    '3. Peek / Top: Views the data at the top position without removing it from the stack.',
    '4. IsEmpty: Memeriksa apakah tumpukan data dalam keadaan kosong.':
    '4. IsEmpty: Checks whether the stack data structure is empty.',

    // Bagian Rangkuman Materi (Queue)
    'Queue adalah struktur data linier yang mengikuti prinsip FIFO (First In First Out), di mana elemen yang pertama kali masuk akan menjadi elemen pertama yang keluar.':
    'Queue is a linear data structure following the FIFO (First In First Out) principle, where the first element inserted is the first element to be removed.',
    'B. Operasi Utama Queue:': 'B. Main Queue Operations:',
    '1. Enqueue: Menambahkan elemen baru ke bagian belakang (Rear) antrean.':
    '1. Enqueue: Adds a new element to the rear of the queue.',
    '2. Dequeue: Menghapus elemen dari bagian depan (Front) antrean.':
    '2. Dequeue: Removes an element from the front of the queue.',

    // Bagian Rangkuman Materi (Searching & Sorting)
    'Pencarian dan pengurutan data adalah operasi dasar dalam algoritma struktur data untuk menyusun dan menemukan elemen secara efisien.':
    'Data searching and sorting are fundamental operations in data structure algorithms to organize and locate elements efficiently.',

    // Soal-soal Evaluasi & Asesmen
    'Struktur data linier yang bersifat dinamis dan menggunakan simpul (node) serta pointer adalah...':
    'A dynamic linear data structure that uses nodes and pointers is...',
    'Prinsip LIFO (Last In First Out) digunakan pada struktur data...':
    'The LIFO (Last In First Out) principle is used in the data structure...',
    'Operasi penambahan elemen baru ke dalam antrean (Queue) dinamakan...':
    'The operation of adding a new element to a Queue is called...',
    'Metode pencarian data yang mengharuskan kumpulan data sudah terurut rapi adalah...':
    'A search method that requires the dataset to be neatly sorted beforehand is...',
    'Simpul pertama pada Linked List yang menjadi pintu masuk penelusuran disebut...':
    'The first node in a Linked List that serves as the entry point for traversal is called...',
    'Operasi untuk mengambil atau menghapus elemen teratas dari struktur data Stack adalah...':
    'The operation to retrieve or remove the topmost element from a Stack data structure is...',
    'Penunjuk yang mengarah ke elemen paling depan pada antrean Queue disebut...':
    'The pointer that points to the frontmost element in a Queue is called...',
    'Algoritma pengurutan data yang berulang kali menukar dua elemen bersebelahan yang tidak urut adalah...':
    'A sorting algorithm that repeatedly swaps two adjacent elements that are out of order is...',
    'Kondisi saat mencoba memasukkan elemen ke dalam Stack yang sudah penuh memori disebut...':
    'The condition when attempting to push an element into a Stack that is full is called...',
    'Kompleksitas waktu terbaik (Best Case) dari Binary Search jika data langsung ditemukan di tengah adalah...':
    'The best-case time complexity of Binary Search when data is immediately found in the middle is...',
    'Nilai penunjuk pada simpul paling akhir dari single linked list adalah...':
    'The pointer value of the last node in a single linked list is...',
    'Keunggulan linked list dibandingkan array statis adalah...':
    'The advantage of a linked list compared to a static array is...',
    'Operasi penelusuran dari awal simpul ke simpul akhir disebut...':
    'The operation of traversing from the first node to the last node is called...',
    'Pada Doubly Linked List, setiap node memiliki pointer penunjuk yaitu...':
    'In a Doubly Linked List, each node contains pointer references namely...',
    'Ciri khas utama dari Circular Linked List adalah...':
    'The primary characteristic of a Circular Linked List is...',
    'Kompleksitas waktu untuk menambahkan node baru di posisi paling awal (Head) adalah...':
    'The time complexity to insert a new node at the very beginning (Head) position is...',
    'Untuk menghapus node di tengah linked list, pointer yang diubah adalah...':
    'To delete a node in the middle of a linked list, the pointer that must be changed is...',

    // Opsi Jawaban (Pilihan)
    'Array Statis': 'Static Array',
    'Ukuran memori dinamis': 'Dynamic memory size',
    'Akses langsung via indeks O(1)': 'Direct access via index O(1)',
    'Tidak perlu pointer': 'No pointer needed',
    'Pasti lebih hemat': 'Guaranteed more memory efficient',
    'Node terakhir menunjuk kembali ke Head': 'The last node points back to Head',
    'Ukuran node terbatas': 'Limited node size',
    'Tidak ada data value': 'No data value',
    'Hanya bisa mundur': 'Can only move backwards',
    'Pointer node sebelumnya diarahkan ke node sesudahnya':
    'Pointer of the preceding node is directed to the subsequent node',
    'Pointer Head ke NULL': 'Pointer Head to NULL',
    'Pointer Tail ke Head': 'Pointer Tail to Head',
    'Tidak perlu ubah pointer': 'No pointer change needed',
  };

  bool _bgTranslating = false;

  /// Background-translates every question that has no complete English version
  /// (batches of 5) so the preview list & detail dialog are 100% English.
  void _ensureQuestionsTranslated() {
    if (_bgTranslating || _questionsList.isEmpty) return;
    final bool en =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    if (!en) return;
    final svc = AutoTranslateService.instance;
    final bool pending = _questionsList
        .whereType<Map>()
        .any((q) => !svc.isQuestionTranslated(Map<String, dynamic>.from(q)));
    if (!pending) return;
    _bgTranslating = true;
    svc.translatePending(_questionsList, onBatch: (updates) {
      if (!mounted) return;
      setState(() {
        updates.forEach((i, v) {
          if (i < _questionsList.length) _questionsList[i] = v;
        });
      });
    }).whenComplete(() => _bgTranslating = false);
  }

  String _translateIfEn(String text) {
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    if (!isEn) return text;
    if (_translations.containsKey(text.trim())) {
      return _translations[text.trim()]!;
    }
    String result = text;
    _translations.forEach((idText, enText) {
      if (result.contains(idText)) {
        result = result.replaceAll(idText, enText);
      }
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_onLanguageChanged);
    _currentLanguage = widget.language ??
        (LanguageController.instance.isEnglish ? 'en' : 'id');

    String defaultModul = _isEdit
        ? (widget.existingMateri?['modul'] ?? 'Pertemuan 1')
        : (widget.forcedType == 'pretest'
        ? 'Pre-Test'
        : (widget.forcedType == 'posttest'
        ? 'Post-Test'
        : 'Pertemuan ${widget.nextPertemuanNumber}'));

    String defaultTitle = widget.existingMateri?['title'] ?? '';
    String defaultDesc = widget.existingMateri?['desc'] ??
        widget.existingMateri?['summary'] ??
        '';

    if (_currentLanguage == 'en' || LanguageController.instance.isEnglish) {
      defaultModul = widget.existingMateri?['modul_en'] ?? _translateIfEn(defaultModul);
      defaultTitle = widget.existingMateri?['title_en'] ?? _translateIfEn(defaultTitle);
      defaultDesc = widget.existingMateri?['desc_en'] ?? _translateIfEn(defaultDesc);
    }

    _modulCtrl = TextEditingController(text: defaultModul);
    _titleCtrl = TextEditingController(text: defaultTitle);
    _descCtrl = TextEditingController(text: defaultDesc);
    _videoCtrl = TextEditingController(
        text: widget.existingMateri?['videoUrl'] ?? '');

    final rawQ = widget.existingMateri?['questions'];
    if (rawQ != null && rawQ is List && rawQ.isNotEmpty) {
      _questionsList = List.from(rawQ);
    }

    final int? initDisplayCount = widget.existingMateri?['displayQuestionCount'] != null
        ? int.tryParse(widget.existingMateri!['displayQuestionCount'].toString())
        : null;
    final int? initDuration = widget.existingMateri?['durationMinutes'] != null
        ? int.tryParse(widget.existingMateri!['durationMinutes'].toString())
        : null;

    final String initialDisplayStr = initDisplayCount != null
        ? '$initDisplayCount'
        : (_questionsList.isNotEmpty ? '${_questionsList.length}' : '30');
    final String initialDurationStr = initDuration != null ? '$initDuration' : '30';

    _displayQuestionCountCtrl = TextEditingController(text: initialDisplayStr);
    _durationMinutesCtrl = TextEditingController(text: initialDurationStr);

    _loadLanguagePreference();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _currentLanguage =
        LanguageController.instance.isEnglish ? 'en' : 'id';
        final isEn = _currentLanguage == 'en';
        if (isEn) {
          _modulCtrl.text = widget.existingMateri?['modul_en'] ?? _translateIfEn(_modulCtrl.text);
          _titleCtrl.text = widget.existingMateri?['title_en'] ?? _translateIfEn(_titleCtrl.text);
          _descCtrl.text = widget.existingMateri?['desc_en'] ?? _translateIfEn(_descCtrl.text);
        } else {
          _modulCtrl.text = widget.existingMateri?['modul'] ?? _modulCtrl.text;
          _titleCtrl.text = widget.existingMateri?['title'] ?? _titleCtrl.text;
          _descCtrl.text = widget.existingMateri?['desc'] ?? _descCtrl.text;
        }
      });
    }
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (mounted && savedLang != null) {
      setState(() {
        _currentLanguage = savedLang;
        if (_currentLanguage == 'en' || LanguageController.instance.isEnglish) {
          _modulCtrl.text = _translateIfEn(_modulCtrl.text);
          _titleCtrl.text = _translateIfEn(_titleCtrl.text);
          _descCtrl.text = _translateIfEn(_descCtrl.text);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TeacherContentFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.language != null && widget.language != _currentLanguage) {
      setState(() {
        _currentLanguage = widget.language!;
        if (_currentLanguage == 'en' || LanguageController.instance.isEnglish) {
          _modulCtrl.text = _translateIfEn(_modulCtrl.text);
          _titleCtrl.text = _translateIfEn(_titleCtrl.text);
          _descCtrl.text = _translateIfEn(_descCtrl.text);
        }
      });
    }
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    _modulCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoCtrl.dispose();
    _displayQuestionCountCtrl.dispose();
    _durationMinutesCtrl.dispose();
    super.dispose();
  }

  void _parseAndImportQuestions(String rawText, [int? customDisplayCount, int? customDurationMinutes]) {
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    if (rawText.trim().isEmpty) return;

    try {
      final String cleanText = rawText.replaceAll('\r', '');
      final List lines = cleanText.split('\n');
      final List parsedSlots = [];

      int? headerDisplayCount;
      int? headerDurationMinutes;

      final displayHeaderRegExp = RegExp(
        r'^(?:Jumlah\s*Soal\s*Ditampilkan|Jumlah\s*Soal|Soal\s*Ditampilkan|Tampil\s*Soal|Jumlah|Display\s*Questions|Questions\s*Displayed|Question\s*Count|Display)\s*[:=]\s*(\d+)',
        caseSensitive: false,
      );

      final durationHeaderRegExp = RegExp(
        r'^(?:Durasi\s*Pengerjaan|Durasi|Waktu\s*Pengerjaan|Waktu|Duration|Time)\s*[:=]\s*(\d+)',
        caseSensitive: false,
      );

      final List<String> questionLines = [];

      for (var rawLine in lines) {
        final String line = rawLine.toString().trim();
        if (line.isEmpty) continue;

        final displayMatch = displayHeaderRegExp.firstMatch(line);
        final durationMatch = durationHeaderRegExp.firstMatch(line);

        if (displayMatch != null && questionLines.isEmpty) {
          headerDisplayCount = int.tryParse(displayMatch.group(1)!);
          continue;
        }

        if (durationMatch != null && questionLines.isEmpty) {
          headerDurationMinutes = int.tryParse(durationMatch.group(1)!);
          continue;
        }

        questionLines.add(line);
      }

      String currentQ = '';
      final List<String> currentOpts = [];
      int? currentAns;
      String currentExp = '';
      bool isParsingExp = false;

      const letters = ['A', 'B', 'C', 'D', 'E'];

      void pushCurrentQuestion() {
        if (currentQ.trim().isNotEmpty) {
          while (currentOpts.length < 4) {
            currentOpts.add('-');
          }
          final String qIndo = currentQ.trim();
          final List<String> optsIndo = List<String>.from(currentOpts);
          final int finalAnsIdx = (currentAns != null && currentAns! >= 0 && currentAns! < optsIndo.length)
              ? currentAns!
              : 0;

          final String ansLetter = finalAnsIdx < letters.length ? letters[finalAnsIdx] : 'A';

          String expIndo = currentExp.trim();
          if (expIndo.isEmpty) {
            expIndo = 'Jawaban yang benar adalah opsi $ansLetter.';
          }

          parsedSlots.add({
            'q': qIndo,
            'question': qIndo,
            'q_en': '',
            'question_en': '',
            'options': optsIndo,
            'options_en': const <String>[],
            'answerIndex': finalAnsIdx,
            'answer': finalAnsIdx,
            'explanation': expIndo,
            'explanation_en': '',
          });

          currentQ = '';
          currentOpts.clear();
          currentAns = null;
          currentExp = '';
          isParsingExp = false;
        }
      }

      final qRegExp = RegExp(r'^(?:Soal\s*)?\d+[.)]\s*(.*)$', caseSensitive: false);
      final optRegExp = RegExp(r'^\*?\s*([A-Ea-e])[.)]\s*\*?\s*(.*)$');
      final ansRegExp = RegExp(
        r'^(?:Kunci\s*Jawaban|Kunci|Jawaban\s*Benar|Jawaban|Correct\s*Answer|Key\s*Answer|Ans|Key)\s*[:=]?\s*\*?([A-Ea-e])\*?',
        caseSensitive: false,
      );
      final expRegExp = RegExp(
        r'^(?:Pembahasan|Penjelasan|Explanation|Expl|Reason|Alasan)\s*[:=]\s*(.*)$',
        caseSensitive: false,
      );

      for (var line in questionLines) {
        final qMatch = qRegExp.firstMatch(line);
        final ansMatch = ansRegExp.firstMatch(line);
        final expMatch = expRegExp.firstMatch(line);
        final optMatch = optRegExp.firstMatch(line);

        if (qMatch != null) {
          pushCurrentQuestion();
          currentQ = qMatch.group(1)!.trim();
          isParsingExp = false;
        } else if (expMatch != null) {
          isParsingExp = true;
          currentExp = expMatch.group(1)!.trim();
        } else if (ansMatch != null) {
          final char = ansMatch.group(1)!.toUpperCase();
          currentAns = char.codeUnitAt(0) - 65;

          final inlineExpMatch = expRegExp.firstMatch(line);
          if (inlineExpMatch != null) {
            isParsingExp = true;
            currentExp = inlineExpMatch.group(1)!.trim();
          }
        } else if (optMatch != null && !isParsingExp) {
          final char = optMatch.group(1)!.toUpperCase();
          final int optIdx = char.codeUnitAt(0) - 65;
          String optText = optMatch.group(2)!.trim();

          if (line.contains('*')) {
            currentAns = optIdx;
            optText = optText.replaceAll('*', '').trim();
          }

          currentOpts.add(optText);
          isParsingExp = false;
        } else {
          if (isParsingExp) {
            currentExp = currentExp.isEmpty ? line : '$currentExp\n$line';
          } else if (currentOpts.isNotEmpty) {
            final lastIdx = currentOpts.length - 1;
            currentOpts[lastIdx] = '${currentOpts[lastIdx]} $line';
          } else if (currentQ.isNotEmpty) {
            currentQ = '$currentQ $line';
          }
        }
      }

      pushCurrentQuestion();

      if (parsedSlots.isNotEmpty) {
        setState(() {
          _questionsList = parsedSlots;

          final int effectiveDisplayInput = headerDisplayCount ?? customDisplayCount ?? parsedSlots.length;
          final int targetDisplay = (effectiveDisplayInput > 0)
              ? (effectiveDisplayInput <= parsedSlots.length ? effectiveDisplayInput : parsedSlots.length)
              : parsedSlots.length;
          _displayQuestionCountCtrl.text = '$targetDisplay';

          final int effectiveDurationInput = headerDurationMinutes ?? customDurationMinutes ?? 30;
          final int targetDur = (effectiveDurationInput > 0) ? effectiveDurationInput : 30;
          _durationMinutesCtrl.text = '$targetDur';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn
                  ? 'Successfully imported ${parsedSlots.length} questions!'
                  : 'Berhasil mengimpor ${parsedSlots.length} butir soal!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn
                  ? 'Script format not recognized. Ensure numbering 1., options A-D/E, and Key / Explanation exist.'
                  : 'Format naskah tidak dikenali. Pastikan ada penomoran 1., pilihan A-D/E, serta Kunci / Pembahasan.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing questions: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showQuickImportDialog() {
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    final importCtrl = TextEditingController();

    final int defaultDisplay = _questionsList.isNotEmpty ? _questionsList.length : 30;
    final int defaultDuration = int.tryParse(_durationMinutesCtrl.text) ?? 30;

    final dialogDisplayCtrl = TextEditingController(
      text: _displayQuestionCountCtrl.text.isNotEmpty
          ? _displayQuestionCountCtrl.text
          : '$defaultDisplay',
    );
    final dialogDurationCtrl = TextEditingController(
      text: _durationMinutesCtrl.text.isNotEmpty
          ? _durationMinutesCtrl.text
          : '$defaultDuration',
    );

    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.flash_on_rounded,
                color: Color(0xFF00F0FF), size: 22),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Quick Import Questions' : 'Quick Import Naskah Soal',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Copy-paste all questions from Word / PDF (Optional top configuration headers):\n'
                      'Questions Displayed: 20\n'
                      'Duration: 25 minutes\n\n'
                      '1. The node storing the next memory address is called...\n'
                      'A. Data\n'
                      'B. Pointer / Next\n'
                      'C. Head\n'
                      'D. Tail\n'
                      'Key: B\n'
                      'Explanation: Node stores payload data and link pointer.\n\n'
                      '2. First node pointer of a linked list...\n'
                      '*A. Head\n'
                      'B. Tail\n'
                      '...etc'
                      : 'Salin (copy-paste) seluruh nomor soal dari file Word / PDF (Opsional baris konfigurasi teratas):\n'
                      'Jumlah Soal: 20\n'
                      'Durasi: 25 menit\n\n'
                      '1. Simpul yang menyimpan alamat memori berikutnya disebut...\n'
                      'A. Data\n'
                      'B. Pointer / Next\n'
                      'C. Head\n'
                      'D. Tail\n'
                      'Kunci Jawaban: B\n'
                      'Pembahasan: Node tersusun dari nilai data dan pointer penunjuk.\n\n'
                      '2. Pointer penunjuk simpul pertama linked list dinamakan...\n'
                      '*A. Head\n'
                      'B. Tail\n'
                      '...dst',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[400], height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: importCtrl,
                  maxLines: 7,
                  style: TextStyle(
                      color: textColor, fontSize: 12, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: isEn
                        ? 'Paste the question script here...'
                        : 'Tempelkan (Paste) seluruh naskah soal di sini...',
                    hintStyle:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: widget.isDarkMode
                        ? const Color(0xFF060913)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dialogDisplayCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(color: textColor, fontSize: 12.5),
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Questions Displayed'
                              : 'Jumlah Soal Ditampilkan',
                          hintText: isEn ? 'Default: Total' : 'Default: Total',
                          labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                          prefixIcon: const Icon(Icons.format_list_numbered_rounded,
                              color: Color(0xFF00F0FF), size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: dialogDurationCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(color: textColor, fontSize: 12.5),
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Exam Duration (Minutes)'
                              : 'Durasi Pengerjaan (Menit)',
                          hintText: '30',
                          labelStyle: TextStyle(color: subTextColor, fontSize: 11),
                          prefixIcon: const Icon(Icons.timer_outlined,
                              color: Colors.amber, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'Batal',
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 16),
            label: Text(
              isEn ? 'Extract & Apply Questions' : 'Ekstrak & Pasang Soal',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              final int? customDisplay = int.tryParse(dialogDisplayCtrl.text.trim());
              final int? customDur = int.tryParse(dialogDurationCtrl.text.trim());

              Navigator.pop(ctx);
              _parseAndImportQuestions(importCtrl.text, customDisplay, customDur);
            },
          ),
        ],
      ),
    );
  }

  void _showQuestionDetailDialog(int qIndex) {
    if (qIndex < 0 || qIndex >= _questionsList.length) return;
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    final qItem = Map<String, dynamic>.from(_questionsList[qIndex] as Map);

    final String qIndo = (qItem['q'] ?? qItem['question'] ?? '').toString();
    final String qEng = (qItem['q_en'] ?? qItem['question_en'] ?? '').toString();
    final String qText = isEn ? (qEng.trim().isNotEmpty ? qEng : qIndo) : qIndo;

    final List optsIndo = (qItem['options'] as List? ?? []).map((o) => o.toString()).toList();
    final List optsEng = (qItem['options_en'] as List? ?? []).map((o) => o.toString()).toList();
    final List opts = isEn ? (optsEng.isNotEmpty ? optsEng : optsIndo) : optsIndo;

    final int ansIdx = qItem['answerIndex'] ?? qItem['answer'] ?? 0;
    final List letters = ['A', 'B', 'C', 'D'];

    final String expIndo = (qItem['explanation'] ?? '').toString();
    final String expEng = (qItem['explanation_en'] ?? '').toString();
    final String expText = isEn ? (expEng.trim().isNotEmpty ? expEng : expIndo) : expIndo;

    final cardBg = widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final boxInnerBg = widget.isDarkMode
        ? const Color(0xFF060913)
        : const Color(0xFFF1F5F9);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final borderColor = widget.isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF00F0FF);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Text(
                '${qIndex + 1}',
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn
                    ? 'Question ${qIndex + 1} Details'
                    : 'Detail Soal No. ${qIndex + 1}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: textColor, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teks Soal Lengkap
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: boxInnerBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: SelectableText(
                    qText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  isEn ? 'Answer Choices:' : 'Pilihan Jawaban:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Daftar Opsi A, B, C, D Lengkap
                ...List.generate(opts.length, (optIdx) {
                  final String letter =
                  optIdx < letters.length ? letters[optIdx] : 'A';
                  final bool isKey = optIdx == ansIdx;
                  final String optText = opts[optIdx].toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isKey
                          ? Colors.greenAccent.withValues(alpha: 0.1)
                          : boxInnerBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isKey ? Colors.greenAccent : borderColor,
                        width: isKey ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isKey
                                ? Colors.greenAccent
                                : accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isKey ? Colors.black : accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            optText,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight:
                              isKey ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isKey) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isEn ? 'Key' : 'Kunci',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (expText.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textColor,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: isEn ? 'Explanation: ' : 'Pembahasan: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                TextSpan(text: expText),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _questionsList.removeAt(qIndex);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEn
                      ? 'Question ${qIndex + 1} deleted'
                      : 'Soal No. ${qIndex + 1} telah dihapus'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 16),
            label: Text(
              isEn ? 'Delete Question' : 'Hapus Soal Ini',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isEn ? 'Close' : 'Tutup',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Please fill in all required fields marked in red.'
              : 'Harap lengkapi semua kolom form yang bertanda merah.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String modulName = _modulCtrl.text.trim();
    String titleName = _titleCtrl.text.trim();
    String descContent = _descCtrl.text.trim();

    if (titleName.isEmpty) {
      titleName = _isExamOnly
          ? (_modulCtrl.text.isNotEmpty ? 'Ujian ${_modulCtrl.text}' : 'Paket Soal Ujian')
          : 'Materi Pertemuan';
    }

    if (!_isExamOnly && descContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Material description content cannot be empty!'
              : 'Rangkuman uraian materi tidak boleh kosong!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_questionsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Question package cannot be empty! Click "Quick Import" to add questions.'
              : 'Paket butir soal tidak boleh kosong! Klik "Quick Import Soal" untuk menambah soal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String modulIndo = isEn ? (widget.existingMateri?['modul'] ?? modulName) : modulName;
    final String titleIndo = isEn ? (widget.existingMateri?['title'] ?? titleName) : titleName;
    final String descIndo = isEn ? (widget.existingMateri?['desc'] ?? descContent) : descContent;

    // Show auto-translation & saving indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF00F0FF)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  isEn
                      ? 'Translating & Saving Material (ML Kit Auto Translate)...'
                      : 'Menerjemahkan Otomatis (ML Kit) & Menyimpan Materi...',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await AutoTranslateService.instance.ensureModelsDownloaded();

      final String matId = _isEdit
          ? widget.existingMateri!['id']
          : 'mat_${DateTime.now().millisecondsSinceEpoch}';

      int? displayCount = int.tryParse(_displayQuestionCountCtrl.text.trim());
      int? durationMins = int.tryParse(_durationMinutesCtrl.text.trim());

      if (displayCount != null) {
        if (displayCount > _questionsList.length && _questionsList.isNotEmpty) {
          displayCount = _questionsList.length;
        }
        if (displayCount < 1) {
          displayCount = 1;
        }
      } else if (_questionsList.isNotEmpty) {
        displayCount = _questionsList.length;
      }

      if (durationMins == null || durationMins < 1) {
        durationMins = 30;
      }

      // Translate ALL questions in batches of 5 items until 100% complete
      List<Map<String, dynamic>> finalQuestions = [];
      try {
        finalQuestions = await AutoTranslateService.instance
            .translateAllQuestions(_questionsList);
      } catch (e) {
        debugPrint('Notice questions save translate notice: $e');
        finalQuestions = _questionsList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      final MateriModel materiModel =
      await AutoTranslateService.instance.translateAndCreateMateriModel(
        id: matId,
        judulId: titleIndo,
        deskripsiId: descIndo,
        modulId: modulIndo,
        videoUrl: _videoCtrl.text.trim(),
        questions: finalQuestions,
        displayQuestionCount: displayCount,
        durationMinutes: durationMins,
        createdAt: widget.existingMateri?['createdAt'],
      );

      if (_isEdit) {
        await TeacherContentHelper.updateMateriModel(materiModel);
      } else {
        await TeacherContentHelper.saveMateriModel(materiModel);
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      Navigator.pop(context, true); // Return to list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? (_isExamOnly
                ? 'Exam question package updated successfully!'
                : (_isEdit
                ? 'Material & assessment updated successfully!'
                : '$modulName published successfully!'))
                : (_isExamOnly
                ? 'Paket butir soal berhasil diperbarui!'
                : (_isEdit
                ? 'Materi & paket soal asesmen berhasil diperbarui!'
                : '$modulName berhasil ditambahkan dan dipublikasikan!')),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading dialog on error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Error saving material: $e'
              : 'Gagal menyimpan materi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn =
        _currentLanguage == 'en' || LanguageController.instance.isEnglish;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureQuestionsTranslated();
    });
    final bgColor =
    widget.isDarkMode ? const Color(0xFF060913) : const Color(0xFFF8FAFC);
    final cardBg =
    widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor =
    widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
    widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const accentColor = Color(0xFF00F0FF);
    final borderColor =
    widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isExamOnly
              ? (isEn
              ? 'Manage Questions: ${_translateIfEn(_modulCtrl.text)}'
              : 'Kelola Butir Soal ${_modulCtrl.text}')
              : (_isEdit
              ? (isEn
              ? 'Edit Material & Assessment'
              : 'Edit Materi & Asesmen')
              : (isEn ? 'Add New Meeting' : 'Tambah Pertemuan Baru')),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom +
              24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INFORMASI JUDUL & SESI EVALUASI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isExamOnly
                              ? Icons.fact_check_rounded
                              : Icons.menu_book_rounded,
                          color: _isExamOnly ? Colors.amber : accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isExamOnly
                              ? (isEn
                              ? '1. Exam Evaluation Information'
                              : '1. Informasi Evaluasi Ujian')
                              : (isEn
                              ? '1. Material & Meeting Information'
                              : '1. Informasi Materi & Sesi Pertemuan'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modulCtrl,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      readOnly: _isExamOnly,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? (isEn
                          ? 'Meeting session cannot be empty'
                          : 'Sesi pertemuan wajib diisi')
                          : null,
                      decoration: InputDecoration(
                        labelText: isEn
                            ? 'Session / Exam Identity'
                            : 'Sesi / Identitas Ujian',
                        labelStyle: TextStyle(color: subTextColor),
                        prefixIcon: const Icon(Icons.event_note_rounded,
                            color: accentColor, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleCtrl,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? (isEn ? 'Title is required' : 'Judul wajib diisi')
                          : null,
                      decoration: InputDecoration(
                        labelText: _isExamOnly
                            ? (isEn ? 'Exam Title' : 'Judul Ujian')
                            : (isEn
                            ? 'Material Topic Title'
                            : 'Judul Topik Materi'),
                        labelStyle: TextStyle(color: subTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    if (!_isExamOnly) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        style: TextStyle(color: textColor, fontSize: 13),
                        maxLines: 8,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? (isEn
                            ? 'Material description cannot be empty'
                            : 'Penjelasan materi tidak boleh kosong')
                            : null,
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Detailed Explanation / Full Summary'
                              : 'Penjelasan / Rangkuman Materi Lengkap',
                          hintText: isEn
                              ? 'Type concepts, mechanisms, operations, and analogies...'
                              : 'Ketik uraian konsep, cara kerja, operasi dasar, hingga analogi nyata...',
                          labelStyle: TextStyle(color: subTextColor),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!_isExamOnly) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.video_library_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEn
                                ? '2. Learning Video Tutorial'
                                : '2. Video Tutorial Pembelajaran',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _videoCtrl,
                        style: TextStyle(color: textColor, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: isEn
                              ? 'Video URL Link (YouTube / Video Link)'
                              : 'Tautan URL Video (YouTube / Tautan Video)',
                          hintText: 'https://www.youtube.com/watch?v=...',
                          labelStyle: TextStyle(color: subTextColor),
                          prefixIcon: const Icon(Icons.link_rounded,
                              color: Colors.redAccent, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 2. BUTIR SOAL LENGKAP & QUICK IMPORT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_rounded,
                            color: Colors.greenAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isExamOnly
                                    ? (isEn
                                    ? '2. Exam Question Package'
                                    : '2. Paket Butir Soal Ujian')
                                    : (isEn
                                    ? '3. Module Assessment Package'
                                    : '3. Paket Asesmen Ujian Modul'),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                              Text(
                                isEn
                                    ? 'Total ${_questionsList.length} questions installed'
                                    : 'Total ${_questionsList.length} butir soal terpasang',
                                style: TextStyle(
                                    fontSize: 10.5, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: _showQuickImportDialog,
                          icon: const Icon(Icons.flash_on_rounded,
                              size: 14, color: Colors.black),
                          label: Text(
                            isEn ? 'Quick Import' : 'Quick Import Soal',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F0FF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_questionsList.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? const Color(0xFF060913)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            isEn
                                ? 'No exam questions yet.\nClick "Quick Import" above to paste the question script.'
                                : 'Belum ada butir soal ujian.\nKlik tombol "Quick Import Soal" di atas untuk menempel naskah soal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: subTextColor,
                                height: 1.5),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEn
                                    ? '${_questionsList.length} questions ready for student assessment.'
                                    : '${_questionsList.length} butir soal siap digunakan untuk ujian peserta didik.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _questionsList.clear()),
                              child: Text(
                                isEn ? 'Reset Questions' : 'Reset Soal',
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questionsList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, qIndex) {
                          final qItem = _questionsList[qIndex] as Map;
                          final String qIndo = (qItem['q'] ?? qItem['question'] ?? '').toString();
                          final String qEng = (qItem['q_en'] ?? qItem['question_en'] ?? '').toString();
                          final String qText = isEn ? (qEng.trim().isNotEmpty ? qEng : qIndo) : qIndo;

                          final List optsIndo = (qItem['options'] as List? ?? []).map((o) => o.toString()).toList();
                          final List optsEng = (qItem['options_en'] as List? ?? []).map((o) => o.toString()).toList();
                          final List opts = isEn ? (optsEng.isNotEmpty ? optsEng : optsIndo) : optsIndo;

                          final int ansIdx = qItem['answerIndex'] ?? qItem['answer'] ?? 0;
                          final List letters = ['A', 'B', 'C', 'D'];
                          final String keyLetter =
                          ansIdx < letters.length ? letters[ansIdx] : 'A';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _showQuestionDetailDialog(qIndex),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode
                                      ? const Color(0xFF060913)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                          accentColor.withValues(alpha: 0.15),
                                          child: Text(
                                            '${qIndex + 1}',
                                            style: const TextStyle(
                                                color: accentColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                qText,
                                                style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isEn
                                                    ? 'Options: ${opts.join(" | ")}'
                                                    : 'Pilihan: ${opts.join(" | ")}',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: subTextColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isEn
                                                ? 'Key: $keyLetter'
                                                : 'Kunci: $keyLetter',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.greenAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          isEn
                                              ? 'Tap to view full details ➔'
                                              : 'Ketuk untuk lihat detail selengkapnya ➔',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewPadding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _isEdit ? Icons.save_rounded : Icons.cloud_upload_rounded,
                color: Colors.black,
                size: 20,
              ),
              label: Text(
                isEn
                    ? (_isExamOnly
                    ? 'SAVE EVALUATION QUESTIONS'
                    : (_isEdit
                    ? 'SAVE CHANGES'
                    : 'PUBLISH THIS MEETING'))
                    : (_isExamOnly
                    ? 'SIMPAN BANK SOAL EVALUASI'
                    : (_isEdit
                    ? 'SIMPAN PERUBAHAN MATERI & ASESMEN'
                    : 'PUBLIKASIKAN PERTEMUAN INI')),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
      );
  }
}
