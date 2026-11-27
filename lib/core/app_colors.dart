import 'package:flutter/material.dart';

/// Warna aplikasi. Warna di bawah ini OTOMATIS berubah mengikuti mode
/// terang / gelap (lewat [AppColors.dark], diatur oleh SettingsProvider).
/// Karena nilainya berubah, jangan dipakai di dalam `const` widget.
class AppColors {
  /// true = mode gelap. Diatur oleh SettingsProvider, jangan diubah manual.
  static bool dark = false;

  static Color _pick(int light, int night) => Color(dark ? night : light);

  // Latar Belakang & Teks
  static Color get baseBg => _pick(0xFFFFFAEB, 0xFF1D2A3C);
  static Color get textDark => _pick(0xFF364A6B, 0xFFE8EFF8);
  static Color get white => surface;

  // Palette Biru (Primer, Sekunder, Tersier)
  static Color get primer => _pick(0xFFCAE7FF, 0xFF2B3E58);
  static Color get sekunder => _pick(0xFFAED8FF, 0xFF3B5475);
  static Color get tersier => _pick(0xFF69AADC, 0xFF7DB6EA);

  // Warna yang dipakai berulang di halaman Figma
  static Color get pageBg => _pick(0xFFE8F3FF, 0xFF141C29);
  static Color get primaryBlue => _pick(0xFF5B9EE1, 0xFF7DB6EA);
  static Color get btnLight => _pick(0xFFCBE5FF, 0xFF2B3E58);
  static Color get iconBg => _pick(0xFFD8ECFF, 0xFF24344B);

  // Permukaan kartu / panel (putih di mode terang) dan teks di atasnya
  static Color get surface => _pick(0xFFFFFFFF, 0xFF1D2A3C);
  static Color get onAccent => _pick(0xFFFFFFFF, 0xFF0F1A2A);
  static Color get softBorder => _pick(0xFFE3F1FF, 0xFF2E435F);
  static Color get softFill => _pick(0xFFF3F8FE, 0xFF24344B);

  // Warna urgensi (Pet, garis kartu tugas, penanda kalender) - sama di kedua mode
  static const Color urgencyCalm = Color(0xFF8FAED6);  // tenang / aman
  static const Color urgencyAlert = Color(0xFFF2D27A); // waspada H-5
  static const Color urgencyWorry = Color(0xFFEBA16F); // khawatir H-3..H-2
  static const Color urgencyPanic = Color(0xFFDF8585); // panik, hari H / lewat
  static const Color doneGrey = Color(0xFFB8BEC8);     // tugas selesai

  // Warna Dark Mode tambahan (milikmu, tidak dipakai di kode lain)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkText = Color(0xFFF1F5F9);
}
