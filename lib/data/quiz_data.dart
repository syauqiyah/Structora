import '../utils/app_translations.dart';

String _cleanNorm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

Map<String, dynamic>? findMasterQuizQuestion(String text) {
  final norm = _cleanNorm(text);
  if (norm.isEmpty) return null;

  for (final q in preTestQuestions) {
    final qNorm = _cleanNorm((q['question'] ?? q['q'] ?? '').toString());
    if (qNorm == norm || (qNorm.length > 15 && norm.contains(qNorm)) || (norm.length > 15 && qNorm.contains(norm))) {
      return q;
    }
  }

  for (final q in postTestQuestions) {
    final qNorm = _cleanNorm((q['question'] ?? q['q'] ?? '').toString());
    if (qNorm == norm || (qNorm.length > 15 && norm.contains(qNorm)) || (norm.length > 15 && qNorm.contains(norm))) {
      return q;
    }
  }

  for (final list in asesmenModulQuestions.values) {
    for (final q in list) {
      final qNorm = _cleanNorm((q['question'] ?? q['q'] ?? '').toString());
      if (qNorm == norm || (qNorm.length > 15 && norm.contains(qNorm)) || (norm.length > 15 && qNorm.contains(norm))) {
        return q;
      }
    }
  }

  return null;
}

