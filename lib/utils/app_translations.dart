import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static final LanguageController instance = LanguageController._internal();
  factory LanguageController() => instance;
  LanguageController._internal();

  Locale _currentLocale = const Locale('id');
  Locale get currentLocale => _currentLocale;
  bool get isEnglish => _currentLocale.languageCode == 'en';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'id';
    _currentLocale = Locale(langCode);
    notifyListeners();
  }

  Future<void> switchLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (isEnglish) {
      await switchLanguage('id');
    } else {
      await switchLanguage('en');
    }
  }
}

class AppText {
  static final LanguageController _ctrl = LanguageController.instance;

  static const Map<String, Map<String, String>> _localizedValues = {
    'id': {
      // Navigasi & Header Siswa
      'nav_home': 'Beranda',
      'nav_materi': 'Materi',
      'nav_lab': 'Simulasi Lab',
      'nav_eval': 'Evaluasi',
      'back_to_list': 'Kembali ke Daftar Materi',

      // Tab Materi Siswa
      'tab_materi': 'Materi',
      'tab_video': 'Video',
      'tab_asesmen': 'Asesmen',
      'watch_instruction': 'Ketuk untuk Menonton',
      'finish_watch': 'Selesai Nonton & Buka Asesmen',
      'video_unavailable': 'Video belum tersedia',

      // Pengaturan Bahasa Siswa
      'lang_setting': 'Bahasa',
      'indo': 'Bahasa Indonesia',
      'eng': 'English',

      // ==========================================
      // PENAMBAHAN: Modul Portal Guru & Dashboard
      // ==========================================
      'teacher_portal': 'Portal Guru Structora',
      'teacher_nav_home': 'Beranda',
      'teacher_nav_progress': 'Progres Siswa',
      'teacher_nav_upload': 'Upload Materi',
      'teacher_nav_profile': 'Profil',
      'welcome_back': 'Selamat Datang Kembali,',
      'teacher_mode_active': 'Mode Guru Aktif (Monitoring Real-time)',
      'stats_summary': 'Statistik Ringkasan Kelas',
      'active_students': 'Siswa Aktif',
      'lms_status': 'Status LMS',
      'status_active': 'Aktif',
      'student_list_title': 'Daftar Progres & Nilai Siswa',
      'student_list_subtitle': 'Ketuk kartu siswa untuk melihat detail analitik.',
      'reload_data': 'Muat ulang data',
      'no_student_data': 'Belum ada data siswa yang masuk.',

      // Panel Profil Modal
      'profile_settings': 'Pengaturan Profil',
      'app_language': 'Bahasa Aplikasi',
      'app_language_active': 'Bahasa Indonesia (Aktif)',
      'dark_mode': 'Mode Gelap',
      'dark_mode_active': 'Tema gelap aktif',
      'light_mode_active': 'Tema terang aktif',
      'font_size': 'Ukuran Font',
      'logout': 'Keluar Akun',

      // Kelola Materi & Asesmen
      'manage_content_title': 'Kelola Materi & Asesmen',
      'manage_content_subtitle': 'Kelola butir soal Pre-Test, Post-Test, serta Modul Pertemuan.',
      'btn_upload_material': 'Upload Materi',
      'eval_package_title': 'Paket Evaluasi Umum (Pre-Test & Post-Test)',
      'learning_modules_title': 'Modul Sesi Pembelajaran',
      'video_active': 'Video Aktif',
      'no_video': 'Tanpa Video',
      'assessment_questions': 'Soal Asesmen',

      // Formulir Editor Materi
      'edit_material': 'Edit Materi & Asesmen',
      'upload_material': 'Upload Materi & Asesmen',
      'save': 'Simpan',
      'publish': 'Publikasikan',
      'sec_meeting_info': '1. Informasi Materi & Sesi Pertemuan',
      'sec_exam_info': '1. Informasi Evaluasi Ujian',
      'label_session': 'Sesi / Identitas Ujian',
      'label_topic_title': 'Judul Topik Materi',
      'label_summary': 'Penjelasan / Rangkuman Materi Lengkap',
      'sec_video': '2. Video Tutorial Pembelajaran',
      'label_video_url': 'Tautan URL Video (YouTube / Tautan Video)',
      'sec_questions': '3. Paket Asesmen Ujian Modul',
      'btn_quick_import': 'Quick Import Soal',

      // Detail Evaluasi Siswa
      'eval_detail': 'Detail Evaluasi',
      'comp_analysis': 'Analisis Perbandingan & Evaluasi',
      'recommendations': 'Rekomendasi Mitigasi & Tindak Lanjut Guru',
      'mentorship_guide': 'Panduan Pendampingan Belajar',
    },
    'en': {
      // Navigasi & Header Siswa (Lama - Tidak Diubah)
      'nav_home': 'Home',
      'nav_materi': 'Topics',
      'nav_lab': '3D Lab',
      'nav_eval': 'Evaluation',
      'back_to_list': 'Back to Topic List',

      // Tab Materi Siswa (Lama - Tidak Diubah)
      'tab_materi': 'Material',
      'tab_video': 'Video',
      'tab_asesmen': 'Assessment',
      'watch_instruction': 'Tap to Watch',
      'finish_watch': 'Finished Watching & Open Assessment',
      'video_unavailable': 'Video not available',

      // Pengaturan Bahasa Siswa (Lama - Tidak Diubah)
      'lang_setting': 'Language',
      'indo': 'Indonesian',
      'eng': 'English',

      // ==========================================
      // PENAMBAHAN: Modul Portal Guru & Dashboard
      // ==========================================
      'teacher_portal': 'Structora Teacher Portal',
      'teacher_nav_home': 'Home',
      'teacher_nav_progress': 'Student Progress',
      'teacher_nav_upload': 'Upload Content',
      'teacher_nav_profile': 'Profile',
      'welcome_back': 'Welcome Back,',
      'teacher_mode_active': 'Teacher Mode Active (Real-time Monitoring)',
      'stats_summary': 'Class Summary Statistics',
      'active_students': 'Active Students',
      'lms_status': 'LMS Status',
      'status_active': 'Active',
      'student_list_title': 'Student Progress & Scores',
      'student_list_subtitle': 'Tap student card to view detailed analytics.',
      'reload_data': 'Reload data',
      'no_student_data': 'No student data available yet.',

      // Panel Profil Modal
      'profile_settings': 'Profile Settings',
      'app_language': 'App Language',
      'app_language_active': 'English (Active)',
      'dark_mode': 'Dark Mode',
      'dark_mode_active': 'Dark theme active',
      'light_mode_active': 'Light theme active',
      'font_size': 'Font Size',
      'logout': 'Log Out',

      // Kelola Materi & Asesmen
      'manage_content_title': 'Manage Materials & Assessments',
      'manage_content_subtitle': 'Manage Pre-Test, Post-Test questions, and Meeting Modules.',
      'btn_upload_material': 'Upload Material',
      'eval_package_title': 'General Evaluation Package (Pre-Test & Post-Test)',
      'learning_modules_title': 'Learning Session Modules',
      'video_active': 'Video Active',
      'no_video': 'No Video',
      'assessment_questions': 'Assessment Questions',

      // Formulir Editor Materi
      'edit_material': 'Edit Material & Assessment',
      'upload_material': 'Upload Material & Assessment',
      'save': 'Save',
      'publish': 'Publish',
      'sec_meeting_info': '1. Material & Meeting Information',
      'sec_exam_info': '1. Exam Evaluation Information',
      'label_session': 'Session / Exam Identity',
      'label_topic_title': 'Material Topic Title',
      'label_summary': 'Detailed Explanation / Full Summary',
      'sec_video': '2. Learning Video Tutorial',
      'label_video_url': 'Video URL Link (YouTube / Video Link)',
      'sec_questions': '3. Module Assessment Package',
      'btn_quick_import': 'Quick Import',

      // Detail Evaluasi Siswa
      'eval_detail': 'Evaluation Details',
      'comp_analysis': 'Comparative Analysis & Evaluation',
      'recommendations': 'Teacher Mitigation & Follow-up Recommendations',
      'mentorship_guide': 'Learning Mentorship Guide',
    },
  };

