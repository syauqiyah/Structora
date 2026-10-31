import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherContentHelper {
  // Key v10 agar data Pre-Test, Post-Test, & Modul default dwibahasa terpasang penuh
  static const String _materiKey = 'custom_teacher_materi_v10';

  static List get _defaultMateriList => [
    // EVALUASI 1: PRE-TEST
    {
      'id': 'pretest',
      'modul': 'Evaluasi Awal',
      'modul_en': 'Initial Evaluation',
      'title': 'Pre-Test: Uji Kemampuan Awal',
      'title_en': 'Pre-Test: Initial Skill Assessment',
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
      'questions': [
        {
          'q': 'Struktur data linier yang bersifat dinamis dan menggunakan simpul (node) serta pointer adalah...',
          'q_en': 'A dynamic linear data structure that uses nodes and pointers is...',
          'options': ['Array Statis', 'Linked List', 'Binary Tree', 'Graph'],
          'options_en': ['Static Array', 'Linked List', 'Binary Tree', 'Graph'],
          'answerIndex': 1,
          'explanation': 'Linked List tersusun dari kumpulan node dinamis yang terhubung via pointer.',
          'explanation_en': 'Linked List consists of dynamic nodes interconnected via pointers.',
        },
        {
          'q': 'Prinsip LIFO (Last In First Out) digunakan pada struktur data...',
          'q_en': 'The LIFO (Last In First Out) principle is used in the data structure...',
          'options': ['Queue', 'Stack', 'Array', 'Linked List'],
          'options_en': ['Queue', 'Stack', 'Array', 'Linked List'],
          'answerIndex': 1,
          'explanation': 'Stack bekerja dengan aturan LIFO: elemen terakhir masuk akan keluar pertama.',
          'explanation_en': 'Stack operates under LIFO: the last item pushed is the first popped.',
        },
        {
          'q': 'Operasi penambahan elemen baru ke dalam antrean (Queue) dinamakan...',
          'q_en': 'The operation of adding a new element to a Queue is called...',
          'options': ['Dequeue', 'Enqueue', 'Push', 'Pop'],
          'options_en': ['Dequeue', 'Enqueue', 'Push', 'Pop'],
          'answerIndex': 1,
          'explanation': 'Enqueue menambahkan elemen baru ke bagian belakang antrean.',
          'explanation_en': 'Enqueue appends a new element to the rear of the queue.',
        },
        {
          'q': 'Metode pencarian data yang mengharuskan kumpulan data sudah terurut rapi adalah...',
          'q_en': 'A search method that requires the dataset to be neatly sorted beforehand is...',
          'options': ['Linear Search', 'Binary Search', 'Random Search', 'Sequential Search'],
          'options_en': ['Linear Search', 'Binary Search', 'Random Search', 'Sequential Search'],
          'answerIndex': 1,
          'explanation': 'Binary Search memerlukan data yang sudah terurut untuk membagi ruang pencarian.',
          'explanation_en': 'Binary Search relies on pre-sorted data to split search boundaries.',
        },
        {
          'q': 'Simpul pertama pada Linked List yang menjadi pintu masuk penelusuran disebut...',
          'q_en': 'The first node in a Linked List that serves as the entry point for traversal is called...',
          'options': ['Head', 'Tail', 'Root', 'Top'],
          'options_en': ['Head', 'Tail', 'Root', 'Top'],
          'answerIndex': 0,
          'explanation': 'Head adalah pointer penunjuk simpul paling awal dalam linked list.',
          'explanation_en': 'Head is the gateway pointer referencing the initial node.',
        },
        {
          'q': 'Operasi untuk mengambil atau menghapus elemen teratas dari struktur data Stack adalah...',
          'q_en': 'The operation to retrieve or remove the topmost element from a Stack data structure is...',
          'options': ['Push', 'Pop', 'Peek', 'Enqueue'],
          'options_en': ['Push', 'Pop', 'Peek', 'Enqueue'],
          'answerIndex': 1,
          'explanation': 'Pop mengambil sekaligus menghapus elemen puncak dari tumpukan.',
          'explanation_en': 'Pop removes and returns the top element from the stack.',
        },
        {
          'q': 'Penunjuk yang mengarah ke elemen paling depan pada antrean Queue disebut...',
          'q_en': 'The pointer that points to the frontmost element in a Queue is called...',
          'options': ['Rear', 'Front', 'Top', 'Bottom'],
          'options_en': ['Rear', 'Front', 'Top', 'Bottom'],
          'answerIndex': 1,
          'explanation': 'Front menunjukkan posisi paling depan antrean untuk diproses.',
          'explanation_en': 'Front points to the leading item ready to be processed.',
        },
        {
          'q': 'Algoritma pengurutan data yang berulang kali menukar dua elemen bersebelahan yang tidak urut adalah...',
          'q_en': 'A sorting algorithm that repeatedly swaps two adjacent elements that are out of order is...',
          'options': ['Bubble Sort', 'Binary Search', 'Linear Search', 'Merge Sort'],
          'options_en': ['Bubble Sort', 'Binary Search', 'Linear Search', 'Merge Sort'],
          'answerIndex': 0,
          'explanation': 'Bubble Sort membandingkan dan menukar pasangan elemen bersebelahan.',
          'explanation_en': 'Bubble Sort compares and swaps adjacent unordered pairs.',
        },
        {
          'q': 'Kondisi saat mencoba memasukkan elemen ke dalam Stack yang sudah penuh memori disebut...',
          'q_en': 'The condition when attempting to push an element into a Stack that is full is called...',
          'options': ['Stack Underflow', 'Stack Overflow', 'Deadlock', 'Memory Leak'],
          'options_en': ['Stack Underflow', 'Stack Overflow', 'Deadlock', 'Memory Leak'],
          'answerIndex': 1,
          'explanation': 'Stack Overflow terjadi ketika tumpukan melampaui kapasitas memori.',
          'explanation_en': 'Stack Overflow occurs when pushing exceeds stack capacity limit.',
        },
        {
          'q': 'Kompleksitas waktu terbaik (Best Case) dari Binary Search jika data langsung ditemukan di tengah adalah...',
          'q_en': 'The best-case time complexity of Binary Search when data is immediately found in the middle is...',
          'options': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'answerIndex': 0,
          'explanation': 'Jika target tepat berada di posisi tengah pertama, kompleksitasnya O(1).',
          'explanation_en': 'If target matches the initial midpoint, complexity is O(1).',
        },
      ],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 1: LINKED LIST
    {
      'id': 'linkedlist',
      'modul': 'Pertemuan 1',
      'modul_en': 'Meeting 1',
      'title': 'Modul 1: Linked List',
      'title_en': 'Module 1: Linked List',
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
2. Insertion: Menyisipkan node baru. Contohnya jika ada untaian 10 -> 20 -> 30, untuk menyisipkan angka 15 di antara 10 dan 20, kita cukup mengalihkan pointer dari node 10 ke 15, lalu pointer 15 disambungkan ke 20 sehingga susunannya menjadi 10 -> 15 -> 20 -> 30.
3. Deletion: Menghapus node tertentu dengan cara menyambungkan pointer node sebelumnya langsung ke node sesudahnya.
4. Searching: Mencari keberadaan nilai data tertentu di dalam untaian node.

E. Analogi Nyata:
Bayangkan rangkaian gerbong kereta api atau permainan berburu harta karun. Setiap lokasi menyimpan petunjuk yang mengarahkanmu ke lokasi berikutnya hingga akhirnya sampai di tujuan akhir.''',
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
      'questions': [
        {
          'q': 'Bagian simpul yang menyimpan alamat memori simpul berikutnya disebut...',
          'q_en': 'The node component that stores the memory address of the next node is called...',
          'options': ['Data/Value', 'Pointer / Next', 'Head', 'Tail'],
          'options_en': ['Data/Value', 'Pointer / Next', 'Head', 'Tail'],
          'answerIndex': 1,
        },
        {
          'q': 'Pointer penunjuk simpul paling pertama dalam linked list disebut...',
          'q_en': 'The pointer pointing to the very first node in a linked list is called...',
          'options': ['Head', 'Root', 'Top', 'Front'],
          'options_en': ['Head', 'Root', 'Top', 'Front'],
          'answerIndex': 0,
        },
        {
          'q': 'Nilai penunjuk pada simpul paling akhir dari single linked list adalah...',
          'q_en': 'The pointer value of the last node in a single linked list is...',
          'options': ['0', 'Undefined', 'NULL', 'Head'],
          'options_en': ['0', 'Undefined', 'NULL', 'Head'],
          'answerIndex': 2,
        },
        {
          'q': 'Keunggulan linked list dibandingkan array statis adalah...',
          'q_en': 'The advantage of a linked list compared to a static array is...',
          'options': ['Ukuran memori dinamis', 'Akses langsung via indeks O(1)', 'Tidak perlu pointer', 'Pasti lebih hemat'],
          'options_en': ['Dynamic memory size', 'Direct index access O(1)', 'No pointer needed', 'Guaranteed memory savings'],
          'answerIndex': 0,
        },
        {
          'q': 'Operasi penelusuran dari awal simpul ke simpul akhir disebut...',
          'q_en': 'The operation of traversing from the first node to the last node is called...',
          'options': ['Traversal', 'Searching', 'Sorting', 'Pop'],
          'options_en': ['Traversal', 'Searching', 'Sorting', 'Pop'],
          'answerIndex': 0,
        },
        {
          'q': 'Pada Doubly Linked List, setiap node memiliki pointer penunjuk yaitu...',
          'q_en': 'In a Doubly Linked List, each node contains pointer references namely...',
          'options': ['Next dan Prev', 'Left dan Right', 'Parent dan Child', 'Head dan Tail'],
          'options_en': ['Next and Prev', 'Left and Right', 'Parent and Child', 'Head and Tail'],
          'answerIndex': 0,
        },
        {
          'q': 'Ciri khas utama dari Circular Linked List adalah...',
          'q_en': 'The primary characteristic of a Circular Linked List is...',
          'options': ['Node terakhir menunjuk kembali ke Head', 'Ukuran node terbatas', 'Tidak ada data value', 'Hanya bisa mundur'],
          'options_en': ['The last node points back to Head', 'Limited node capacity', 'No data value', 'Can only move backwards'],
          'answerIndex': 0,
        },
        {
          'q': 'Kompleksitas waktu untuk menambahkan node baru di posisi paling awal (Head) adalah...',
          'q_en': 'The time complexity to insert a new node at the Head position is...',
          'options': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'answerIndex': 0,
        },
        {
          'q': 'Untuk menghapus node di tengah linked list, pointer yang diubah adalah...',
          'q_en': 'To delete a node in the middle of a linked list, the pointer changed is...',
          'options': ['Pointer node sebelumnya diarahkan ke node sesudahnya', 'Pointer Head ke NULL', 'Pointer Tail ke Head', 'Tidak perlu ubah pointer'],
          'options_en': ['Pointer of preceding node is directed to subsequent node', 'Pointer Head to NULL', 'Pointer Tail to Head', 'No pointer change needed'],
          'answerIndex': 0,
        },
        {
          'q': 'Kelemahan alokasi memori pada linked list dibandingkan array biasa adalah...',
          'q_en': 'The memory allocation drawback of a linked list compared to a standard array is...',
          'options': ['Memerlukan ruang ekstra untuk menyimpan pointer', 'Tidak bisa menampung data besar', 'Data mudah corrupt', 'Tidak ada Head'],
          'options_en': ['Requires extra memory space to store pointers', 'Cannot hold large datasets', 'Data easily corrupts', 'No Head pointer'],
          'answerIndex': 0,
        },
      ],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 2: STACK
    {
      'id': 'stack',
      'modul': 'Pertemuan 2',
      'modul_en': 'Meeting 2',
      'title': 'Modul 2: Stack (Tumpukan Data)',
      'title_en': 'Module 2: Stack',
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

D. Operasi Tambahan:
1. Size: Menghitung total banyaknya elemen yang berada di dalam tumpukan saat ini.
2. Clear: Mengosongkan seluruh isi tumpukan seketika.

E. Analogi Nyata:
Bayangkan tumpukan piring di meja makan prasmanan atau tumpukan buku di dalam kardus sempit. Piring yang paling terakhir ditaruh di atas adalah piring yang pertama kali akan diambil oleh orang berikutnya.''',
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
      'questions': [
        {
          'q': 'Prinsip utama yang diterapkan pada struktur data Stack adalah...',
          'q_en': 'The core principle applied to the Stack data structure is...',
          'options': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Random Access', 'Priority Ordering'],
          'options_en': ['FIFO (First In First Out)', 'LIFO (Last In First Out)', 'Random Access', 'Priority Ordering'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi untuk memasukkan data baru ke posisi teratas stack dinamakan...',
          'q_en': 'The operation to insert new data into the top position of a stack is called...',
          'options': ['Pop', 'Push', 'Peek', 'Enqueue'],
          'options_en': ['Pop', 'Push', 'Peek', 'Enqueue'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi untuk mengambil atau menghapus data teratas stack dinamakan...',
          'q_en': 'The operation to retrieve or remove top data from a stack is called...',
          'options': ['Pop', 'Push', 'Dequeue', 'Clear'],
          'options_en': ['Pop', 'Push', 'Dequeue', 'Clear'],
          'answerIndex': 0,
        },
        {
          'q': 'Melihat isi elemen teratas stack tanpa menghapusnya dari memori disebut...',
          'q_en': 'Inspecting top element content in stack without deleting it from memory is called...',
          'options': ['Peek / Top', 'Search', 'Pop', 'Inspect'],
          'options_en': ['Peek / Top', 'Search', 'Pop', 'Inspect'],
          'answerIndex': 0,
        },
        {
          'q': 'Kondisi kegagalan yang terjadi saat melakukan Push pada stack yang sudah penuh adalah...',
          'q_en': 'The failure state occurring when attempting Push on a full stack is...',
          'options': ['Stack Underflow', 'Stack Overflow', 'Memory Leak', 'Null Pointer Exception'],
          'options_en': ['Stack Underflow', 'Stack Overflow', 'Memory Leak', 'Null Pointer Exception'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi Pop pada stack yang tidak memiliki elemen sama sekali menghasilkan kondisi...',
          'q_en': 'A Pop operation on a stack containing zero elements results in condition...',
          'options': ['Stack Underflow', 'Stack Overflow', 'Deadlock', 'Memory Leak'],
          'options_en': ['Stack Underflow', 'Stack Overflow', 'Deadlock', 'Memory Leak'],
          'answerIndex': 0,
        },
        {
          'q': 'Fungsi tombol Undo pada aplikasi text editor bekerja berdasarkan struktur data...',
          'q_en': 'The Undo button function in text editor applications operates based on data structure...',
          'options': ['Stack', 'Queue', 'Graph', 'Tree'],
          'options_en': ['Stack', 'Queue', 'Graph', 'Tree'],
          'answerIndex': 0,
        },
        {
          'q': 'Operasi Push dan Pop pada Stack memiliki kompleksitas waktu...',
          'q_en': 'Push and Pop operations on Stack have time complexity of...',
          'options': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'answerIndex': 0,
        },
        {
          'q': 'Pointer penunjuk elemen teratas pada stack umumnya dinamakan...',
          'q_en': 'The pointer referencing top element on stack is commonly named...',
          'options': ['Top', 'Front', 'Rear', 'Root'],
          'options_en': ['Top', 'Front', 'Rear', 'Root'],
          'answerIndex': 0,
        },
        {
          'q': 'Konversi notasi infix ke postfix memanfaatkan struktur data...',
          'q_en': 'Converting infix to postfix notation utilizes data structure...',
          'options': ['Stack', 'Queue', 'Array 2D', 'Linked List melingkar'],
          'options_en': ['Stack', 'Queue', '2D Array', 'Circular Linked List'],
          'answerIndex': 0,
        },
      ],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 3: QUEUE
    {
      'id': 'queue',
      'modul': 'Pertemuan 3',
      'modul_en': 'Meeting 3',
      'title': 'Modul 3: Queue (Antrean Terurut)',
      'title_en': 'Module 3: Queue',
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

D. Karakteristik Operasi:
1. IsFull: Memeriksa apakah antrean telah mencapai kapasitas maksimal.
2. IsEmpty: Memeriksa apakah antrean dalam keadaan kosong sebelum Dequeue.

E. Analogi Nyata:
Bayangkan barisan antrean pembeli karcis bioskop atau antrean kasir supermarket. Orang yang datang pertama kali akan dilayani terlebih dahulu dan meninggalkan antrean paling awal.''',
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
      'questions': [
        {
          'q': 'Prinsip di mana elemen yang pertama masuk akan pertama kali keluar disebut...',
          'q_en': 'The principle where earliest inserted element is dequeued first is called...',
          'options': ['LIFO', 'FIFO', 'Greedy', 'Divide & Conquer'],
          'options_en': ['LIFO', 'FIFO', 'Greedy', 'Divide & Conquer'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi penambahan elemen baru ke dalam antrean Queue dinamakan...',
          'q_en': 'The operation of adding a new element to a Queue is called...',
          'options': ['Enqueue', 'Dequeue', 'Push', 'Append'],
          'options_en': ['Enqueue', 'Dequeue', 'Push', 'Append'],
          'answerIndex': 0,
        },
        {
          'q': 'Operasi mengeluarkan elemen terdepan dari Queue dinamakan...',
          'q_en': 'The operation of removing the front element from a Queue is called...',
          'options': ['Enqueue', 'Dequeue', 'Pop', 'Delete'],
          'options_en': ['Enqueue', 'Dequeue', 'Pop', 'Delete'],
          'answerIndex': 1,
        },
        {
          'q': 'Penunjuk yang mengarah ke simpul paling belakang dari antrean adalah...',
          'q_en': 'The pointer referencing the rearmost node of a queue is...',
          'options': ['Front', 'Rear / Tail', 'Head', 'Top'],
          'options_en': ['Front', 'Rear / Tail', 'Head', 'Top'],
          'answerIndex': 1,
        },
        {
          'q': 'Kondisi error saat melakukan Dequeue pada Queue yang kosong adalah...',
          'q_en': 'The error state when attempting Dequeue on an empty Queue is...',
          'options': ['Underflow', 'Overflow', 'Deadlock', 'Out of Memory'],
          'options_en': ['Underflow', 'Overflow', 'Deadlock', 'Out of Memory'],
          'answerIndex': 0,
        },
        {
          'q': 'Penunjuk yang mengarah ke elemen paling depan antrean untuk diproses adalah...',
          'q_en': 'The pointer pointing to frontmost element for processing in queue is...',
          'options': ['Front', 'Rear', 'Top', 'Bottom'],
          'options_en': ['Front', 'Rear', 'Top', 'Bottom'],
          'answerIndex': 0,
        },
        {
          'q': 'Sistem antrean printer komputer (Print Spooling) menerapkan struktur data...',
          'q_en': 'Computer printer spooling queue system implements data structure...',
          'options': ['Queue', 'Stack', 'Tree', 'Graph'],
          'options_en': ['Queue', 'Stack', 'Tree', 'Graph'],
          'answerIndex': 0,
        },
        {
          'q': 'Pada Circular Queue, jika Rear mencapai batas indeks maksimum maka posisi berikutnya diarahkan ke...',
          'q_en': 'In a Circular Queue, when Rear hits max index capacity, next position wraps to...',
          'options': ['Indeks 0 (jika masih kosong)', 'NULL', 'Ditolak error', 'Indeks terakhir'],
          'options_en': ['Index 0 (if available)', 'NULL', 'Rejected with error', 'Last index'],
          'answerIndex': 0,
        },
        {
          'q': 'Operasi Enqueue dan Dequeue pada implementasi Queue efisien memiliki kompleksitas...',
          'q_en': 'Enqueue and Dequeue operations on efficient Queue implementation have complexity...',
          'options': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'answerIndex': 0,
        },
        {
          'q': 'Struktur antrean di mana elemen dengan prioritas tertinggi dilayani lebih dahulu disebut...',
          'q_en': 'A queue structure where highest priority element is serviced first is called...',
          'options': ['Priority Queue', 'Double Ended Queue', 'Circular Queue', 'Linear Queue'],
          'options_en': ['Priority Queue', 'Double Ended Queue', 'Circular Queue', 'Linear Queue'],
          'answerIndex': 0,
        },
      ],
      'createdAt': '30/10/2026',
    },

    // PERTEMUAN 4: SEARCHING & SORTING
    {
      'id': 'searching_sorting',
      'modul': 'Pertemuan 4',
      'modul_en': 'Meeting 4',
      'title': 'Modul 4: Searching & Sorting Algorithm',
      'title_en': 'Module 4: Searching & Sorting Algorithm',
      'desc':
      '''A. Algoritma Pencarian (Searching):
1. Linear Search: Memeriksa elemen array satu per satu secara berurutan dari awal hingga akhir. Cocok untuk data acak maupun data yang belum terurut.
2. Binary Search: Mencari data dengan cara membagi ruang pencarian menjadi dua secara berulang. Syarat mutlaknya adalah data harus dalam kondisi terurut (sorted).

B. Algoritma Pengurutan (Sorting):
1. Bubble Sort: Mengurutkan data dengan membandingkan pasangan elemen yang bersebelahan dan menukarnya jika urutannya salah secara berulang.
2. Selection Sort: Mengurutkan data dengan mencari nilai terkecil/terbesar dari daftar elemen yang belum terurut, kemudian menukarnya ke posisi target yang tepat.

C. Karakteristik Kompleksitas:
1. Linear Search memiliki kompleksitas waktu O(n).
2. Binary Search memiliki kompleksitas waktu terbaik O(1) dan rata-rata O(log n).
3. Bubble Sort dan Selection Sort memiliki kompleksitas rata-rata O(n^2).''',
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
      'questions': [
        {
          'q': 'Syarat utama agar algoritma Binary Search dapat dijalankan adalah...',
          'q_en': 'The primary prerequisite for executing Binary Search algorithm is...',
          'options': ['Data harus berukuran genap', 'Data harus sudah dalam keadaan terurut', 'Data harus berupa angka numerik saja', 'Data harus tersimpan di struktur Stack'],
          'options_en': ['Data must be even-sized', 'Data must already be sorted', 'Data must consist solely of numbers', 'Data must reside inside a Stack'],
          'answerIndex': 1,
        },
        {
          'q': 'Kompleksitas waktu terbaik (Best Case) dari algoritma Binary Search adalah...',
          'q_en': 'Best-case time complexity of Binary Search algorithm is...',
          'options': ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
          'answerIndex': 0,
        },
        {
          'q': 'Algoritma yang berulang kali menukar dua elemen bersebelahan yang tidak urut adalah...',
          'q_en': 'The algorithm repeatedly swapping two adjacent out-of-order elements is...',
          'options': ['Bubble Sort', 'Binary Search', 'Linear Search', 'Merge Sort'],
          'options_en': ['Bubble Sort', 'Binary Search', 'Linear Search', 'Merge Sort'],
          'answerIndex': 0,
        },
        {
          'q': 'Metode pencarian yang memeriksa setiap elemen array satu per satu dari awal adalah...',
          'q_en': 'The search method inspecting every array element sequentially from start is...',
          'options': ['Binary Search', 'Linear Search', 'Tree Search', 'Interpolation Search'],
          'options_en': ['Binary Search', 'Linear Search', 'Tree Search', 'Interpolation Search'],
          'answerIndex': 1,
        },
        {
          'q': 'Selection Sort bekerja dengan mekanisme utama yaitu...',
          'q_en': 'Selection Sort operates via main mechanism of...',
          'options': ['Mencari nilai ekstrem (minimum/maksimum) lalu menukarnya ke posisi tujuan', 'Membagi array menjadi dua bagian sama besar', 'Memasukkan elemen ke tumpukan memori LIFO', 'Menghapus simpul pertama secara berurutan'],
          'options_en': ['Find extreme (min/max) value and swap to target slot', 'Split array into two equal halves', 'Push element into LIFO stack memory', 'Sequentially delete first node'],
          'answerIndex': 0,
        },
        {
          'q': 'Kompleksitas waktu rata-rata (Average Case) dari Binary Search adalah...',
          'q_en': 'Average-case time complexity of Binary Search is...',
          'options': ['O(log n)', 'O(n)', 'O(n^2)', 'O(1)'],
          'options_en': ['O(log n)', 'O(n)', 'O(n^2)', 'O(1)'],
          'answerIndex': 0,
        },
        {
          'q': 'Jika data terdiri dari 1000 data acak dan tidak terurut, metode pencarian yang tepat adalah...',
          'q_en': 'Given 1000 unsorted random elements, appropriate search method is...',
          'options': ['Linear Search', 'Binary Search', 'Jump Search terurut', 'Interpolation'],
          'options_en': ['Linear Search', 'Binary Search', 'Sorted Jump Search', 'Interpolation'],
          'answerIndex': 0,
        },
        {
          'q': 'Kompleksitas waktu terburuk (Worst Case) algoritma Bubble Sort adalah...',
          'q_en': 'Worst-case time complexity of Bubble Sort algorithm is...',
          'options': ['O(n^2)', 'O(n)', 'O(log n)', 'O(1)'],
          'options_en': ['O(n^2)', 'O(n)', 'O(log n)', 'O(n^2)'],
          'answerIndex': 0,
        },
        {
          'q': 'Algoritma pengurutan yang membagi larik menjadi two bagian kemudian menggabungkannya secara terurut adalah...',
          'q_en': 'The sorting algorithm splitting array in two and merging sorted halves is...',
          'options': ['Merge Sort', 'Bubble Sort', 'Selection Sort', 'Linear Sort'],
          'options_en': ['Merge Sort', 'Bubble Sort', 'Selection Sort', 'Linear Sort'],
          'answerIndex': 0,
        },
        {
          'q': 'Pada algoritma Linear Search, kasus terburuk (Worst Case) terjadi ketika...',
          'q_en': 'In Linear Search algorithm, worst-case scenario occurs when...',
          'options': ['Elemen yang dicari berada di paling akhir atau tidak ditemukan', 'Elemen dicari berada di awal', 'Data sudah terurut', 'Array kosong'],
          'options_en': ['Searched element is at the end or not found', 'Searched element is at start', 'Data is already sorted', 'Array is empty'],
          'answerIndex': 0,
        },
      ],
      'createdAt': '30/10/2026',
    },

    // EVALUASI 2: POST-TEST
    {
      'id': 'posttest',
      'modul': 'Evaluasi Akhir',
      'modul_en': 'Final Evaluation',
      'title': 'Post-Test: Evaluasi Akhir Kelulusan',
      'title_en': 'Post-Test: Final Graduation Evaluation',
      'desc':
      '''Petunjuk Ujian Post-Test:
Post-Test merupakan evaluasi komprehensif akhir untuk seluruh modul pembelajaran struktur data (Linked List, Stack, Queue, Searching & Sorting).

Ketentuan Kelulusan:
1. Standar KKM adalah nilai 80.
2. Siswa yang lulus akan membuka sertifikasi ketuntasan belajar. Siswa yang belum mencapai nilai 80 dapat mengulang ujian remedial.''',
      'desc_en':
      '''Post-Test Exam Instructions:
Post-Test is the final comprehensive evaluation covering all data structure learning modules (Linked List, Stack, Queue, Searching & Sorting).

Graduation Requirements:
1. Passing standard is score 80.
2. Students who pass will earn competency certification. Students scoring below 80 may retake the remedial exam.''',
      'videoUrl': '',
      'questions': [
        {
          'q': 'Pada Single Linked List, simpul terakhir selalu memiliki pointer penunjuk yang mengarah ke...',
          'q_en': 'In Single Linked List, last node always has pointer directing to...',
          'options': ['0', 'NULL', 'Head', 'Undefined'],
          'options_en': ['0', 'NULL', 'Head', 'Undefined'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi penambahan elemen ke posisi teratas pada struktur data Stack dinamakan...',
          'q_en': 'The operation adding element to peak position on Stack is called...',
          'options': ['Enqueue', 'Push', 'Pop', 'Peek'],
          'options_en': ['Enqueue', 'Push', 'Pop', 'Peek'],
          'answerIndex': 1,
        },
        {
          'q': 'Struktur data antrean yang memproses data yang pertama kali datang dinamakan prinsip...',
          'q_en': 'Queue data structure processing earliest arrived data operates on principle...',
          'options': ['LIFO', 'FIFO', 'Random', 'Priority'],
          'options_en': ['LIFO', 'FIFO', 'Random', 'Priority'],
          'answerIndex': 1,
        },
        {
          'q': 'Operasi pengeluaran elemen dari antrean (Queue) dinamakan...',
          'q_en': 'The operation evicting element from Queue is called...',
          'options': ['Dequeue', 'Enqueue', 'Pop', 'Delete'],
          'options_en': ['Dequeue', 'Enqueue', 'Pop', 'Delete'],
          'answerIndex': 0,
        },
        {
          'q': 'Jika array sudah berurutan dari kecil ke besar, algoritma pencarian yang paling efisien adalah...',
          'q_en': 'If array is already sorted ascending, the most efficient search algorithm is...',
          'options': ['Linear Search', 'Binary Search', 'Bubble Sort', 'Selection Sort'],
          'options_en': ['Linear Search', 'Binary Search', 'Bubble Sort', 'Selection Sort'],
          'answerIndex': 1,
        },
        {
          'q': 'Pada Doubly Linked List, setiap simpul dilengkapi dengan dua pointer yaitu...',
          'q_en': 'In Doubly Linked List, each node features two pointers namely...',
          'options': ['Next dan Prev', 'Left dan Right', 'Parent dan Child', 'Head dan Tail'],
          'options_en': ['Next and Prev', 'Left and Right', 'Parent and Child', 'Head and Tail'],
          'answerIndex': 0,
        },
        {
          'q': 'Mekanisme tombol Undo/Redo pada aplikasi pengolah kata menerapkan struktur data...',
          'q_en': 'Undo/Redo button mechanism in word processor applies data structure...',
          'options': ['Stack', 'Queue', 'Array', 'Linked List'],
          'options_en': ['Stack', 'Queue', 'Array', 'Linked List'],
          'answerIndex': 0,
        },
        {
          'q': 'Antrean tugas pencetakan printer (print spooler) menerapkan prinsip struktur data...',
          'q_en': 'Printer print spooler task queue applies data structure principle...',
          'options': ['Queue', 'Stack', 'Binary Tree', 'Graph'],
          'options_en': ['Queue', 'Stack', 'Binary Tree', 'Graph'],
          'answerIndex': 0,
        },
        {
          'q': 'Algoritma yang berulang kali mencari nilai terkecil dari elemen yang belum terurut lalu menukarnya adalah...',
          'q_en': 'Algorithm repeatedly isolating minimum value from unsorted slice and swapping it is...',
          'options': ['Bubble Sort', 'Selection Sort', 'Linear Search', 'Binary Search'],
          'options_en': ['Bubble Sort', 'Selection Sort', 'Linear Search', 'Binary Search'],
          'answerIndex': 1,
        },
        {
          'q': 'Kompleksitas waktu rata-rata (Average Case) dari algoritma pencarian Binary Search adalah...',
          'q_en': 'Average-case time complexity of Binary Search lookup algorithm is...',
          'options': ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
          'options_en': ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
          'answerIndex': 1,
        },
      ],
      'createdAt': '30/10/2026',
    },
  ];

  static Future<List<dynamic>> getMateriList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_materiKey);
    if (rawJson == null || rawJson.isEmpty) {
      await prefs.setString(_materiKey, jsonEncode(_defaultMateriList));
      return _defaultMateriList;
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded;
      }
      return _defaultMateriList;
    } catch (_) {
      return _defaultMateriList;
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
    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();

    final newMateri = {
      'id': 'mat_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'title_en': titleEn ?? title,
      'modul': modul,
      'modul_en': modulEn ?? modul,
      'desc': desc,
      'desc_en': descEn ?? desc,
      'videoUrl': videoUrl,
      'questions': questions,
      'createdAt':
      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    };

    list.add(newMateri);
    await prefs.setString(_materiKey, jsonEncode(list));
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
    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();

    final int index = list.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      list[index]['title'] = title;
      if (titleEn != null) list[index]['title_en'] = titleEn;
      list[index]['modul'] = modul;
      if (modulEn != null) list[index]['modul_en'] = modulEn;
      list[index]['desc'] = desc;
      if (descEn != null) list[index]['desc_en'] = descEn;
      list[index]['videoUrl'] = videoUrl;
      list[index]['questions'] = questions;
      await prefs.setString(_materiKey, jsonEncode(list));
    }
  }

  static Future<void> deleteMateri(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getMateriList();
    list.removeWhere((item) => item['id'] == id);
    await prefs.setString(_materiKey, jsonEncode(list));
  }

  static Future<List<dynamic>?> getQuestionsForModule(String moduleId) async {
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
}