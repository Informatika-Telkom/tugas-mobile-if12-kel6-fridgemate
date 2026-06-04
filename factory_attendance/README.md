# Factory Attendance App 🏭

Aplikasi Flutter untuk sistem absensi karyawan pabrik yang dilengkapi dengan fitur-fitur canggih seperti autentikasi, deteksi wajah, pelacakan lokasi (Geotagging), dan notifikasi terintegrasi dengan Firebase.

## 🚀 Fitur Utama (Features)

Tugas ini mengimplementasikan beberapa fitur utama, di antaranya:
1. **Autentikasi (Authentication)**: Login dan manajemen sesi pengguna.
2. **Absensi dengan Kamera (Camera & ML Kit)**: Mengambil foto absensi secara real-time dan mendeteksi wajah menggunakan `google_mlkit_face_detection` untuk memvalidasi absensi.
3. **Pelacakan Lokasi (Geolocation)**: Mengambil titik koordinat pengguna (Latitude & Longitude) saat melakukan absensi menggunakan package `geolocator` untuk memastikan karyawan berada di lokasi yang tepat.
4. **Penyimpanan Cloud (Firebase)**: 
   - Menyimpan data absensi (waktu, lokasi, dll) ke dalam **Cloud Firestore**.
   - Mengunggah foto bukti absensi ke **Firebase Storage**.
5. **Notifikasi Push (Firebase Cloud Messaging)**: Memberikan notifikasi langsung ke perangkat (contoh: notifikasi pengingat absensi atau konfirmasi absensi berhasil).
6. **State Management**: Menggunakan `Provider` (seperti `AuthProvider` dan `AttendanceProvider`) untuk memisahkan logika bisnis dari tampilan antarmuka (UI).

## 🛠️ Teknologi yang Digunakan
- **Framework**: Flutter & Dart
- **Arsitektur**: MVVM (Model-View-ViewModel) dengan `Provider`
- **Backend / BaaS**: Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **Library Tambahan**: 
  - `camera` (Akses kamera)
  - `google_mlkit_face_detection` (Deteksi wajah)
  - `geolocator` (Akses GPS)
  - `flutter_local_notifications` (Notifikasi lokal)
  - `flutter_dotenv` (Manajemen environment variable)

## 📂 Struktur Folder Utama
- `lib/core/` : Berisi konfigurasi dasar, tema warna, dan service pendukung (seperti `notification_service.dart`).
- `lib/data/` : Berisi implementasi repository untuk mengambil/menyimpan data (contoh: `attendance_repository_impl.dart`).
- `lib/presentation/` : Berisi tampilan UI (Screens) dan logika State Management (Providers).

## 🏃 Cara Menjalankan Project

1. **Clone repositori ini**:
   ```bash
   git clone <url-repo>
   ```
2. **Masuk ke folder project**:
   ```bash
   cd factory_attendance
   ```
3. **Unduh semua dependency**:
   ```bash
   flutter pub get
   ```
4. **Konfigurasi Firebase**:
   Pastikan Anda sudah memiliki file `google-services.json` (untuk Android) di folder `android/app/` dan file `.env` di root folder.
5. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

---
*Dibuat untuk memenuhi tugas Mobile App Development.*