  // Kamus Konten Menyeluruh (Soal, Opsi, Judul, & Deskripsi Materi)
  static const Map<String, String> _contentDictionary = {
    // Label Sesi & Evaluasi
    'Pertemuan': 'Meeting',
    'Pertemuan 1': 'Meeting 1',
    'Pertemuan 2': 'Meeting 2',
    'Pertemuan 3': 'Meeting 3',
    'Pertemuan 4': 'Meeting 4',
    'Pertemuan 5': 'Meeting 5',
    'Modul': 'Module',
    'Modul 1': 'Module 1',
    'Modul 2': 'Module 2',
    'Modul 3': 'Module 3',
    'Modul 4': 'Module 4',
    'Evaluasi Awal': 'Initial Assessment',
    'Evaluasi Akhir': 'Final Evaluation',
    'Pre-Test: Uji Kemampuan Awal': 'Pre-Test: Initial Skill Assessment',
    'Post-Test: Evaluasi Akhir Kelulusan': 'Post-Test: Final Graduation Evaluation',
    'Uji Kemampuan Awal': 'Initial Skill Assessment',
    'Evaluasi Akhir Kelulusan': 'Final Graduation Evaluation',
    'Belum Ujian': 'Not Tested',
    'Tuntas': 'Completed',
    'Pengguna': 'Student',
    'Ibu Guru': 'Teacher',
    'Guru': 'Teacher',
    'Siswa': 'Student',

    // Bank Soal Pre-Test, Asesmen & Post-Test
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
    'Bagian simpul yang menyimpan alamat memori simpul berikutnya disebut...':
    'The node component that stores the memory address of the next node is called...',
    'Pointer penunjuk simpul paling pertama dalam linked list disebut...':
    'The pointer pointing to the very first node in a linked list is called...',
    'Kelemahan alokasi memori pada linked list dibandingkan array biasa adalah...':
    'The memory allocation drawback of a linked list compared to a standard array is...',
    'Prinsip utama yang diterapkan pada struktur data Stack adalah...':
    'The core principle applied to the Stack data structure is...',
    'Operasi untuk memasukkan data baru ke posisi teratas stack dinamakan...':
    'The operation to insert new data into the top position of a stack is called...',
    'Operasi untuk mengambil atau menghapus data teratas stack dinamakan...':
    'The operation to retrieve or remove top data from a stack is called...',
    'Melihat isi elemen teratas stack tanpa menghapusnya dari memori disebut...':
    'Inspecting top element content in stack without deleting it from memory is called...',
    'Kondisi kegagalan yang terjadi saat melakukan Push pada stack yang sudah penuh adalah...':
    'The failure state occurring when attempting Push on a full stack is...',
    'Operasi Pop pada stack yang tidak memiliki elemen sama sekali menghasilkan kondisi...':
    'A Pop operation on a stack containing zero elements results in condition...',
    'Fungsi tombol Undo pada aplikasi text editor bekerja berdasarkan struktur data...':
    'The Undo button function in text editor applications operates based on data structure...',
    'Operasi Push dan Pop pada Stack memiliki kompleksitas waktu...':
    'Push and Pop operations on Stack have time complexity of...',
    'Pointer penunjuk elemen teratas pada stack umumnya dinamakan...':
    'The pointer referencing top element on stack is commonly named...',
    'Konversi notasi infix ke postfix memanfaatkan struktur data...':
    'Converting infix to postfix notation utilizes data structure...',
    'Prinsip di mana elemen yang pertama masuk akan pertama kali keluar disebut...':
    'The principle where earliest inserted element is dequeued first is called...',
    'Operasi mengeluarkan elemen terdepan dari Queue dinamakan...':
    'The operation of removing the front element from a Queue is called...',
    'Penunjuk yang mengarah ke simpul paling belakang dari antrean adalah...':
    'The pointer referencing the rearmost node of a queue is...',
    'Kondisi error saat melakukan Dequeue pada Queue yang kosong adalah...':
    'The error state when attempting Dequeue on an empty Queue is...',
    'Penunjuk yang mengarah ke elemen paling depan antrean untuk diproses adalah...':
    'The pointer pointing to frontmost element for processing in queue is...',
    'Sistem antrean printer komputer (Print Spooling) menerapkan struktur data...':
    'Computer printer spooling queue system implements data structure...',
    'Pada Circular Queue, jika Rear mencapai batas indeks maksimum maka posisi berikutnya diarahkan ke...':
    'In a Circular Queue, when Rear hits max index capacity, next position wraps to...',
    'Operasi Enqueue dan Dequeue pada implementasi Queue efisien memiliki kompleksitas...':
    'Enqueue and Dequeue operations on efficient Queue implementation have complexity...',
    'Struktur antrean di mana elemen dengan prioritas tertinggi dilayani lebih dahulu disebut...':
    'A queue structure where highest priority element is serviced first is called...',
    'Syarat utama agar algoritma Binary Search dapat dijalankan adalah...':
    'The primary prerequisite for executing Binary Search algorithm is...',
    'Kompleksitas waktu terbaik (Best Case) dari algoritma Binary Search adalah...':
    'Best-case time complexity of Binary Search algorithm is...',
    'Algoritma yang berulang kali menukar dua elemen bersebelahan yang tidak urut adalah...':
    'The algorithm repeatedly swapping two adjacent out-of-order elements is...',
    'Metode pencarian yang memeriksa setiap elemen array satu per satu dari awal adalah...':
    'The search method inspecting every array element sequentially from start is...',
    'Selection Sort bekerja dengan mekanisme utama yaitu...':
    'Selection Sort operates via main mechanism of...',
    'Kompleksitas waktu rata-rata (Average Case) dari Binary Search adalah...':
    'Average-case time complexity of Binary Search is...',
    'Jika data terdiri dari 1000 data acak dan tidak terurut, metode pencarian yang tepat adalah...':
    'Given 1000 unsorted random elements, appropriate search method is...',
    'Kompleksitas waktu terburuk (Worst Case) algoritma Bubble Sort adalah...':
    'Worst-case time complexity of Bubble Sort algorithm is...',
    'Algoritma pengurutan yang membagi larik menjadi dua bagian kemudian menggabungkannya secara terurut adalah...':
    'The sorting algorithm splitting array in two and merging sorted halves is...',
    'Pada algoritma Linear Search, kasus terburuk (Worst Case) terjadi ketika...':
    'In Linear Search algorithm, worst-case scenario occurs when...',
    'Pada Single Linked List, simpul terakhir selalu memiliki pointer penunjuk yang mengarah ke...':
    'In Single Linked List, last node always has pointer directing to...',
    'Operasi penambahan elemen ke posisi teratas pada struktur data Stack dinamakan...':
    'The operation adding element to peak position on Stack is called...',
    'Struktur data antrean yang memproses data yang pertama kali datang dinamakan prinsip...':
    'Queue data structure processing earliest arrived data operates on principle...',
    'Operasi pengeluaran elemen dari antrean (Queue) dinamakan...':
    'The operation evicting element from Queue is called...',
    'Jika array sudah berurutan dari kecil ke besar, algoritma pencarian yang paling efisien adalah...':
    'If array is already sorted ascending, the most efficient search algorithm is...',
    'Pada Doubly Linked List, setiap simpul dilengkapi dengan dua pointer yaitu...':
    'In Doubly Linked List, each node features two pointers namely...',
    'Mekanisme tombol Undo/Redo pada aplikasi pengolah kata menerapkan struktur data...':
    'Undo/Redo button mechanism in word processor applies data structure...',
    'Antrean tugas pencetakan printer (print spooler) menerapkan prinsip struktur data...':
    'Printer print spooler task queue applies data structure principle...',
    'Algoritma yang berulang kali mencari nilai terkecil dari elemen yang belum terurut lalu menukarnya adalah...':
    'Algorithm repeatedly isolating minimum value from unsorted slice and swapping it is...',
    'Kompleksitas waktu rata-rata (Average Case) dari algoritma pencarian Binary Search adalah...':
    'Average-case time complexity of Binary Search lookup algorithm is...',

    // Opsi Pilihan Jawaban
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

    // Rangkuman Materi Konsep Linked List & Stack
    'A. Pengertian:': 'A. Definition:',
    'Linked List adalah struktur data linier yang tersusun dari kumpulan elemen bernama Node. Berbeda dengan Array statis yang ukurannya kaku dan harus berurutan di memori komputer, Linked List bersifat dinamis sehingga penambahan atau pengurangan elemen dapat dilakukan secara fleksibel tanpa perlu menggeser posisi data lainnya.':
    'Linked List is a linear data structure composed of a collection of elements called Nodes. Unlike a static Array whose size is fixed and contiguous in computer memory, a Linked List is dynamic, allowing elements to be inserted or removed flexibly without shifting other elements.',
    'B. Komponen Utama Node:': 'B. Main Node Components:',
    '1. Data atau Value: Nilai atau informasi aktual yang tersimpan di dalam node.':
    '1. Data or Value: The actual value or information stored within the node.',
    '2. Next Pointer: Penunjuk alamat memori yang menghubungkan node saat ini ke node berikutnya.':
    '2. Next Pointer: The memory address pointer connecting the current node to the next node.',
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

    // Bank Soal Pre-Test & Uji Kemampuan Awal
    'Struktur data digunakan dalam pemrograman untuk ....':
    'Data structures are used in computer programming to ....',
    'Mempercantik tampilan aplikasi saja': 'Beautify application appearance only',
    'Menyimpan dan mengatur data agar mudah diolah': 'Store and organize data for efficient processing',
    'Mengganti sistem operasi komputer': 'Replace computer operating systems',
    'Menghapus seluruh kesalahan program secara otomatis': 'Automatically resolve all software bugs',
    'Memperbesar ukuran memori komputer': 'Physically expand computer RAM size',
    'Struktur data berfungsi mengorganisasi dan menyimpan data di memori agar penelusuran dan pemrosesannya efisien.':
    'Data structures organize and store data in memory to enable efficient access and modification.',

    'Sebuah aplikasi menyimpan data siswa yang jumlahnya dapat bertambah dan berkurang sewaktu-waktu. Struktur data yang setiap elemennya dapat dihubungkan menggunakan pointer adalah ....':
    'An application stores student records whose quantity changes dynamically. A data structure whose elements are interconnected via pointers is ....',
    'Linked List tersusun dari kumpulan node dinamis yang saling terhubung melalui pointer.':
    'A Linked List is composed of dynamic nodes interconnected through pointers.',

    'Dalam kehidupan sehari-hari, tumpukan piring memiliki prinsip bahwa piring yang terakhir diletakkan akan diambil terlebih dahulu. Prinsip ini disebut ....':
    'In everyday life, a stack of plates operates on the principle that the last plate placed is the first one taken. This principle is called ....',
    'LIFO (Last In First Out) berarti data yang paling akhir dimasukkan akan diambil terlebih dahulu.':
    'LIFO (Last In First Out) means that the last item inserted will be retrieved first.',

    'Pada sistem antrean di loket sekolah, siswa yang datang pertama akan dilayani terlebih dahulu. Struktur data yang paling sesuai adalah ....':
    'In a school counter queue, the first student to arrive is served first. The most appropriate data structure is ....',
    'Queue menggunakan mekanisme FIFO (First In First Out) di mana yang datang pertama dilayani pertama.':
    'Queue utilizes a FIFO (First In First Out) mechanism where the earliest arrival is served first.',

    'Seorang guru ingin mengurutkan nilai siswa dari nilai terkecil hingga terbesar. Proses yang harus dilakukan adalah ....':
    'A teacher wants to order student scores from lowest to highest. The required process is ....',
    'Sorting adalah proses mengatur elemen data yang acak menjadi berurutan secara sistematis.':
    'Sorting is the systematic arrangement of unordered data elements into a specified sequence.',

    'Tipe data terstruktur yang ukuran memorinya tetap dan kaku sejak awal dideklarasikan adalah ....':
    'A structured data type with a fixed and rigid memory allocation defined at declaration is ....',
    'Array statis': 'Static Array',
    'Dynamic Stack': 'Dynamic Stack',
    'Tree pointer': 'Tree pointer',
    'Array statis memesan blok memori tetap secara berurutan dan ukurannya tidak dapat membesar secara fleksibel.':
    'Static arrays allocate fixed contiguous memory blocks that cannot expand dynamically.',

    'Operasi dasar untuk menelusuri seluruh data dalam struktur data satu per satu disebut ....':
    'The foundational operation of visiting every element in a data structure sequentially is called ....',
    'Traversal adalah kunjungan ke setiap elemen struktur data secara berurutan untuk membaca atau menampilkan isinya.':
    'Traversal involves visiting every node/element sequentially to read or process its content.',

    'Algoritma yang bertujuan menemukan letak posisi elemen tertentu di dalam sekumpulan data disebut ....':
    'An algorithm designed to locate the position of a specific target value within a dataset is called ....',
    'Searching adalah prosedur pencarian untuk menemukan target data yang dicari.':
    'Searching is an algorithmic procedure to determine whether a target key exists and locate it.',

    'Pengurutan data dari angka terbesar menuju angka terkecil disebut ....':
    'Arranging data values from highest to lowest is termed ....',
    'Descending adalah susunan terurut menurun dari nilai terbesar ke nilai terkecil.':
    'Descending order arranges items in a downward progression from greatest to least.',

    'Komponen utama di dalam memori komputer yang menyimpan alamat dari data lain dinamakan ....':
    'A core computing construct that holds the memory address of another value is known as a ....',
    'Pointer / Reference': 'Pointer / Reference',
    'Pointer menyimpan nilai alamat memori (memory address) yang menunjuk ke lokasi data lainnya.':
    'A pointer stores the memory address reference pointing directly to another data location.',

    // Bank Soal Post-Test & Asesmen Lanjutan
    'Pada Linked List, komponen yang menghubungkan sebuah node dengan node berikutnya adalah ....':
    'In a Linked List, the component that connects a node to the next node is ....',
    'Next Pointer menunjuk ke alamat memori dari node berikutnya di dalam rantai data.':
    'Next Pointer contains the memory reference pointing to the succeeding node.',

    'Sebuah Stack memiliki isi dari bawah ke atas berupa A, B, C. Jika dilakukan Pop sebanyak satu kali, isi Stack dari bawah ke atas menjadi ....':
    'A Stack contains bottom-to-top items A, B, C. After calling Pop() once, the bottom-to-top contents are ....',
    'Elemen C di puncak dikeluarkan, menyisakan A di bawah dan B di atasnya.':
    'Element C on top is popped, leaving A at bottom and B on top.',

    'Dalam Queue, data yang pertama kali masuk akan ....':
    'In a Queue, the item that arrived first will be ....',
    'Prinsip FIFO menetapkan data pertama yang masuk akan diproses dan dikeluarkan pertama kali.':
    'FIFO guarantees the earliest arrival is processed and evicted first.',

    'Algoritma yang membandingkan elemen bersebelahan dan menukarnya apabila urutannya salah adalah ....':
    'The algorithm that compares neighbor elements and swaps them if disordered is ....',
    'Bubble Sort membandingkan dan menukar dua elemen yang berdampingan secara terus menerus.':
    'Bubble Sort iteratively swaps adjacent unordered pairs.',

    'Seorang siswa ingin mencari nomor induk tertentu dalam daftar yang belum terurut. Metode yang dapat langsung digunakan tanpa mengurutkan data terlebih dahulu adalah ....':
    'A student needs to locate an ID in an unsorted list. The method usable without prior sorting is ....',
    'Linear Search dapat langsung digunakan pada data acak tanpa perlu pengurutan awal.':
    'Linear Search works out of the box on arbitrary unsorted collections.',

    'Pada Circular Linked List, node terakhir memiliki pointer yang mengarah kembali ke ....':
    'In a Circular Linked List, the terminal node has a pointer directing back to ....',

    'Dikeluarkan terakhir': 'Dequeued last',
    'Dikeluarkan pertama': 'Dequeued first',
    'Selalu berada di tengah': 'Fixed permanently in the middle',
    'Dipindahkan ke Stack': 'Pushed into a Stack',
    'Dihapus secara acak': 'Randomly removed',
    'Node terakhir': 'The last node',
    'Node pertama': 'The first node',
    'Node kedua saja': 'The second node only',
    'Head dan NULL sekaligus': 'Both Head and NULL',
    'Kosong': 'Empty',

    // Soal & Opsi Doubly Linked List (Riwayat Aktivitas)
    'Sebuah aplikasi menggunakan Doubly Linked List untuk menyimpan riwayat aktivitas. Programmer menemukan bahwa pengguna dapat bergerak maju, tetapi gagal kembali ke aktivitas sebelumnya. Bagian yang perlu diperiksa adalah ....':
    'An application uses a Doubly Linked List to store activity history. A programmer finds that users can move forward, but fail to navigate back to the previous activity. The component that needs inspection is ....',
    'Sebuah aplikasi menggunakan Doubly Linked List untuk menyimpan riwayat aktivitas. Programmer menemukan bahwa pengguna dapat bergerak maju, tetapi gagal kembali ke aktivitas sebelumnya. Bagian yang perlu diperiksa adalah...':
    'An application uses a Doubly Linked List to store activity history. A programmer finds that users can move forward, but fail to navigate back to the previous activity. The component that needs inspection is...',
    'Pointer Prev': 'Prev Pointer',
    'Head saja': 'Head only',
    'Pointer Next saja': 'Next Pointer only',
    'Data Value': 'Data Value',
    'Pointer Prev saja': 'Prev Pointer only',
    'Pointer Tail saja': 'Tail Pointer only',
    'Node Head': 'Head Node',
    'Node Tail': 'Tail Node',

    // Soal & Opsi Tambahan (Pre-Test, Asesmen & Sistem)
    'Dalam sebuah program, terdapat tiga node yang saling terhubung. The first node menyimpan angka 15, node kedua menyimpan angka 25, dan node ketiga menyimpan angka 35. Komponen yang digunakan untuk menunjukkan node pertama adalah ....':
    'In a program, three nodes are interconnected. The first node stores the number 15, the second node stores 25, and the third node stores 35. The component used to designate the first node is ....',
    'Dalam sebuah program, terdapat tiga node yang saling terhubung. Node pertama menyimpan angka 15, node kedua menyimpan angka 25, dan node ketiga menyimpan angka 35. Komponen yang digunakan untuk menunjukkan node pertama adalah ....':
    'In a program, three nodes are interconnected. The first node stores the number 15, the second node stores 25, and the third node stores 35. The component used to designate the first node is ....',
    'Dalam sebuah Stack, program menjalankan operasi Pop ketika tidak terdapat satu pun elemen di dalamnya. Kondisi kesalahan yang terjadi adalah ....':
    'In a Stack, a program executes a Pop operation when there are no elements inside it. The error condition that occurs is ....',
    'Dalam sebuah Stack, program menjalankan operasi Pop ketika tidak terdapat satu pun elemen di dalamnya. Kondisi kesalahan yang terjadi is ....':
    'In a Stack, a program executes a Pop operation when there are no elements inside it. The error condition that occurs is ....',
    'Sebuah perusahaan ingin mengembangkan aplikasi pengelolaan daftar pekerjaan. Data sering ditambahkan dan dihapus, serta pengguna dapat berpindah dari pekerjaan sebelumnya ke pekerjaan berikutnya maupun sebaliknya. Setelah mempertimbangkan kebutuhan tersebut, programmer memilih Doubly Linked List. Alasan paling tepat adalah ....':
    'A company wants to develop a task list management application. Data is frequently added and deleted, and users can navigate between previous and next tasks bidirectionally. After evaluating these requirements, the programmer selects a Doubly Linked List. The most appropriate reason is ....',
    'Sebuah perusahaan ingin mengembangkan aplikasi pengelolaan daftar pekerjaan. Data sering ditambahkan dan dihapus, serta pengguna dapat berpindah dari pekerjaan sebelumnya ke pekerjaan berikutnya maupun sebaliknya. Setelah mempertimbangkan kebutuhan tersebut, programmer memilih Doubly Linked List. Alasan paling tepat is ....':
    'A company wants to develop a task list management application. Data is frequently added and deleted, and users can navigate between previous and next tasks bidirectionally. After evaluating these requirements, the programmer selects a Doubly Linked List. The most appropriate reason is ....',
    'Seorang pengembang sedang membuat aplikasi pengelolaan data anggota organisasi. Jumlah anggota dapat bertambah dan berkurang setiap saat. Pengembang ingin menambahkan anggota baru tanpa harus memindahkan seluruh data yang sudah tersimpan. Struktur data yang paling sesuai adalah ....':
    'A developer is building an organization member data management application. The number of members can dynamically expand and shrink at any time. The developer wants to insert new members without shifting all existing stored data. The most suitable data structure is ....',
    'Seorang pengembang sedang membuat aplikasi pengelolaan data anggota organisasi. Jumlah anggota dapat bertambah dan berkurang setiap saat. Pengembang ingin menambahkan anggota baru tanpa harus memindahkan seluruh data yang sudah tersimpan. Struktur data yang paling sesuai is ....':
    'A developer is building an organization member data management application. The number of members can dynamically expand and shrink at any time. The developer wants to insert new members without shifting all existing stored data. The most suitable data structure is ....',
    'Node memiliki pointer ke elemen sebelumnya dan berikutnya':
    'Nodes contain pointers to both previous and next elements',
    'Data hanya dapat diproses dari belakang': 'Data can only be processed from the rear',
    'Semua data disimpan dalam satu posisi': 'All data is stored in a single position',
    'Setiap penambahan data harus menghapus data lama': 'Every data addition requires deleting old data',
    'Array dengan kapasitas tetap': 'Fixed-capacity Array',
    'Sebuah Linked List memiliki node terakhir yang tidak lagi menunjuk ke node lain. Nilai pointer pada node terakhir tersebut adalah NULL. Fungsi NULL dalam kondisi tersebut adalah ....':
    'A Linked List has a terminal node that no longer points to another node. The pointer value at this terminal node is NULL. The purpose of NULL in this condition is to ....',
    'Sebuah Linked List memiliki node terakhir yang tidak lagi menunjuk ke node lain. Nilai pointer pada node terakhir tersebut adalah NULL. Fungsi NULL dalam kondisi tersebut is ....':
    'A Linked List has a terminal node that no longer points to another node. The pointer value at this terminal node is NULL. The purpose of NULL in this condition is to ....',
    'Menghubungkan dua node sekaligus': 'Connect two nodes simultaneously',
    'Menyimpan data tambahan': 'Store additional data',
    'Menunjukkan node pertama': 'Indicate the first node',
    'Menandai akhir rantai node': 'Mark the end of the node chain',
    'Sebuah sistem menerima data A, B, C, dan D melalui operasi Enqueue secara berurutan. Setelah itu, sistem menjalankan dua kali Dequeue. Data yang masih berada dalam antrean adalah ....':
    'A system receives data A, B, C, and D through Enqueue operations sequentially. Afterward, the system executes Dequeue twice. The data remaining in the queue is ....',
    'Sebuah sistem menerima data A, B, C, dan D melalui operasi Enqueue secara berurutan. Setelah itu, sistem menjalankan dua kali Dequeue. Data yang masih berada dalam antrean is ....':
    'A system receives data A, B, C, and D through Enqueue operations sequentially. Afterward, the system executes Dequeue twice. The data remaining in the queue is ....',
    'Sebuah sistem mencetak dokumen berdasarkan urutan dokumen yang dikirim oleh pengguna. Dokumen pertama yang dikirim harus dicetak sebelum dokumen berikutnya. Struktur data yang paling tepat adalah ....':
    'A system prints documents based on the sequence in which users submit them. The first document sent must be printed before subsequent documents. The most suitable data structure is ....',
    'Sebuah sistem mencetak dokumen berdasarkan urutan dokumen yang dikirim oleh pengguna. Dokumen pertama yang dikirim harus dicetak sebelum dokumen berikutnya. Struktur data yang paling tepat is ....':
    'A system prints documents based on the sequence in which users submit them. The first document sent must be printed before subsequent documents. The most suitable data structure is ....',
    'Sebuah program memiliki Stack dengan kapasitas maksimal lima elemen. Saat ini seluruh':
    'A program features a Stack with a maximum capacity of five elements. Currently all',
    'Sebuah program memiliki Stack dengan kapasitas maksimal lima elemen.':
    'A program features a Stack with a maximum capacity of five elements.',
  };

