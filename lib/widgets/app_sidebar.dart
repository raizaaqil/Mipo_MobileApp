import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../providers/auth_provider.dart';
import '../views/about_view.dart';
import '../views/help_view.dart';
import '../views/profile_view.dart';
import '../views/setting_view.dart';
import 'mipo_ui.dart';
import 'tap_scale.dart';

/// Sidebar Home: Profile, Setting, Help, About.
/// Menu muncul berurutan dari kiri setiap kali sidebar dibuka.
class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  void _open(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop(); // tutup sidebar
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width * 0.72).clamp(240.0, 320.0);
    return MipoThemed(
      child: Builder(
        builder: (context) {
          final p = context.palette;
          final auth = context.watch<AuthProvider>();
          return Drawer(
            width: width,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: p.panelSoft,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: TapScale(
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 34, color: p.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        beginOffset: const Offset(-0.2, 0),
                        child: Text(
                          '${context.tr('hello')} ${auth.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: p.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _item(context, 1, Icons.account_circle_outlined,
                          'menu_profile', const ProfileView()),
                      _item(context, 2, Icons.settings_outlined,
                          'menu_setting', const SettingView()),
                      _item(context, 3, Icons.help_outline_rounded,
                          'menu_help', const HelpView()),
                      _item(context, 4, Icons.info_outline_rounded,
                          'menu_about', const AboutView()),
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

  Widget _item(BuildContext context, int index, IconData icon, String titleKey,
      Widget page) {
    final p = context.palette;
    return FadeSlideIn(
      delay: Duration(milliseconds: 70 * index),
      beginOffset: const Offset(-0.25, 0),
      child: TapScale(
        onTap: () => _open(context, page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: p.panel, shape: BoxShape.circle),
                child: Icon(icon, color: p.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                context.tr(titleKey),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
