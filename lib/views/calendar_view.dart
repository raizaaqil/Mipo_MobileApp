import 'package:flutter/material.dart';
import '../core/app_strings.dart';

import '../core/app_colors.dart';
import '../data/mipo_store.dart';
import '../widgets/tap_scale.dart';


enum _Section { schedule, alarm, notes }

// ============================================================================
// WARNA URGENSI (sama dengan Virtual Pet dan Home)
// ============================================================================

DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

enum _Urgency { calm, alert, worry, panic }

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

Color get _softBorder => AppColors.softBorder;
Color get _fieldBg => AppColors.softFill;

List<BoxShadow> _blueShadow({double blur = 16, double dy = 4, double alpha = 0.45}) {
  return [
    BoxShadow(
      color: AppColors.sekunder.withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

List<String> get _monthNames => AppStrings.monthNames;

List<String> get _shortMonths => AppStrings.shortMonths;

List<String> get _dayNames => AppStrings.dayNames;

String _dayName(DateTime d) => _dayNames[d.weekday - 1];

String _dateLabel(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

String _fullDate(DateTime d) =>
    '${_dayName(d)}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

String _repeatLabel(AlarmItem a) {
  switch (a.repeat) {
    case AlarmRepeat.once:
      return '${_dayName(a.date)}, ${_dateLabel(a.date)}';
    case AlarmRepeat.daily:
      return AppStrings.t('cal_daily');
    case AlarmRepeat.weekly:
      return AppStrings.t('cal_every_dayname', {'d': _dayName(a.date)});
  }
}

// ============================================================================
// HALAMAN CALENDAR
// ============================================================================

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay; // disimpan sebagai _dateOnly
  _Section? _expanded; // hanya satu tabel yang terbuka dalam satu waktu

  // Data diambil dari penyimpanan bersama (dipakai juga oleh Smart AI).
  final _store = MipoStore.instance;

  List<ScheduleItem> get _schedules => _store.schedules;
  List<AlarmItem> get _alarms => _store.alarms;
  List<NoteItem> get _notes => _store.notes;

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOGIKA DATA
  // --------------------------------------------------------------------------
  List<ScheduleItem> _schedulesOn(DateTime day) {
    final key = _dateOnly(day);
    return _schedules.where((s) => _dateOnly(s.date) == key).toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
  }

  List<AlarmItem> _alarmsOn(DateTime day) {
    return _alarms.where((a) => a.occursOn(day)).toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
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

  void _toggle(_Section section) {
    setState(() => _expanded = _expanded == section ? null : section);
  }

  // Menampilkan tanggal tertentu di kalender + popup isinya.
  void _focusOnDate(DateTime d) {
    setState(() {
      _focusedMonth = DateTime(d.year, d.month, 1);
      _selectedDay = _dateOnly(d);
    });
    _showDayPopup(d);
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final schedules = [..._schedules]..sort((a, b) {
        final byDate = _dateOnly(a.date).compareTo(_dateOnly(b.date));
        return byDate != 0 ? byDate : _minutes(a.time).compareTo(_minutes(b.time));
      });
    final alarms = [..._alarms]
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));

    // Tinggi panel putih dihitung supaya selalu sampai ujung bawah layar.
    // 72 = tinggi blok header, 20 = jarak kalender ke panel.
    final calendarHeight = 125 + _weeksIn(_focusedMonth) * 42.0;
    final used = media.padding.top + 72 + calendarHeight + 20;
    final panelMinHeight = media.size.height > used ? media.size.height - used : 0.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCalendarCard(),
              ),
              const SizedBox(height: 20),
              _buildPanel(panelMinHeight, media.padding.bottom, schedules, alarms),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER: tombol kembali + judul
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
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _softBorder, width: 1.2),
                  boxShadow: _blueShadow(),
                ),
                child: Icon(
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: _softBorder, width: 1.2),
                boxShadow: _blueShadow(),
              ),
              child: Text(AppStrings.t('cal_title'), style: _text(16, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // KALENDER
  // --------------------------------------------------------------------------
  Widget _buildCalendarCard() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final offset = DateTime(year, month, 1).weekday % 7; // Minggu = 0
    final weeks = _weeksIn(_focusedMonth);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              children: AppStrings.dayShortSunFirst
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

  Widget _dot({required bool filled, required Color color}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color, width: 1.3),
      ),
    );
  }

  Widget _dayCell(DateTime day) {
    final inMonth = day.month == _focusedMonth.month;
    final key = _dateOnly(day);
    final isToday = key == _dateOnly(DateTime.now());
    final isSelected = inMonth && key == _selectedDay;

    final schedules = inMonth ? _schedulesOn(day) : const <ScheduleItem>[];
    final hasAlarm = inMonth && _alarms.any((a) => a.occursOn(day));
    final urgencyColor = _urgencyColor(_urgencyOf(day));

    final marks = <Widget>[
      for (int i = 0; i < schedules.length && i < 2; i++)
        _dot(filled: true, color: urgencyColor),
      if (hasAlarm)
        _dot(filled: false, color: AppColors.textDark.withValues(alpha: 0.7)),
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
                        ? AppColors.onAccent
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
    final labelStyle = _text(
      10,
      color: AppColors.textDark.withValues(alpha: 0.6),
    );
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final c in [
            AppColors.urgencyCalm,
            AppColors.urgencyAlert,
            AppColors.urgencyWorry,
            AppColors.urgencyPanic,
          ])
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: _dot(filled: true, color: c),
            ),
          const SizedBox(width: 2),
          Text(AppStrings.t('legend_activity'), style: labelStyle),
          const SizedBox(width: 14),
          _dot(filled: false, color: AppColors.textDark.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text('Alarm', style: labelStyle),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // POPUP MELAYANG (isi satu tanggal / detail notes)
  // --------------------------------------------------------------------------
  Future<void> _showFloating(Widget child) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.t('close'),
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
      _DayPopup(
        day: day,
        schedules: _schedulesOn(day),
        alarms: _alarmsOn(day),
      ),
    );
  }

  void _showNoteDetail(NoteItem note) {
    _showFloating(_NoteDetail(note: note));
  }

  // --------------------------------------------------------------------------
  // PANEL PUTIH: memanjang sampai ujung bawah, berisi 3 tabel
  // --------------------------------------------------------------------------
  Widget _buildPanel(
    double minHeight,
    double bottomInset,
    List<ScheduleItem> schedules,
    List<AlarmItem> alarms,
  ) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: _blueShadow(blur: 24, dy: -6, alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _expandableCard<ScheduleItem>(
            section: _Section.schedule,
            title: AppStrings.t('cal_your_schedule'),
            items: schedules,
            previewCount: 3,
            emptyText: AppStrings.t('cal_empty_sched'),
            itemBuilder: _scheduleBar,
            onItemTap: (s) => _focusOnDate(s.date),
          ),
          const SizedBox(height: 16),
          _expandableCard<AlarmItem>(
            section: _Section.alarm,
            title: AppStrings.t('cal_your_alarm'),
            items: alarms,
            previewCount: 3,
            emptyText: AppStrings.t('cal_empty_alarm'),
            itemBuilder: _alarmBar,
            onItemTap: (a) => _focusOnDate(a.date),
          ),
          const SizedBox(height: 16),
          _expandableCard<NoteItem>(
            section: _Section.notes,
            title: AppStrings.t('cal_your_notes'),
            items: _notes,
            previewCount: 2,
            emptyText: AppStrings.t('cal_empty_notes'),
            itemBuilder: _noteBar,
            onItemTap: _showNoteDetail,
          ),
        ],
      ),
    );
  }

  /// Tabel yang bisa memanjang. Saat terbuka: list bisa di-scroll dan tombol
  /// tambah (+) muncul di kanan atas dengan efek membesar.
  Widget _expandableCard<T>({
    required _Section section,
    required String title,
    required List<T> items,
    required int previewCount,
    required String emptyText,
    required Widget Function(T item, VoidCallback onTap) itemBuilder,
    required void Function(T item) onItemTap,
  }) {
    final expanded = _expanded == section;

    List<Widget> buildItems(Iterable<T> list) => [
          for (final it in list)
            itemBuilder(it, expanded ? () => onItemTap(it) : () => _toggle(section)),
        ];

    final Widget body;
    if (items.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyText,
          style: _text(12, color: AppColors.textDark.withValues(alpha: 0.5)),
        ),
      );
    } else if (expanded) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: buildItems(items)),
        ),
      );
    } else {
      body = Column(
        children: [
          ...buildItems(items.take(previewCount)),
          if (items.length > previewCount)
            TapScale(
              pressedScale: 0.95,
              onTap: () => _toggle(section),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  AppStrings.t('see_more', {'n': items.length - previewCount}),
                  style: _text(
                    11,
                    weight: FontWeight.w600,
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                TapScale(
                  pressedScale: 0.96,
                  onTap: () => _toggle(section),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: _text(15, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IgnorePointer(
                  ignoring: !expanded,
                  child: AnimatedScale(
                    scale: expanded ? 1 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: expanded ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: TapScale(
                        pressedScale: 0.88,
                        onTap: () => _openAddSheet(section),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.tersier,
                            shape: BoxShape.circle,
                            boxShadow: _blueShadow(blur: 10, dy: 3),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 22,
                            color: AppColors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(width: double.infinity, child: body),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BAR-BAR ISI TABEL
  // --------------------------------------------------------------------------

  /// Bar kegiatan: garis urgensi di kiri, lalu nama, hari/tanggal, keterangan.
  Widget _scheduleBar(ScheduleItem s, VoidCallback onTap) {
    final color = _urgencyColor(_urgencyOf(s.date));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        pressedScale: 0.97,
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 10, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(12.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dayName(s.date)}, ${_dateLabel(s.date)} · ${_fmtTime(s.time)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      10.5,
                      weight: FontWeight.w600,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      11,
                      color: AppColors.textDark.withValues(alpha: 0.75),
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

  /// Bar alarm: nama/tag di kiri, jam alarm di kanan.
  Widget _alarmBar(AlarmItem a, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        pressedScale: 0.97,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  size: 18,
                  color: AppColors.tersier,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(12.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _repeatLabel(a),
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
              const SizedBox(width: 8),
              Text(_fmtTime(a.time), style: _text(16, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  /// Bar notes: judul + cuplikan isi.
  Widget _noteBar(NoteItem n, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TapScale(
        pressedScale: 0.97,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(12.5, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                n.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _text(
                  11,
                  color: AppColors.textDark.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAMBAH DATA
  // --------------------------------------------------------------------------
  Future<void> _openAddSheet(_Section kind) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        kind: kind,
        initialDate: _selectedDay ?? DateTime.now(),
      ),
    );

    if (!mounted || result == null) return;

    String message = '';
    if (result is ScheduleItem) {
      _store.addSchedule(result);
      message = AppStrings.t('cal_added_sched');
    } else if (result is AlarmItem) {
      _store.addAlarm(result);
      message = AppStrings.t('cal_added_alarm');
    } else if (result is NoteItem) {
      _store.addNote(result);
      message = AppStrings.t('cal_added_note');
    }
    if (message.isNotEmpty) _toast(message);
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: _text(13, weight: FontWeight.w600, color: AppColors.onAccent),
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
}

// ============================================================================
// KARTU MELAYANG (dipakai popup tanggal dan detail notes)
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
        color: AppColors.surface,
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
        child: Icon(Icons.close_rounded, size: 16, color: AppColors.textDark),
      ),
    );
  }
}

/// Isi satu tanggal: kegiatan + alarm. Kalau kosong: pesan tidak ada kegiatan.
class _DayPopup extends StatelessWidget {
  final DateTime day;
  final List<ScheduleItem> schedules;
  final List<AlarmItem> alarms;

  const _DayPopup({
    required this.day,
    required this.schedules,
    required this.alarms,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor(_urgencyOf(day));
    final isEmpty = schedules.isEmpty && alarms.isEmpty;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            text,
            style: _text(
              11,
              weight: FontWeight.w600,
              color: AppColors.textDark.withValues(alpha: 0.5),
            ),
          ),
        );

    return _FloatingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_fullDate(day), style: _text(14, weight: FontWeight.w700)),
              ),
              const _CloseButton(),
            ],
          ),
          const SizedBox(height: 12),
          if (isEmpty)
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
                    Icons.event_available_rounded,
                    size: 26,
                    color: AppColors.tersier.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.t('cal_none_on_date'),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (schedules.isNotEmpty) label(AppStrings.t('legend_activity')),
                    for (final s in schedules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: urgencyColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _text(12.5, weight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_fmtTime(s.time)} · ${s.description}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _text(
                                      10.5,
                                      color: AppColors.textDark.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (alarms.isNotEmpty) label('Alarm'),
                    for (final a in alarms)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.alarm_rounded,
                              size: 18,
                              color: AppColors.tersier,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _text(12.5, weight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              _fmtTime(a.time),
                              style: _text(13, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Isi lengkap sebuah notes.
class _NoteDetail extends StatelessWidget {
  final NoteItem note;

  const _NoteDetail({required this.note});

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
                child: Text(note.title, style: _text(15, weight: FontWeight.w700)),
              ),
              const _CloseButton(),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
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
                  note.content.isEmpty ? AppStrings.t('cal_no_content') : note.content,
                  style: _text(13, color: AppColors.textDark.withValues(alpha: 0.85)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORM TAMBAH (schedule / alarm / notes), muncul dari bawah
// ============================================================================

class _AddSheet extends StatefulWidget {
  final _Section kind;
  final DateTime initialDate;

  const _AddSheet({required this.kind, required this.initialDate});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  AlarmRepeat _repeat = AlarmRepeat.once;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate;
    _date = DateTime(d.year, d.month, d.day);
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  Widget _pickerTheme(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.tersier,
          onPrimary: AppColors.onAccent,
          onSurface: AppColors.textDark,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final Object result = switch (widget.kind) {
      _Section.schedule => ScheduleItem(
          title: title,
          description: body.isEmpty ? '-' : body,
          date: _date,
          time: _time,
        ),
      _Section.alarm => AlarmItem(
          title: title,
          date: _date,
          time: _time,
          repeat: _repeat,
        ),
      _Section.notes => NoteItem(title: title, content: body),
    };
    Navigator.pop(context, result);
  }

  // ---- potongan UI form ----

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
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

  Widget _field(TextEditingController ctrl, String hint, {int lines = 1}) {
    return TextField(
      controller: ctrl,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      style: _text(14),
      cursorColor: AppColors.tersier,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _text(13, color: AppColors.textDark.withValues(alpha: 0.4)),
        filled: true,
        fillColor: _fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.tersier, width: 1.4),
        ),
      ),
    );
  }

  Widget _pickerPill(IconData icon, String label, VoidCallback onTap) {
    return TapScale(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.tersier),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(13, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _repeatChip(String label, AlarmRepeat value) {
    final selected = _repeat == value;
    return Expanded(
      child: TapScale(
        pressedScale: 0.94,
        onTap: () => setState(() => _repeat = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.tersier : _fieldBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: _text(
              12,
              weight: FontWeight.w600,
              color: selected ? AppColors.onAccent : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final sheetTitle = switch (kind) {
      _Section.schedule => AppStrings.t('cal_add_sched'),
      _Section.alarm => AppStrings.t('cal_add_alarm'),
      _Section.notes => AppStrings.t('cal_add_notes'),
    };
    final titleLabel = switch (kind) {
      _Section.schedule => AppStrings.t('cal_name_sched'),
      _Section.alarm => AppStrings.t('cal_name_alarm'),
      _Section.notes => AppStrings.t('cal_name_notes'),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: _blueShadow(blur: 24, dy: -6, alpha: 0.6),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _softBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(sheetTitle, style: _text(17, weight: FontWeight.w700)),
                _label(titleLabel),
                _field(_titleCtrl, AppStrings.t('cal_type_here')),
                if (kind == _Section.schedule) ...[
                  _label(AppStrings.t('cal_desc')),
                  _field(_bodyCtrl, AppStrings.t('cal_desc_hint'), lines: 2),
                ],
                if (kind == _Section.notes) ...[
                  _label(AppStrings.t('cal_note_body')),
                  _field(_bodyCtrl, AppStrings.t('cal_note_hint'), lines: 6),
                ],
                if (kind != _Section.notes) ...[
                  _label(kind == _Section.alarm ? AppStrings.t('cal_date_time_alarm') : AppStrings.t('cal_date_time')),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _pickerPill(
                          Icons.event_rounded,
                          '${_date.day} ${_shortMonths[_date.month - 1]} ${_date.year}',
                          _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _pickerPill(
                          Icons.schedule_rounded,
                          _fmtTime(_time),
                          _pickTime,
                        ),
                      ),
                    ],
                  ),
                ],
                if (kind == _Section.alarm) ...[
                  _label(AppStrings.t('cal_repeat')),
                  Row(
                    children: [
                      _repeatChip(AppStrings.t('cal_once'), AlarmRepeat.once),
                      const SizedBox(width: 8),
                      _repeatChip(AppStrings.t('cal_daily'), AlarmRepeat.daily),
                      const SizedBox(width: 8),
                      _repeatChip(AppStrings.t('cal_weekly'), AlarmRepeat.weekly),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TapScale(
                        pressedScale: 0.95,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _softBorder, width: 1.4),
                          ),
                          child: Text(AppStrings.t('cancel_btn'), style: _text(14, weight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TapScale(
                        pressedScale: 0.95,
                        onTap: _canSave ? _save : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.tersier.withValues(alpha: _canSave ? 1 : 0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            AppStrings.t('save_btn'),
                            style: _text(14, weight: FontWeight.w700, color: AppColors.onAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