extension QuizLocalizationExtension on Map<String, dynamic> {
  String getLocalizedQuestion([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    final String qIndo = (this['question'] ?? this['q'] ?? '').toString().trim();
    if (!en) {
      return qIndo;
    }

    final String qEn = (this['question_en'] ?? this['q_en'] ?? '').toString().trim();
    if (qEn.isNotEmpty && _cleanNorm(qEn) != _cleanNorm(qIndo)) {
      return qEn;
    }

    // Try finding master question
    final master = findMasterQuizQuestion(qIndo);
    if (master != null) {
      final masterEn = (master['question_en'] ?? master['q_en'] ?? '').toString().trim();
      if (masterEn.isNotEmpty && _cleanNorm(masterEn) != _cleanNorm(qIndo)) {
        return masterEn;
      }
    }

    // Fallback to universal auto-translator / dictionary
    final autoResult = AppText.auto(qIndo);
    if (autoResult.isNotEmpty && _cleanNorm(autoResult) != _cleanNorm(qIndo)) {
      return autoResult;
    }

    return qEn.isNotEmpty ? qEn : qIndo;
  }

  List<String> getLocalizedOptions([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    final List<String> rawOpts = (this['options'] as List? ?? []).map((e) => e.toString().trim()).toList();
    if (!en) {
      return rawOpts;
    }

    final List? optsEnRaw = this['options_en'] as List?;
    if (optsEnRaw != null && optsEnRaw.isNotEmpty) {
      final List<String> optsEn = optsEnRaw.map((e) => e.toString().trim()).toList();
      bool hasDifferentTranslation = false;
      for (int i = 0; i < optsEn.length && i < rawOpts.length; i++) {
        if (_cleanNorm(optsEn[i]) != _cleanNorm(rawOpts[i])) {
          hasDifferentTranslation = true;
          break;
        }
      }
      if (hasDifferentTranslation) {
        return optsEn;
      }
    }

    // Lookup in master
    final String qIndo = (this['question'] ?? this['q'] ?? '').toString().trim();
    final master = findMasterQuizQuestion(qIndo);
    if (master != null && master['options_en'] != null) {
      final masterOpts = (master['options'] as List? ?? []).map((e) => e.toString().trim()).toList();
      final masterOptsEn = (master['options_en'] as List? ?? []).map((e) => e.toString().trim()).toList();

      List<String> result = [];
      for (final opt in rawOpts) {
        final optNorm = _cleanNorm(opt);
        final idx = masterOpts.indexWhere((m) => _cleanNorm(m) == optNorm);
        if (idx != -1 && idx < masterOptsEn.length) {
          result.add(masterOptsEn[idx]);
        } else {
          result.add(AppText.auto(opt));
        }
      }
      return result;
    }

    return rawOpts.map((e) => AppText.auto(e)).toList();
  }

  String getLocalizedExplanation([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    final String expIndo = (this['explanation'] ?? '').toString().trim();
    if (!en) {
      return expIndo;
    }

    final String expEn = (this['explanation_en'] ?? '').toString().trim();
    if (expEn.isNotEmpty && _cleanNorm(expEn) != _cleanNorm(expIndo)) {
      return expEn;
    }

    // Try finding master question
    final String qIndo = (this['question'] ?? this['q'] ?? '').toString().trim();
    final master = findMasterQuizQuestion(qIndo);
    if (master != null) {
      final masterExpEn = (master['explanation_en'] ?? '').toString().trim();
      if (masterExpEn.isNotEmpty && _cleanNorm(masterExpEn) != _cleanNorm(expIndo)) {
        return masterExpEn;
      }
    }

    if (expIndo.isNotEmpty) {
      final autoResult = AppText.auto(expIndo);
      if (autoResult.isNotEmpty && _cleanNorm(autoResult) != _cleanNorm(expIndo)) {
        return autoResult;
      }
    }

    return 'Correct answer according to module material script.';
  }
}

// ==========================================
// BANK SOAL A: PRETEST (Pool 10 Soal -> Diambil 5 Acak)
// ==========================================
final List<Map<String, dynamic>> preTestQuestions = [
  {
    'question': 'Struktur data digunakan dalam pemrograman untuk ....',
    'question_en': 'Data structures are used in computer programming to ....',
    'options': [
      'Mempercantik tampilan aplikasi saja',
      'Menyimpan dan mengatur data agar mudah diolah',
      'Mengganti sistem operasi komputer',
      'Menghapus seluruh kesalahan program secara otomatis',
      'Memperbesar ukuran memori komputer',
    ],
    'options_en': [
      'Beautify application appearance only',
      'Store and organize data for efficient processing',
      'Replace computer operating systems',
      'Automatically resolve all software bugs',
      'Physically expand computer RAM size',
    ],
    'answer': 1,
    'explanation': 'Struktur data berfungsi mengorganisasi dan menyimpan data di memori agar penelusuran dan pemrosesannya efisien.',
    'explanation_en': 'Data structures organize and store data in memory to enable efficient access and modification.',
  },
  {
    'question': 'Sebuah aplikasi menyimpan data siswa yang jumlahnya dapat bertambah dan berkurang sewaktu-waktu. Struktur data yang setiap elemennya dapat dihubungkan menggunakan pointer adalah ....',
    'question_en': 'An application stores student records whose quantity changes dynamically. A data structure whose elements are interconnected via pointers is ....',
    'options': ['Integer', 'Boolean', 'Linked List', 'Char', 'String'],
    'options_en': ['Integer', 'Boolean', 'Linked List', 'Char', 'String'],
    'answer': 2,
    'explanation': 'Linked List tersusun dari kumpulan node dinamis yang saling terhubung melalui pointer.',
    'explanation_en': 'A Linked List is composed of dynamic nodes interconnected through pointers.',
  },
  {
    'question': 'Dalam kehidupan sehari-hari, tumpukan piring memiliki prinsip bahwa piring yang terakhir diletakkan akan diambil terlebih dahulu. Prinsip ini disebut ....',
    'question_en': 'In everyday life, a stack of plates operates on the principle that the last plate placed is the first one taken. This principle is called ....',
    'options': ['FIFO', 'LIFO', 'Ascending', 'Searching', 'Traversal'],
    'options_en': ['FIFO', 'LIFO', 'Ascending', 'Searching', 'Traversal'],
    'answer': 1,
    'explanation': 'LIFO (Last In First Out) berarti data yang paling akhir dimasukkan akan diambil terlebih dahulu.',
    'explanation_en': 'LIFO (Last In First Out) means that the last item inserted will be retrieved first.',
  },
  {
    'question': 'Pada sistem antrean di loket sekolah, siswa yang datang pertama akan dilayani terlebih dahulu. Struktur data yang paling sesuai adalah ....',
    'question_en': 'In a school counter queue, the first student to arrive is served first. The most appropriate data structure is ....',
    'options': ['Stack', 'Linked List', 'Queue', 'Binary Search', 'Selection Sort'],
    'options_en': ['Stack', 'Linked List', 'Queue', 'Binary Search', 'Selection Sort'],
    'answer': 2,
    'explanation': 'Queue menggunakan mekanisme FIFO (First In First Out) di mana yang datang pertama dilayani pertama.',
    'explanation_en': 'Queue utilizes a FIFO (First In First Out) mechanism where the earliest arrival is served first.',
  },
  {
    'question': 'Seorang guru ingin mengurutkan nilai siswa dari nilai terkecil hingga terbesar. Proses yang harus dilakukan adalah ....',
    'question_en': 'A teacher wants to order student scores from lowest to highest. The required process is ....',
    'options': ['Searching', 'Deletion', 'Enqueue', 'Sorting', 'Pop'],
    'options_en': ['Searching', 'Deletion', 'Enqueue', 'Sorting', 'Pop'],
    'answer': 3,
    'explanation': 'Sorting adalah proses mengatur elemen data yang acak menjadi berurutan secara sistematis.',
    'explanation_en': 'Sorting is the systematic arrangement of unordered data elements into a specified sequence.',
  },
  {
    'question': 'Tipe data terstruktur yang ukuran memorinya tetap dan kaku sejak awal dideklarasikan adalah ....',
    'question_en': 'A structured data type with a fixed and rigid memory allocation defined at declaration is ....',
    'options': ['Linked List', 'Array statis', 'Dynamic Stack', 'Tree pointer', 'Graph'],
    'options_en': ['Linked List', 'Static Array', 'Dynamic Stack', 'Tree pointer', 'Graph'],
    'answer': 1,
    'explanation': 'Array statis memesan blok memori tetap secara berurutan dan ukurannya tidak dapat membesar secara fleksibel.',
    'explanation_en': 'Static arrays allocate fixed contiguous memory blocks that cannot expand dynamically.',
  },
  {
    'question': 'Operasi dasar untuk menelusuri seluruh data dalam struktur data satu per satu disebut ....',
    'question_en': 'The foundational operation of visiting every element in a data structure sequentially is called ....',
    'options': ['Traversal', 'Pop', 'Push', 'Sorting', 'Swap'],
    'options_en': ['Traversal', 'Pop', 'Push', 'Sorting', 'Swap'],
    'answer': 0,
    'explanation': 'Traversal adalah kunjungan ke setiap elemen struktur data secara berurutan untuk membaca atau menampilkan isinya.',
    'explanation_en': 'Traversal involves visiting every node/element sequentially to read or process its content.',
  },
  {
    'question': 'Algoritma yang bertujuan menemukan letak posisi elemen tertentu di dalam sekumpulan data disebut ....',
    'question_en': 'An algorithm designed to locate the position of a specific target value within a dataset is called ....',
    'options': ['Searching', 'Sorting', 'Enqueue', 'Dequeue', 'Clustering'],
    'options_en': ['Searching', 'Sorting', 'Enqueue', 'Dequeue', 'Clustering'],
    'answer': 0,
    'explanation': 'Searching adalah prosedur pencarian untuk menemukan target data yang dicari.',
    'explanation_en': 'Searching is an algorithmic procedure to determine whether a target key exists and locate it.',
  },
  {
    'question': 'Pengurutan data dari angka terbesar menuju angka terkecil disebut ....',
    'question_en': 'Arranging data values from highest to lowest is termed ....',
    'options': ['Ascending', 'Descending', 'Linear', 'Random', 'Binary'],
    'options_en': ['Ascending', 'Descending', 'Linear', 'Random', 'Binary'],
    'answer': 1,
    'explanation': 'Descending adalah susunan terurut menurun dari nilai terbesar ke nilai terkecil.',
    'explanation_en': 'Descending order arranges items in a downward progression from greatest to least.',
  },
  {
    'question': 'Komponen utama di dalam memori komputer yang menyimpan alamat dari data lain dinamakan ....',
    'question_en': 'A core computing construct that holds the memory address of another value is known as a ....',
    'options': ['Pointer / Reference', 'Value', 'Index', 'Counter', 'Accumulator'],
    'options_en': ['Pointer / Reference', 'Value', 'Index', 'Counter', 'Accumulator'],
    'answer': 0,
    'explanation': 'Pointer menyimpan nilai alamat memori (memory address) yang menunjuk ke lokasi data lainnya.',
    'explanation_en': 'A pointer stores the memory address reference pointing directly to another data location.',
  },
];

// ==========================================
// BANK SOAL ASESMEN PER MODUL (Masing-masing Pool 10 Soal -> Diambil 5 Acak)
// ==========================================
final Map<String, List<Map<String, dynamic>>> asesmenModulQuestions = {
  // MODUL 1 — LINKED LIST
  'linkedlist': [
    {
      'question': 'Linked List adalah struktur data yang terdiri atas kumpulan elemen yang disebut ....',
      'question_en': 'A Linked List is a data structure composed of a collection of elements called ....',
      'options': ['Index', 'Node', 'Queue', 'Stack', 'Array index'],
      'options_en': ['Index', 'Node', 'Queue', 'Stack', 'Array index'],
      'answer': 1,
      'explanation': 'Elemen dasar pembentuk Linked List disebut Node yang berisi data dan pointer.',
      'explanation_en': 'The atomic building blocks of a Linked List are Nodes, containing data and link pointers.',
    },
    {
      'question': 'Pada Linked List, komponen yang menunjukkan node pertama adalah ....',
      'question_en': 'In a Linked List, the reference pointing to the very first node is ....',
      'options': ['Rear', 'Top', 'Front', 'Head', 'NULL'],
      'options_en': ['Rear', 'Top', 'Front', 'Head', 'NULL'],
      'answer': 3,
      'explanation': 'Head adalah gerbang awal atau pointer penunjuk node pertama di rantai Linked List.',
      'explanation_en': 'Head serves as the primary gateway pointer designating the initial node.',
    },
    {
      'question': 'Perhatikan rangkaian Linked List berikut:\n10 → 20 → 30 → NULL\nJika angka 25 disisipkan di antara node 20 dan 30, susunan yang benar adalah ....',
      'question_en': 'Consider the following Linked List:\n10 → 20 → 30 → NULL\nIf node 25 is inserted between node 20 and 30, the resulting sequence is ....',
      'options': [
        '10 → 25 → 20 → 30 → NULL',
        '25 → 10 → 20 → 30 → NULL',
        '10 → 20 → 25 → 30 → NULL',
        '10 → 20 → 30 → 25 → NULL',
        '30 → 20 → 10 → 25 → NULL',
      ],
      'options_en': [
        '10 → 25 → 20 → 30 → NULL',
        '25 → 10 → 20 → 30 → NULL',
        '10 → 20 → 25 → 30 → NULL',
        '10 → 20 → 30 → 25 → NULL',
        '30 → 20 → 10 → 25 → NULL',
      ],
      'answer': 2,
      'explanation': 'Node 20 akan mengarahkan pointernya ke 25, dan node 25 menyambungkan pointer ke 30.',
      'explanation_en': 'Node 20 updates its pointer to node 25, and node 25 links its pointer to 30.',
    },
    {
      'question': 'Perbedaan utama Singly Linked List dan Doubly Linked List adalah ....',
      'question_en': 'The fundamental difference between a Singly Linked List and a Doubly Linked List is ....',
      'options': [
        'Singly Linked List tidak memiliki data',
        'Doubly Linked List hanya memiliki satu node',
        'Singly Linked List selalu berbentuk lingkaran',
        'Doubly Linked List memiliki pointer ke node sebelumnya dan berikutnya',
        'Singly Linked List harus selalu berisi angka',
      ],
      'options_en': [
        'Singly Linked Lists do not contain data values',
        'Doubly Linked Lists can only hold one single node',
        'Singly Linked Lists are always circular',
        'Doubly Linked Lists contain pointers to both the previous and next nodes',
        'Singly Linked Lists must strictly store numeric values',
      ],
      'answer': 3,
      'explanation': 'Doubly Linked List memiliki dua pointer: Next (ke depan) dan Prev (ke belakang).',
      'explanation_en': 'Doubly Linked Lists feature bidirectional navigation via Next and Prev pointers.',
    },
    {
      'question': '[HOTS — Analisis kasus]\nSebuah aplikasi playlist menyimpan lagu dalam urutan A → B → C → D. Pengguna ingin menghapus lagu B tanpa mengubah urutan lagu lainnya. Jika menggunakan Singly Linked List dan node A berada tepat sebelum B, tindakan yang paling tepat adalah ....',
      'question_en': '[HOTS — Case Analysis]\nA music playlist stores songs as A → B → C → D. The user wishes to remove song B without altering the rest. In a Singly Linked List where node A precedes B, the optimal operation is ....',
      'options': [
        'Mengubah pointer A agar menunjuk ke C, kemudian menghapus node B',
        'Mengubah pointer D agar menunjuk ke A',
        'Menghapus seluruh node setelah B',
        'Mengubah Head agar langsung menunjuk ke D',
        'Mengurutkan ulang semua lagu berdasarkan abjad',
      ],
      'options_en': [
        'Re-link node A pointer directly to C, then deallocate node B',
        'Re-link node D pointer to node A',
        'Delete all nodes trailing B',
        'Update Head to point directly to D',
        'Re-sort the entire playlist alphabetically',
      ],
      'answer': 0,
      'explanation': 'Pointer dari node A dialihkan langsung ke C, melewati node B yang hendak dihapus.',
      'explanation_en': 'Node A\'s pointer is bypassed around node B straight to C before deleting B.',
    },
    {
      'question': 'Pointer penunjuk khusus pada node paling akhir Singly Linked List bernilai ....',
      'question_en': 'The next pointer of the final terminal node in a Singly Linked List references ....',
      'options': ['Head', 'Root', 'NULL', 'Zero', 'Undefined'],
      'options_en': ['Head', 'Root', 'NULL', 'Zero', 'Undefined'],
      'answer': 2,
      'explanation': 'NULL menandakan ujung akhir rantai data di mana tidak ada node lanjutan lagi.',
      'explanation_en': 'NULL signifies the terminating boundary of a non-circular linked list.',
    },
    {
      'question': 'Kelebihan utama Linked List dibanding Array statis dalam alokasi memori adalah ....',
      'question_en': 'The primary advantage of Linked Lists over static Arrays regarding memory allocation is ....',
      'options': [
        'Ukurannya dinamis dan tidak perlu memori yang bersebelahan',
        'Pengaksesan data secara acak lebih cepat',
        'Membutuhkan memori lebih sedikit karena tanpa pointer',
        'Otomatis terurut tanpa algoritma sorting',
        'Tidak memerlukan node',
      ],
      'options_en': [
        'Dynamic capacity without requiring contiguous memory blocks',
        'Faster instantaneous random indexing',
        'Lower memory footprint because pointers are omitted',
        'Automatic sorting without sorting algorithms',
        'Nodes are not required',
      ],
      'answer': 0,
      'explanation': 'Linked List menaruh node secara bebas di memori yang kosong dan saling disambung via pointer.',
      'explanation_en': 'Linked Lists allocate memory non-contiguously on the heap connected via pointers.',
    },
    {
      'question': 'Linked List yang node terakhirnya menghubungkan pointer kembali ke node Head disebut ....',
      'question_en': 'A Linked List where the last node links its next pointer back to the Head is known as a ....',
      'options': ['Circular Linked List', 'Doubly Linked List', 'Singly Linked List', 'Stack List', 'Queue List'],
      'options_en': ['Circular Linked List', 'Doubly Linked List', 'Singly Linked List', 'Stack List', 'Queue List'],
      'answer': 0,
      'explanation': 'Circular Linked List membentuk lingkaran tertutup tanpa penunjuk NULL di ujungnya.',
      'explanation_en': 'Circular Linked Lists create a closed ring without null termination.',
    },
    {
      'question': 'Untuk membaca atau mencetak seluruh isi Linked List dari awal sampai akhir, operasi yang digunakan adalah ....',
      'question_en': 'To read or print all node values in a Linked List from start to end, the operation used is ....',
      'options': ['Deletion', 'Insertion', 'Traversal', 'Swap', 'Pop'],
      'options_en': ['Deletion', 'Insertion', 'Traversal', 'Swap', 'Pop'],
      'answer': 2,
      'explanation': 'Traversal melintasi setiap node mulai dari Head hingga menemukan penunjuk NULL.',
      'explanation_en': 'Traversal iterates sequentially across nodes from Head through the terminal pointer.',
    },
    {
      'question': 'Dua bagian utama yang selalu menyusun sebuah node pada Singly Linked List adalah ....',
      'question_en': 'The two primary constituent fields of a Singly Linked List node are ....',
      'options': [
        'Data dan Next Pointer',
        'Head dan Tail',
        'Index dan Array',
        'Top dan Pop',
        'Front dan Rear',
      ],
      'options_en': [
        'Data value and Next Pointer',
        'Head and Tail',
        'Index and Array',
        'Top and Pop',
        'Front and Rear',
      ],
      'answer': 0,
      'explanation': 'Setiap node pada Singly Linked List minimal memuat nilai data dan pointer ke node berikutnya.',
      'explanation_en': 'Each singly linked node encapsulates its payload data and a reference to the next node.',
    },
  ],

  // MODUL 2 — STACK
  'stack': [
    {
      'question': 'Stack menerapkan prinsip ....',
      'question_en': 'The Stack data structure enforces which operating principle? ....',
      'options': [
        'FIFO (First In, First Out)',
        'LIFO (Last In, First Out)',
        'Ascending',
        'Descending',
        'Binary',
      ],
      'options_en': [
        'FIFO (First In, First Out)',
        'LIFO (Last In, First Out)',
        'Ascending',
        'Descending',
        'Binary',
      ],
      'answer': 1,
      'explanation': 'Stack bekerja dengan aturan LIFO: data yang terakhir masuk keluar lebih dahulu.',
      'explanation_en': 'Stack operates under LIFO: elements added most recently are dequeued first.',
    },
    {
      'question': 'Operasi yang digunakan untuk menambahkan data baru ke bagian atas Stack adalah ....',
      'question_en': 'The operation used to append an item to the peak of a Stack is ....',
      'options': ['Pop', 'Peek', 'Push', 'Dequeue', 'Traversal'],
      'options_en': ['Pop', 'Peek', 'Push', 'Dequeue', 'Traversal'],
      'answer': 2,
      'explanation': 'Push adalah perintah untuk menyisipkan data baru ke puncak (Top) tumpukan.',
      'explanation_en': 'Push adds a new data element onto the Top of the stack.',
    },
    {
      'question': 'Sebuah Stack awalnya kosong. Kemudian dilakukan operasi berikut:\nPush(A)\nPush(B)\nPush(C)\nPop()\nData yang keluar dari Stack adalah ....',
      'question_en': 'An initially empty Stack undergoes these operations:\nPush(A)\nPush(B)\nPush(C)\nPop()\nThe item returned by Pop() is ....',
      'options': ['A', 'B', 'C', 'A dan B', 'Tidak ada data yang keluar'],
      'options_en': ['A', 'B', 'C', 'A and B', 'No data returned'],
      'answer': 2,
      'explanation': 'Elemen C berada di puncak tumpukan (terakhir masuk), sehingga C yang dikeluarkan saat Pop().',
      'explanation_en': 'Element C rests on the top of the stack (last pushed), hence it is popped first.',
    },
    {
      'question': 'Apa yang terjadi jika program melakukan operasi Pop pada Stack yang kosong?',
      'question_en': 'What runtime error condition arises if Pop() is invoked on an empty Stack?',
      'options': ['Overflow', 'Underflow', 'Sorting', 'Enqueue', 'Traversal'],
      'options_en': ['Overflow', 'Underflow', 'Sorting', 'Enqueue', 'Traversal'],
      'answer': 1,
      'explanation': 'Underflow adalah kondisi galat saat mencoba mengeluarkan elemen dari Stack yang kosong.',
      'explanation_en': 'Stack Underflow occurs when an extraction operation is attempted on an empty stack.',
    },
    {
      'question': '[HOTS — Analisis kasus]\nSebuah aplikasi desain memiliki fitur Undo untuk membatalkan tindakan terakhir. Pengguna melakukan tindakan berikut secara berurutan:\n1. Menambahkan teks.\n2. Mengubah warna teks.\n3. Memperbesar ukuran teks.\nJika fitur Undo dipanggil satu kali dan sistem menggunakan Stack, tindakan yang seharusnya dibatalkan adalah ....',
      'question_en': '[HOTS — Case Analysis]\nA graphic editor has an Undo feature. A user performs the following actions sequentially:\n1. Add text.\n2. Change text color.\n3. Enlarge font size.\nIf Undo is invoked once on a Stack-backed history, which action is reverted?',
      'options': [
        'Menambahkan teks',
        'Mengubah warna teks',
        'Memperbesar ukuran teks',
        'Seluruh tindakan sekaligus',
        'Tidak ada tindakan yang dibatalkan',
      ],
      'options_en': [
        'Add text',
        'Change text color',
        'Enlarge font size',
        'All actions simultaneously',
        'No action reverted',
      ],
      'answer': 2,
      'explanation': 'Fitur Undo berprinsip LIFO, membatalkan aksi paling mutakhir yaitu memperbesar ukuran teks.',
      'explanation_en': 'Undo adheres to LIFO, rolling back the most recent operation (enlarging text).',
    },
    {
      'question': 'Kondisi saat program mencoba menambahkan data baru (Push) ke dalam Stack yang kapasitasnya sudah penuh disebut ....',
      'question_en': 'The error state occurring when pushing an item into a Stack that has reached its ceiling capacity is ....',
      'options': ['Overflow', 'Underflow', 'Empty', 'Peak', 'NullPointer'],
      'options_en': ['Overflow', 'Underflow', 'Empty', 'Peak', 'NullPointer'],
      'answer': 0,
      'explanation': 'Overflow terjadi ketika tumpukan melebihi batas tampung yang dialokasikan.',
      'explanation_en': 'Stack Overflow happens when push exceeds the allocated stack boundary.',
    },
    {
      'question': 'Operasi untuk melihat nilai elemen teratas pada Stack tanpa menghapusnya dari tumpukan adalah ....',
      'question_en': 'The operation that inspects the topmost element in a Stack without popping it is ....',
      'options': ['Peek / Top', 'Pop', 'Push', 'IsEmpty', 'Clear'],
      'options_en': ['Peek / Top', 'Pop', 'Push', 'IsEmpty', 'Clear'],
      'answer': 0,
      'explanation': 'Peek (atau Top) hanya memeriksa data di posisi puncak tanpa merubah struktur tumpukan.',
      'explanation_en': 'Peek returns the top item without mutating stack size.',
    },
    {
      'question': 'Pintu masuk dan keluar seluruh elemen data pada struktur data Stack berada di ....',
      'question_en': 'The point of access for all insertion and deletion in a Stack is situated at ....',
      'options': ['Satu ujung yang sama (Top)', 'Dua ujung berlawanan', 'Bagian tengah', 'Di mana saja secara acak', 'Sesuai urutan abjad'],
      'options_en': ['The same single terminus (Top)', 'Two opposite ends', 'The center point', 'Any arbitrary location', 'Alphabetical sequence'],
      'answer': 0,
      'explanation': 'Stack hanya memiliki satu akses gerbang untuk operasi penambahan dan penghapusan data.',
      'explanation_en': 'All stack push and pop operations are strictly localized at the Top.',
    },
    {
      'question': 'Sebuah browser web menggunakan Stack untuk menyimpan riwayat tombol Back. Jika user membuka: Beranda -> Berita -> Video, lalu menekan tombol Back satu kali, halaman yang ditampilkan adalah ....',
      'question_en': 'A browser uses a Stack for history. If a user visits: Home -> News -> Video, and taps Back once, which page is rendered?',
      'options': ['Berita', 'Beranda', 'Video', 'Browser tertutup', 'Download'],
      'options_en': ['News', 'Home', 'Video', 'Browser closed', 'Download'],
      'answer': 0,
      'explanation': 'Halaman Video di-pop, membawa pengguna kembali ke halaman tepat sebelumnya yaitu Berita.',
      'explanation_en': 'Video is popped off, uncovering News as the active top page.',
    },
    {
      'question': 'Fungsi IsEmpty pada implementasi struktur data Stack bertujuan untuk ....',
      'question_en': 'The IsEmpty helper method on a Stack implementation is designed to ....',
      'options': [
        'Memeriksa apakah tumpukan tidak memiliki data (kosong)',
        'Menghapus seluruh elemen',
        'Mengisi tumpukan hingga penuh',
        'Menghitung jumlah total kapasitas',
        'Mengurutkan tumpukan',
      ],
      'options_en': [
        'Check whether the stack contains zero elements',
        'Purge all stored elements',
        'Fill stack to maximum capacity',
        'Compute total physical allocation',
        'Sort the stack elements',
      ],
      'answer': 0,
      'explanation': 'IsEmpty mengembalikan nilai boolean benar (true) jika ukuran tumpukan adalah 0.',
      'explanation_en': 'IsEmpty yields true when stack size is zero.',
    },
  ],

  // MODUL 3 — QUEUE
  'queue': [
    {
      'question': 'Queue adalah struktur data yang menerapkan prinsip ....',
      'question_en': 'Queue data structures strictly adhere to which fundamental concept?',
      'options': ['LIFO', 'FIFO', 'FILO', 'Ascending', 'Descending'],
      'options_en': ['LIFO', 'FIFO', 'FILO', 'Ascending', 'Descending'],
      'answer': 1,
      'explanation': 'Queue menerapkan aturan First In, First Out: yang pertama datang akan pertama keluar.',
      'explanation_en': 'Queue abides by First In, First Out: earliest arrivals are processed first.',
    },
    {
      'question': 'Pada Queue, operasi untuk menambahkan data ke bagian belakang antrean disebut ....',
      'question_en': 'In a Queue, the operation used to insert an item into the rear is called ....',
      'options': ['Push', 'Pop', 'Dequeue', 'Enqueue', 'Peek'],
      'options_en': ['Push', 'Pop', 'Dequeue', 'Enqueue', 'Peek'],
      'answer': 3,
      'explanation': 'Enqueue adalah operasi memasukkan elemen baru dari sisi belakang (Rear/Tail).',
      'explanation_en': 'Enqueue appends items to the rear/tail of the queue line.',
    },
    {
      'question': 'Perhatikan urutan operasi berikut:\nEnqueue(A)\nEnqueue(B)\nEnqueue(C)\nDequeue()\nIsi Queue setelah seluruh operasi selesai adalah ....',
      'question_en': 'Given the sequence:\nEnqueue(A)\nEnqueue(B)\nEnqueue(C)\nDequeue()\nThe remaining Queue state is ....',
      'options': ['[A, B, C]', '[A, C]', '[B, C]', '[C, B]', '[A, B]'],
      'options_en': ['[A, B, C]', '[A, C]', '[B, C]', '[C, B]', '[A, B]'],
      'answer': 2,
      'explanation': 'Elemen A berada paling depan dan keluar saat Dequeue(), menyisakan elemen B dan C.',
      'explanation_en': 'Element A was the first in line, so Dequeue() removes A, leaving [B, C].',
    },
    {
      'question': 'Jenis Queue yang memungkinkan data dengan prioritas lebih tinggi diproses lebih dahulu adalah ....',
      'question_en': 'A Queue variant where items with higher precedence weights are dispatched first is a ....',
      'options': ['Linear Queue', 'Circular Queue', 'Priority Queue', 'Singly Linked List', 'Stack Queue'],
      'options_en': ['Linear Queue', 'Circular Queue', 'Priority Queue', 'Singly Linked List', 'Stack Queue'],
      'answer': 2,
      'explanation': 'Priority Queue melayani elemen berdasarkan nilai urgensi/prioritas tertinggi.',
      'explanation_en': 'Priority Queues service items according to importance scores.',
    },
    {
      'question': '[HOTS — Analisis kasus]\nSebuah sistem pencetakan menerima dokumen dengan urutan A, B, dan C. Sebelum semua dokumen dicetak, dokumen D masuk ke antrean. Jika printer menggunakan Queue biasa dan belum ada dokumen yang selesai dicetak, urutan dokumen yang akan dicetak adalah ....',
      'question_en': '[HOTS — Case Analysis]\nA print spooler receives documents A, B, and C. Before processing begins, document D joins. If standard Queue FIFO logic governs the printer, what is the output sequence?',
      'options': ['D, A, B, C', 'C, B, A, D', 'A, B, C, D', 'A, D, B, C', 'B, A, D, C'],
      'options_en': ['D, A, B, C', 'C, B, A, D', 'A, B, C, D', 'A, D, B, C', 'B, A, D, C'],
      'answer': 2,
      'explanation': 'Karena printer melayani secara FIFO adil sesuai kedatangan, urutan cetak tetap A, B, C, D.',
      'explanation_en': 'Under strict FIFO, arrival order A, B, C, D dictates print execution order.',
    },
    {
      'question': 'Penunjuk yang menandakan letak data yang akan diambil atau diproses pertama kali pada Queue disebut ....',
      'question_en': 'The pointer designating the next item to be consumed in a Queue is ....',
      'options': ['Front / Head', 'Rear / Tail', 'Top', 'Bottom', 'Middle'],
      'options_en': ['Front / Head', 'Rear / Tail', 'Top', 'Bottom', 'Middle'],
      'answer': 0,
      'explanation': 'Front adalah ujung depan antrean tempat data diambil atau dikeluarkan (Dequeue).',
      'explanation_en': 'Front/Head marks the removal terminus in a queue.',
    },
    {
      'question': 'Operasi untuk mengambil sekaligus menghapus elemen paling depan pada antrean Queue adalah ....',
      'question_en': 'The operation that retrieves and evicts the leading element from a Queue is ....',
      'options': ['Dequeue', 'Enqueue', 'Push', 'Peek', 'Shift'],
      'options_en': ['Dequeue', 'Enqueue', 'Push', 'Peek', 'Shift'],
      'answer': 0,
      'explanation': 'Dequeue memproses dan mengeluarkan elemen yang berada di barisan paling depan.',
      'explanation_en': 'Dequeue dequeues the element at the Front index.',
    },
    {
      'question': 'Keunggulan utama Circular Queue dibandingkan Linear Queue biasa pada implementasi Array adalah ....',
      'question_en': 'The primary advantage of a Circular Queue over a Linear Queue in array implementations is ....',
      'options': [
        'Dapat memanfaatkan kembali ruang memori depan yang kosong setelah Dequeue',
        'Ukuran antrean menjadi tidak terbatas',
        'Tidak membutuhkan pointer Front dan Rear',
        'Dapat diakses secara LIFO',
        'Kecepatan pencarian menjadi binary',
      ],
      'options_en': [
        'Recycles vacant memory slots left open by preceding dequeue calls',
        'Achieves infinite memory capacity',
        'Eliminates the need for Front and Rear markers',
        'Provides LIFO access capabilities',
        'Converts lookups into binary searches',
      ],
      'answer': 0,
      'explanation': 'Circular Queue menyambungkan indeks ujung ke awal sehingga memori depan yang kosong bisa dipakai lagi.',
      'explanation_en': 'Circular Queues wrap indexes modulo capacity to reuse empty front cells.',
    },
    {
      'question': 'Jika sebuah antrean kosong memiliki kapasitas 5 dan dilakukan Enqueue sebanyak 6 kali tanpa Dequeue, akan terjadi ....',
      'question_en': 'If an empty static queue has capacity 5 and receives 6 consecutive Enqueues, the result is ....',
      'options': ['Queue Overflow', 'Queue Underflow', 'Deadlock', 'Data otomatis tertukar', 'Segmentation Fault'],
      'options_en': ['Queue Overflow', 'Queue Underflow', 'Deadlock', 'Data automatically swapped', 'Segmentation Fault'],
      'answer': 0,
      'explanation': 'Overflow terjadi saat data baru dimasukkan melampaui daya tampung antrean.',
      'explanation_en': 'Overflow occurs when inserting past maximum buffer capacity.',
    },
    {
      'question': 'Elemen baru pada Queue biasa selalu masuk melalui bagian ....',
      'question_en': 'In standard Queues, incoming items are invariably appended at the ....',
      'options': ['Belakang (Rear / Tail)', 'Depan (Front / Head)', 'Tengah', 'Top', 'Sesuai urutan nilai'],
      'options_en': ['Rear / Tail', 'Front / Head', 'Center', 'Top', 'Sorted value slot'],
      'answer': 0,
      'explanation': 'Penambahan data (Enqueue) selalu ditempatkan di posisi paling belakang antrean.',
      'explanation_en': 'All queue insertions are localized at the Rear/Tail.',
    },
  ],

  // MODUL 4 — SEARCHING DAN SORTING
  'searching_sorting': [
    {
      'question': 'Proses mengurutkan kumpulan data dari nilai terkecil ke terbesar disebut ....',
      'question_en': 'Arranging a dataset from minimum to maximum value is known as ....',
      'options': ['Searching', 'Deletion', 'Ascending Sorting', 'Descending Searching', 'Traversal'],
      'options_en': ['Searching', 'Deletion', 'Ascending Sorting', 'Descending Searching', 'Traversal'],
      'answer': 2,
      'explanation': 'Ascending adalah pengurutan menaik dari nilai terkecil ke nilai terbesar.',
      'explanation_en': 'Ascending sorting arranges values in an increasing order.',
    },
    {
      'question': 'Algoritma pencarian yang memeriksa elemen satu per satu dari awal hingga data ditemukan disebut ....',
      'question_en': 'A search algorithm that verifies items one by one sequentially from start to finish is ....',
      'options': ['Binary Search', 'Linear Search', 'Bubble Sort', 'Selection Sort', 'Insertion'],
      'options_en': ['Binary Search', 'Linear Search', 'Bubble Sort', 'Selection Sort', 'Insertion'],
      'answer': 1,
      'explanation': 'Linear Search mengecek setiap butir data mulai indeks pertama sampai data ditemukan.',
      'explanation_en': 'Linear Search verifies elements in index order until matched.',
    },
    {
      'question': 'Syarat utama agar Binary Search dapat diterapkan dengan benar pada kumpulan data adalah ....',
      'question_en': 'The mandatory prerequisite for applying Binary Search correctly is ....',
      'options': [
        'Data harus selalu berbentuk teks',
        'Data harus memiliki jumlah genap',
        'Data harus tersimpan dalam Stack',
        'Data harus sudah terurut',
        'Data harus memiliki nilai yang sama',
      ],
      'options_en': [
        'Data must consist solely of strings',
        'Collection must contain an even count',
        'Data must reside inside a Stack',
        'Data must already be sorted',
        'All elements must share equal values',
      ],
      'answer': 3,
      'explanation': 'Binary Search memerlukan data yang sudah tersusun rapi untuk membagi wilayah pencarian.',
      'explanation_en': 'Binary Search relies on sorted elements to systematically divide search boundaries.',
    },
    {
      'question': 'Bubble Sort bekerja dengan cara ....',
      'question_en': 'The mechanism of Bubble Sort operates by ....',
      'options': [
        'Membandingkan elemen yang bersebelahan dan menukarnya jika urutannya salah',
        'Menghapus seluruh elemen yang tidak sesuai',
        'Mencari data hanya pada posisi tengah',
        'Memasukkan data ke dalam Queue',
        'Menghubungkan setiap elemen dengan pointer',
      ],
      'options_en': [
        'Comparing adjacent elements and swapping them if out of order',
        'Purging all elements that violate ordering',
        'Inspecting items exclusively at the midpoint',
        'Pushing elements into a Queue',
        'Linking nodes using pointers',
      ],
      'answer': 0,
      'explanation': 'Bubble Sort membandingkan elemen berpasangan dan menukarnya hingga data terbesar mengapung ke belakang.',
      'explanation_en': 'Bubble Sort swaps adjacent out-of-order pairs until sorted.',
    },
    {
      'question': '[HOTS — Analisis kasus]\nSebuah toko online memiliki data harga produk berikut:\n45.000, 20.000, 35.000, 15.000, 30.000\n\nPemilik toko ingin menampilkan harga dari yang termurah ke termahal menggunakan Selection Sort. Setelah langkah pertama, nilai terkecil dari seluruh data dipindahkan ke posisi pertama. Susunan yang benar setelah langkah tersebut adalah ....',
      'question_en': '[HOTS — Case Analysis]\nAn e-commerce store has product prices:\n45,000, 20,000, 35,000, 15,000, 30,000\n\nSorting in ascending order using Selection Sort swaps the minimum item with the first element in pass 1. The resulting array is ....',
      'options': [
        '20.000, 45.000, 35.000, 15.000, 30.000',
        '15.000, 20.000, 35.000, 45.000, 30.000',
        '15.000, 20.000, 35.000, 30.000, 45.000',
        '45.000, 20.000, 35.000, 15.000, 30.000',
        '20.000, 15.000, 30.000, 35.000, 45.000',
      ],
      'options_en': [
        '20,000, 45,000, 35,000, 15,000, 30,000',
        '15,000, 20,000, 35,000, 45,000, 30,000',
        '15,000, 20,000, 35,000, 30,000, 45,000',
        '45,000, 20,000, 35,000, 15,000, 30,000',
        '20,000, 15,000, 30,000, 35,000, 45,000',
      ],
      'answer': 1,
      'explanation': 'Elemen minimum 15.000 ditukar dengan elemen pertama (45.000), menjadi: 15.000, 20.000, 35.000, 45.000, 30.000.',
      'explanation_en': 'The minimum value 15,000 is swapped with index 0 (45,000), yielding [15000, 20000, 35000, 45000, 30000].',
    },
    {
      'question': 'Pada algoritma Binary Search, data dibandingkan terlebih dahulu dengan elemen yang berada di posisi ....',
      'question_en': 'In Binary Search, the search key is initially compared against the element at the ....',
      'options': ['Tengah (Mid)', 'Awal (First)', 'Akhir (Last)', 'Acak (Random)', 'Indeks ke-1'],
      'options_en': ['Midpoint (Mid)', 'Beginning (First)', 'End (Last)', 'Random index', 'Index 1'],
      'answer': 0,
      'explanation': 'Binary Search menghitung nilai indeks tengah (mid = (low + high) / 2) pada tiap langkah.',
      'explanation_en': 'Binary Search probes the middle index mid = (low + high) ~/ 2 first.',
    },
    {
      'question': 'Algoritma sorting yang bekerja dengan mencari nilai minimum di sisa array lalu menukarnya ke posisi awal disebut ....',
      'question_en': 'The sorting algorithm that selects the smallest item from the unsorted subarray and swaps it into place is ....',
      'options': ['Selection Sort', 'Bubble Sort', 'Quick Search', 'Linear Search', 'Merge Pop'],
      'options_en': ['Selection Sort', 'Bubble Sort', 'Quick Search', 'Linear Search', 'Merge Pop'],
      'answer': 0,
      'explanation': 'Selection Sort memilih elemen terkecil secara berulang untuk ditempatkan pada posisi terdepan yang belum terurut.',
      'explanation_en': 'Selection Sort isolates the minimum element and moves it to the target frontier.',
    },
    {
      'question': 'Jika data berjumlah 1.000.000 elemen dan sudah terurut, algoritma pencarian yang paling efisien adalah ....',
      'question_en': 'Across 1,000,000 pre-sorted elements, the most computationally efficient search algorithm is ....',
      'options': ['Binary Search', 'Linear Search', 'Bubble Search', 'Queue Traversal', 'Stack Search'],
      'options_en': ['Binary Search', 'Linear Search', 'Bubble Search', 'Queue Traversal', 'Stack Search'],
      'answer': 0,
      'explanation': 'Binary Search memiliki kompleksitas O(log N), jauh lebih cepat daripada Linear Search O(N).',
      'explanation_en': 'Binary Search operates in O(log N) logarithmic time, vastly outperforming linear scans.',
    },
    {
      'question': 'Pengurutan dari nilai tertinggi ke terendah dinamakan ....',
      'question_en': 'Arranging values from top score down to the lowest is called ....',
      'options': ['Descending', 'Ascending', 'Sequential', 'Binary', 'Linear'],
      'options_en': ['Descending', 'Ascending', 'Sequential', 'Binary', 'Linear'],
      'answer': 0,
      'explanation': 'Descending adalah teknik mengurutkan data dari besar ke kecil (Z ke A atau 10 ke 1).',
      'explanation_en': 'Descending order arranges items in decreasing magnitude.',
    },
    {
      'question': 'Kelemahan algoritma Linear Search dibandingkan Binary Search adalah ....',
      'question_en': 'The primary disadvantage of Linear Search relative to Binary Search is ....',
      'options': [
        'Membutuhkan waktu pemeriksaan lebih lama pada jumlah data yang sangat besar',
        'Data wajib terurut terlebih dahulu',
        'Hanya bisa digunakan pada tipe data String',
        'Tidak dapat menemukan data',
        'Membutuhkan memori ganda',
      ],
      'options_en': [
        'Excessive execution latency when applied over massive datasets',
        'Requires datasets to be sorted beforehand',
        'Restricted strictly to String data types',
        'Inability to locate matches reliably',
        'Requires double memory capacity',
      ],
      'answer': 0,
      'explanation': 'Linear Search harus mengecek satu per satu data sehingga lambat jika datanya jutaan.',
      'explanation_en': 'Linear Search scans O(N) sequentially, causing performance degradation on large arrays.',
    },
  ],
};

// ==========================================
// BANK SOAL F: POST-TEST (Pool 15 Soal dengan Label Modul)
// ==========================================
final List<Map<String, dynamic>> postTestQuestions = [
  {
    'moduleId': 'linkedlist',
    'question': 'Pada Linked List, komponen yang menghubungkan sebuah node dengan node berikutnya adalah ....',
    'question_en': 'In a Linked List, the component that connects a node to the next node is ....',
    'options': ['Head', 'Top', 'Next Pointer', 'Rear', 'Front'],
    'options_en': ['Head', 'Top', 'Next Pointer', 'Rear', 'Front'],
    'answer': 2,
    'explanation': 'Next Pointer menunjuk ke alamat memori dari node berikutnya di dalam rantai data.',
    'explanation_en': 'Next Pointer contains the memory reference pointing to the succeeding node.',
  },
  {
    'moduleId': 'stack',
    'question': 'Sebuah Stack memiliki isi dari bawah ke atas berupa A, B, C. Jika dilakukan Pop sebanyak satu kali, isi Stack dari bawah ke atas menjadi ....',
    'question_en': 'A Stack contains bottom-to-top items A, B, C. After calling Pop() once, the bottom-to-top contents are ....',
    'options': ['A, B', 'B, C', 'A, C', 'C', 'Kosong'],
    'options_en': ['A, B', 'B, C', 'A, C', 'C', 'Empty'],
    'answer': 0,
    'explanation': 'Elemen C di puncak dikeluarkan, menyisakan A di bawah dan B di atasnya.',
    'explanation_en': 'Element C on top is popped, leaving A at bottom and B on top.',
  },
  {
    'moduleId': 'queue',
    'question': 'Dalam Queue, data yang pertama kali masuk akan ....',
    'question_en': 'In a Queue, the item that arrived first will be ....',
    'options': ['Dikeluarkan terakhir', 'Dikeluarkan pertama', 'Selalu berada di tengah', 'Dipindahkan ke Stack', 'Dihapus secara acak'],
    'options_en': ['Dequeued last', 'Dequeued first', 'Fixed permanently in the middle', 'Pushed into a Stack', 'Randomly removed'],
    'answer': 1,
    'explanation': 'Prinsip FIFO menetapkan data pertama yang masuk akan diproses dan dikeluarkan pertama kali.',
    'explanation_en': 'FIFO guarantees the earliest arrival is processed and evicted first.',
  },
  {
    'moduleId': 'searching_sorting',
    'question': 'Algoritma yang membandingkan elemen bersebelahan dan menukarnya apabila urutannya salah adalah ....',
    'question_en': 'The algorithm that compares neighbor elements and swaps them if disordered is ....',
    'options': ['Linear Search', 'Binary Search', 'Selection Sort', 'Bubble Sort', 'Traversal'],
    'options_en': ['Linear Search', 'Binary Search', 'Selection Sort', 'Bubble Sort', 'Traversal'],
    'answer': 3,
    'explanation': 'Bubble Sort membandingkan dan menukar dua elemen yang berdampingan secara terus menerus.',
    'explanation_en': 'Bubble Sort iteratively swaps adjacent unordered pairs.',
  },
  {
    'moduleId': 'searching_sorting',
    'question': 'Seorang siswa ingin mencari nomor induk tertentu dalam daftar yang belum terurut. Metode yang dapat langsung digunakan tanpa mengurutkan data terlebih dahulu adalah ....',
    'question_en': 'A student needs to locate an ID in an unsorted list. The method usable without prior sorting is ....',
    'options': ['Binary Search', 'Linear Search', 'Selection Sort', 'Bubble Sort', 'Enqueue'],
    'options_en': ['Binary Search', 'Linear Search', 'Selection Sort', 'Bubble Sort', 'Enqueue'],
    'answer': 1,
    'explanation': 'Linear Search dapat langsung digunakan pada data acak tanpa perlu pengurutan awal.',
    'explanation_en': 'Linear Search works out of the box on arbitrary unsorted collections.',
  },
  {
    'moduleId': 'linkedlist',
    'question': 'Pada Circular Linked List, node terakhir memiliki pointer yang mengarah kembali ke ....',
    'question_en': 'In a Circular Linked List, the terminal node has a pointer directing back to ....',
    'options': ['NULL', 'Node terakhir', 'Node pertama', 'Node kedua saja', 'Head dan NULL sekaligus'],
    'options_en': ['NULL', 'The last node', 'The first node', 'The second node only', 'Both Head and NULL'],
    'answer': 2,
    'explanation': 'Node ekor pada Circular Linked List tersambung kembali ke node kepala (Head).',
    'explanation_en': 'The tail node in a circular list loops back to the Head node.',
  },
  {
    'moduleId': 'stack',
    'question': '[HOTS — Analisis dan penerapan]\nSebuah aplikasi pelayanan kampus memiliki dua fitur: riwayat halaman yang terakhir dibuka dapat dikembalikan dengan tombol Back, sedangkan permintaan pencetakan dokumen dilayani berdasarkan urutan kedatangan. Pasangan struktur data yang paling tepat untuk kedua fitur tersebut adalah ....',
    'question_en': '[HOTS — System Design]\nA campus portal needs two mechanisms: browser Back button history navigation, and printer document queues processed by arrival. The ideal data structure pair is ....',
    'options': [
      'Queue untuk tombol Back dan Stack untuk pencetakan',
      'Stack untuk tombol Back dan Queue untuk pencetakan',
      'Linked List untuk keduanya tanpa operasi tambahan',
      'Sorting untuk tombol Back dan Searching untuk pencetakan',
      'Binary Search untuk tombol Back dan Bubble Sort untuk pencetakan',
    ],
    'options_en': [
      'Queue for Back button, and Stack for printing',
      'Stack for Back button, and Queue for printing',
      'Linked List for both without additional logic',
      'Sorting for Back button, and Searching for printing',
      'Binary Search for Back button, and Bubble Sort for printing',
    ],
    'answer': 1,
    'explanation': 'Tombol Back menggunakan Stack (LIFO), sedangkan antrean cetak memakai Queue (FIFO).',
    'explanation_en': 'Back button history is a LIFO Stack, while document spooling is a FIFO Queue.',
  },
  {
    'moduleId': 'searching_sorting',
    'question': 'Perhatikan data terurut berikut:\n[10, 20, 30, 40, 50, 60, 70]\nJika Binary Search mencari nilai 60, nilai tengah yang diperiksa pertama kali adalah ....',
    'question_en': 'Consider sorted elements:\n[10, 20, 30, 40, 50, 60, 70]\nSearching for 60 with Binary Search probes which initial midpoint value?',
    'options': ['10', '20', '30', '40', '60'],
    'options_en': ['10', '20', '30', '40', '60'],
    'answer': 3,
    'explanation': 'Terdapat 7 elemen (indeks 0–6). Nilai tengah awal adalah indeks ke-3 yaitu angka 40.',
    'explanation_en': 'Across 7 elements (indexes 0 to 6), the initial midpoint is index 3 (value 40).',
  },
  {
    'moduleId': 'searching_sorting',
    'question': '[HOTS — Evaluasi algoritma]\nSebuah toko online memiliki 10.000 data produk yang belum terurut. Pengguna sering mencari produk berdasarkan kode produk, dan data produk jarang berubah. Pengembang ingin membuat pencarian berulang menjadi lebih efisien dengan menggunakan Binary Search. Strategi yang paling tepat adalah ....',
    'question_en': '[HOTS — Algorithmic Strategy]\nAn app has 10,000 unsorted product records queried frequently by product code with rare updates. To maximize lookup speed via Binary Search, the developer should ....',
    'options': [
      'Menggunakan Binary Search langsung pada data acak',
      'Mengurutkan data terlebih dahulu, kemudian menggunakan Binary Search',
      'Menghapus setengah data sebelum melakukan pencarian',
      'Menggunakan Pop untuk mencari kode produk',
      'Memasukkan seluruh data ke Stack tanpa mengubah urutannya',
    ],
    'options_en': [
      'Apply Binary Search directly onto unsorted data',
      'Sort the dataset once initially, then execute repeated Binary Searches',
      'Delete half the array before executing lookups',
      'Call Pop() repeatedly to locate the product ID',
      'Push all records into a Stack without reordering',
    ],
    'answer': 1,
    'explanation': 'Mengurutkan data di awal memungkinkan ribuan pencarian berikutnya berjalan efisien dengan Binary Search.',
    'explanation_en': 'A one-time sort allows repeated subsequent queries to execute in O(log N).',
  },
  {
    'moduleId': 'searching_sorting',
    'question': 'Pada Selection Sort secara ascending, tindakan utama yang dilakukan pada setiap tahap adalah ....',
    'question_en': 'In ascending Selection Sort, the recurring operation in each iteration is ....',
    'options': [
      'Memeriksa setiap elemen tanpa pernah menukarnya',
      'Memindahkan elemen terbesar ke akhir pada setiap tahap',
      'Mencari elemen terkecil pada bagian yang belum terurut, lalu menempatkannya pada posisi yang tepat',
      'Membagi data menjadi dua bagian untuk mencari target',
      'Menghapus elemen yang nilainya paling kecil',
    ],
    'options_en': [
      'Scan items without executing any swaps',
      'Relocate the largest item to the end in every pass',
      'Find the minimum element in the unsorted slice and swap it into the boundary slot',
      'Split data in two halves to find targets',
      'Delete the smallest detected element',
    ],
    'answer': 2,
    'explanation': 'Selection Sort memilih elemen nilai terendah dan memindahkannya ke indeks target.',
    'explanation_en': 'Selection Sort identifies the minimum key in the remaining sublist and swaps it.',
  },
  {
    'moduleId': 'queue',
    'question': 'Struktur data di mana penyisipan dilakukan dari satu ujung dan penghapusan dilakukan dari ujung lainnya adalah ....',
    'question_en': 'A data structure where insertions occur at one end and deletions at the opposite end is a ....',
    'options': ['Queue', 'Stack', 'Array', 'Single Node', 'Binary Tree'],
    'options_en': ['Queue', 'Stack', 'Array', 'Single Node', 'Binary Tree'],
    'answer': 0,
    'explanation': 'Queue memiliki dua ujung terpisah: Enqueue di Rear dan Dequeue di Front.',
    'explanation_en': 'Queues use distinct endpoints: Enqueue at Rear and Dequeue at Front.',
  },
  {
    'moduleId': 'stack',
    'question': 'Kondisi saat sebuah fungsi memanggil dirinya sendiri, yang di dalam arsitektur komputer eksekusinya ditangani menggunakan memori berstruktur ....',
    'question_en': 'When a function calls itself recursively, computer architectures manage the call frames using a ....',
    'options': ['Call Stack', 'Queue Buffer', 'Circular Array', 'Linked Pointer', 'Index Table'],
    'options_en': ['Call Stack', 'Queue Buffer', 'Circular Array', 'Linked Pointer', 'Index Table'],
    'answer': 0,
    'explanation': 'Komputer melacak panggilan rekursif menggunakan struktur data Call Stack.',
    'explanation_en': 'Operating systems manage nested recursive execution via the hardware Call Stack.',
  },
  {
    'moduleId': 'linkedlist',
    'question': 'Pointer yang bernilai kosong atau tidak menunjuk ke alamat memori manapun disebut ....',
    'question_en': 'A pointer holding a null reference that points to no memory address is called a ....',
    'options': ['NULL Pointer', 'Head Pointer', 'Next Pointer', 'Root Pointer', 'Leaf Pointer'],
    'options_en': ['NULL Pointer', 'Head Pointer', 'Next Pointer', 'Root Pointer', 'Leaf Pointer'],
    'answer': 0,
    'explanation': 'NULL menandakan pointer kosong tanpa target rujukan.',
    'explanation_en': 'A NULL pointer represents an unassigned memory reference.',
  },
  {
    'moduleId': 'searching_sorting',
    'question': 'Jika sebuah deret [5, 1, 4] diurutkan secara ascending dengan Bubble Sort, langkah pertukaran pertama menghasilkan deret ....',
    'question_en': 'Sorting array [5, 1, 4] in ascending order with Bubble Sort produces which array after the first swap?',
    'options': ['[1, 5, 4]', '[5, 4, 1]', '[4, 1, 5]', '[1, 4, 5]', '[5, 1, 4]'],
    'options_en': ['[1, 5, 4]', '[5, 4, 1]', '[4, 1, 5]', '[1, 4, 5]', '[5, 1, 4]'],
    'answer': 0,
    'explanation': 'Elemen 5 dan 1 dibandingkan. Karena 5 > 1, posisinya ditukar menjadi [1, 5, 4].',
    'explanation_en': '5 and 1 are compared. Since 5 > 1, they swap, resulting in [1, 5, 4].',
  },
  {
    'moduleId': 'linkedlist',
    'question': 'Keunggulan utama Linked List dibandingkan Stack yang diimplementasikan dengan Array berukuran tetap adalah ....',
    'question_en': 'The core advantage of a Linked List over a fixed-size Array-based Stack is ....',
    'options': [
      'Tidak memiliki batas maksimal kapasitas (tidak mudah Stack Overflow)',
      'Akses indeks langsung O(1)',
      'Membutuhkan memori lebih ringkas',
      'Tidak memerlukan pointer',
      'Otomatis terurut',
    ],
    'options_en': [
      'No rigid capacity bound (immune to static stack overflow)',
      'Constant time O(1) random indexing',
      'Smaller memory consumption',
      'Eliminates pointer overhead',
      'Maintains sorted order automatically',
    ],
    'answer': 0,
    'explanation': 'Linked List mengalokasikan memori per node secara dinamis sehingga kapasitasnya tidak terkunci ukuran tetap.',
    'explanation_en': 'Linked Lists allocate nodes on demand, eliminating fixed stack capacity constraints.',
  },
];

// ==========================================
// HELPER METHOD PENGAMBIL DAFTAR SOAL
// ==========================================
List<Map<String, dynamic>> getQuestionsForType(String quizType) {
  if (quizType == 'pretest') {
    return preTestQuestions;
  } else if (quizType == 'posttest') {
    return postTestQuestions;
  } else if (quizType.startsWith('asesmen_')) {
    final moduleId = quizType.replaceFirst('asesmen_', '');
    return asesmenModulQuestions[moduleId] ?? [];
  }
  return [];
}