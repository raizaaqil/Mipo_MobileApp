import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/mipo_octopus.dart';
import '../widgets/tap_scale.dart';

// ============================================================================
// DATA
// (Sementara disimpan di memori. Nanti disambungkan ke database.)
// ============================================================================

/// Dipakai untuk tugas maupun kegiatan.
class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
  });
}

enum _DetailAction { camera, file, delete }

// ============================================================================
// WARNA URGENSI (sama dengan Home dan Calendar)
// ============================================================================

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _inDays(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + n);
}

enum _Urgency { calm, alert, worry, panic }

int _daysLeft(DateTime deadline) =>
    _dateOnly(deadline).difference(_dateOnly(DateTime.now())).inDays;

/// Biru: masih jauh | Kuning: H-5..H-4 | Oranye: H-3..H-1 | Merah: hari H / lewat
_Urgency _urgencyOf(DateTime deadline) {
  final days = _daysLeft(deadline);
  if (days <= 0) return _Urgency.panic;
  if (days <= 3) return _Urgency.worry;
  if (days <= 5) return _Urgency.alert;
  return _Urgency.calm;
}

Color _urgencyColor(_Urgency u) {
  switch (u) {
    case _Urgency.calm:
      return AppColors.urgencyCalm;
    case _Urgency.alert:
      return AppColors.urgencyAlert;
    case _Urgency.worry:
      return AppColors.urgencyWorry;
    case _Urgency.panic:
      return AppColors.urgencyPanic;
  }
}

String _deadlineLabel(DateTime deadline) {
  final days = _daysLeft(deadline);
  if (days < 0) return 'Lewat ${-days} hari';
  if (days == 0) return 'Hari ini';
  if (days == 1) return 'Besok';
  return 'H-$days';
}

// ============================================================================
// GAYA BERSAMA (satu font: Huninn, dibedakan lewat ketebalan saja)
// ============================================================================

TextStyle _text(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Huninn',
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textDark,
  );
}

const _softBorder = Color(0xFFE3F1FF);
const _fieldBg = Color(0xFFF3F8FE);

