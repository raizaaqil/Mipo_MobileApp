import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Semua teks aplikasi (Indonesia / Inggris) ada di sini.
/// Pakai di dalam build():  context.tr('login')
/// Pakai di dalam fungsi onTap/async:  context.trNow('login')
class AppStrings {
  static String get(String lang, String key) {
    final map = lang == 'en' ? _en : _id;
    return map[key] ?? _id[key] ?? key;
  }

  static const Map<String, String> _id = {
    // Umum
    'ok': 'OK',
    'save': 'Simpan',
    'cancel': 'Batal',
    'yes': 'Ya',
    'loading': 'Memuat...',
    'retry': 'Coba lagi',
    // Welcome
    'welcome_headline': 'Halo, selamat datang!',
    'welcome_tagline': 'Pengingat tugas dan pengatur waktu belajarmu, ditemani Mipo.',
    'choose_language': 'Pilih bahasa',
    'login': 'Masuk',
    'register': 'Daftar',
    // Auth
    'email': 'Email',
    'password': 'Kata sandi',
    'forgot_password': 'Lupa kata sandi?',
    'no_account': 'Belum punya akun?',
    'have_account': 'Sudah punya akun?',
    'name': 'Nama',
    'age': 'Umur',
    'education': 'Jenjang pendidikan',
    'next': 'Lanjut',
    'pet_profile': 'Profil Pet',
    'pet_name': 'Nama Pet',
    'pet_hint': 'Beri nama untuk ubur-ubur kecilmu',
    'forgot_title': 'Lupa Kata Sandi',
    'forgot_hint': 'Masukkan email akunmu. Kami kirim tautan untuk mengatur ulang kata sandi.',
    'send_link': 'Kirim tautan',
    'email_sent': 'Email terkirim! Cek kotak masukmu.',
    'confirm_email_info': 'Akun dibuat! Cek emailmu untuk konfirmasi, lalu masuk.',
    // Error
    'err_required': 'Wajib diisi',
    'err_email_invalid': 'Format email belum benar',
    'err_password_short': 'Kata sandi minimal 6 karakter',
    'err_age_invalid': 'Masukkan umur yang valid (5-100)',
    'err_invalid_credentials': 'Email atau kata sandi salah',
    'err_email_taken': 'Email ini sudah terdaftar',
    'err_email_not_confirmed': 'Email belum dikonfirmasi. Cek kotak masukmu.',
    'err_network': 'Tidak ada koneksi internet. Coba lagi.',
    'err_rate_limit': 'Terlalu banyak percobaan. Tunggu sebentar.',
    'err_generic': 'Terjadi kesalahan. Coba lagi.',
    'err_password_mismatch': 'Konfirmasi kata sandi tidak sama',
    'err_old_password_wrong': 'Kata sandi lama salah',
    'err_same_password': 'Kata sandi baru harus berbeda dari yang lama',
    // Sidebar
    'hello': 'Halo,',
    'menu_profile': 'Profil',
    'menu_setting': 'Pengaturan',
    'menu_help': 'Bantuan',
    'menu_about': 'Tentang',
    // Settings
    'setting': 'Pengaturan',
    'account': 'Akun',
    'notification': 'Notifikasi',
    'display': 'Tampilan',
    'privacy': 'Privasi',
    'language': 'Bahasa',
    'logout': 'Keluar',
    'notif_on': 'Aktifkan notifikasi',
    'dark_mode': 'Mode gelap',
    'dark_mode_note': 'Karakter Pet tetap memakai warna aslinya.',
    'old_password': 'Kata sandi lama',
    'new_password': 'Kata sandi baru',
    'confirm_password': 'Konfirmasi kata sandi baru',
    'password_changed': 'Kata sandi berhasil diubah',
    'logout_confirm': 'Yakin mau keluar dari akun?',
    'settings_saved': 'Pengaturan disimpan',
    'delete_account': 'Hapus akun',
    'delete_confirm': 'Akun dan semua datamu akan dihapus permanen. Lanjutkan?',
    'profile_saved': 'Profil diperbarui',
    'profile': 'Profil',
    'edit': 'Ubah',
    'email_readonly': 'Email tidak bisa diubah',
  };

  static const Map<String, String> _en = {
    'ok': 'OK',
    'save': 'Save',
    'cancel': 'Cancel',
    'yes': 'Yes',
    'loading': 'Loading...',
    'retry': 'Try again',
    'welcome_headline': 'Hi, welcome!',
    'welcome_tagline': 'Your task reminder and study-time planner, with Mipo by your side.',
    'choose_language': 'Choose language',
    'login': 'Log in',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'no_account': "Don't have an account?",
    'have_account': 'Already have an account?',
    'name': 'Name',
    'age': 'Age',
    'education': 'Education level',
    'next': 'Next',
    'pet_profile': 'Pet Profile',
    'pet_name': 'Pet name',
    'pet_hint': 'Give your little jellyfish a name',
    'forgot_title': 'Forgot Password',
    'forgot_hint': "Enter your account email. We'll send a link to reset your password.",
    'send_link': 'Send link',
    'email_sent': 'Email sent! Check your inbox.',
    'confirm_email_info': 'Account created! Check your email to confirm, then log in.',
    'err_required': 'Required',
    'err_email_invalid': 'Email format looks wrong',
    'err_password_short': 'Password must be at least 6 characters',
    'err_age_invalid': 'Enter a valid age (5-100)',
    'err_invalid_credentials': 'Wrong email or password',
    'err_email_taken': 'This email is already registered',
    'err_email_not_confirmed': 'Email not confirmed yet. Check your inbox.',
    'err_network': 'No internet connection. Please try again.',
    'err_rate_limit': 'Too many attempts. Please wait a moment.',
    'err_generic': 'Something went wrong. Please try again.',
    'err_password_mismatch': "Password confirmation doesn't match",
    'err_old_password_wrong': 'Old password is incorrect',
    'err_same_password': 'New password must be different from the old one',
    'hello': 'Hi,',
    'menu_profile': 'Profile',
    'menu_setting': 'Settings',
    'menu_help': 'Help',
    'menu_about': 'About',
    'setting': 'Settings',
    'account': 'Account',
    'notification': 'Notification',
    'display': 'Display',
    'privacy': 'Privacy',
    'language': 'Language',
    'logout': 'Log out',
    'notif_on': 'Turn on notifications',
    'dark_mode': 'Dark mode',
    'dark_mode_note': 'The Pet character keeps its original colors.',
    'old_password': 'Old password',
    'new_password': 'New password',
    'confirm_password': 'Confirm new password',
    'password_changed': 'Password changed successfully',
    'logout_confirm': 'Are you sure you want to log out?',
    'settings_saved': 'Settings saved',
    'delete_account': 'Delete account',
    'delete_confirm': 'Your account and all your data will be permanently deleted. Continue?',
    'profile_saved': 'Profile updated',
    'profile': 'Profile',
    'edit': 'Edit',
    'email_readonly': 'Email cannot be changed',
  };
}

extension TrContext on BuildContext {
  /// Dipakai di dalam build(): otomatis ikut berubah saat bahasa diganti.
  String tr(String key) =>
      AppStrings.get(Provider.of<SettingsProvider>(this).language, key);

  /// Dipakai di callback (onTap, async): hanya membaca bahasa saat ini.
  String trNow(String key) =>
      AppStrings.get(Provider.of<SettingsProvider>(this, listen: false).language, key);
}
