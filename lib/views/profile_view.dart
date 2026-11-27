import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../providers/auth_provider.dart';
import '../widgets/soft_ui.dart';
import '../widgets/tap_scale.dart';
import 'setting_view.dart';

/// Profil pengguna dan Pet. Data diambil dari akun yang sedang login.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    Widget row(IconData icon, String labelKey, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SoftBar(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: AppColors.tersier),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(labelKey),
                      style: softText(
                        10.5,
                        color: AppColors.textDark.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? '-' : value,
                      style: softText(13, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SoftPage(
      title: context.tr('profile'),
      child: Column(
        children: [
          SoftFadeIn(
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                children: [
                  TapScale(
                    pressedScale: 0.94,
                    onTap: () {},
                    child: Image.asset(
                      'assets/images/mipo_biru.gif',
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.bubble_chart_rounded,
                        size: 90,
                        color: AppColors.tersier,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: softBorder, width: 1.2),
                    ),
                    child: Text(
                      auth.petName,
                      style: softText(14, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftFadeIn(
            delayMs: 80,
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Column(
                children: [
                  row(Icons.person_outline_rounded, 'name', auth.name),
                  row(Icons.cake_outlined, 'age', auth.age?.toString() ?? ''),
                  row(Icons.mail_outline_rounded, 'email', auth.email),
                  row(Icons.school_outlined, 'education', auth.education),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SoftFadeIn(
            delayMs: 140,
            child: SoftButton(
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
