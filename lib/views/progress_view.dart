import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/tap_scale.dart';

// ============================================================================
// DATA
// (Sementara disimpan di memori. Nanti disambungkan ke database.)
// ============================================================================

enum ProgressStatus { todo, inProgress, done }

extension _StatusLabel on ProgressStatus {
  String get label {
    switch (this) {
      case ProgressStatus.todo:
        return 'To Do';
      case ProgressStatus.inProgress:
        return 'In Progress';
      case ProgressStatus.done:
        return 'Done';
    }
  }
}

class ProgressTask {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  ProgressStatus status;

  ProgressTask({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.status = ProgressStatus.todo,
  });
}

// ============================================================================
// WARNA URGENSI (sama persis dengan Virtual Pet)
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

/// Warna tabel utama (biru muda). Tab yang aktif memakai warna yang sama.
final Color _tableColor =
    Color.alphaBlend(AppColors.primer.withValues(alpha: 0.5), Colors.white);

/// Warna bar "tambah tugas": sedikit lebih gelap dari tabel.
final Color _addBarColor = Color.lerp(_tableColor, AppColors.tersier, 0.55)!;

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
// HALAMAN PROGRESS
// ============================================================================

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  ProgressStatus _tab = ProgressStatus.todo;
  String? _expandedId;

  // DATA CONTOH: ganti dengan data asli nanti.
  final List<ProgressTask> _tasks = [
    ProgressTask(
      id: 't1',
      title: 'Laprak Animasi 3D',
      description:
          'Mengerjakan laporan praktikum animasi 3D, membuat karakter dengan teknik edge modeling.',
      deadline: _inDays(0),
    ),
    ProgressTask(
      id: 't2',
      title: 'Website Pemrograman',
      description:
          'Mengerjakan desain dan pemrograman web, membuat website memakai Visual Studio Code.',
      deadline: _inDays(2),
      status: ProgressStatus.inProgress,
    ),
    ProgressTask(
      id: 't3',
      title: 'Laporan Bisnis Kelompok',
      description:
          'Menjalankan usaha kelompok dan menyusun laporan hasil usahanya.',
      deadline: _inDays(5),
    ),
    ProgressTask(
      id: 't4',
      title: 'Esai Kewirausahaan',
      description:
          'Menulis esai tentang peluang usaha di bidang kreatif, minimal 3 halaman.',
      deadline: _inDays(12),
    ),
    ProgressTask(
      id: 't5',
      title: 'Laprak Produksi Multimedia',
      description:
          'Menyusun hasil praktikum produksi multimedia dan melengkapi bagian-bagian laporan.',
      deadline: _inDays(-1),
      status: ProgressStatus.done,
    ),
  ];

  List<ProgressTask> _itemsOf(ProgressStatus s) {
    final list = _tasks.where((t) => t.status == s).toList();
    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  // --------------------------------------------------------------------------
  // AKSI
  // --------------------------------------------------------------------------
  void _toggleExpand(String id) {
    setState(() => _expandedId = _expandedId == id ? null : id);
  }

  void _move(ProgressTask t, ProgressStatus to) {
    setState(() {
      t.status = to;
      _expandedId = null;
    });
    _toast('Dipindahkan ke ${to.label}');
  }

  Future<void> _confirmDelete(ProgressTask t) async {
    final ok = await _showFloating<bool>(_ConfirmDelete(task: t));
    if (ok == true && mounted) {
      setState(() {
        _tasks.removeWhere((e) => e.id == t.id);
        _expandedId = null;
      });
      _toast('Tugas dibuang');
    }
  }

  Future<void> _addTask() async {
    final created = await _showFloating<ProgressTask>(const _AddTaskDialog());
    if (created != null && mounted) {
      setState(() {
        _tasks.add(created);
        _expandedId = null;
      });
      _toast('Tugas ditambahkan ke To Do');
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
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Center(
            child: SingleChildScrollView(
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
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
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
            child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTable()
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
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
            const SizedBox(width: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: _softBorder, width: 1.2),
                boxShadow: _blueShadow(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    size: 20,
                    color: AppColors.tersier,
                  ),
                  const SizedBox(width: 8),
                  Text('Progress', style: _text(16, weight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB: aktif = warna tabel, tidak aktif = putih
  // --------------------------------------------------------------------------
  Widget _buildTabs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < ProgressStatus.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _tab_(ProgressStatus.values[i])),
        ],
      ],
    );
  }

    Widget _tab_(ProgressStatus s) {
    final active = _tab == s;
    final count = _tasks.where((t) => t.status == s).length;

    return TapScale(
      pressedScale: 0.94,
      onTap: () {
        if (_tab == s) return;
        setState(() {
          _tab = s;
          _expandedId = null;
        });
      },
      child: Stack(
        clipBehavior: Clip.none, // izinkan latar keluar dari batas tab
        children: [
          // LATAR TAB: yang tidak aktif dipanjangkan 24px ke bawah
          // (masuk ke belakang tabel biru agar tidak ada celah)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            top: 0,
            bottom: active ? 0 : -24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: active ? _tableColor : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow:
                    active ? const [] : _blueShadow(blur: 10, dy: 2, alpha: 0.3),
              ),
            ),
          ),

          // ISI TAB (teks + jumlah)
          AnimatedPadding(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding:
                EdgeInsets.symmetric(vertical: active ? 13 : 10, horizontal: 6),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: _text(
                        12.5,
                        weight: active ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.textDark
                            .withValues(alpha: active ? 1 : 0.6),
                      ),
                      child: Text(s.label),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : _tableColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('$count',
                          style: _text(10.5, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TABEL UTAMA
  // --------------------------------------------------------------------------
  Widget _buildTable() {
  final idx = ProgressStatus.values.indexOf(_tab);
  final items = _itemsOf(_tab);
  final bottomInset = MediaQuery.of(context).padding.bottom;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
    width: double.infinity,
    decoration: BoxDecoration(
      color: _tableColor,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
        topLeft: Radius.circular(idx == 0 ? 0 : 24),
        topRight: Radius.circular(idx == ProgressStatus.values.length - 1 ? 0 : 24),
      ),
      boxShadow: _blueShadow(blur: 20, dy: 4, alpha: 0.35),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_tab),
        child: _buildTableContent(items, bottomInset),
      ),
    ),
  );
}

  Widget _buildTableContent(List<ProgressTask> items, double bottomInset) {
  final isTodo = _tab == ProgressStatus.todo;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 34,
                      color: AppColors.tersier.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emptyText(_tab),
                      textAlign: TextAlign.center,
                      style: _text(
                        12.5,
                        weight: FontWeight.w600,
                        color: AppColors.textDark.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  14,
                  14,
                  isTodo ? 8 : 14 + bottomInset,
                ),
                children: [
                  for (var i = 0; i < items.length; i++) _itemBar(items[i], i),
                ],
              ),
      ),
      if (isTodo)
        Padding(
          padding: EdgeInsets.fromLTRB(14, 6, 14, 14 + bottomInset),
          child: _buildAddBar(),
        ),
    ],
  );
}

  String _emptyText(ProgressStatus s) {
    switch (s) {
      case ProgressStatus.todo:
        return 'Belum ada tugas. Tambahkan tugas barumu!';
      case ProgressStatus.inProgress:
        return 'Belum ada tugas yang sedang dikerjakan.';
      case ProgressStatus.done:
        return 'Belum ada tugas yang selesai.';
    }
  }

  // --------------------------------------------------------------------------
  // BAR TAMBAH TUGAS (khusus tab To Do)
  // --------------------------------------------------------------------------
  Widget _buildAddBar() {
  return TapScale(
    pressedScale: 0.96,
    onTap: _addTask,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _addBarColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _blueShadow(blur: 10, dy: 3, alpha: 0.35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Tambah tugas baru',
            style: _text(13.5, weight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

  // --------------------------------------------------------------------------
  // BAR TUGAS: garis urgensi di kiri, bisa memanjang saat diklik
  // --------------------------------------------------------------------------
  Widget _itemBar(ProgressTask t, int index) {
    final expanded = _expandedId == t.id;
    final isDone = t.status == ProgressStatus.done;
    final color = isDone
        ? AppColors.urgencyCalm
        : _urgencyColor(_urgencyOf(t.deadline));
    final label = isDone ? 'Selesai' : _deadlineLabel(t.deadline);

    return _FadeSlideIn(
      key: ValueKey(t.id),
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TapScale(
          pressedScale: expanded ? 0.99 : 0.97,
          onTap: () => _toggleExpand(t.id),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 12, 10),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 280),
                    sizeCurve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _collapsedContent(t, label),
                    secondChild: _expandedContent(t, label, color, isDone),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 10,
                  bottom: 10,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
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
        ),
      ),
    );
  }

  Widget _collapsedContent(ProgressTask t, String label) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(12.5, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                t.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(11, color: AppColors.textDark.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: _text(
            10.5,
            weight: FontWeight.w600,
            color: AppColors.textDark.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _expandedContent(ProgressTask t, String label, Color color, bool isDone) {
    final isTodo = t.status == ProgressStatus.todo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul + tombol sampah di pojok kanan atas.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(t.title, style: _text(14, weight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            TapScale(
              pressedScale: 0.85,
              onTap: () => _confirmDelete(t),
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
        const SizedBox(height: 6),
        Text(_fullDate(t.deadline), style: _text(11.5, weight: FontWeight.w600)),
        Text(
          label,
          style: _text(10.5, color: AppColors.textDark.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            t.description,
            style: _text(12.5, color: AppColors.textDark.withValues(alpha: 0.85)),
          ),
        ),
        if (!isDone) ...[
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Pindahkan status ke',
              style: _text(
                11.5,
                weight: FontWeight.w600,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: _statusButton(
              icon: isTodo ? Icons.autorenew_rounded : Icons.undo_rounded,
              label: isTodo ? 'In Progress' : 'To Do',
              onTap: () => _move(
                t,
                isTodo ? ProgressStatus.inProgress : ProgressStatus.todo,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Pengumpulan tugas dilakukan di halaman Pet',
              textAlign: TextAlign.center,
              style: _text(
                10.5,
                color: AppColors.textDark.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TapScale(
      pressedScale: 0.9,
      onTap: onTap,
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
}

// ============================================================================
// ANIMASI MUNCUL (item baru / ganti tab)
// ============================================================================

class _FadeSlideIn extends StatelessWidget {
  final int index;
  final Widget child;

  const _FadeSlideIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final ms = 280 + (index > 6 ? 6 : index) * 50;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
      ),
      child: child,
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

/// Konfirmasi sebelum membuang tugas.
class _ConfirmDelete extends StatelessWidget {
  final ProgressTask task;

  const _ConfirmDelete({required this.task});

  @override
  Widget build(BuildContext context) {
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
          Text('Buang tugas ini?', style: _text(16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '"${task.title}" akan dihapus dan tidak dianggap selesai.',
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
// FORM TAMBAH TUGAS: tag/nama, keterangan, deadline
// ============================================================================

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog();

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _deadline = _inDays(1);
  bool _showError = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.tersier,
            onPrimary: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      ProgressTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: _descCtrl.text.trim().isEmpty
            ? 'Belum ada keterangan.'
            : _descCtrl.text.trim(),
        deadline: _deadline,
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _text(12.5, color: AppColors.textDark.withValues(alpha: 0.4)),
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.tersier, width: 1.4),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: _text(
          12,
          weight: FontWeight.w600,
          color: AppColors.textDark.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tugas baru', style: _text(16, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          _label('Tag / nama tugas'),
          TextField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: _text(13.5, weight: FontWeight.w600),
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: _decoration('Contoh: Laprak Animasi 3D'),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: _showError
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Nama tugas wajib diisi',
                      style: _text(11, color: AppColors.urgencyPanic),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 12),
          _label('Keterangan'),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: _text(13),
            decoration: _decoration('Tulis detail tugasnya'),
          ),
          const SizedBox(height: 12),
          _label('Deadline'),
          TapScale(
            pressedScale: 0.97,
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: AppColors.tersier,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fullDate(_deadline),
                      style: _text(13, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TapScale(
                  pressedScale: 0.95,
                  onTap: () => Navigator.of(context).pop(),
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
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tersier,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _blueShadow(blur: 10, dy: 3, alpha: 0.35),
                    ),
                    child: Text(
                      'Simpan',
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
