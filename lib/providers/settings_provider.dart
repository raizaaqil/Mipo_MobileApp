import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pengaturan: bahasa, mode gelap, notifikasi.
/// Disimpan di perangkat (cepat, dipakai sebelum login) dan di tabel
/// `profiles` Supabase (permanen per akun, ikut pindah ke perangkat lain).
class SettingsProvider extends ChangeNotifier {
  static const _kLang = 'settings.language';
  static const _kDark = 'settings.dark_mode';
  static const _kNotif = 'settings.notifications';

  SharedPreferences? _prefs;
  String _language = 'id';
  bool _darkMode = false;
  bool _notifications = true;

  String get language => _language;
  bool get darkMode => _darkMode;
  bool get notifications => _notifications;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _language = _prefs!.getString(_kLang) ?? (deviceLang == 'id' ? 'id' : 'en');
    _darkMode = _prefs!.getBool(_kDark) ?? false;
    _notifications = _prefs!.getBool(_kNotif) ?? true;
  }

  Future<void> setLanguage(String code) async {
    if (code != 'id' && code != 'en') return;
    _language = code;
    notifyListeners();
    await _prefs?.setString(_kLang, code);
    await _syncRemote();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _prefs?.setBool(_kDark, value);
    await _syncRemote();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    await _prefs?.setBool(_kNotif, value);
    await _syncRemote();
  }

  /// Dipanggil setelah login: pengaturan milik akun menggantikan yang di perangkat.
  void applyRemote(Map<String, dynamic> row) {
    final lang = row['language'];
    if (lang == 'id' || lang == 'en') _language = lang as String;
    if (row['dark_mode'] is bool) _darkMode = row['dark_mode'] as bool;
    if (row['notifications_enabled'] is bool) {
      _notifications = row['notifications_enabled'] as bool;
    }
    _prefs?.setString(_kLang, _language);
    _prefs?.setBool(_kDark, _darkMode);
    _prefs?.setBool(_kNotif, _notifications);
    notifyListeners();
  }

  Future<void> _syncRemote() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('profiles').update({
        'language': _language,
        'dark_mode': _darkMode,
        'notifications_enabled': _notifications,
      }).eq('id', user.id);
    } catch (_) {
      // Tidak ada internet: nilai tetap tersimpan di perangkat dan
      // akan disinkronkan lagi pada perubahan berikutnya.
    }
  }
}
