import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/mipo_ui.dart';
import '../widgets/panel_scaffold.dart';
import 'setting_view.dart';

/// Profil pengguna dan Pet. Data diambil dari akun yang sedang login.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthProvider>();
    Widget row(String labelKey, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  context.tr(labelKey),
                  style: TextStyle(
                      color: p.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                      color: p.text, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
        );

    return PanelScaffold(
      title: context.tr('profile'),
      child: Column(
        children: [
          FadeSlideIn(
            child: Floating(
              child: Image.asset(
                'assets/images/mipo_kuning.png',
                height: 120,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.bubble_chart_rounded, size: 90, color: p.accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              auth.petName,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.panelSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  row('name', auth.name),
                  row('age', auth.age?.toString() ?? ''),
                  row('email', auth.email),
                  row('education', auth.education),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: MipoButton(
              label: context.tr('edit'),
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingView()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
