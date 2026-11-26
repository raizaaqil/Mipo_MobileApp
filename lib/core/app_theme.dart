import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// Transisi halaman: fade + geser naik sedikit. Ringan dan sama di semua halaman.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class AppTheme {
  static const _transitions = PageTransitionsTheme(builders: {
    TargetPlatform.android: SmoothPageTransitionsBuilder(),
    TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
  });

  // Jalan pintas untuk tema terang dan gelap
  static ThemeData get lightTheme => build(Brightness.light);
  static ThemeData get darkTheme => build(Brightness.dark);

  static ThemeData build(Brightness brightness) {
    final p = brightness == Brightness.dark ? MipoPalette.dark : MipoPalette.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: p.pageBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: brightness,
      ).copyWith(primary: p.accent, surface: p.surface),
      pageTransitionsTheme: _transitions,
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }
}