import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import 'tap_scale.dart';

// ============================================================================
// KOMPONEN BERSAMA HALAMAN WELCOME / LOGIN / REGISTER
// Gaya disamakan dengan HomeView: latar biru (primer), panel putih dengan
// shadow biru, font Huninn, border lembut, dan interaksi TapScale.
// ============================================================================

const kAuthSoftBorder = Color(0xFFE3F1FF);
const kAuthFieldBg = Color(0xFFF3F8FE);

/// Lebar maksimal kartu, supaya di layar lebar (tablet/web) tetap presisi.
const double kAuthCardMaxWidth = 420;

TextStyle authText(
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

List<BoxShadow> authBlueShadow({
  double blur = 8,
  double dy = 2,
  double alpha = 0.45,
}) {
  return [
    BoxShadow(
      color: AppColors.sekunder.withValues(alpha: alpha),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
  ];
}

// ----------------------------------------------------------------------------
// SCAFFOLD: latar biru + (opsional) tombol kembali bulat seperti tombol menu Home
// ----------------------------------------------------------------------------
class AuthScaffold extends StatelessWidget {
  /// Isi di atas kartu (mis. GIF Mipo), tampil langsung di latar biru.
  final Widget? header;
  final Widget child;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.child,
    this.header,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Jarak atas/bawah sama besar supaya kartu terlihat seimbang.
    final vertical = showBack ? media.padding.top + 70 : media.padding.top + 24;

    return Scaffold(
      backgroundColor: AppColors.primer,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  vertical,
                  20,
                  24 + media.padding.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight -
                            vertical -
                            24 -
                            media.padding.bottom)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: kAuthCardMaxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (header != null) ...[
                            Center(child: header!),
                            const SizedBox(height: 14),
                          ],
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (showBack)
            Positioned(
              top: media.padding.top + 8,
              left: 16,
              child: TapScale(
                pressedScale: 0.9,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kAuthSoftBorder, width: 1.2),
                    boxShadow: authBlueShadow(blur: 4, dy: 1, alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.tersier,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// KARTU PUTIH: keempat sudut sama (radius 32), padding sama di semua sisi,
// shadow biru.
// ----------------------------------------------------------------------------
class AuthCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const AuthCard({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: kAuthSoftBorder, width: 1.2),
        boxShadow: authBlueShadow(blur: 18, dy: 4, alpha: 0.35),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: authText(20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// TOMBOL: pil bulat (tinggi 48), TapScale seperti tombol di Home.
// ----------------------------------------------------------------------------
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool loading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.tersier;

    return TapScale(
      pressedScale: 0.97,
      onTap: () {
        if (!loading) onPressed();
      },
      child: Container(
        height: 48,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.tersier : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: filled ? AppColors.tersier : kAuthSoftBorder,
            width: 1.2,
          ),
          boxShadow: authBlueShadow(blur: 4, dy: 1, alpha: 0.2),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Text(label, style: authText(14, weight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// BARIS TAUTAN: "Belum punya akun? Daftar"
// ----------------------------------------------------------------------------
class AuthLinkRow extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;

  const AuthLinkRow({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: authText(12.5, color: AppColors.textDark.withValues(alpha: 0.6)),
        ),
        AuthTextLink(label: action, onTap: onTap, bold: true),
      ],
    );
  }
}

class AuthTextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool bold;

  const AuthTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      pressedScale: 0.96,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          style: authText(
            12.5,
            weight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.tersier,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// INPUT: latar sama dengan bar di Home (0xFFF3F8FE), border lembut, fokus biru.
// ----------------------------------------------------------------------------
class AuthTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.tersier,
      style: authText(14, weight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: authText(
          13,
          color: AppColors.textDark.withValues(alpha: 0.55),
        ),
        floatingLabelStyle: authText(
          13,
          weight: FontWeight.w700,
          color: AppColors.tersier,
        ),
        errorText: widget.errorText,
        errorStyle: authText(11.5, color: AppColors.urgencyPanic),
        counterText: '',
        filled: true,
        fillColor: kAuthFieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(kAuthSoftBorder),
        enabledBorder: _border(kAuthSoftBorder),
        focusedBorder: _border(AppColors.tersier, width: 1.4),
        errorBorder: _border(AppColors.urgencyPanic),
        focusedErrorBorder: _border(AppColors.urgencyPanic, width: 1.4),
        suffixIcon: widget.obscure
            ? TapScale(
                pressedScale: 0.85,
                onTap: () => setState(() => _hidden = !_hidden),
                child: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.tersier,
                ),
              )
            : null,
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// DIALOG: kartu putih, sudut sama, shadow biru.
// ----------------------------------------------------------------------------
Future<T?> showAuthDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kAuthCardMaxWidth),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: kAuthSoftBorder, width: 1.2),
            boxShadow: authBlueShadow(blur: 18, dy: 4, alpha: 0.35),
          ),
          child: builder(ctx),
        ),
      ),
    ),
  );
}
