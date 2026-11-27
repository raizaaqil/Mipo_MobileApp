import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_palette.dart';
import '../core/app_theme.dart';
import '../providers/settings_provider.dart';
import 'tap_scale.dart';

/// Membungkus halaman agar ikut mode terang/gelap dengan transisi halus.
class MipoThemed extends StatelessWidget {
  final Widget child;
  const MipoThemed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<SettingsProvider>().darkMode;
    return AnimatedTheme(
      data: AppTheme.build(dark ? Brightness.dark : Brightness.light),
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

/// Muncul pelan dari bawah sambil memudar masuk. Pakai delay untuk efek berurutan.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.beginOffset = const Offset(0, 0.12),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
            .animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Melayang naik-turun pelan (idle animation) untuk logo / karakter.
class Floating extends StatefulWidget {
  final Widget child;
  final double distance;
  const Floating({super.key, required this.child, this.distance = 7});

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, (t - 0.5) * 2 * widget.distance),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class MipoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;
  final bool expand;
  final IconData? icon;

  const MipoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.loading = false,
    this.expand = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final fg = filled ? p.onAccent : p.accent;
    final button = TapScale(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? p.accent : p.accent.withValues(alpha: 0.55))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: filled ? null : Border.all(color: p.accent, width: 1.6),
          boxShadow: filled && enabled
              ? [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class MipoTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const MipoTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<MipoTextField> createState() => _MipoTextFieldState();
}

class _MipoTextFieldState extends State<MipoTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);
  bool _hidden = true;

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = _focus.hasFocus;
    final hasError = widget.errorText != null;
    final border = hasError
        ? AppColors.urgencyPanic
        : (focused ? p.accent : p.accent.withValues(alpha: 0.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: focused ? p.accent : p.textMuted,
            ),
            child: Text(widget.label),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled ? p.fieldFill : p.panelSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: focused ? 2 : 1.4),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.22),
                      blurRadius: 12,
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            obscureText: widget.obscure && _hidden,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            cursorColor: p.accent,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: p.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      color: AppColors.urgencyPanic,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class MipoPill extends StatelessWidget {
  final String text;
  final bool filled;
  final double fontSize;
  const MipoPill(this.text, {super.key, this.filled = true, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? p.accent : p.panel,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: filled ? p.onAccent : p.accent,
        ),
      ),
    );
  }
}

/// Saklar Indonesia / English dengan indikator yang bergeser halus.
class LanguageSwitch extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const LanguageSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 220,
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment:
                value == 'id' ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _segment(p, 'Indonesia', 'id')),
              Expanded(child: _segment(p, 'English', 'en')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(MipoPalette p, String label, String code) {
    final selected = value == code;
    return TapScale(
      onTap: () => onChanged(code),
      pressedScale: 0.92,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: selected ? p.onAccent : p.accent,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Dialog dengan animasi membesar halus. Warna mengikuti tema halaman pemanggil.
Future<T?> showMipoDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  final theme = Theme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'dialog',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => Theme(
      data: theme,
      child: SafeArea(child: Center(child: Builder(builder: builder))),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class MipoDialogCard extends StatelessWidget {
  final Widget child;
  const MipoDialogCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: p.surface,
          elevation: 8,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi Ya / Batal. Mengembalikan true jika memilih Ya.
Future<bool> showMipoConfirm(
  BuildContext context, {
  required String message,
  required String yesLabel,
  required String cancelLabel,
}) async {
  final result = await showMipoDialog<bool>(
    context,
    builder: (ctx) => MipoDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ctx.palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MipoButton(
                  label: cancelLabel,
                  filled: false,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MipoButton(
                  label: yesLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

void showMipoSnack(BuildContext context, String message, {bool error = false}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.urgencyPanic : p.accent,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(seconds: 3),
        content: Text(
          message,
          style: TextStyle(
            color: error ? AppColors.onAccent : p.onAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
}
