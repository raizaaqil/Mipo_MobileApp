import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../widgets/tap_scale.dart';

// ===========================================================
// KONSTANTA & GAYA (sama dengan Home, Pet, dan Progress)
// ===========================================================

const Color _softBorder = Color(0xFFE3F1FF);
const Color _fieldBg = Color(0xFFF3F8FE);
const int _maxPinned = 10;

/// Biru muda untuk bubble AI, chat aktif, dan kartu terpilih.
final Color _tableColor =
    Color.alphaBlend(AppColors.primer.withValues(alpha: 0.5), Colors.white);

/// Satu-satunya gaya teks di halaman ini (hanya font Huninn).
TextStyle _t({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.textDark,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Huninn',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

List<BoxShadow> _blueShadow({double blur = 16, double dy = 4, double alpha = 0.45}) {
  return [
    BoxShadow(
      color: AppColors.sekunder.withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

/// Tombol bulat putih bergaya sama dengan tombol kembali di halaman lain.
Widget _circleButton(IconData icon, VoidCallback onTap, {double iconSize = 20}) {
  return TapScale(
    pressedScale: 0.9,
    onTap: onTap,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _softBorder, width: 1.2),
        boxShadow: _blueShadow(),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.tersier),
    ),
  );
}

// ===========================================================
// MODEL
// ===========================================================

class ScheduleItem {
  final String time;
  final String activity;

  const ScheduleItem(this.time, this.activity);
}

/// Satu rekomendasi susunan jadwal dari AI.
class ScheduleOption {
  final String title;
  final List<ScheduleItem> items;

  const ScheduleOption({required this.title, required this.items});
}

class _Message {
  final String text;
  final bool isUser;
  final List<ScheduleOption>? options;
  int? acceptedIndex;

  _Message({
    required this.text,
    required this.isUser,
    this.options,
  });
}

class _Chat {
  final String id;
  String title;
  bool pinned;
  final List<_Message> messages;

  _Chat({
    required this.id,
    required this.title,
    this.pinned = false,
    List<_Message>? messages,
  }) : messages = messages ?? [];
}

// ===========================================================
// HALAMAN SMART AI
// ===========================================================

class SmartAiView extends StatefulWidget {
  final VoidCallback? onHomeTap;

  /// Dipanggil saat user menyetujui rekomendasi jadwal.
  /// Hubungkan ke list jadwal & kalender milik user.
  final ValueChanged<ScheduleOption>? onScheduleAccepted;

  const SmartAiView({
    super.key,
    this.onHomeTap,
    this.onScheduleAccepted,
  });

  @override
  State<SmartAiView> createState() => _SmartAiViewState();
}

class _SmartAiViewState extends State<SmartAiView> {
  final FocusNode _inputFocus = FocusNode();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _historySearchController =
      TextEditingController();
  final GlobalKey _inputKey = GlobalKey();
  final Random _random = Random();

  static const List<String> _greetings = [
    'Ada tugas atau deadline apa yang perlu diatur hari ini?',
    'Mau cek jadwal kegiatanmu hari ini?',
    'Butuh bantuan menyusun waktu untuk tugasmu?',
    'Mau pasang alarm untuk kegiatan penting?',
    'Ada deadline yang sedang mengejarmu?',
    'Kegiatan apa yang ingin kamu rencanakan hari ini?',
  ];

  bool _isFocused = false;
  bool _isSidebarOpen = false;
  bool _isWaiting = false;
  String? _pinNotice;
  late String _greeting;

  String? _activeChatId;

  final List<_Chat> _chats = [
    _seedChat('1', 'Atur Waktu Ngerjain Tugas Desain', pinned: true),
    _seedChat('2', 'Bagi Tugas Berdasarkan Deadline', pinned: true),
    _seedChat('3', 'Jadwal Revisi Sebelum Presentasi', pinned: true),
    _seedChat('4', 'Atur Jadwal Seminggu Penuh'),
    _seedChat('5', 'Jadwal Kuliah dan Organisasi'),
  ];

  static _Chat _seedChat(String id, String title, {bool pinned = false}) {
    return _Chat(
      id: id,
      title: title,
      pinned: pinned,
      messages: [
        _Message(text: title, isUser: true),
        _Message(
          text: 'Siap, aku bantu susun jadwalnya. Kamu bisa minta saran '
              'kapan saja.',
          isUser: false,
        ),
      ],
    );
  }

  // Contoh rekomendasi. Ganti dengan respons backend nanti.
  static const List<ScheduleOption> _sampleOptions = [
    ScheduleOption(
      title: 'Fokus pagi, santai malam',
      items: [
        ScheduleItem('08.00', 'Kerjakan bagian tersulit tugas'),
        ScheduleItem('10.30', 'Istirahat dan makan siang'),
        ScheduleItem('13.00', 'Lanjutkan revisi'),
        ScheduleItem('19.30', 'Review ringan dan siapkan besok'),
      ],
    ),
    ScheduleOption(
      title: 'Mulai siang, selesai sore',
      items: [
        ScheduleItem('11.00', 'Kumpulkan referensi dan bahan'),
        ScheduleItem('13.30', 'Kerjakan inti tugas'),
        ScheduleItem('16.00', 'Istirahat singkat'),
        ScheduleItem('16.30', 'Finalisasi dan cek ulang'),
      ],
    ),
  ];

  _Chat? get _activeChat {
    for (final c in _chats) {
      if (c.id == _activeChatId) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _greeting = _greetings[_random.nextInt(_greetings.length)];
    _inputFocus.addListener(() {
      if (!mounted) return;
      setState(() => _isFocused = _inputFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // LOGIKA
  // ---------------------------------------------------------

  void _pickNewGreeting() {
    String next;
    do {
      next = _greetings[_random.nextInt(_greetings.length)];
    } while (next == _greeting && _greetings.length > 1);
    _greeting = next;
  }

  void _openSidebar() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() => _isSidebarOpen = true);
  }

  void _closeSidebar() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSidebarOpen = false);
  }

  void _goHome() {
    _closeSidebar();
    if (widget.onHomeTap != null) {
      widget.onHomeTap!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _startNewChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeChatId = null;
      _isSidebarOpen = false;
      _pickNewGreeting();
    });
  }

  void _openChat(_Chat chat) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeChatId = chat.id;
      _isSidebarOpen = false;
    });
    _scrollToBottom(jump: true);
  }

  void _togglePin(_Chat chat) {
    HapticFeedback.selectionClick();
    if (!chat.pinned && _chats.where((c) => c.pinned).length >= _maxPinned) {
      _showPinNotice(
        'Maksimal $_maxPinned chat yang bisa dipin. '
        'Lepas pin salah satu dulu.',
      );
      return;
    }
    setState(() => chat.pinned = !chat.pinned);
  }

  void _showPinNotice(String message) {
    setState(() => _pinNotice = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pinNotice == message) {
        setState(() => _pinNotice = null);
      }
    });
  }

  String _makeTitle(String text) {
    final clean = text.replaceAll('\n', ' ');
    return clean.length > 32 ? '${clean.substring(0, 32)}…' : clean;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isWaiting) return;

    HapticFeedback.lightImpact();
    _inputController.clear();

    final _Chat chat;
    final existing = _activeChat;
    if (existing == null) {
      chat = _Chat(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _makeTitle(text),
      );
      _chats.insert(0, chat);
      _activeChatId = chat.id;
    } else {
      chat = existing;
    }

    setState(() {
      chat.messages.add(_Message(text: text, isUser: true));
      _isWaiting = true;
    });
    _scrollToBottom();

    // TODO(backend): ganti dengan pemanggilan AI yang sebenarnya.
    final reply = await _mockAiReply(text);
    if (!mounted) return;

    setState(() {
      chat.messages.add(reply);
      _isWaiting = false;
    });
    _scrollToBottom();
  }

  Future<_Message> _mockAiReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    final p = prompt.toLowerCase();
    const keys = ['saran', 'rekomendasi', 'atur', 'susun', 'bagi', 'jadwalkan'];
    final wantsAdvice = keys.any((k) => p.contains(k));

    if (wantsAdvice) {
      return _Message(
        text: 'Ini 2 rekomendasi susunan jadwal yang bisa kamu pilih:',
        isUser: false,
        options: _sampleOptions,
      );
    }
    return _Message(
      text: 'Aku bisa bantu soal jadwal, alarm, tugas, file dokumen, dan '
          'deadline. Coba minta saran penyusunan jadwal, ya!',
      isUser: false,
    );
  }

  Future<void> _selectOption(_Message msg, int index) async {
    if (msg.acceptedIndex != null) return;
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();

    final option = msg.options![index];

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => _ConfirmDialog(option: option),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    setState(() {
      msg.acceptedIndex = index;
      _activeChat?.messages.add(
        _Message(
          text: 'Siap! "${option.title}" sudah masuk ke daftar jadwal '
              'dan kalendermu.',
          isUser: false,
        ),
      );
    });
    widget.onScheduleAccepted?.call(option);
    _scrollToBottom();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Jadwal ditambahkan ke kalender',
          style: _t(size: 13, weight: FontWeight.w600, color: Colors.white),
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

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sidebarWidth = min(320.0, width * 0.85);

    return Scaffold(
      // Biru muda Home. Samakan dengan latar Home jika berbeda.
      backgroundColor: AppColors.baseBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // HALAMAN
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildSheet()),
                ],
              ),
            ),
          ),

          // OVERLAY
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isSidebarOpen,
              child: GestureDetector(
                onTap: _closeSidebar,
                child: AnimatedOpacity(
                  opacity: _isSidebarOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(color: Colors.black.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ),

          // SIDEBAR
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            left: _isSidebarOpen ? 0 : -(sidebarWidth + 40),
            width: sidebarWidth,
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // HEADER: tombol menu bulat + pill judul (seperti halaman lain)
  // ---------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _circleButton(Icons.menu_rounded, _openSidebar, iconSize: 22),
            ),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 22),
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
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: AppColors.tersier,
                  ),
                  const SizedBox(width: 8),
                  Text('Smart AI', style: _t(size: 16, weight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // PANEL PUTIH (bayangan biru di atas, seperti halaman Pet)
  // ---------------------------------------------------------

  Widget _buildSheet() {
    final chat = _activeChat;
    final hasMessages = chat != null && chat.messages.isNotEmpty;
    const radius = BorderRadius.vertical(top: Radius.circular(32));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: _blueShadow(blur: 24, dy: -6, alpha: 0.55),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: hasMessages
            ? Column(
                children: [
                  Expanded(child: _buildMessages(chat)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: _buildInputBar(),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primer.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 30,
                          color: AppColors.tersier,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _greeting,
                          key: ValueKey(_greeting),
                          textAlign: TextAlign.center,
                          style: _t(
                            size: 22,
                            weight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildInputBar(),
                      SizedBox(
                        height: 60 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------
  // INPUT "TANYA AKU" + TOMBOL KIRIM
  // ---------------------------------------------------------

  Widget _buildInputBar() {
    final hasText = _inputController.text.trim().isNotEmpty;

    return KeyedSubtree(
      key: _inputKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _inputFocus.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isFocused ? AppColors.tersier : _softBorder,
              width: _isFocused ? 1.6 : 1.2,
            ),
            boxShadow: _blueShadow(
              blur: _isFocused ? 16 : 12,
              dy: 3,
              alpha: _isFocused ? 0.5 : 0.35,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    _send();
                    _inputFocus.requestFocus();
                  },
                  style: _t(size: 14, weight: FontWeight.w600),
                  cursorColor: AppColors.tersier,
                  decoration: InputDecoration(
                    hintText: 'Tanya aku',
                    hintStyle: _t(
                      size: 14,
                      color: AppColors.textDark.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: hasText ? 1 : 0.9,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: TapScale(
                  pressedScale: 0.88,
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasText
                          ? AppColors.tersier
                          : AppColors.tersier.withValues(alpha: 0.35),
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // DAFTAR PESAN
  // ---------------------------------------------------------

  Widget _buildMessages(_Chat chat) {
    final screenWidth = MediaQuery.of(context).size.width;
    final count = chat.messages.length + (_isWaiting ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i >= chat.messages.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypingBubble(),
            ),
          );
        }
        return _buildMessage(chat.messages[i], screenWidth);
      },
    );
  }

  Widget _buildMessage(_Message m, double screenWidth) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: m.isUser ? AppColors.tersier : _tableColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(m.isUser ? 20 : 6),
          bottomRight: Radius.circular(m.isUser ? 6 : 20),
        ),
      ),
      child: Text(
        m.text,
        style: _t(
          size: 13.5,
          weight: FontWeight.w600,
          color: m.isUser ? Colors.white : AppColors.textDark,
          height: 1.4,
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      key: ObjectKey(m),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              bubble,
              if (m.options != null)
                for (var i = 0; i < m.options!.length; i++)
                  SizedBox(
                    width: screenWidth - 32,
                    child: _buildOptionCard(m, i),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(_Message msg, int i) {
    final option = msg.options![i];
    final accepted = msg.acceptedIndex == i;
    final dimmed = msg.acceptedIndex != null && !accepted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accepted ? _tableColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accepted ? AppColors.tersier : _softBorder,
            width: accepted ? 1.8 : 1.2,
          ),
          boxShadow: _blueShadow(blur: 12, dy: 3, alpha: 0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tersier,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Opsi ${i + 1}',
                    style: _t(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.title,
                    style: _t(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in option.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        item.time,
                        style: _t(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.tersier,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.activity,
                        style: _t(
                          size: 12.5,
                          color: AppColors.textDark.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TapScale(
              pressedScale: 0.96,
              onTap: msg.acceptedIndex == null
                  ? () => _selectOption(msg, i)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accepted ? Colors.white : AppColors.tersier,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (accepted) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.tersier,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      accepted ? 'Terpilih' : 'Pilih jadwal ini',
                      style: _t(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: accepted ? AppColors.textDark : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // SIDEBAR
  // ---------------------------------------------------------

  Widget _buildSidebar() {
    final query = _historySearchController.text.trim().toLowerCase();
    final pinnedAll = _chats.where((c) => c.pinned).toList();
    final pinned = pinnedAll
        .where((c) => c.title.toLowerCase().contains(query))
        .toList();
    final history =
        _chats.where((c) => c.title.toLowerCase().contains(query)).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
          border: Border.all(color: _softBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.sekunder.withValues(alpha: 0.5),
              blurRadius: 28,
              offset: const Offset(6, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HOME (KIRI) & TUTUP (KANAN)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(Icons.home_rounded, _goHome, iconSize: 22),
                    _circleButton(
                      Icons.arrow_back_ios_new_rounded,
                      _closeSidebar,
                      iconSize: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SEARCH RIWAYAT
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: TextField(
                    controller: _historySearchController,
                    onChanged: (_) => setState(() {}),
                    cursorColor: AppColors.tersier,
                    style: _t(size: 13.5, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Cari percakapan',
                      hintStyle: _t(
                        size: 13.5,
                        color: AppColors.textDark.withValues(alpha: 0.4),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.tersier,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // NEW CHAT
                _sidebarAction(
                  icon: Icons.add_comment_rounded,
                  label: 'New Chat',
                  onTap: _startNewChat,
                ),

                // NOTIFIKASI BATAS PIN
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _pinNotice == null
                      ? const SizedBox(width: double.infinity)
                      : Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _tableColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _pinNotice!,
                            style: _t(size: 12, weight: FontWeight.w600),
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // PINNED + HISTORY (SCROLL)
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _sectionTitle('Pinned (${pinnedAll.length}/$_maxPinned)'),
                      const SizedBox(height: 8),
                      if (pinned.isEmpty)
                        _emptyHint('Belum ada chat yang dipin')
                      else
                        for (final c in pinned)
                          _chatTile(c, key: ValueKey('p-${c.id}')),
                      const SizedBox(height: 20),
                      _sectionTitle('History'),
                      const SizedBox(height: 8),
                      if (history.isEmpty)
                        _emptyHint('Tidak ada percakapan')
                      else
                        for (final c in history)
                          _chatTile(c, key: ValueKey('h-${c.id}')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: _t(size: 14.5, weight: FontWeight.w700)),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: _t(size: 12, color: AppColors.textDark.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _sidebarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TapScale(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _tableColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.tersier),
            const SizedBox(width: 12),
            Text(label, style: _t(size: 14, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(_Chat chat, {Key? key}) {
    final isActive = chat.id == _activeChatId;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 4),
      child: TapScale(
        pressedScale: 0.97,
        onTap: () => _openChat(chat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
          decoration: BoxDecoration(
            color: isActive ? _tableColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(
                    size: 12.5,
                    weight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textDark
                        .withValues(alpha: isActive ? 1 : 0.8),
                  ),
                ),
              ),
              TapScale(
                pressedScale: 0.8,
                onTap: () => _togglePin(chat),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      chat.pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      key: ValueKey(chat.pinned),
                      size: 18,
                      color: chat.pinned
                          ? AppColors.tersier
                          : AppColors.textDark.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// DIALOG KONFIRMASI JADWAL (gaya kartu melayang)
// ===========================================================

class _ConfirmDialog extends StatelessWidget {
  final ScheduleOption option;

  const _ConfirmDialog({required this.option});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _softBorder, width: 1.2),
            boxShadow: _blueShadow(blur: 24, dy: 8, alpha: 0.6),
          ),
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
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.tersier,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pakai jadwal ini?',
                style: _t(size: 16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                option.title,
                textAlign: TextAlign.center,
                style: _t(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.tersier,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jadwal akan otomatis masuk ke daftar jadwal dan '
                'kalendermu.',
                textAlign: TextAlign.center,
                style: _t(
                  size: 12.5,
                  color: AppColors.textDark.withValues(alpha: 0.7),
                  height: 1.4,
                ),
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
                        child: Text(
                          'Kembali',
                          style: _t(size: 14, weight: FontWeight.w700),
                        ),
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
                          color: AppColors.tersier,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _blueShadow(blur: 10, dy: 3, alpha: 0.35),
                        ),
                        child: Text(
                          'Setuju',
                          style: _t(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }
}

// ===========================================================
// INDIKATOR MENGETIK
// ===========================================================

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _tableColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.18) % 1.0;
            final y = -5 * sin(t * pi);
            return Transform.translate(
              offset: Offset(0, y),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: const BoxDecoration(
                  color: AppColors.tersier,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}