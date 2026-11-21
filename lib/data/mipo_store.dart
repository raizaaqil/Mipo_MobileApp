import 'package:flutter/material.dart';

// ============================================================================
// DATA BERSAMA MIPO (sementara disimpan di memori)
//
// Satu tempat untuk jadwal, alarm, notes, tugas, dan file. Halaman yang
// memakainya otomatis ikut berubah saat datanya berubah (lewat addListener).
// Nanti isi file ini bisa diganti agar membaca dan menulis ke Supabase.
// ============================================================================

enum AlarmRepeat { once, daily, weekly }

DateTime _dOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _plusDays(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + n);
}

class ScheduleItem {
  final String title; // tag / nama kegiatan
  final String description; // keterangan
  final DateTime date;
  final TimeOfDay time;

  ScheduleItem({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });
}

class AlarmItem {
  final String title; // tag / nama alarm
  final DateTime date; // tanggal mulai
  final TimeOfDay time;
  final AlarmRepeat repeat;

  AlarmItem({
    required this.title,
    required this.date,
    required this.time,
    this.repeat = AlarmRepeat.once,
  });

  /// Apakah alarm ini berbunyi pada tanggal [day]?
  bool occursOn(DateTime day) {
    final start = _dOnly(date);
    final d = _dOnly(day);
    switch (repeat) {
      case AlarmRepeat.once:
        return d == start;
      case AlarmRepeat.daily:
        return !d.isBefore(start);
      case AlarmRepeat.weekly:
        return !d.isBefore(start) && d.weekday == start.weekday;
    }
  }
}

class NoteItem {
  final String title;
  final String content;

  NoteItem({required this.title, required this.content});
}

/// Tugas yang punya deadline.
class TaskRecord {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;

  TaskRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
  });
}

/// Foto atau dokumen yang pernah dikumpulkan.
class FileRecord {
  final String id;
  final String name;
  final String tag;
  final bool isPhoto;
  final DateTime date;

  FileRecord({
    required this.id,
    required this.name,
    required this.tag,
    required this.isPhoto,
    required this.date,
  });
}

class MipoStore extends ChangeNotifier {
  MipoStore._();

  static final MipoStore instance = MipoStore._();

  // DATA CONTOH: ganti dengan data asli nanti.
  final List<ScheduleItem> schedules = [
    ScheduleItem(
      title: 'Praktikum Multimedia',
      description: 'Bawa laptop dan kabel LAN',
      date: _plusDays(0),
      time: const TimeOfDay(hour: 8, minute: 0),
    ),
    ScheduleItem(
      title: 'Konsultasi dosen',
      description: 'Bawa draf laporan akhir',
      date: _plusDays(1),
      time: const TimeOfDay(hour: 13, minute: 0),
    ),
    ScheduleItem(
      title: 'Rapat kelompok',
      description: 'Bahas pembagian tugas animasi',
      date: _plusDays(2),
      time: const TimeOfDay(hour: 15, minute: 30),
    ),
    ScheduleItem(
      title: 'Seminar Kewirausahaan',
      description: 'Aula utama gedung B',
      date: _plusDays(4),
      time: const TimeOfDay(hour: 9, minute: 0),
    ),
    ScheduleItem(
      title: 'Kunjungan industri',
      description: 'Kumpul di parkiran kampus',
      date: _plusDays(9),
      time: const TimeOfDay(hour: 7, minute: 0),
    ),
    ScheduleItem(
      title: 'Presentasi proyek akhir',
      description: 'Siapkan slide dan demo aplikasi',
      date: _plusDays(14),
      time: const TimeOfDay(hour: 10, minute: 0),
    ),
  ];

  final List<AlarmItem> alarms = [
    AlarmItem(
      title: 'Bangun pagi',
      date: _plusDays(0),
      time: const TimeOfDay(hour: 5, minute: 30),
      repeat: AlarmRepeat.daily,
    ),
    AlarmItem(
      title: 'Berangkat kuliah',
      date: _plusDays(0),
      time: const TimeOfDay(hour: 7, minute: 0),
      repeat: AlarmRepeat.weekly,
    ),
    AlarmItem(
      title: 'Kerjakan laprak',
      date: _plusDays(0),
      time: const TimeOfDay(hour: 20, minute: 0),
    ),
    AlarmItem(
      title: 'Ingat rapat kelompok',
      date: _plusDays(2),
      time: const TimeOfDay(hour: 14, minute: 30),
    ),
  ];