List<BoxShadow> _blueShadow({double blur = 16, double dy = 4, double alpha = 0.45}) {
  return [
    BoxShadow(
      color: AppColors.sekunder.withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _fullDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

// ============================================================================
// HALAMAN VIRTUAL PET
// ============================================================================

class VirtualPetView extends StatefulWidget {
  const VirtualPetView({super.key});

  @override
  State<VirtualPetView> createState() => _VirtualPetViewState();
}

class _VirtualPetViewState extends State<VirtualPetView> {
  // DATA CONTOH: ganti dengan data asli nanti.
  final List<TaskItem> _tasks = [
    TaskItem(
      id: 't1',
      title: 'Laprak Animasi 3D',
      description:
          'Mengerjakan laporan praktikum animasi 3D, membuat karakter dengan teknik edge modeling.',
      deadline: _inDays(0),
    ),
    TaskItem(
      id: 't2',
      title: 'Website Pemrograman',
      description:
          'Mengerjakan desain dan pemrograman web, membuat website memakai Visual Studio Code.',
      deadline: _inDays(2),
    ),
    TaskItem(
      id: 't3',
      title: 'Laporan Bisnis Kelompok',
      description:
          'Menjalankan usaha kelompok dan menyusun laporan hasil usahanya.',
      deadline: _inDays(5),
    ),
    TaskItem(
      id: 't4',
      title: 'Esai Kewirausahaan',
      description: 'Menulis esai tentang peluang usaha di bidang kreatif, minimal 3 halaman.',
      deadline: _inDays(12),
    ),
  ];

  final List<TaskItem> _activities = [
    TaskItem(
      id: 'a1',
      title: 'Praktikum Multimedia',
      description: 'Bawa laptop dan kabel LAN. Foto bukti kehadiran saat selesai.',
      deadline: _inDays(1),
    ),
    TaskItem(
      id: 'a2',
      title: 'Rapat kelompok',
      description: 'Membahas pembagian tugas animasi dan jadwal pengerjaan.',
      deadline: _inDays(3),
    ),
    TaskItem(
      id: 'a3',
      title: 'Seminar Kewirausahaan',
      description: 'Aula utama gedung B. Catat poin penting untuk laporan.',
      deadline: _inDays(6),
    ),
    TaskItem(
      id: 'a4',
      title: 'Kunjungan industri',
      description: 'Kumpul di parkiran kampus pukul 07.00, memakai almamater.',
      deadline: _inDays(9),
    ),
  ];

  // Perayaan singkat setelah menyelesaikan sesuatu.
  String? _celebration;
  Timer? _celebrationTimer;

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // EMOSI PET: ditentukan oleh item yang paling mendesak
  // --------------------------------------------------------------------------
  List<TaskItem> get _pending => [..._tasks, ..._activities];

  _Urgency? get _mostUrgent {
    final list = _pending;
    if (list.isEmpty) return null;
    final nearest = list.reduce((a, b) => a.deadline.isBefore(b.deadline) ? a : b);
    return _urgencyOf(nearest.deadline);
  }

  PetMood get _mood {
    if (_celebration != null) return PetMood.happy;
    switch (_mostUrgent) {
      case null:
        return PetMood.happy;
      case _Urgency.panic:
        return PetMood.panic;
      case _Urgency.worry:
        return PetMood.worried;
      case _Urgency.alert:
      case _Urgency.calm:
        return PetMood.calm;
    }
  }

  String get _message {
    if (_celebration != null) return _celebration!;
    switch (_mostUrgent) {
      case null:
        return 'Semua beres! Mipo senang sekali, kamu hebat!';
      case _Urgency.panic:
        final n = _pending.where((e) => _urgencyOf(e.deadline) == _Urgency.panic).length;
        return n > 1
            ? 'Ada $n yang deadline-nya hari ini atau sudah lewat. Yuk kumpulkan sekarang!'
            : 'Ada yang deadline-nya hari ini atau sudah lewat. Yuk kumpulkan sekarang!';
      case _Urgency.worry:
        return 'Deadline-nya tinggal sebentar lagi, Mipo jadi cemas. Ayo mulai dikerjakan!';
      case _Urgency.alert:
        return 'Ada yang mulai mendekati deadline. Cicil pelan-pelan ya!';
      case _Urgency.calm:
        return 'Semuanya masih aman. Tetap semangat ya!';
    }
  }

  Color get _accent {
    final u = _mostUrgent;
    if (_celebration != null || u == null) return AppColors.tersier;
    return _urgencyColor(u);
  }

  // --------------------------------------------------------------------------
  // AKSI: selesai / buang
  // --------------------------------------------------------------------------
  void _complete(TaskItem item, {required bool isTask}) {
    setState(() {
      (isTask ? _tasks : _activities).removeWhere((e) => e.id == item.id);
      _celebration = 'Yay! "${item.title}" selesai. Mipo senang sekali!';
    });
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _celebration = null);
    });
    _toast(isTask ? 'Tugas berhasil dikumpulkan' : 'Kegiatan berhasil diselesaikan');
  }

  void _remove(TaskItem item, {required bool isTask}) {
    setState(() {
      (isTask ? _tasks : _activities).removeWhere((e) => e.id == item.id);
    });
    _toast(isTask ? 'Tugas dibuang' : 'Kegiatan dibuang');
  }

  Future<void> _openDetail(TaskItem item, {required bool isTask}) async {
    final action = await _showFloating<_DetailAction>(
      _ItemDetail(item: item, isTask: isTask),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _DetailAction.camera:
        await _openCamera(item, isTask: isTask);
      case _DetailAction.file:
        await _pickFile(item, isTask: isTask);
      case _DetailAction.delete:
        final ok = await _showFloating<bool>(
          _ConfirmDelete(item: item, isTask: isTask),
        );
        if (ok == true && mounted) _remove(item, isTask: isTask);
    }
  }

  Future<void> _pickFile(TaskItem item, {required bool isTask}) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (!mounted) return;
      if (result != null) _complete(item, isTask: isTask);
    } catch (_) {
      if (mounted) _toast('File tidak bisa dibuka');
    }
  }

  Future<void> _openCamera(TaskItem item, {required bool isTask}) async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        _toast('Kamera tidak ditemukan');
        return;
      }
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => CameraScreen(camera: cameras.first)),
      );
      if (!mounted) return;
      if (result == true) _complete(item, isTask: isTask);
    } catch (_) {
      if (mounted) _toast('Kamera tidak bisa dibuka');
    }
  }

  // --------------------------------------------------------------------------
  // POPUP MELAYANG & TOAST
  // --------------------------------------------------------------------------
  Future<T?> _showFloating<T>(Widget child) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, _, __) => SafeArea(
        child: Center(
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: _text(13, weight: FontWeight.w600, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.tersier,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // Urutkan dari deadline paling dekat ke paling jauh.
    final tasks = [..._tasks]..sort((a, b) => a.deadline.compareTo(b.deadline));
    final activities = [..._activities]..sort((a, b) => a.deadline.compareTo(b.deadline));

    // Tinggi blok atas dibuat tetap supaya panel putih di bawahnya bisa
    // dihitung pasti dan selalu sampai ujung bawah layar.
    // 72 = header, 290 = area Mipo + bubble chat.
    const headerHeight = 72.0;
    const petHeight = 290.0;
    final used = media.padding.top + headerHeight + petHeight;
    final panelMinHeight = media.size.height > used ? media.size.height - used : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildPetSection(petHeight),
              _buildPanel(panelMinHeight, media.padding.bottom, tasks, activities),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            TapScale(
              pressedScale: 0.9,
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _softBorder, width: 1.2),
                  boxShadow: _blueShadow(),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.tersier,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PET + BUBBLE CHAT (mengikuti urgensi)
  // --------------------------------------------------------------------------
  Widget _buildPetSection(double height) {
    final message = _message;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          MipoOctopus(size: 156, interactive: true, mood: _mood),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(message),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _accent, width: 1.6),
                boxShadow: _blueShadow(blur: 12, dy: 3, alpha: 0.35),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: _text(12.5, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PANEL PUTIH (bayangan biru) berisi dua tabel
  // --------------------------------------------------------------------------
  Widget _buildPanel(
    double minHeight,
    double bottomInset,
    List<TaskItem> tasks,
    List<TaskItem> activities,
  ) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: _blueShadow(blur: 24, dy: -6, alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _listCard(
            title: 'Tugasmu',
            items: tasks,
            isTask: true,
            emptyText: 'Semua tugas sudah selesai!',
          ),
          const SizedBox(height: 16),
          _listCard(
            title: 'Kegiatanmu',
            items: activities,
            isTask: false,
            emptyText: 'Semua kegiatan sudah selesai!',
          ),
        ],
      ),
    );
  }

  Widget _listCard({
    required String title,
    required List<TaskItem> items,
    required bool isTask,
    required String emptyText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: _text(15, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${items.length}', style: _text(11, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.tersier,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            emptyText,
                            style: _text(
                              12,
                              weight: FontWeight.w600,
                              color: AppColors.textDark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  // Tinggi dibatasi (sekitar 3 bar) supaya sisanya di-scroll.
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            for (final it in items) _itemBar(it, isTask: isTask),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Satu bar: garis urgensi di kiri, nama, keterangan singkat, sisa waktu.
  Widget _itemBar(TaskItem it, {required bool isTask}) {
    final color = _urgencyColor(_urgencyOf(it.deadline));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        pressedScale: 0.97,
        onTap: () => _openDetail(it, isTask: isTask),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(12.5, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          it.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            11,
                            color: AppColors.textDark.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _deadlineLabel(it.deadline),
                    style: _text(
                      10.5,
                      weight: FontWeight.w600,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              top: 10,
              bottom: 10,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// KARTU MELAYANG
// ============================================================================

class _FloatingCard extends StatelessWidget {
  final Widget child;

  const _FloatingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(blur: 24, dy: 8, alpha: 0.6),
      ),
      child: child,
    );
  }
}

/// Keterangan lengkap + pilihan mengumpulkan (kiri bawah) + tombol sampah
/// (kanan atas).
class _ItemDetail extends StatelessWidget {
  final TaskItem item;
  final bool isTask;

  const _ItemDetail({required this.item, required this.isTask});

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required _DetailAction action,
  }) {
    return TapScale(
      pressedScale: 0.9,
      onTap: () => Navigator.of(context).pop(action),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.tersier),
          ),
          const SizedBox(height: 6),
          Text(label, style: _text(11, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(_urgencyOf(item.deadline));

    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(item.title, style: _text(16, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              TapScale(
                pressedScale: 0.85,
                onTap: () => Navigator.of(context).pop(_DetailAction.delete),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.urgencyPanic.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.urgencyPanic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullDate(item.deadline),
                      style: _text(11.5, weight: FontWeight.w600),
                    ),
                    Text(
                      _deadlineLabel(item.deadline),
                      style: _text(
                        10.5,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _fieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.description,
                  style: _text(13, color: AppColors.textDark.withValues(alpha: 0.85)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isTask ? 'Kumpulkan tugas dengan' : 'Selesaikan kegiatan dengan foto',
              style: _text(
                11.5,
                weight: FontWeight.w600,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                context,
                icon: Icons.camera_alt_outlined,
                label: 'Foto',
                action: _DetailAction.camera,
              ),
              if (isTask) ...[
                const SizedBox(width: 28),
                _actionButton(
                  context,
                  icon: Icons.folder_open_rounded,
                  label: 'File',
                  action: _DetailAction.file,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Konfirmasi sebelum membuang tugas / kegiatan.
class _ConfirmDelete extends StatelessWidget {
  final TaskItem item;
  final bool isTask;

  const _ConfirmDelete({required this.item, required this.isTask});

  @override
  Widget build(BuildContext context) {
    final noun = isTask ? 'tugas' : 'kegiatan';
    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.urgencyPanic.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 28,
              color: AppColors.urgencyPanic,
            ),
          ),
          const SizedBox(height: 14),
          Text('Buang $noun ini?', style: _text(16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '"${item.title}" akan dihapus dan tidak dianggap selesai.',
            textAlign: TextAlign.center,
            style: _text(12.5, color: AppColors.textDark.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TapScale(
                  pressedScale: 0.95,
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _softBorder, width: 1.4),
                    ),
                    child: Text('Batal', style: _text(14, weight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TapScale(
                  pressedScale: 0.95,
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.urgencyPanic,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Buang',
                      style: _text(14, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KAMERA (latar putih, rasio 3:4)
// ============================================================================

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraController _controller;
  late final Future<void> _initFuture;
  bool _isFlashOn = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final next = !_isFlashOn;
    try {
      await _controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _isFlashOn = next);
    } catch (_) {
      // Sebagian perangkat / browser tidak punya lampu kilat.
    }
  }

  Future<void> _takePicture() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _initFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ImagePreviewScreen(imagePath: image.path)),
      );
      if (!mounted) return;
      if (result == true) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error camera: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, {bool active = false}) {
    return TapScale(
      pressedScale: 0.9,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? AppColors.primer : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _softBorder, width: 1.2),
          boxShadow: _blueShadow(),
        ),
        child: Icon(icon, size: 22, color: AppColors.tersier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _roundButton(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context),
                  ),
                  _roundButton(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    _toggleFlash,
                    active: _isFlashOn,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: _blueShadow(blur: 24, dy: 6, alpha: 0.6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          color: _fieldBg,
                          child: FutureBuilder<void>(
                            future: _initFuture,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Kamera tidak bisa dibuka. Cek izin kamera di perangkatmu.',
                                      textAlign: TextAlign.center,
                                      style: _text(13, weight: FontWeight.w600),
                                    ),
                                  ),
                                );
                              }
                              if (snapshot.connectionState == ConnectionState.done) {
                                return CameraPreview(_controller);
                              }
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.tersier,
                                  strokeWidth: 3,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: TapScale(
                pressedScale: 0.88,
                onTap: _busy ? null : _takePicture,
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sekunder, width: 3),
                    boxShadow: _blueShadow(),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.tersier,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PRATINJAU FOTO (Batal / Upload)
// ============================================================================

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: _blueShadow(blur: 24, dy: 6, alpha: 0.6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Container(
                          color: _fieldBg,
                          // Dibaca sebagai byte supaya jalan di web maupun HP.
                          child: FutureBuilder(
                            future: XFile(imagePath).readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Foto tidak bisa ditampilkan',
                                    style: _text(13, weight: FontWeight.w600),
                                  ),
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.tersier,
                                  strokeWidth: 3,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: TapScale(
                      pressedScale: 0.95,
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _softBorder, width: 1.4),
                        ),
                        child: Text('Batal', style: _text(15, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: TapScale(
                      pressedScale: 0.95,
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.tersier,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _blueShadow(blur: 12, dy: 4),
                        ),
                        child: Text(
                          'Upload',
                          style: _text(15, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
