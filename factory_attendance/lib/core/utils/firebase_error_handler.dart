import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class FirebaseErrorHandler {
  /// Menerjemahkan Exception standar/Firebase menjadi pesan bahasa Indonesia 
  /// yang user-friendly untuk ditampilkan di UI.
  static String getMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'network-request-failed':
          return 'Koneksi internet terganggu, silakan coba lagi.';
        case 'permission-denied':
          return 'Anda tidak memiliki akses untuk memuat data ini.';
        case 'quota-exceeded':
          return 'Sistem sedang padat (kuota habis), silakan coba beberapa saat lagi.';
        case 'not-found':
          return 'Data yang Anda cari tidak ditemukan.';
        case 'deadline-exceeded':
          return 'Waktu permintaan habis (timeout). Pastikan internet Anda stabil.';
        default:
          return 'Terjadi gangguan sistem (${error.code}). Silakan coba lagi nanti.';
      }
    } else if (error is SocketException) {
      // Menangkap error jaringan standar bawaan Dart
      return 'Tidak ada koneksi internet. Pastikan WiFi atau Data Seluler Anda aktif.';
    }
    
    // Fallback jika tipe error tidak diketahui
    return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
  }
}