  static String tr(String key) {
    final langCode = _ctrl.currentLocale.languageCode;
    return _localizedValues[langCode]?[key] ?? _localizedValues['id']?[key] ?? key;
  }

  // Fungsi Penerjemah Universal untuk teks dinamis/soal/paragraf
  static String auto(String text) {
    if (!_ctrl.isEnglish) return text;
    return translateDirect(text);
  }

  static String translateDirect(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    // 1. Direct Exact Dictionary Match
    if (_contentDictionary.containsKey(trimmed)) {
      return _contentDictionary[trimmed]!;
    }

    // 2. Normalized Dictionary Match (Ignoring casing and special characters)
    final normInput = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normInput.isNotEmpty) {
      for (final entry in _contentDictionary.entries) {
        final normKey = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (normKey.isNotEmpty && normKey == normInput) {
          return entry.value;
        }
      }
    }

    String result = text;

    // 3. Sentence Pattern Translators (Structured Template Translation for Exam Questions)
    final List<MapEntry<RegExp, String Function(Match)>> patternTranslators = [
      // Pattern: "Sebuah/Suatu [Structure] memiliki/menggunakan/tersusun..."
      MapEntry(
        RegExp(r'^(Sebuah|Suatu)\s+(queue|stack|linked list|array|tree|graph)\s+(memiliki|menggunakan|tersusun)\s+(.*)', caseSensitive: false),
        (m) {
          final struct = m.group(2)!;
          final rest = m.group(4)!;
          return 'A ${struct.toLowerCase()} contains $rest';
        },
      ),
      // Pattern: "Manakah [pernyataan/opsi] [berikut] yang [benar/tepat]..."
      MapEntry(
        RegExp(r'^Manakah\s+.*?(pernyataan|opsi|pilihan).*?(benar|tepat|sesuai)\s*(.*)', caseSensitive: false),
        (m) {
          final rest = m.group(3)!;
          final cleanRest = rest.startsWith('mengenai') || rest.startsWith('tentang')
              ? 'regarding ${rest.replaceFirst(RegExp(r'^(mengenai|tentang)\s*', caseSensitive: false), '')}'
              : rest;
          return 'Which of the following statements is correct $cleanRest'.trim();
        },
      ),
      // Pattern: "Apa [hasil|keluaran|fungsi|kegunaan] dari..."
      MapEntry(
        RegExp(r'^Apa\s+(hasil|keluaran|output|fungsi|kegunaan|tujuan)\s+dari\s+(.*)', caseSensitive: false),
        (m) {
          final noun = m.group(1)!.toLowerCase();
          final rest = m.group(2)!;
          String target = 'result';
          if (noun == 'fungsi' || noun == 'kegunaan') target = 'purpose';
          if (noun == 'tujuan') target = 'goal';
          return 'What is the $target of $rest';
        },
      ),
      // Pattern: "Urutan [langkah|proses|elemen] yang [benar|tepat]..."
      MapEntry(
        RegExp(r'^Urutan\s+(langkah|proses|elemen)\s+yang\s+(benar|tepat|sesuai)\s*(.*)', caseSensitive: false),
        (m) {
          final item = m.group(1)!.toLowerCase();
          final rest = m.group(3)!;
          String noun = 'sequence of steps';
          if (item == 'proses') noun = 'order of processing';
          if (item == 'elemen') noun = 'sequence of elements';
          return 'The correct $noun $rest'.trim();
        },
      ),
      // Pattern: "Keuntungan/Kelebihan/Kelemahan/Kekurangan utama [dari|menggunakan]..."
      MapEntry(
        RegExp(r'^(Keuntungan|Kelebihan|Kelemahan|Kekurangan)\s+utama\s+(?:dari|menggunakan)?\s*(.*)', caseSensitive: false),
        (m) {
          final type = m.group(1)!.toLowerCase();
          final rest = m.group(2)!;
          final isAdv = type == 'keuntungan' || type == 'kelebihan';
          final label = isAdv ? 'primary advantage' : 'main drawback';
          return 'The $label of $rest'.trim();
        },
      ),
      // Pattern: "Kondisi [saat|di mana|ketika]..."
      MapEntry(
        RegExp(r'^Kondisi\s+(?:saat|di mana|ketika)\s+(.*)', caseSensitive: false),
        (m) => 'The condition when ${m.group(1)}',
      ),
      // Pattern: "Operasi [untuk] [menambahkan|menghapus|mengambil|melihat|menelusuri]..."
      MapEntry(
        RegExp(r'^Operasi\s+(?:untuk\s+)?(menambahkan|menghapus|mengambil|melihat|menelusuri)\s+(.*)', caseSensitive: false),
        (m) {
          final action = m.group(1)!.toLowerCase();
          final rest = m.group(2)!;
          String verb = 'manipulate';
          if (action == 'menambahkan') verb = 'add an element to';
          if (action == 'menghapus') verb = 'delete an element from';
          if (action == 'mengambil') verb = 'retrieve an element from';
          if (action == 'melihat') verb = 'view the element in';
          if (action == 'menelusuri') verb = 'traverse';
          return 'The operation to $verb $rest';
        },
      ),
      // Pattern: "Kompleksitas waktu [terbaik|rata-rata|terburuk]..."
      MapEntry(
        RegExp(r'^Kompleksitas\s+waktu\s*(terbaik|rata-rata|terburuk)?\s*(?:dari|pada)?\s*(.*)', caseSensitive: false),
        (m) {
          final type = (m.group(1) ?? '').toLowerCase();
          final rest = m.group(2)!;
          String tag = 'time complexity';
          if (type.contains('terbaik')) tag = 'best-case time complexity';
          if (type.contains('rata')) tag = 'average-case time complexity';
          if (type.contains('terburuk')) tag = 'worst-case time complexity';
          return 'The $tag of $rest'.trim();
        },
      ),
    ];

