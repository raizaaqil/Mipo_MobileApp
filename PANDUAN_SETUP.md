# Panduan Setup MiPo (Tahap 1 dan 2)

Ikuti urutannya. Totalnya sekitar 15 menit.

## 1. Pasang paket baru
Di terminal, dari folder proyek:

```
flutter pub get
```

## 2. Buat project Supabase (gratis)
1. Buka https://supabase.com, klik **Start your project**, masuk dengan GitHub atau email.
2. Klik **New project**. Isi nama (misalnya `mipo`), buat **Database Password** dan simpan di tempat aman, pilih region **Southeast Asia (Singapore)**, lalu **Create new project**. Tunggu 1 sampai 2 menit sampai selesai.

## 3. Buat tabel profil
1. Di menu kiri pilih **SQL Editor** lalu **New query**.
2. Buka file `supabase/01_profiles.sql` di proyek ini, salin seluruh isinya, tempel di editor, lalu klik **Run**.
3. Harus muncul **Success. No rows returned**.

File ini membuat tabel `profiles` (nama, umur, jenjang pendidikan, nama Pet, bahasa, mode gelap, notifikasi) dan aturan keamanan supaya tiap akun hanya bisa melihat dan mengubah datanya sendiri.

## 4. Matikan konfirmasi email (untuk masa pengembangan)
Supaya akun yang baru didaftarkan bisa langsung dipakai tanpa klik tautan di email:

**Authentication > Sign In / Providers > Email**, matikan **Confirm email**, lalu **Save**.

Kalau dibiarkan menyala, setelah daftar kamu harus membuka email konfirmasi dulu sebelum bisa masuk. Aplikasinya sudah menangani kasus ini dan menampilkan pesan pemberitahuan.

## 5. Salin URL dan kunci
1. Buka **Project Settings** (ikon gigi) lalu **API Keys** / **API**.
2. Salin **Project URL**.
3. Salin kunci **anon** (atau **publishable**). **Jangan** pakai kunci `service_role`, itu rahasia.
4. Buka `lib/core/supabase_config.dart` dan ganti dua nilai `GANTI_DENGAN_...` dengan salinan tadi.

## 6. Jalankan
```
flutter run
```
Kalau URL dan kunci belum diisi, aplikasi menampilkan layar "Supabase belum disiapkan", bukan crash.

## 7. Cek apakah sudah benar
- Welcome muncul, ganti bahasa Indonesia/English, teksnya langsung berubah.
- Daftar akun baru (2 langkah), setelah itu langsung masuk ke Home.
- Tutup aplikasi sepenuhnya lalu buka lagi: langsung ke Home (sesi tersimpan).
- Home > ikon menu: sidebar muncul, buka Settings.
- Display: aktifkan Mode Gelap, simpan. Halaman Settings dan sidebar ikut gelap.
- Privacy: ganti kata sandi, lalu Log Out dan masuk dengan kata sandi baru.
- Log Out: kembali ke Welcome.
- Daftar akun kedua di perangkat yang sama: pengaturannya terpisah dari akun pertama.
- Di dashboard: **Table Editor > profiles** menampilkan satu baris per akun.

## Masalah umum
| Gejala | Penyebab / solusi |
|---|---|
| Layar "Supabase belum disiapkan" | `supabase_config.dart` belum diisi. |
| "Invalid API key" | Kunci salah salin, atau memakai kunci `service_role`. |
| Daftar berhasil tapi profil kosong / error | SQL di langkah 3 belum dijalankan. Jalankan ulang. |
| "Email belum dikonfirmasi" | Langkah 4 belum dilakukan. |
| "Tidak ada koneksi internet" di emulator | Cek koneksi emulator. Di perangkat asli pastikan internet aktif. |
| Hapus akun gagal | Pastikan fungsi `delete_my_account` di SQL berhasil dibuat. |

## Yang belum ada di tahap ini
- Notifikasi baru tersimpan sebagai pengaturan ON/OFF. Pengingat sungguhan dibuat bersama Alarm di tahap Calendar.
- Tautan "Lupa kata sandi" mengirim email reset. Membuka tautan itu di dalam aplikasi (deep link) belum dipasang.
- Foto profil dan upload file menyusul di tahap File dan Kamera.
- Mode gelap baru berlaku di halaman yang sudah dirombak (Welcome, Login, Register, Sidebar, Settings, Profil). Halaman lain mengikuti saat tiap halaman dikerjakan.
