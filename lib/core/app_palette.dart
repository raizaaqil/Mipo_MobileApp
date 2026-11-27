import 'package:flutter/material.dart';

/// Kumpulan warna yang berubah mengikuti mode terang / gelap.
/// Pakai: `final p = context.palette;` lalu `p.text`, `p.surface`, dst.
@immutable
class MipoPalette extends ThemeExtension<MipoPalette> {
  final Color pageBg;   // latar halaman
  final Color surface;  // panel putih / dialog
  final Color panel;    // kartu & tombol biru muda
  final Color panelSoft;
  final Color accent;   // biru utama
  final Color onAccent; // teks di atas biru utama
  final Color text;
  final Color textMuted;
  final Color fieldFill;
  final Color shadow;

  const MipoPalette({
    required this.pageBg,
    required this.surface,
    required this.panel,
    required this.panelSoft,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textMuted,
    required this.fieldFill,
    required this.shadow,
  });

  static const light = MipoPalette(
    pageBg: Color(0xFFE8F3FF),
    surface: Color(0xFFFFFFFF),
    panel: Color(0xFFCBE5FF),
    panelSoft: Color(0xFFD8ECFF),
    accent: Color(0xFF5B9EE1),
    onAccent: Color(0xFFFFFFFF),
    text: Color(0xFF364A6B),
    textMuted: Color(0xFF6B7F9E),
    fieldFill: Color(0xFFFFFFFF),
    shadow: Color(0x1F000000),
  );

  static const dark = MipoPalette(
    pageBg: Color(0xFF141C29),
    surface: Color(0xFF1D2A3C),
    panel: Color(0xFF2B3E58),
    panelSoft: Color(0xFF24344B),
    accent: Color(0xFF7DB6EA),
    onAccent: Color(0xFF0F1A2A),
    text: Color(0xFFE8EFF8),
    textMuted: Color(0xFF9AAEC8),
    fieldFill: Color(0xFF24344B),
    shadow: Color(0x66000000),
  );

  @override
  MipoPalette copyWith({
    Color? pageBg, Color? surface, Color? panel, Color? panelSoft,
    Color? accent, Color? onAccent, Color? text, Color? textMuted,
    Color? fieldFill, Color? shadow,
  }) {
    return MipoPalette(
      pageBg: pageBg ?? this.pageBg,
      surface: surface ?? this.surface,
      panel: panel ?? this.panel,
      panelSoft: panelSoft ?? this.panelSoft,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      fieldFill: fieldFill ?? this.fieldFill,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  MipoPalette lerp(ThemeExtension<MipoPalette>? other, double t) {
    if (other is! MipoPalette) return this;
    return MipoPalette(
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  MipoPalette get palette =>
      Theme.of(this).extension<MipoPalette>() ?? MipoPalette.light;
}