  final List<NoteItem> notes = [
    NoteItem(
      title: 'Ide animasi 3D',
      content:
          'Karakter utama berupa gurita biru yang suka berpetualang. Tambahkan adegan bawah air dengan cahaya lembut dari atas.',
    ),
    NoteItem(
      title: 'Belanja kebutuhan kuliah',
      content: 'Kertas A3, tinta printer, dan flashdisk cadangan.',
    ),
    NoteItem(
      title: 'Catatan seminar',
      content:
          'Pembicara menekankan pentingnya validasi ide sebelum membuat produk. Cari contoh studi kasus untuk laporan.',
    ),
    NoteItem(
      title: 'Target minggu ini',
      content: 'Selesaikan laprak, mulai kerangka website, dan istirahat cukup.',
    ),
  ];

  final List<TaskRecord> tasks = [
    TaskRecord(
      id: 't1',
      title: 'Laprak Animasi 3D',
      description: 'Laporan praktikum animasi 3D dengan teknik edge modeling.',
      deadline: _plusDays(0),
    ),
    TaskRecord(
      id: 't2',
      title: 'Website Pemrograman',
      description: 'Desain dan pemrograman website memakai Visual Studio Code.',
      deadline: _plusDays(2),
    ),
    TaskRecord(
      id: 't3',
      title: 'Laporan Bisnis Kelompok',
      description: 'Menyusun laporan hasil usaha kelompok.',
      deadline: _plusDays(5),
    ),
    TaskRecord(
      id: 't4',
      title: 'Esai Kewirausahaan',
      description: 'Esai tentang peluang usaha di bidang kreatif, minimal 3 halaman.',
      deadline: _plusDays(12),
    ),
  ];

  final List<FileRecord> files = [
    FileRecord(id: 'p1', name: 'Sketsa karakter', tag: 'Tugas', isPhoto: true, date: _plusDays(0)),
    FileRecord(id: 'p2', name: 'Hasil render awal', tag: 'Tugas', isPhoto: true, date: _plusDays(0)),
    FileRecord(id: 'p3', name: 'Foto kehadiran praktikum', tag: 'Kegiatan', isPhoto: true, date: _plusDays(-1)),
    FileRecord(id: 'p4', name: 'Poster seminar', tag: 'Kegiatan', isPhoto: true, date: _plusDays(-3)),
    FileRecord(id: 'p5', name: 'Desain halaman Home', tag: 'Tugas', isPhoto: true, date: _plusDays(-3)),
    FileRecord(id: 'p6', name: 'Foto kunjungan industri', tag: 'Kegiatan', isPhoto: true, date: _plusDays(-6)),
    FileRecord(id: 'p7', name: 'Papan tulis rapat', tag: 'Kegiatan', isPhoto: true, date: _plusDays(-8)),
    FileRecord(id: 'p8', name: 'Wireframe website', tag: 'Tugas', isPhoto: true, date: _plusDays(-8)),
    FileRecord(id: 'p9', name: 'Prototipe aplikasi', tag: 'Tugas', isPhoto: true, date: _plusDays(-8)),
    FileRecord(id: 'd1', name: 'Laprak Animasi 3D.pdf', tag: 'Tugas', isPhoto: false, date: _plusDays(0)),
    FileRecord(id: 'd2', name: 'Catatan Seminar.docx', tag: 'Kegiatan', isPhoto: false, date: _plusDays(-3)),
    FileRecord(id: 'd3', name: 'Laporan Bisnis.pdf', tag: 'Tugas', isPhoto: false, date: _plusDays(-5)),
    FileRecord(id: 'd4', name: 'Esai Kewirausahaan.docx', tag: 'Tugas', isPhoto: false, date: _plusDays(-8)),
    FileRecord(id: 'd5', name: 'Jadwal Praktikum.pdf', tag: 'Kegiatan', isPhoto: false, date: _plusDays(-12)),
    FileRecord(id: 'd6', name: 'Proposal Proyek.pdf', tag: 'Tugas', isPhoto: false, date: _plusDays(-20)),
  ];

  void addSchedule(ScheduleItem item) {
    schedules.add(item);
    notifyListeners();
  }

  void addSchedules(Iterable<ScheduleItem> items) {
    schedules.addAll(items);
    notifyListeners();
  }

  void addAlarm(AlarmItem item) {
    alarms.add(item);
    notifyListeners();
  }

  void addNote(NoteItem item) {
    notes.add(item);
    notifyListeners();
  }
}
