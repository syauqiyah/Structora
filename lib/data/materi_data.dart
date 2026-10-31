import 'package:flutter/material.dart';
import '../utils/app_translations.dart';

// Helper Extension agar pemanggilan di widget sangat ringkas
extension ModulLocalizationExtension on Map<String, dynamic> {
  String getLocalizedTitle([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['title_en'] ?? this['title']) : this['title'];
  }

  String getLocalizedDesc([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['desc_en'] ?? this['desc']) : this['desc'];
  }

  String getLocalizedVideoTitle([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['videoTitle_en'] ?? this['videoTitle']) : this['videoTitle'];
  }

  Map<String, dynamic> getLocalizedPenjelasan([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['penjelasan_en'] ?? this['penjelasan']) : this['penjelasan'];
  }

  Map<String, dynamic> getLocalizedPretest([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['pretest_en'] ?? this['pretest']) : this['pretest'];
  }

  Map<String, dynamic> getLocalizedPosttest([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    return en ? (this['posttest_en'] ?? this['posttest']) : this['posttest'];
  }

  String getFormattedExplanation([bool? isEnglish]) {
    final en = isEnglish ?? LanguageController.instance.isEnglish;
    final map = getLocalizedPenjelasan(en);
    if (map.containsKey('sub_bab') && map['sub_bab'] is List) {
      final List subBab = map['sub_bab'];
      final buffer = StringBuffer();
      for (var sb in subBab) {
        if (sb is Map) {
          if (buffer.isNotEmpty) buffer.write('\n\n');
          buffer.write('${sb['judul']}\n${sb['isi']}');
        }
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }
    return getLocalizedDesc(en);
  }
}

final List<Map<String, dynamic>> listModulMateri = [
  // ==========================================
  // MODUL 1: LINKED LIST
  // ==========================================
  {
    'id': 'linkedlist',
    'title': 'Modul 1: Linked List',
    'title_en': 'Module 1: Linked List',
    'desc': 'Struktur data elemen node fleksibel yang terhubung via pointer dinamis.',
    'desc_en': 'Flexible node element data structure connected via dynamic pointers.',
    'icon': Icons.hub_outlined,
    'color': const Color(0xFF0284C7),
    'videoTitle': 'Visualisasi Node, Pointer, dan Traversal Linked List',
    'videoTitle_en': 'Node Visualization, Pointers, and Linked List Traversal',
    'videoDuration': '08:45',
    'penjelasan': {
      'sub_bab': [
        {
          'judul': 'A. Pengertian',
          'isi':
          'Linked List adalah struktur data linier yang tersusun dari kumpulan elemen bernama Node. Berbeda dengan Array statis yang ukurannya kaku dan harus berurutan di memori komputer, Linked List bersifat dinamis sehingga penambahan atau pengurangan elemen dapat dilakukan secara fleksibel tanpa perlu menggeser posisi data lainnya.',
        },
        {
          'judul': 'B. Komponen Utama Node:',
          'isi':
          '1. Data atau Value: Nilai atau informasi aktual yang tersimpan di dalam node.\n'
              '2. Next Pointer: Penunjuk alamat memori yang menghubungkan node saat ini ke node berikutnya.\n'
              '3. Head: Pintu masuk utama atau node pertama di dalam linked list.\n'
              '4. NULL Pointer: Penunjuk khusus di node paling akhir yang menandakan ujung dari rantai data.',
        },
        {
          'judul': 'C. Jenis-Jenis Linked List:',
          'isi':
          '1. Singly Linked List: Setiap node hanya memiliki satu pointer yang mengarah ke depan. Penelusuran hanya bisa dilakukan satu arah dari Head ke belakang.\n'
              '2. Doubly Linked List: Setiap node memiliki dua pointer, yaitu penunjuk ke node sebelumnya (Prev) dan ke node berikutnya (Next). Data dapat dijelajahi dua arah, baik maju maupun mundur.\n'
              '3. Circular Linked List: Node terakhir tidak mengarah ke NULL, melainkan tersambung kembali ke node pertama sehingga membentuk siklus melingkar.',
        },
        {
          'judul': 'D. Operasi Dasar dan Cara Kerja:',
          'isi':
          '1. Traversal: Mengunjungi setiap node satu demi satu untuk membaca atau menampilkan isi data.\n'
              '2. Insertion: Menyisipkan node baru. Contohnya jika ada untaian 10 -> 20 -> 30, untuk menyisipkan angka 15 di antara 10 dan 20, kita cukup mengalihkan pointer dari node 10 ke 15, lalu pointer 15 disambungkan ke 20 sehingga susunannya menjadi 10 -> 15 -> 20 -> 30.\n'
              '3. Deletion: Menghapus node tertentu dengan cara menyambungkan pointer node sebelumnya langsung ke node sesudahnya.\n'
              '4. Searching: Mencari keberadaan nilai data tertentu di dalam untaian node.',
        },
        {
          'judul': 'E. Analogi Nyata:',
          'isi':
          'Bayangkan rangkaian gerbong kereta api atau permainan berburu harta karun. Setiap lokasi menyimpan petunjuk yang mengarahkanmu ke lokasi berikutnya hingga akhirnya sampai di tujuan akhir.',
        },
      ],
    },
    'penjelasan_en': {
      'sub_bab': [
        {
          'judul': 'A. Definition',
          'isi':
          'A Linked List is a linear data structure composed of a collection of elements called Nodes. Unlike static Arrays which have rigid sizes and must be contiguous in memory, Linked Lists are dynamic, allowing flexible insertion and deletion of elements without shifting existing elements.',
        },
        {
          'judul': 'B. Main Components of a Node:',
          'isi':
          '1. Data or Value: The actual data or value stored within the node.\n'
              '2. Next Pointer: Memory address reference linking the current node to the next node.\n'
              '3. Head: The main entry point or the first node of the linked list.\n'
              '4. NULL Pointer: A special pointer at the very last node signaling the end of the chain.',
        },
        {
          'judul': 'C. Types of Linked Lists:',
          'isi':
          '1. Singly Linked List: Each node contains only one pointer pointing forward. Traversal can only be performed in one direction from Head to end.\n'
              '2. Doubly Linked List: Each node contains two pointers: previous (Prev) and next (Next). Data can be navigated both ways.\n'
              '3. Circular Linked List: The last node points back to the first node instead of NULL, forming a circular cycle.',
        },
        {
          'judul': 'D. Basic Operations and Workflow:',
          'isi':
          '1. Traversal: Visiting each node sequentially to read or display the data.\n'
              '2. Insertion: Inserting a new node. For example, in 10 -> 20 -> 30, inserting 15 between 10 and 20 simply updates 10 to point to 15, and 15 to point to 20, forming 10 -> 15 -> 20 -> 30.\n'
              '3. Deletion: Removing a node by redirecting the previous node\'s pointer directly to the following node.\n'
              '4. Searching: Finding a specific target value within the node sequence.',
        },
        {
          'judul': 'E. Real-Life Analogy:',
          'isi':
          'Think of train carriages connected in sequence or a treasure hunt game. Each clue directs you to the next location until reaching the final destination.',
        },
      ],
    },
    'pretest': {
      'question': 'Elemen pada Linked List saling terhubung menggunakan...',
      'options': ['Index angka tetap', 'Pointer / Reference', 'Cache CPU', 'Registry'],
      'answer': 1
    },
    'pretest_en': {
      'question': 'Elements in a Linked List are connected to each other using...',
      'options': ['Fixed numerical index', 'Pointer / Reference', 'CPU Cache', 'Registry'],
      'answer': 1
    },
    'posttest': {
      'question': 'Penunjuk khusus yang menandakan node paling pertama pada Linked List adalah...',
      'options': ['Tail', 'Head', 'NULL', 'Root'],
      'answer': 1
    },
    'posttest_en': {
      'question': 'The special pointer indicating the very first node in a Linked List is...',
      'options': ['Tail', 'Head', 'NULL', 'Root'],
      'answer': 1
    },
  },

  // ==========================================
  // MODUL 2: STACK (TUMPUKAN)
  // ==========================================
  {
    'id': 'stack',
    'title': 'Modul 2: Stack (Tumpukan)',
    'title_en': 'Module 2: Stack',
    'desc': 'Struktur data tumpukan linear dengan mekanisme Last In, First Out (LIFO).',
    'desc_en': 'Linear stack data structure adhering to the Last In, First Out (LIFO) mechanism.',
    'icon': Icons.layers_outlined,
    'color': const Color(0xFFD97706),
    'videoTitle': 'Operasi Push, Pop, Peek, dan Top pada Stack',
    'videoTitle_en': 'Push, Pop, Peek, and Top Operations in Stack',
    'videoDuration': '07:15',
    'penjelasan': {
      'sub_bab': [
        {
          'judul': 'A. Pengertian',
          'isi':
          'Stack adalah struktur data linier yang bekerja dengan prinsip LIFO (Last In, First Out), artinya data yang terakhir kali dimasukkan akan menjadi data yang pertama kali diambil atau dikeluarkan. Seluruh aktivitas penambahan dan pengambilan data hanya dilakukan melalui satu pintu di posisi teratas (Top).',
        },
        {
          'judul': 'B. Komponen dan Operasi Utama:',
          'isi':
          '1. Top: Penunjuk posisi elemen data yang berada di puncak tumpukan.\n'
              '2. Push: Operasi menyisipkan atau menaruh data baru ke bagian paling atas tumpukan.\n'
              '3. Pop: Operasi mengambil sekaligus mengeluarkan data teratas dari tumpukan.\n'
              '4. Peek atau Top: Operasi mengintip nilai data yang ada di posisi teratas tanpa menghapusnya.\n'
              '5. IsEmpty: Memeriksa apakah tumpukan sedang kosong.\n'
              '6. IsFull: Memeriksa apakah kapasitas tumpukan sudah terisi penuh.',
        },
        {
          'judul': 'C. Kondisi Batas Stack:',
          'isi':
          '1. Overflow: Kondisi galat (error) saat program mencoba memasukkan data baru (Push) ke tumpukan yang sudah terisi penuh.\n'
              '2. Underflow: Kondisi saat program mencoba mengambil data (Pop) dari tumpukan yang sedang kosong.',
        },
        {
          'judul': 'D. Analogi Nyata:',
          'isi':
          'Bayangkan tumpukan piring bersih di meja prasmanan. Piring yang terakhir ditaruh di bagian paling atas adalah piring yang pertama kali diambil oleh tamu.',
        },
      ],
    },
    'penjelasan_en': {
      'sub_bab': [
        {
          'judul': 'A. Definition',
          'isi':
          'Stack is a linear data structure that operates under the LIFO (Last In, First Out) principle, meaning that the last item inserted is the first one to be removed. All insertions and removals occur solely through a single access point known as the Top.',
        },
        {
          'judul': 'B. Key Components and Operations:',
          'isi':
          '1. Top: Pointer indicating the current element positioned at the peak of the stack.\n'
              '2. Push: Operation to insert an element onto the top of the stack.\n'
              '3. Pop: Operation to remove and retrieve the top element from the stack.\n'
              '4. Peek / Top: Inspects the value of the top element without removing it.\n'
              '5. IsEmpty: Checks whether the stack is currently empty.\n'
              '6. IsFull: Checks whether the stack has reached maximum capacity.',
        },
        {
          'judul': 'C. Stack Boundary Conditions:',
          'isi':
          '1. Overflow: Error condition triggered when attempting to push new data onto an already full stack.\n'
              '2. Underflow: Error condition triggered when attempting to pop data from an empty stack.',
        },
        {
          'judul': 'D. Real-Life Analogy:',
          'isi':
          'Picture a stack of clean plates at a buffet. The last plate placed on top is the very first plate picked up by a guest.',
        },
      ],
    },
    'pretest': {
      'question': 'Prinsip kerja struktur data Stack adalah...',
      'options': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Random Access', 'Prioritas tertinggi'],
      'answer': 1
    },
    'pretest_en': {
      'question': 'The operating principle of a Stack data structure is...',
      'options': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Random Access', 'Highest Priority'],
      'answer': 1
    },
    'posttest': {
      'question': 'Operasi untuk melihat elemen teratas Stack tanpa menghapusnya disebut...',
      'options': ['Pop', 'Push', 'Peek', 'Shift'],
      'answer': 2
    },
    'posttest_en': {
      'question': 'The operation to view the topmost element of a Stack without removing it is called...',
      'options': ['Pop', 'Push', 'Peek', 'Shift'],
      'answer': 2
    },
  },

  // ==========================================
  // MODUL 3: QUEUE (ANTREAN)
  // ==========================================
  {
    'id': 'queue',
    'title': 'Modul 3: Queue (Antrean)',
    'title_en': 'Module 3: Queue',
    'desc': 'Struktur data antrean linear dengan mekanisme First In, First Out (FIFO).',
    'desc_en': 'Linear queue data structure operating on a First In, First Out (FIFO) basis.',
    'icon': Icons.sync_alt,
    'color': const Color(0xFF10B981),
    'videoTitle': 'Simulasi Antrean Real-Time Enqueue dan Dequeue',
    'videoTitle_en': 'Real-Time Queue Simulation: Enqueue and Dequeue',
    'videoDuration': '09:20',
    'penjelasan': {
      'sub_bab': [
        {
          'judul': 'A. Pengertian',
          'isi':
          'Queue adalah struktur data linier yang menggunakan prinsip FIFO (First In, First Out), artinya data yang pertama kali masuk akan menjadi data yang pertama kali diproses dan dikeluarkan.',
        },
        {
          'judul': 'B. Komponen dan Istilah Penting:',
          'isi':
          '1. Front atau Head: Ujung depan antrean tempat data diproses dan dikeluarkan.\n'
              '2. Rear atau Tail: Ujung belakang antrean tempat data baru disisipkan.\n'
              '3. Enqueue: Operasi memasukkan elemen baru ke bagian belakang antrean.\n'
              '4. Dequeue: Operasi mengeluarkan elemen dari bagian paling depan antrean.\n'
              '5. Peek: Melihat data yang berada di posisi paling depan tanpa mengeluarkannya.\n'
              '6. IsEmpty: Mengecek apakah antrean sedang kosong.',
        },
        {
          'judul': 'C. Simulasi Alur Kerja Antrean:',
          'isi':
          '1. Kondisi awal antrean kosong: [ ]\n'
              '2. Enqueue (A) menghasilkan antrean: [A]\n'
              '3. Enqueue (B) menghasilkan antrean: [A, B]\n'
              '4. Enqueue (C) menghasilkan antrean: [A, B, C]\n'
              '5. Dequeue () membuat data A keluar karena datang pertama kali. Antrean menjadi: [B, C]\n'
              '6. Enqueue (D) menghasilkan antrean: [B, C, D] di mana B dan C tetap diproses sebelum D.',
        },
        {
          'judul': 'D. Jenis-Jenis Queue:',
          'isi':
          '1. Linear Queue: Antrean biasa di mana elemen masuk dari belakang dan keluar dari depan.\n'
              '2. Circular Queue: Posisi terakhir tersambung kembali ke posisi awal membentuk lingkaran agar ruang memori yang kosong bekas dequeue dapat langsung digunakan kembali.\n'
              '3. Priority Queue: Setiap data memiliki bobot prioritas. Data dengan prioritas paling darurat akan diproses lebih dahulu meskipun baru saja tiba, mirip seperti pasien darurat di rumah sakit.',
        },
        {
          'judul': 'E. Analogi Nyata:',
          'isi':
          'Bayangkan antrean pembeli di kasir supermarket atau loket tiket bioskop. Orang yang datang paling awal akan dilayani dan keluar lebih dulu, sementara orang yang baru datang harus berdiri mengantre di barisan paling belakang.',
        },
      ],
    },
    'penjelasan_en': {
      'sub_bab': [
        {
          'judul': 'A. Definition',
          'isi':
          'A Queue is a linear data structure using the FIFO (First In, First Out) principle, meaning that the first item added will be the first item processed and removed.',
        },
        {
          'judul': 'B. Essential Components and Terminology:',
          'isi':
          '1. Front / Head: The front end of the queue where elements are dequeued.\n'
              '2. Rear / Tail: The rear end of the queue where new elements are enqueued.\n'
              '3. Enqueue: Operation to append a new element to the back of the queue.\n'
              '4. Dequeue: Operation to remove an element from the front of the queue.\n'
              '5. Peek: Views the front element without removing it.\n'
              '6. IsEmpty: Determines if the queue is empty.',
        },
        {
          'judul': 'C. Step-by-Step Simulation:',
          'isi':
          '1. Initial empty queue: [ ]\n'
              '2. Enqueue (A) -> Queue: [A]\n'
              '3. Enqueue (B) -> Queue: [A, B]\n'
              '4. Enqueue (C) -> Queue: [A, B, C]\n'
              '5. Dequeue () removes A because it arrived first. Queue: [B, C]\n'
              '6. Enqueue (D) -> Queue: [B, C, D] where B and C remain processed ahead of D.',
        },
        {
          'judul': 'D. Types of Queues:',
          'isi':
          '1. Linear Queue: Standard queue where elements enter at the rear and exit at the front.\n'
              '2. Circular Queue: The last position wraps around to the front, reusing memory vacated by previous dequeue operations.\n'
              '3. Priority Queue: Each item has a priority weighting. Items with critical priority are processed first regardless of arrival time, akin to emergency room triage.',
        },
        {
          'judul': 'E. Real-Life Analogy:',
          'isi':
          'Consider a queue at a supermarket checkout or cinema box office. The customer arriving first is served first, while later arrivals join at the back.',
        },
      ],
    },
    'pretest': {
      'question': 'Prinsip kerja struktur data Queue adalah...',
      'options': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Binary Traversal', 'Hashing'],
      'answer': 0
    },
    'pretest_en': {
      'question': 'The core principle of a Queue data structure is...',
      'options': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Binary Traversal', 'Hashing'],
      'answer': 0
    },
    'posttest': {
      'question': 'Operasi menghapus data terdepan pada antrean Queue dinamakan...',
      'options': ['Enqueue', 'Pop', 'Dequeue', 'Drop'],
      'answer': 2
    },
    'posttest_en': {
      'question': 'The operation that removes the leading element in a Queue is called...',
      'options': ['Enqueue', 'Pop', 'Dequeue', 'Drop'],
      'answer': 2
    },
  },

  // ==========================================
  // MODUL 4: SEARCHING DAN SORTING
  // ==========================================
  {
    'id': 'searching_sorting',
    'title': 'Modul 4: Searching & Sorting',
    'title_en': 'Module 4: Searching & Sorting',
    'desc': 'Teknik penemuan dan pengurutan data: Linear/Binary Search serta Bubble/Selection Sort.',
    'desc_en': 'Data search and ordering algorithms: Linear/Binary Search and Bubble/Selection Sort.',
    'icon': Icons.sort,
    'color': const Color(0xFFE11D48),
    'videoTitle': 'Perbandingan Algoritma Pencarian dan Pengurutan Data',
    'videoTitle_en': 'Comparison of Searching and Sorting Algorithms',
    'videoDuration': '11:10',
    'penjelasan': {
      'sub_bab': [
        {
          'judul': 'A. Pengertian',
          'isi':
          'Searching dan Sorting adalah dua proses algoritma mendasar yang saling melengkapi. Kumpulan data yang tersusun rapi lewat proses Sorting akan membuat pencarian data melalui teknik Searching berjalan jauh lebih cepat dan efisien.\n\n'
              '1. Searching (Pencarian Data)\n'
              'Searching adalah metode untuk menemukan posisi atau keberadaan nilai data tertentu di dalam kumpulan data.\n'
              '- Linear Search (Pencarian Berurutan):\n'
              'Cara kerja metode ini adalah memeriksa elemen satu per satu mulai dari awal sampai akhir hingga data ditemukan. Metode ini dapat digunakan pada data yang susunannya masih acak, tetapi membutuhkan waktu lebih lama jika jumlah datanya sangat banyak.\n\n'
              '- Binary Search (Pencarian Bagi Dua):\n'
              'Cara kerja metode ini adalah membagi ruang pencarian menjadi dua bagian secara berulang. Algoritma akan memeriksa nilai tengah dari data; jika target lebih kecil, pencarian fokus ke separuh kiri, dan jika lebih besar, pencarian pindah ke separuh kanan. Syarat mutlak metode ini adalah datanya wajib sudah terurut terlebih dahulu. Keunggulannya adalah proses pencarian menjadi sangat cepat pada data berukuran besar.\n\n'
              '2. Sorting (Pengurutan Data)\n'
              'Sorting adalah proses mengatur susunan data acak menjadi berurutan, baik secara Ascending (dari kecil ke besar atau A sampai Z) maupun Descending (dari besar ke kecil atau Z sampai A).\n'
              '- Bubble Sort:\n'
              'Cara kerjanya adalah membandingkan dua data yang posisinya bersebelahan. Jika urutannya salah, kedua data langsung ditukar. Langkah ini diulangi terus-menerus hingga seluruh data berada di posisi yang benar, mirip seperti gelembung udara yang perlahan naik ke permukaan air.\n\n'
              '- Selection Sort:\n'
              'Cara kerjanya adalah mencari nilai paling kecil atau paling besar dari bagian data yang belum terurut, kemudian langsung memindahkannya ke posisi awal target secara bertahap.',
        },
        {
          'judul': 'B. Contoh Penerapan Nyata:',
          'isi':
          '- Pencarian Produk: Menemukan barang tertentu berdasarkan kata kunci nama di aplikasi belanja online.\n'
              '- Filter Urutan: Menampilkan produk dari harga termurah ke termahal pada toko online.\n'
              '- Daftar Nilai: Guru mengurutkan skor ujian siswa dari nilai tertinggi ke terendah untuk menentukan peringkat kelas.',
        },
      ],
    },
    'penjelasan_en': {
      'sub_bab': [
        {
          'judul': 'A. Definition',
          'isi':
          'Searching and Sorting are two foundational, complementary algorithmic processes. Data organized via Sorting makes retrieval through Searching substantially faster and more efficient.\n\n'
              '1. Searching\n'
              'Searching is the technique of locating the presence or index of a specific value within a dataset.\n'
              '- Linear Search:\n'
              'Sequentially checks elements one by one from start to end until a match is found. Works on unsorted collections, but scales slowly on large datasets.\n\n'
              '- Binary Search:\n'
              'Repeatedly divides the search range in half. It inspects the middle value; if the target is smaller, search shifts to the left half, and if larger, to the right half. Strictly requires data to be sorted beforehand. Offers high performance on large datasets.\n\n'
              '2. Sorting\n'
              'Sorting arranges unstructured data in an ordered sequence, either Ascending (lowest to highest / A-Z) or Descending (highest to lowest / Z-A).\n'
              '- Bubble Sort:\n'
              'Compares adjacent items and swaps them if out of order. Repeats iteratively until the entire collection is sorted, similar to bubbles rising to the surface.\n\n'
              '- Selection Sort:\n'
              'Repeatedly selects the smallest (or largest) remaining element and places it into its final position stage by stage.',
        },
        {
          'judul': 'B. Real-World Applications:',
          'isi':
          '- Product Search: Locating products by name keywords in e-commerce apps.\n'
              '- Sorting Filters: Ordering products from lowest to highest price.\n'
              '- Grade Books: Teachers ranking student exam scores from highest to lowest.',
        },
      ],
    },
    'pretest': {
      'question': 'Syarat utama agar algoritma Binary Search dapat dijalankan adalah...',
      'options': ['Data harus bertipe string', 'Data harus sudah terurut', 'Data harus berjumlah ganjil', 'Memori harus kosong'],
      'answer': 1
    },
    'pretest_en': {
      'question': 'The prerequisite for running the Binary Search algorithm is...',
      'options': ['Data must be of string type', 'Data must already be sorted', 'Data count must be odd', 'Memory must be empty'],
      'answer': 1
    },
    'posttest': {
      'question': 'Algoritma sorting yang menyeleksi elemen terkecil lalu menaruhnya ke posisi yang tepat adalah...',
      'options': ['Bubble Sort', 'Linear Search', 'Selection Sort', 'Binary Search'],
      'answer': 2
    },
    'posttest_en': {
      'question': 'The sorting algorithm that selects the minimum element and places it into the target position is...',
      'options': ['Bubble Sort', 'Linear Search', 'Selection Sort', 'Binary Search'],
      'answer': 2
    },
  },
];