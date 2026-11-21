import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/mipo_octopus.dart';
import '../widgets/tap_scale.dart';
import 'calendar_view.dart';
import 'file_view.dart';
import 'progress_view.dart';
import 'smart_ai_view.dart';
import 'virtual_pet.dart';

// ============================================================================
// DATA & WARNA URGENSI
// ============================================================================

/// Satu baris kegiatan / tugas di Home.
/// (Sementara data contoh. Nanti diganti data asli dari database.)
class _Entry {
  final String title;
  final String tag;
  final DateTime deadline;
  final String status; // dipakai untuk tugas: 'To Do' / 'In Progress'

  const _Entry({
    required this.title,
    required this.tag,
    required this.deadline,
    this.status = '',
  });
}

enum _Urgency { calm, alert, worry, panic }

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _inDays(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + n);
}

/// Biru: masih jauh | Kuning: H-5..H-4 | Oranye: H-3..H-1 | Merah: hari H / lewat
_Urgency _urgencyOf(DateTime deadline) {
  final days = _dateOnly(deadline).difference(_dateOnly(DateTime.now())).inDays;
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

// ============================================================================
// GAYA TEKS & EFEK (satu font: Huninn, dibedakan lewat ketebalan saja)
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

List<BoxShadow> _blueShadow({double blur = 8, double dy = 2, double alpha = 0.2}) {
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

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _dateLabel(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

// ============================================================================
// HALAMAN HOME
// ============================================================================

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scroll = ScrollController();

  /// true = navigation bar sudah berubah jadi ikon bulat (halaman di-scroll)
  bool _collapsed = false;

  late DateTime _focusedDate;

  // Foto hasil jepretan user untuk mengerjakan tugas (URL).
  // Kosong = tampil kotak kosong. Nanti diisi dari penyimpanan Supabase.
  final List<String> _photoUrls = [];

  // DATA CONTOH: ganti dengan data asli nanti.
  final List<_Entry> _schedules = [
    _Entry(title: 'Praktikum Multimedia', tag: 'Kuliah', deadline: _inDays(0)),
    _Entry(title: 'Rapat kelompok', tag: 'Organisasi', deadline: _inDays(2)),
    _Entry(title: 'Seminar Kewirausahaan', tag: 'Acara', deadline: _inDays(4)),
    _Entry(title: 'Kunjungan industri', tag: 'Kuliah', deadline: _inDays(9)),
  ];

  final List<_Entry> _tasks = [
    _Entry(title: 'Laprak Multimedia', tag: 'Tugas', deadline: _inDays(0), status: 'To Do'),
    _Entry(title: 'Animasi 3D', tag: 'Tugas', deadline: _inDays(2), status: 'In Progress'),
    _Entry(title: 'Website Pemrograman', tag: 'Proyek', deadline: _inDays(5), status: 'To Do'),
    _Entry(title: 'Laporan Bisnis', tag: 'Kelompok', deadline: _inDays(12), status: 'In Progress'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month, 1);
    _scroll.addListener(() {
      final shouldCollapse = _scroll.hasClients && _scroll.offset > 24;
      if (shouldCollapse != _collapsed) {
        setState(() => _collapsed = shouldCollapse);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + increment, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // Urutkan dari deadline paling dekat ke paling jauh.
    final schedules = [..._schedules]..sort((a, b) => a.deadline.compareTo(b.deadline));
    final tasks = [..._tasks]..sort((a, b) => a.deadline.compareTo(b.deadline));
    final marked = {for (final e in [...schedules, ...tasks]) _dateOnly(e.deadline)};

    // Tinggi area Mipo dibuat tetap, supaya tinggi panel di bawahnya
    // bisa dihitung pasti (sisa layar).
    final petHeight = media.padding.top + 300;
    final panelMinHeight =
        media.size.height > petHeight ? media.size.height - petHeight : 0.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.primer,
      drawerScrimColor: Colors.black.withValues(alpha: 0.35),
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildPetSection(petHeight, media.padding.top, tasks),
                // Panel utama minimal setinggi sisa layar, jadi selalu
                // memanjang sampai ujung bawah.
                _buildMainPanel(
                  media.padding.bottom,
                  panelMinHeight,
                  schedules,
                  tasks,
                  marked,
                ),
              ],
            ),
          ),
          Positioned(
            top: media.padding.top + 8,
            left: 16,
            right: 16,
            child: _buildFloatingHeader(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER MELAYANG: hamburger + navigation bar yang berubah jadi ikon chat
  // --------------------------------------------------------------------------
  Widget _buildFloatingHeader() {
    const circle = 46.0;
    const gap = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth = constraints.maxWidth - circle - gap;

        return Row(
          children: [
            TapScale(
              pressedScale: 0.9,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _softBorder, width: 1.2),
                  boxShadow: _blueShadow(),
                ),
                child: const Icon(Icons.menu_rounded, color: AppColors.tersier, size: 24),
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: TapScale(
                  pressedScale: 0.96,
                  onTap: () => _go(const SmartAiView()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOutCubic,
                    width: _collapsed ? circle : expandedWidth,
                    height: circle,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(circle / 2),
                      border: Border.all(color: _softBorder, width: 1.2),
                      boxShadow: _blueShadow(),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(circle / 2),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Tampilan bar penuh (memudar saat mengecil)
                          AnimatedOpacity(
                            opacity: _collapsed ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: expandedWidth,
                              maxWidth: expandedWidth,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                      color: AppColors.textDark.withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ask Anything!',
                                      style: _text(
                                        14,
                                        color: AppColors.textDark.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Ikon bubble chat (muncul saat sudah bulat)
                          AnimatedOpacity(
                            opacity: _collapsed ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 22,
                              color: AppColors.tersier,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // PET MIPO + KALIMAT SINGKAT
  // --------------------------------------------------------------------------
  String _petMessage(List<_Entry> tasks) {
    if (tasks.isEmpty) return 'Semua tugas beres, mantap!';
    switch (_urgencyOf(tasks.first.deadline)) {
      case _Urgency.panic:
        return 'Ada tugas yang deadline-nya hari ini, yuk kebut!';
      case _Urgency.worry:
        return 'Deadline sudah dekat, ayo mulai kerjakan!';
      case _Urgency.alert:
        return 'Cicil tugasnya pelan-pelan, ya.';
      case _Urgency.calm:
        return 'Santai dulu, tapi jangan lupa tugasmu.';
    }
  }

  Widget _buildPetSection(double height, double topInset, List<_Entry> tasks) {
    return SizedBox(
      height: height,
      child: Padding(
        // 46 (tinggi header) + 8 + 8 = ruang agar pet tidak tertutup header
        padding: EdgeInsets.only(top: topInset + 70),
        child: Column(
        children: [
          TapScale(
            pressedScale: 0.96,
            onTap: () => _go(const VirtualPetView()),
            child: const MipoOctopus(size: 124, interactive: false),
          ),
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _softBorder, width: 1.2),
            ),
            child: Text(
              _petMessage(tasks),
              textAlign: TextAlign.center,
              style: _text(12.5, weight: FontWeight.w600),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TABEL 1: kalender (memanjang sampai ujung bawah layar)
  // --------------------------------------------------------------------------
  Widget _buildMainPanel(
    double bottomInset,
    double minHeight,
    List<_Entry> schedules,
    List<_Entry> tasks,
    Set<DateTime> marked,
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
          _buildCalendar(marked),
          const SizedBox(height: 18),
          _buildSchedulePanel(schedules),
          const SizedBox(height: 16),
          _buildTaskPanel(tasks),
        ],
      ),
    );
  }

  Widget _buildCalendar(Set<DateTime> marked) {
    final year = _focusedDate.year;
    final month = _focusedDate.month;
    final offset = DateTime(year, month, 1).weekday % 7; // Minggu = 0
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weeks = ((daysInMonth + offset) / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _monthArrow(Icons.chevron_left_rounded, () => _changeMonth(-1)),
            Text(
              '${_monthNames[month - 1]} $year',
              style: _text(15, weight: FontWeight.w700),
            ),
            _monthArrow(Icons.chevron_right_rounded, () => _changeMonth(1)),
          ],
        ),
        const SizedBox(height: 10),
        // Menyentuh area tanggal membuka halaman Calendar.
        TapScale(
          pressedScale: 0.985,
          onTap: () => _go(const CalendarView()),
          child: Column(
            children: [
              Row(
                children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: _text(
                              10.5,
                              weight: FontWeight.w600,
                              color: AppColors.textDark.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              for (int w = 0; w < weeks; w++)
                Row(
                  children: [
                    for (int d = 0; d < 7; d++)
                      _dayCell(DateTime(year, month, 1 - offset + w * 7 + d), marked),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _monthArrow(IconData icon, VoidCallback onTap) {
    return TapScale(
      pressedScale: 0.85,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primer.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: AppColors.textDark),
      ),
    );
  }

  Widget _dayCell(DateTime day, Set<DateTime> marked) {
    final inMonth = day.month == _focusedDate.month;
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    final hasEntry = inMonth && marked.contains(_dateOnly(day));

    return Expanded(
      child: SizedBox(
        height: 42,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? AppColors.tersier : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: _text(
                  12,
                  weight: inMonth ? FontWeight.w600 : FontWeight.w400,
                  color: isToday
                      ? Colors.white
                      : AppColors.textDark.withValues(alpha: inMonth ? 1 : 0.28),
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Titik kecil = ada kegiatan/tugas di tanggal itu (warna sesuai urgensi)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasEntry ? _urgencyColor(_urgencyOf(day)) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TABEL 2: jadwal kegiatan (kiri) + foto (kanan)
  // --------------------------------------------------------------------------
  Widget _buildSchedulePanel(List<_Entry> schedules) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(blur: 18, dy: 5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Kegiatanmu', () => _go(const CalendarView())),
                const SizedBox(height: 10),
                if (schedules.isEmpty)
                  _emptyText('Belum ada kegiatan.')
                else
                  for (final e in schedules.take(3))
                    _entryBar(
                      e,
                      background: const Color(0xFFF3F8FE),
                      onTap: () => _go(const CalendarView()),
                    ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Fotomu', () => _go(const FileView())),
                const SizedBox(height: 10),
                _buildPhotoGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    // 3 baris x 2 kotak persegi.
    return Column(
      children: [
        for (int row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _photoTile(row * 2)),
              const SizedBox(width: 8),
              Expanded(child: _photoTile(row * 2 + 1)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _photoTile(int i) {
    final hasPhoto = i < _photoUrls.length;
    return TapScale(
      pressedScale: 0.9,
      onTap: () => _go(const FileView()),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasPhoto
              ? Image.network(
                  _photoUrls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder(),
                )
              : _photoPlaceholder(),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Center(
      child: Icon(
        Icons.photo_outlined,
        size: 18,
        color: AppColors.tersier.withValues(alpha: 0.5),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TABEL 3 (biru): daftar tugas
  // --------------------------------------------------------------------------
  Widget _buildTaskPanel(List<_Entry> tasks) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Tugasmu', () => _go(const ProgressView())),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            _emptyText('Belum ada tugas.')
          else
            for (final e in tasks.take(4))
              _entryBar(
                e,
                background: Colors.white,
                onTap: () => _go(const ProgressView()),
                trailing: _statusPill(e.status),
              ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final label = status == 'In Progress' ? 'Progress' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: _text(10, weight: FontWeight.w600)),
    );
  }

  // --------------------------------------------------------------------------
  // KOMPONEN BERSAMA
  // --------------------------------------------------------------------------
  Widget _sectionTitle(String title, VoidCallback onTap) {
    return TapScale(
      pressedScale: 0.96,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: _text(14, weight: FontWeight.w700)),
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textDark.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: _text(12, color: AppColors.textDark.withValues(alpha: 0.5)),
      ),
    );
  }

  /// Satu bar: garis urgensi kecil di kiri + nama, tag, dan tanggal deadline.
  Widget _entryBar(
    _Entry e, {
    required Color background,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final color = _urgencyColor(_urgencyOf(e.deadline));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        pressedScale: 0.97,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(12.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.tag} · ${_dateLabel(e.deadline)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        10.5,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing,
              ],
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
