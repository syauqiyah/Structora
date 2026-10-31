# 📘 Structora — Interactive Data Structure Learning & Evaluation App

<p align="center">
  <a href="https://github.com/syauqiyah/Structora/releases/download/v1.1.0/app-release.apk">
    <img src="https://img.shields.io/badge/📥_Download-Structora_APK_v1.1.0_(Bug_Fix)-0284C7?style=for-the-badge&logo=android&logoColor=white" height="45" alt="Download Structora APK v1.1.0">
  </a>
  <a href="https://github.com/syauqiyah/Structora/releases">
    <img src="https://img.shields.io/badge/📦_GitHub-Releases-22C55E?style=for-the-badge&logo=github&logoColor=white" height="45" alt="GitHub Releases">
  </a>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-FFCA28?logo=firebase&logoColor=black" alt="Firebase"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

---

**Structora** adalah aplikasi pembelajaran dan evaluasi interaktif berbasis mobile dan web yang dirancang khusus untuk mempermudah pemahaman dasar-dasar **Struktur Data** (Linked List, Stack, Queue, Searching & Sorting). Aplikasi ini dilengkapi dengan sistem dual-role (Siswa & Guru), Simulasi 3D Interaktif, Portal LMS Guru, Ujian Terkunci Anti-Kecurangan, Fitur Otomatis Dwibahasa (Indonesia ⇄ Inggris), serta Integrasi Cloud Realtime menggunakan **Google Cloud Firestore** dan **Firebase Authentication**.

---

## 📥 Download Aplikasi (Installer APK)

Klik tombol di bawah ini untuk mengunduh installer APK rilis terbaru yang telah melalui perbaikan bug (*Bug Fix*):

