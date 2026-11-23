import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../providers/settings_provider.dart';
import '../widgets/auth_ui.dart';
import '../widgets/mipo_ui.dart' show MipoThemed, LanguageSwitch;
import '../widgets/tap_scale.dart';
import 'login_view.dart';
import 'register_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MipoThemed(
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          return AuthScaffold(
            showBack: false,
            // Mipo tampil langsung di latar biru, seperti di Home.
            header: TapScale(
              pressedScale: 0.96,
              onTap: () {},
              child: Image.asset(
                'assets/images/mipo_biru.gif',
                width: 165,
                height: 165,
                fit: BoxFit.contain,
              ),
            ),
            child: AuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo_mipo.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        'MiPo',
                        style: authText(
                          44,
                          weight: FontWeight.w800,
                          color: AppColors.tersier,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('welcome_headline'),
                    textAlign: TextAlign.center,
                    style: authText(20, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('welcome_tagline'),
                    textAlign: TextAlign.center,
                    style: authText(
                      13,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('choose_language'),
                    textAlign: TextAlign.center,
                    style: authText(
                      12.5,
                      weight: FontWeight.w700,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: LanguageSwitch(
                      value: settings.language,
                      onChanged: (code) => settings.setLanguage(code),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthButton(
                    label: context.tr('login'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthButton(
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
          );
        },
      ),
    );
  }
}