    for (final pattern in patternTranslators) {
      final match = pattern.key.firstMatch(result);
      if (match != null) {
        result = pattern.value(match);
        break;
      }
    }

    // 4. Multi-Word Phrase Replacements (Longest phrases substituted first)
    final Map<String, String> phraseMap = {
      'Dalam sebuah program, terdapat tiga node yang saling terhubung':
          'In a program, three nodes are interconnected',
      'The first node menyimpan angka 15, node kedua menyimpan angka 25, dan node ketiga menyimpan angka 35':
          'The first node stores the number 15, the second node stores 25, and the third node stores 35',
      'Node pertama menyimpan angka 15, node kedua menyimpan angka 25, dan node ketiga menyimpan angka 35':
          'The first node stores the number 15, the second node stores 25, and the third node stores 35',
      'Komponen yang digunakan untuk menunjukkan node pertama':
          'The component used to designate the first node',
      'Dalam sebuah Stack, program menjalankan operasi Pop ketika tidak terdapat satu pun elemen di dalamnya':
          'In a Stack, a program executes a Pop operation when there are no elements inside it',
      'Sebuah perusahaan ingin mengembangkan aplikasi pengelolaan daftar pekerjaan':
          'A company wants to develop a task list management application',
      'Data sering ditambahkan dan dihapus, serta pengguna dapat berpindah dari pekerjaan sebelumnya ke pekerjaan berikutnya maupun sebaliknya':
          'Data is frequently added and deleted, and users can navigate between previous and next tasks bidirectionally',
      'Setelah mempertimbangkan kebutuhan tersebut, programmer memilih Doubly Linked List':
          'After evaluating these requirements, the programmer selects a Doubly Linked List',
      'Node memiliki pointer ke elemen sebelumnya dan berikutnya':
          'Nodes contain pointers to both previous and next elements',
      'Data hanya dapat diproses dari belakang': 'Data can only be processed from the rear',
      'Semua data disimpan dalam satu posisi': 'All data is stored in a single position',
      'Setiap penambahan data harus menghapus data lama': 'Every data addition requires deleting old data',
      'Seorang pengembang sedang membuat aplikasi pengelolaan data anggota organisasi':
          'A developer is building an organization member data management application',
      'Jumlah anggota dapat bertambah dan berkurang setiap saat':
          'The number of members can dynamically expand and shrink at any time',
      'Pengembang ingin menambahkan anggota baru tanpa harus memindahkan seluruh data yang sudah tersimpan':
          'The developer wants to insert new members without shifting all existing stored data',
      'Struktur data yang paling sesuai': 'The most suitable data structure',
      'Array dengan kapasitas tetap': 'Fixed-capacity Array',
      'Sebuah Linked List memiliki node terakhir yang tidak lagi menunjuk ke node lain':
          'A Linked List has a terminal node that no longer points to another node',
      'Nilai pointer pada node terakhir tersebut adalah NULL':
          'The pointer value at this terminal node is NULL',
      'Fungsi NULL dalam kondisi tersebut':
          'The purpose of NULL in this condition',
      'Menghubungkan dua node sekaligus': 'Connect two nodes simultaneously',
      'Menyimpan data tambahan': 'Store additional data',
      'Menunjukkan node pertama': 'Indicate the first node',
      'Menandai akhir rantai node': 'Mark the end of the node chain',
      'Setelah itu, sistem menjalankan dua kali Dequeue':
          'Afterward, the system executes Dequeue twice',
      'Data yang masih berada dalam antrean': 'The data remaining in the queue',
      'Sebuah sistem mencetak dokumen berdasarkan urutan dokumen yang dikirim oleh pengguna':
          'A system prints documents based on the sequence submitted by users',
      'Dokumen pertama yang dikirim harus dicetak sebelum dokumen berikutnya':
          'The first document sent must be printed before subsequent documents',
      'Sebuah program memiliki Stack dengan kapasitas maksimal lima elemen':
          'A program features a Stack with a maximum capacity of five elements',
      'Programmer menemukan bahwa pengguna dapat bergerak maju, tetapi gagal kembali ke aktivitas sebelumnya':
          'A programmer finds that users can move forward, but fail to navigate back to the previous activity',
      'Bagian yang perlu diperiksa adalah': 'The component that needs inspection is',
      'Kunci jawaban yang benar adalah opsi': 'Correct answer is option',
      'Kunci jawaban yang benar adalah': 'The correct answer is',
      'Jawaban benar berdasarkan naskah materi yang disusun oleh guru.':
          'Correct answer according to module material script.',
      'Jawaban benar berdasarkan naskah materi.':
          'Correct answer according to module material script.',
      'Jawaban benar berdasarkan': 'Correct answer according to',
      'Pembahasan:': 'Explanation:',
      'Penjelasan:': 'Explanation:',
      'Kunci Jawaban:': 'Correct Key:',
      'Jawaban Kamu:': 'Your Answer:',
      'Jawaban Kamu - Benar': 'Your Answer - Correct',
      'Pointer Prev saja': 'Prev Pointer only',
      'Pointer Next saja': 'Next Pointer only',
      'Pointer Prev': 'Prev Pointer',
      'Pointer Next': 'Next Pointer',
      'Head saja': 'Head only',
      'Tail saja': 'Tail only',
      'Data Value': 'Data Value',
      'adalah ....': 'is ....',
      'adalah...': 'is...',
    };

    phraseMap.forEach((idPhrase, enPhrase) {
      if (result.contains(idPhrase)) {
        result = result.replaceAll(idPhrase, enPhrase);
      }
    });

    _contentDictionary.forEach((idKey, enVal) {
      if (result.contains(idKey)) {
        result = result.replaceAll(idKey, enVal);
      }
    });

    // 5. Clean option suffix formatting (e.g. "... saja" -> "... only")
    if (result.trim().endsWith(' saja')) {
      final base = result.trim().substring(0, result.trim().length - 5).trim();
      result = '$base only';
    }

    return result;
  }
}