| File Installer | Versi | Status | Catatan Rilis | Tautan Unduh |
| :--- | :--- | :--- | :--- | :--- |
| **Structora Android App** | `v1.1.0` | 🟢 Rilis Terbaru (Bug Fix) | Perbaikan bahasa campur (dwibahasa menyeluruh), sinkronisasi nilai 0 & chart grafik, Firestore fix, serta tombol publikasi materi ganda | [📥 **Download v1.1.0 APK**](https://github.com/syauqiyah/Structora/releases/download/v1.1.0/app-release.apk) |
| **Structora Android App** | `v1.0.0` | ⚪ Rilis Sebelumnya | Versi awal rilis stabil | [📥 **Download v1.0.0 APK**](https://github.com/syauqiyah/Structora/releases/download/v1.0.0/app-release.apk) |

---

## 🌟 Fitur Utama Aplikasi

### 👤 1. Portal Siswa (Student Portal)
- **Alur Pembelajaran Bertahap**: Membuka modul secara berurutan (*Pre-Test → Modul 1 → Modul 2 → Modul 3 → Modul 4 → Post-Test*) berdasarkan KKM nilai 80.
- **Materi Multi-Media**: Penjelasan teks terstruktur, video tutorial YouTube terintegrasi, dan kuis asesmen pada tiap modul.
- **Simulasi Lab 3D Interaktif**: Visualisasi 3D secara realtime untuk memahami cara kerja pointer Linked List, tumpukan Memory Stack, antrean Queue, serta animasi algoritma Searching & Sorting.
- **Sistem Ujian Terkunci (Anti-Cheating)**:
  - Deteksi pelanggaran otomatis jika siswa berpindah aplikasi saat ujian.
  - Timer hitung mundur (*countdown timer*).
  - Pengacakan butir soal & opsi jawaban dengan algoritma penyaring soal unik (tanpa soal ganda).
  - Lembar evaluasi dan pembetulan jawaban lengkap dengan pembahasan dinamis.

### 🏫 2. Portal Guru & LMS (Teacher Portal)
- **Dashboard Analitik Siswa Realtime**: Memantau perkembangan nilai seluruh siswa (*Pre-Test*, *Asesmen Modul 1–4*, *Post-Test*, dan status ketuntasan) secara *live* dari Firestore.
- **Manajemen Modul & Bank Soal (LMS)**:
  - Menambah, mengubah, dan menghapus modul pembelajaran secara dinamis.
  - **Fitur Auto-Import Naskah Soal**: Mengimpor soal secara otomatis dari teks berformat A–D.
  - Mendukung input dwibahasa (Bahasa Indonesia & Bahasa Inggris) untuk judul, deskripsi, dan pembahasan soal.

### 🌐 3. Fitur Dwibahasa Otomatis (Bilingual ID ⇄ EN)
- Pengalih bahasa instan (**ID ⇄ EN**) dengan *LanguageController*.
- Kamus penerjemah otomatis (*Auto-translation Dictionary*) yang mampu menerjemahkan konten dinamis rakitan guru secara otomatis jika versi Bahasa Inggris tidak diisi.

### ⚡ 4. Arsitektur Hybrid Offline-First & Cloud Firestore
- **Offline-First Caching**: Aplikasi dapat diakses secara cepat dengan penyimpanan lokal `SharedPreferences`.
- **Background Non-Blocking Sync**: Sinkronisasi data ke Cloud Firestore berjalan secara asinkron di latar belakang tanpa menghambat antarmuka pengguna (*UI*).

---

## 📚 Kurikulum Modul Pembelajaran

| Modul | Topik Pembelajaran | Fitur Interaktif |
| :--- | :--- | :--- |
| **Pre-Test** | Evaluasi Kemampuan Awal | 5 Butir Soal Acak Unik dari Bank Soal |
| **Modul 1** | Linked List (Singly, Doubly, Circular) | Simulasi 3D Node Pointer & Traversal |
| **Modul 2** | Stack (Tumpukan Data LIFO) | Simulasi Push, Pop, & Mechanism Undo/Redo |
| **Modul 3** | Queue (Antrean Terurut FIFO) | Simulasi Enqueue, Dequeue, & Print Spooler |
| **Modul 4** | Searching & Sorting Algorithm | Visualisasi Linear/Binary Search & Bubble/Selection Sort |
| **Post-Test**| Evaluasi Akhir Kelulusan | Ujian Komprehensif & Diagnostik Kelulusan |

---

## 🗄️ Struktur Database Cloud Firestore

Aplikasi terhubung ke Firebase Project `structo-b3429` dengan 3 koleksi utama:

1. **`users/{uid}`**:
   - `uid`, `email`, `name`, `role` (`student` / `teacher`), `isTeacher` (bool), `lastActive`.
2. **`materi/{materiId}`**:
   - `id`, `modul`, `modul_en`, `title`, `title_en`, `desc`, `desc_en`, `videoUrl`, `questions` (array soal dwibahasa).
3. **`student_progress/{emailClean}`**:
   - `name`, `email`, `preTest`, `assessment1..4`, `postTest`, `status`, `completedSteps`, `lastActive`.

---

## 🛠️ Teknologi & Library yang Digunakan

- **Framework**: [Flutter](https://flutter.dev) (Channel Stable v3.47.2)
- **Bahasa Pemrograman**: [Dart](https://dart.dev) (v3.13.2)
- **Backend & Database**:
  - `firebase_core: ^3.6.0`
  - `firebase_auth: ^5.3.1`
  - `cloud_firestore: ^5.4.4`
- **Penyimpanan Lokal**: `shared_preferences: ^2.5.3`
- **Media & Multimedia**:
  - `youtube_player_iframe: ^5.2.1`
  - `image_picker: ^1.2.1`
- **Notifikasi**: `flutter_local_notifications: ^18.0.1`

---

## 🚀 Cara Menjalankan Proyek di Lokal

### Prasyarat:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 atau lebih baru)
- [Android Studio](https://developer.android.com/studio) / VS Code
- [Java JDK 17 atau JDK 21](https://adoptium.net/)

### Langkah-Langkah:

1. **Clone Repositori**:
   ```bash
   git clone https://github.com/syauqiyah/Structora.git
   cd Structora
   ```

2. **Install Dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan Analisis Kode**:
   ```bash
   flutter analyze
   ```

4. **Jalankan Aplikasi**:
   - **Di Emulator Android**:
     ```bash
     flutter run -d emulator-5554
     ```
   - **Di Browser Chrome (Web)**:
     ```bash
     flutter run -d chrome
     ```

5. **Build APK Release**:
   ```bash
   flutter build apk --release
   ```
   *File APK Release akan dihasilkan di `build/app/outputs/flutter-apk/app-release.apk`.*

---

## 🔐 Akun Demo Akses Cepat

Untuk mencoba aplikasi tanpa perlu mendaftar email baru, gunakan tombol **Akses Demo**:

- **Portal Guru Demo**:
  - Email: `teacher.demo@structora.app`
  - Akses: Pengelolaan Modul, Bank Soal, & Monitoring Progres Siswa
- **Portal Siswa Demo**:
  - Email: `demo@structora.app`
  - Akses: Pengerjaan Pre-Test, Pembelajaran Modul 1–4, Simulasi 3D, & Post-Test

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License** — bebas digunakan dan dikembangkan untuk kepentingan pendidikan.
