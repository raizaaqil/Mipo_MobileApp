/// Validasi sederhana. Mengembalikan kunci teks error (AppStrings) atau null jika valid.
class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String v) {
    if (v.trim().isEmpty) return 'err_required';
    if (!_email.hasMatch(v.trim())) return 'err_email_invalid';
    return null;
  }

  static String? password(String v) {
    if (v.isEmpty) return 'err_required';
    if (v.length < 6) return 'err_password_short';
    return null;
  }

  static String? required(String v) => v.trim().isEmpty ? 'err_required' : null;

  static String? age(String v) {
    if (v.trim().isEmpty) return 'err_required';
    final n = int.tryParse(v.trim());
    if (n == null || n < 5 || n > 100) return 'err_age_invalid';
    return null;
  }
}
