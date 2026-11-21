import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/tap_scale.dart';
import 'virtual_pet.dart';

// ============================================================================
// DATA
// (Sementara data contoh di memori. Nanti diambil dari penyimpanan Supabase.)
// ============================================================================

enum FileKind { photo, document }

class FileEntry {
  final String id;
  final String name; // nama file
  final String tag; // tag, misalnya Tugas / Kegiatan
  final FileKind kind;
  final DateTime date; // tanggal foto diambil / file dikumpulkan
  final Uint8List? bytes; // isi foto (kalau ada)
  final String? url; // alamat foto (kalau ada)

  FileEntry({
    required this.id,
    required this.name,
    required this.tag,
    required this.kind,
    required this.date,
    this.bytes,
    this.url,
  });
}

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime _inDays(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + n);
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

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _fullDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

String _shortDate(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]} ${d.year}';

String _ext(String name) {
  final i = name.lastIndexOf('.');
  return (i > 0 && i < name.length - 1) ? name.substring(i + 1).toUpperCase() : 'DOC';
}

// ============================================================================
// HALAMAN FILE
// ============================================================================

class FileView extends StatefulWidget {
  const FileView({super.key});

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  final _searchCtrl = TextEditingController();
  late DateTime _focusedMonth;
  DateTime? _selectedDay; // disimpan sebagai _dateOnly
  FileKind _tab = FileKind.photo;
  String _query = '';

  // DATA CONTOH: ganti dengan data asli nanti.
  late final List<FileEntry> _entries = [
    FileEntry(id: 'p1', name: 'Sketsa karakter', tag: 'Tugas', kind: FileKind.photo, date: _inDays(0)),
    FileEntry(id: 'p2', name: 'Hasil render awal', tag: 'Tugas', kind: FileKind.photo, date: _inDays(0)),
    FileEntry(id: 'p3', name: 'Foto kehadiran praktikum', tag: 'Kegiatan', kind: FileKind.photo, date: _inDays(-1)),
    FileEntry(id: 'p4', name: 'Poster seminar', tag: 'Kegiatan', kind: FileKind.photo, date: _inDays(-3)),
    FileEntry(id: 'p5', name: 'Desain halaman Home', tag: 'Tugas', kind: FileKind.photo, date: _inDays(-3)),
    FileEntry(id: 'p6', name: 'Foto kunjungan industri', tag: 'Kegiatan', kind: FileKind.photo, date: _inDays(-6)),
    FileEntry(id: 'p7', name: 'Papan tulis rapat', tag: 'Kegiatan', kind: FileKind.photo, date: _inDays(-8)),
    FileEntry(id: 'p8', name: 'Wireframe website', tag: 'Tugas', kind: FileKind.photo, date: _inDays(-8)),
    FileEntry(id: 'p9', name: 'Prototipe aplikasi', tag: 'Tugas', kind: FileKind.photo, date: _inDays(-8)),
    FileEntry(id: 'd1', name: 'Laprak Animasi 3D.pdf', tag: 'Tugas', kind: FileKind.document, date: _inDays(0)),
    FileEntry(id: 'd2', name: 'Catatan Seminar.docx', tag: 'Kegiatan', kind: FileKind.document, date: _inDays(-3)),
    FileEntry(id: 'd3', name: 'Laporan Bisnis.pdf', tag: 'Tugas', kind: FileKind.document, date: _inDays(-5)),
    FileEntry(id: 'd4', name: 'Esai Kewirausahaan.docx', tag: 'Tugas', kind: FileKind.document, date: _inDays(-8)),
    FileEntry(id: 'd5', name: 'Jadwal Praktikum.pdf', tag: 'Kegiatan', kind: FileKind.document, date: _inDays(-12)),
    FileEntry(id: 'd6', name: 'Proposal Proyek.pdf', tag: 'Tugas', kind: FileKind.document, date: _inDays(-20)),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOGIKA DATA
  // --------------------------------------------------------------------------

  /// Hasil setelah pencarian (nama atau tag). Dipakai kalender dan daftar.
  List<FileEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries
        .where((e) => e.name.toLowerCase().contains(q) || e.tag.toLowerCase().contains(q))
        .toList();
  }

