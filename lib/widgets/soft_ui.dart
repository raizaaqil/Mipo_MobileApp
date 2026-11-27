import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import 'tap_scale.dart';


Color get softBorder => AppColors.softBorder;
Color get softFill => AppColors.softFill;

/// Shadow biru yang sama dengan Home.
List<BoxShadow> softShadow({double blur = 10, double dy = 2, double alpha = 0.3}) {
  return [
    BoxShadow(
      color: AppColors.sekunder.withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

TextStyle softText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Huninn',
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textDark,
    height: height,
  );
}

// ----------------------------------------------------------------------------
// ANIMASI MASUK (fade + geser sedikit dari bawah)
// ----------------------------------------------------------------------------
class SoftFadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const SoftFadeIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<SoftFadeIn> createState() => _SoftFadeInState();
}

class _SoftFadeInState extends State<SoftFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    final total = widget.delayMs + 420;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total))
      ..forward();
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(widget.delayMs / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * 14),
          child: child,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// KERANGKA HALAMAN: header melayang (tombol kembali + judul) + isi bisa di-scroll
// ----------------------------------------------------------------------------
class SoftPage extends StatelessWidget {
  final String title;
  final Widget child;
  const SoftPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const circle = 46.0;

    return Scaffold(
      backgroundColor: AppColors.primer,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  TapScale(
                    pressedScale: 0.9,
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: circle,
                      height: circle,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: softBorder, width: 1.2),
                        boxShadow: softShadow(blur: 8, alpha: 0.35),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.tersier,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: circle,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(circle / 2),
                        border: Border.all(color: softBorder, width: 1.2),
                        boxShadow: softShadow(blur: 8, alpha: 0.35),
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: softText(15, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Padding di DALAM scroll supaya shadow tidak terpotong.
                padding: EdgeInsets.fromLTRB(16, 18, 16, 28 + media.padding.bottom),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// KARTU PUTIH: semua sudut sama (tidak ada bentuk atas/bawah yang beda)
// ----------------------------------------------------------------------------
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool shadow;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.color,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: softBorder, width: 1.2),
        boxShadow: shadow ? softShadow(blur: 14, dy: 4) : null,
      ),
      child: child,
    );
  }
}

/// Bar kecil abu-biru (seperti bar kegiatan di Home).
class SoftBar extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const SoftBar({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: softFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
    if (onTap == null) return bar;
    return TapScale(pressedScale: 0.97, onTap: onTap!, child: bar);
  }
}

// ----------------------------------------------------------------------------
// TOMBOL
// ----------------------------------------------------------------------------
class SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool loading;

  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.onAccent : AppColors.tersier;
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: TapScale(
        pressedScale: 0.96,
        onTap: () {
          if (enabled) onPressed!();
        },
        child: Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.tersier : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: filled ? null : Border.all(color: softBorder, width: 1.4),
            boxShadow: softShadow(blur: 8, dy: 2, alpha: filled ? 0.4 : 0.25),
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: softText(14, weight: FontWeight.w700, color: fg)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// KOLOM ISIAN
// ----------------------------------------------------------------------------
class SoftField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscure;
  final bool enabled;
  final int? maxLength;
  final int? minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final bool pill;

  const SoftField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscure = false,
    this.enabled = true,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(pill ? 24 : 18);
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c, width: w),
        );

    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      maxLength: maxLength,
      minLines: obscure ? 1 : minLines,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.tersier,
      style: softText(13.5, weight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        counterText: '',
        filled: true,
        fillColor: enabled ? softFill : softFill.withValues(alpha: 0.6),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: pill ? 12 : 14,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: AppColors.tersier),
        labelStyle: softText(13, color: AppColors.textDark.withValues(alpha: 0.55)),
        floatingLabelStyle: softText(12.5, weight: FontWeight.w600, color: AppColors.tersier),
        hintStyle: softText(13, color: AppColors.textDark.withValues(alpha: 0.4)),
        errorStyle: softText(11.5, color: AppColors.urgencyPanic),
        border: border(softBorder),
        enabledBorder: border(softBorder),
        disabledBorder: border(softBorder.withValues(alpha: 0.6)),
        focusedBorder: border(AppColors.tersier, 1.4),
        errorBorder: border(AppColors.urgencyPanic),
        focusedErrorBorder: border(AppColors.urgencyPanic, 1.4),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// DIALOG (kartu putih, semua sudut membulat, tidak terpotong keyboard)
// ----------------------------------------------------------------------------
Future<T?> showSoftDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppStrings.t('close'),
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  // ruang untuk shadow agar tidak terpotong
                  padding: const EdgeInsets.all(20),
                  child: SoftCard(
                    radius: 28,
                    padding: const EdgeInsets.all(22),
                    child: builder(ctx),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Judul di dalam dialog.
class SoftDialogTitle extends StatelessWidget {
  final String text;
  const SoftDialogTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: softText(14.5, weight: FontWeight.w700)),
      ),
    );
  }
}

/// Dua tombol sejajar (batal + simpan/kirim).
class SoftDialogActions extends StatelessWidget {
  final String cancelLabel;
  final String okLabel;
  final VoidCallback onOk;
  final bool loading;

  const SoftDialogActions({
    super.key,
    required this.cancelLabel,
    required this.okLabel,
    required this.onOk,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SoftButton(
            label: cancelLabel,
            filled: false,
            onPressed: loading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SoftButton(label: okLabel, loading: loading, onPressed: onOk),
        ),
      ],
    );
  }
}

/// Dialog pemberitahuan singkat dengan satu tombol.
Future<void> showSoftNotice(
  BuildContext context, {
  required String message,
  String? okLabel,
}) {
  return showSoftDialog<void>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: softText(14, weight: FontWeight.w700, height: 1.4),
        ),
        const SizedBox(height: 18),
        SoftButton(
            label: okLabel ?? AppStrings.t('ok'),
            onPressed: () => Navigator.of(ctx).pop()),
      ],
    ),
  );
}

/// Dialog konfirmasi ya / batal. Mengembalikan true kalau dipilih "ya".
Future<bool> showSoftConfirm(
  BuildContext context, {
  required String message,
  required String yesLabel,
  required String cancelLabel,
}) async {
  final result = await showSoftDialog<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: softText(14, weight: FontWeight.w700, height: 1.4),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SoftButton(
                label: cancelLabel,
                filled: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SoftButton(
                label: yesLabel,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Snackbar melayang bergaya putih + border biru.
void showSoftSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: softBorder, width: 1.2),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: softText(13, weight: FontWeight.w600),
        ),
      ),
    );
}
