import 'package:flutter/material.dart';

class AppColors {
  // Latar Belakang & Teks
  static const Color baseBg = Color(0xFFFFFAEB);     // #FFFAEB - Cream
  static const Color textDark = Color(0xFF364A6B);   // #364A6B - Navy Gelap
  static const Color white = Color(0xFFFFFFFF);      // #FFFFFF - Putih

  // Palette Biru (Primer, Sekunder, Tersier)
  static const Color primer = Color(0xFFCAE7FF);     // #CAE7FF - Tabel BG 1
  static const Color sekunder = Color(0xFFAED8FF);   // #AED8FF - Tabel BG 2
  static const Color tersier = Color(0xFF69AADC);    // #69AADC - UI / Aksen

  // Warna yang dipakai berulang di halaman Figma
  static const Color pageBg = Color(0xFFE8F3FF);
  static const Color primaryBlue = Color(0xFF5B9EE1);
  static const Color btnLight = Color(0xFFCBE5FF);
  static const Color iconBg = Color(0xFFD8ECFF);

  // Warna urgensi (Pet, garis kartu tugas, penanda kalender)
  static const Color urgencyCalm = Color(0xFF8FAED6);  // tenang / aman
  static const Color urgencyAlert = Color(0xFFF2D27A); // waspada H-5
  static const Color urgencyWorry = Color(0xFFEBA16F); // khawatir H-3..H-2
  static const Color urgencyPanic = Color(0xFFDF8585); // panik, hari H / lewat
  static const Color doneGrey = Color(0xFFB8BEC8);     // tugas selesai

  // Warna Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkText = Color(0xFFF1F5F9);
}