  List<FileEntry> _entriesOn(DateTime day) {
    final key = _dateOnly(day);
    return _filtered.where((e) => _dateOnly(e.date) == key).toList()
      ..sort((a, b) {
        final byKind = a.kind.index.compareTo(b.kind.index);
        return byKind != 0 ? byKind : a.name.compareTo(b.name);
      });
  }

  int _weeksIn(DateTime month) {
    final offset = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    return ((days + offset) / 7).ceil();
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment, 1);
    });
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final filtered = _filtered;

    // Panel putih dibuat setinggi sisa layar (dengan jarak ke tepi layar).
    // 72 = header, 62 = search bar + jarak, 20 = jarak kalender ke panel,
    // 16 = jarak panel ke tepi bawah layar.
    final calendarHeight = 125 + _weeksIn(_focusedMonth) * 42.0;
    final used = media.padding.top + 72 + 62 + calendarHeight + 20 + 16 + media.padding.bottom;
    final panelHeight = math.max(420.0, media.size.height - used);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCalendarCard(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + media.padding.bottom),
                child: SizedBox(
                  height: panelHeight,
                  child: _buildPanel(filtered),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER: tombol kembali (kiri) + judul "File Page" (kanan atas)
  // --------------------------------------------------------------------------
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
            const Spacer(),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: _softBorder, width: 1.2),
                boxShadow: _blueShadow(),
              ),
              child: Text('File Page', style: _text(16, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SEARCH BAR: cari berdasarkan nama atau tag
  // --------------------------------------------------------------------------
  Widget _buildSearchBar() {
    final hasText = _query.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textDark.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: _text(14),
              cursorColor: AppColors.tersier,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Cari nama atau tag file...',
                hintStyle: _text(14, color: AppColors.textDark.withValues(alpha: 0.5)),
              ),
            ),
          ),
          // Tombol hapus teks: muncul dengan efek membesar.
          IgnorePointer(
            ignoring: !hasText,
            child: AnimatedScale(
              scale: hasText ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: TapScale(
                pressedScale: 0.85,
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // KALENDER (tanda = foto / dokumen yang pernah diambil)
  // --------------------------------------------------------------------------
  Widget _buildCalendarCard() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final offset = DateTime(year, month, 1).weekday % 7; // Minggu = 0
    final weeks = _weeksIn(_focusedMonth);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(blur: 18, dy: 5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
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
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 20,
            child: Row(
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
          ),
          const SizedBox(height: 4),
          for (int w = 0; w < weeks; w++)
            Row(
              children: [
                for (int d = 0; d < 7; d++)
                  _dayCell(DateTime(year, month, 1 - offset + w * 7 + d)),
              ],
            ),
          const SizedBox(height: 8),
          _buildLegend(),
        ],
      ),
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

  Widget _dot({required bool filled}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.tersier : Colors.transparent,
        border: filled ? null : Border.all(color: AppColors.tersier, width: 1.3),
      ),
    );
  }

  Widget _dayCell(DateTime day) {
    final inMonth = day.month == _focusedMonth.month;
    final key = _dateOnly(day);
    final isToday = key == _dateOnly(DateTime.now());
    final isSelected = inMonth && key == _selectedDay;
    final items = inMonth ? _entriesOn(day) : const <FileEntry>[];

    final marks = <Widget>[
      // Titik penuh = foto, lingkaran kosong = dokumen (maksimal 3 tanda).
      for (int i = 0; i < items.length && i < 3; i++)
        _dot(filled: items[i].kind == FileKind.photo),
    ];

    return Expanded(
      child: TapScale(
        pressedScale: 0.88,
        onTap: inMonth
            ? () {
                setState(() => _selectedDay = key);
                _showDayPopup(day);
              }
            : null,
        child: SizedBox(
          height: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? AppColors.tersier
                      : (isSelected
                          ? AppColors.primer.withValues(alpha: 0.6)
                          : Colors.transparent),
                  border: isSelected
                      ? Border.all(color: AppColors.tersier, width: 1.6)
                      : null,
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
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final m in marks)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: m,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final labelStyle = _text(10, color: AppColors.textDark.withValues(alpha: 0.6));
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(filled: true),
          const SizedBox(width: 5),
          Text('Foto', style: labelStyle),
          const SizedBox(width: 14),
          _dot(filled: false),
          const SizedBox(width: 5),
          Text('Dokumen', style: labelStyle),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // POPUP MELAYANG
  // --------------------------------------------------------------------------
  Future<void> _showFloating(Widget child) {
    return showGeneralDialog(
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

  void _showDayPopup(DateTime day) {
    _showFloating(
      _DayFiles(
        day: day,
        items: _entriesOn(day),
        onOpen: (e) => _showFloating(_FilePreview(entry: e)),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PANEL PUTIH: pilihan Foto / Dokumen + isi (scroll) + tombol kumpulkan tugas
  // --------------------------------------------------------------------------
  Widget _buildPanel(List<FileEntry> filtered) {
    final photos = filtered.where((e) => e.kind == FileKind.photo).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final docs = filtered.where((e) => e.kind == FileKind.document).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final items = _tab == FileKind.photo ? photos : docs;
    final otherCount = _tab == FileKind.photo ? docs.length : photos.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(blur: 22, dy: 6, alpha: 0.55),
      ),
      child: Column(
        children: [
          _buildTabs(photos.length, docs.length),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: items.isEmpty
                  ? _buildEmpty(
                      key: ValueKey('empty-$_tab-$_query'),
                      otherCount: otherCount,
                    )
                  : _buildGrid(items, key: ValueKey('grid-$_tab-$_query')),
            ),
          ),
          const SizedBox(height: 12),
          _buildSubmitCard(),
        ],
      ),
    );
  }

  Widget _buildTabs(int photoCount, int docCount) {
    final isPhoto = _tab == FileKind.photo;

    Widget label(String text, IconData icon, int count, FileKind kind) {
      final active = _tab == kind;
      final color = active ? AppColors.textDark : AppColors.textDark.withValues(alpha: 0.55);
      return Expanded(
        child: TapScale(
          pressedScale: 0.96,
          onTap: () => setState(() => _tab = kind),
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: active ? AppColors.tersier : color),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: _text(13, weight: active ? FontWeight.w700 : FontWeight.w600, color: color),
                  child: Text(text),
                ),
                const SizedBox(width: 6),
                Text('$count', style: _text(11, weight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: isPhoto ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _blueShadow(blur: 8, dy: 2, alpha: 0.35),
                ),
              ),
            ),
          ),
          Row(
            children: [
              label('Foto', Icons.image_outlined, photoCount, FileKind.photo),
              label('Dokumen', Icons.description_outlined, docCount, FileKind.document),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<FileEntry> items, {Key? key}) {
    return GridView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 112,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        return TapScale(
          pressedScale: 0.94,
          onTap: () => _showFloating(_FilePreview(entry: e)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _Thumb(entry: e),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(11, weight: FontWeight.w700),
              ),
              Text(
                '${e.tag} · ${e.date.day} ${_shortMonths[e.date.month - 1]}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(9.5, color: AppColors.textDark.withValues(alpha: 0.55)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty({Key? key, required int otherCount}) {
    final isPhoto = _tab == FileKind.photo;
    final searching = _query.trim().isNotEmpty;
    final noun = isPhoto ? 'foto' : 'dokumen';
    final otherNoun = isPhoto ? 'dokumen' : 'foto';

    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.folder_open_rounded,
            size: 40,
            color: AppColors.tersier.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            searching ? 'Tidak ada $noun yang cocok' : 'Belum ada $noun',
            style: _text(13, weight: FontWeight.w700),
          ),
          if (searching && otherCount > 0) ...[
            const SizedBox(height: 10),
            TapScale(
              pressedScale: 0.94,
              onTap: () => setState(() {
                _tab = isPhoto ? FileKind.document : FileKind.photo;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Ada $otherCount $otherNoun yang cocok',
                  style: _text(11.5, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tabel kecil biru: pindah ke halaman Mipo untuk mengumpulkan tugas.
  Widget _buildSubmitCard() {
    return TapScale(
      pressedScale: 0.97,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VirtualPetView()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 21,
                color: AppColors.tersier,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kumpulkan tugas', style: _text(13, weight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                    'Buka Mipo untuk mengumpulkan tugas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(10.5, color: AppColors.textDark.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MINIATUR FOTO / DOKUMEN
// ============================================================================

/// Menampilkan foto asli kalau ada. Kalau belum ada, tampil kotak biru muda
/// dengan ikon (dokumen juga menampilkan jenis filenya, misalnya PDF).
class _Thumb extends StatelessWidget {
  final FileEntry entry;

  const _Thumb({required this.entry});

  static const _palettes = [
    [Color(0xFFD6ECFF), Color(0xFFBFE0FF)],
    [Color(0xFFE3F1FF), Color(0xFFC9E6FF)],
    [Color(0xFFDDEBFF), Color(0xFFB9D9F7)],
    [Color(0xFFE6F3FF), Color(0xFFCBE4FA)],
  ];

  Widget _placeholder() {
    final colors = _palettes[entry.id.hashCode.abs() % _palettes.length];
    final isPhoto = entry.kind == FileKind.photo;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPhoto ? Icons.image_outlined : Icons.description_outlined,
                  size: 32,
                  color: AppColors.tersier.withValues(alpha: 0.8),
                ),
                if (!isPhoto) ...[
                  const SizedBox(height: 2),
                  Text(
                    _ext(entry.name),
                    style: _text(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.tersier.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (entry.bytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          entry.bytes!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    if (entry.url != null) {
      return SizedBox.expand(
        child: Image.network(
          entry.url!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return SizedBox.expand(child: _placeholder());
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

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return TapScale(
      pressedScale: 0.85,
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primer.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textDark),
      ),
    );
  }
}

/// Pratinjau satu foto / dokumen.
class _FilePreview extends StatelessWidget {
  final FileEntry entry;

  const _FilePreview({required this.entry});

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.tersier),
          const SizedBox(width: 5),
          Text(text, style: _text(11, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = entry.kind == FileKind.photo;
    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _text(15, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              const _CloseButton(),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _Thumb(entry: entry),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(entry.tag, Icons.sell_outlined),
              _chip(_shortDate(entry.date), Icons.event_rounded),
              _chip(isPhoto ? 'Foto' : _ext(entry.name), isPhoto ? Icons.image_outlined : Icons.description_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

/// Isi satu tanggal. 1 berkas = besar, 2 sampai 4 = kolase, lebih = grid scroll.
class _DayFiles extends StatelessWidget {
  final DateTime day;
  final List<FileEntry> items;
  final void Function(FileEntry) onOpen;

  const _DayFiles({
    required this.day,
    required this.items,
    required this.onOpen,
  });

  Widget _tile(FileEntry e) {
    return TapScale(
      pressedScale: 0.96,
      onTap: () => onOpen(e),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumb(entry: e),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(10.5, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collage() {
    const gap = 8.0;
    switch (items.length) {
      case 1:
        return SizedBox(height: 220, child: _tile(items[0]));
      case 2:
        return SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(child: _tile(items[0])),
              const SizedBox(width: gap),
              Expanded(child: _tile(items[1])),
            ],
          ),
        );
      case 3:
        return SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(flex: 3, child: _tile(items[0])),
              const SizedBox(width: gap),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(child: _tile(items[1])),
                    const SizedBox(height: gap),
                    Expanded(child: _tile(items[2])),
                  ],
                ),
              ),
            ],
          ),
        );
      case 4:
        return SizedBox(
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _tile(items[0])),
                    const SizedBox(width: gap),
                    Expanded(child: _tile(items[1])),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _tile(items[2])),
                    const SizedBox(width: gap),
                    Expanded(child: _tile(items[3])),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _tile(items[i]),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fullDate(day), style: _text(14, weight: FontWeight.w700)),
                    if (items.isNotEmpty)
                      Text(
                        '${items.length} berkas',
                        style: _text(10.5, color: AppColors.textDark.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
              const _CloseButton(),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 26,
                    color: AppColors.tersier.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada foto atau dokumen di tanggal ini',
                    textAlign: TextAlign.center,
                    style: _text(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            _collage(),
        ],
      ),
    );
  }
}
