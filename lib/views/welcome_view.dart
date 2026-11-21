import '../widgets/mipo_octopus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../providers/settings_provider.dart';
import '../widgets/mipo_ui.dart';
import 'login_view.dart';
import 'register_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MipoThemed(
      child: Builder(
        builder: (context) {
          final p = context.palette;
          final settings = context.watch<SettingsProvider>();
          return Scaffold(
            backgroundColor: p.pageBg,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeSlideIn(
                      child: MipoOctopus(size: 170),
                        ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Image.asset(
                          'assets/images/logo_mipo.png',
                          height:150,
                          errorBuilder: (_, __, ___) => Text(
                            'MiPo',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: p.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          context.tr('welcome_headline'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 280),
                        child: Text(
                          context.tr('welcome_tagline'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 360),
                        child: Column(
                          children: [
                            Text(
                              context.tr('choose_language'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LanguageSwitch(
                              value: settings.language,
                              onChanged: (code) => settings.setLanguage(code),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 460),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Column(
                            children: [
                              MipoButton(
                                label: context.tr('login'),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginView()),
                                ),
                              ),
                              const SizedBox(height: 12),
                              MipoButton(
                                label: context.tr('register'),
                                filled: false,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterAccountView()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                     ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
