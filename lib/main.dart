import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_palette.dart';
import 'core/app_strings.dart';
import 'core/app_theme.dart';
import 'core/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'views/home_views.dart';
import 'views/welcome_view.dart';
import 'widgets/mipo_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.load();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(MipoApp(settings: settings));
}

class MipoApp extends StatelessWidget {
  final SettingsProvider settings;
  const MipoApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return MaterialApp(
        title: 'MiPo App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(Brightness.light),
        home: const SetupRequiredView(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(settings),
        ),
      ],
      child: MaterialApp(
        title: 'MiPo App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(Brightness.light),
        home: const AuthGate(),
      ),
    );
  }
}

/// Penentu halaman pertama: belum login -> Welcome, sudah login -> Home.
/// Sesi tersimpan otomatis, jadi setelah aplikasi ditutup dan dibuka lagi
/// pengguna langsung masuk ke Home. Log out otomatis kembali ke Welcome.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final Widget page;
    if (!auth.isLoggedIn) {
      page = const WelcomeView(key: ValueKey('welcome'));
    } else if (!auth.profileLoaded) {
      page = const _LoadingProfileView(key: ValueKey('loading'));
    } else {
      page = const HomeView(key: ValueKey('home'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: page,
    );
  }
}

class _LoadingProfileView extends StatelessWidget {
  const _LoadingProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MipoThemed(
      child: Builder(
        builder: (context) {
          final p = context.palette;
          final failed = auth.profileErrorKey != null;
          return Scaffold(
            backgroundColor: p.pageBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Floating(
                    child: Image.asset(
                      'assets/images/logo_mipo.png',
                      height: 110,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.bubble_chart_rounded,
                          size: 200,
                          color: p.accent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!failed)
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: p.accent),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        context.tr(auth.profileErrorKey!),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.text, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MipoButton(
                      label: context.tr('retry'),
                      expand: false,
                      onPressed: auth.loadProfile,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.signOut,
                      child: Text(context.tr('logout'),
                          style: TextStyle(color: p.accent)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Muncul kalau URL dan kunci Supabase belum diisi, supaya aplikasi
/// tidak crash dan pemula tahu apa yang harus dilakukan.
class SetupRequiredView extends StatelessWidget {
  const SetupRequiredView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE8F3FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_suggest_rounded,
                    size: 72, color: Color(0xFF5B9EE1)),
                SizedBox(height: 16),
                Text(
                  'Supabase belum disiapkan',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF364A6B)),
                ),
                SizedBox(height: 10),
                Text(
                  'Buka lib/core/supabase_config.dart lalu isi Project URL dan '
                  'anon key dari dashboard Supabase. Langkah lengkapnya ada di '
                  'PANDUAN_SETUP.md.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, height: 1.4, color: Color(0xFF364A6B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
