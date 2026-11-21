import 'package:flutter_test/flutter_test.dart';
import 'package:mipo_aplikasi/core/app_strings.dart';
import 'package:mipo_aplikasi/core/validators.dart';

void main() {
  test('Validator email menolak format yang salah', () {
    expect(Validators.email(''), 'err_required');
    expect(Validators.email('gita@'), 'err_email_invalid');
    expect(Validators.email('gita@mail.com'), isNull);
  });

  test('Validator password minimal 6 karakter', () {
    expect(Validators.password('12345'), 'err_password_short');
    expect(Validators.password('123456'), isNull);
  });

  test('Validator umur harus 5 sampai 100', () {
    expect(Validators.age('3'), 'err_age_invalid');
    expect(Validators.age('20'), isNull);
  });

  test('Teks tersedia dalam Indonesia dan Inggris', () {
    expect(AppStrings.get('id', 'login'), 'Masuk');
    expect(AppStrings.get('en', 'login'), 'Log in');
  });
}