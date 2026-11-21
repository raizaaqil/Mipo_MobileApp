import 'package:flutter/material.dart';
import '../core/app_palette.dart';
import 'mipo_ui.dart';
import 'tap_scale.dart';

/// Kerangka halaman berpanel (Login, Register, Settings, Profil) sesuai Figma:
/// latar biru muda, tombol kembali, panel putih bundar dengan judul di atasnya.
class PanelScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;

  const PanelScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return MipoThemed(
      child: Builder(
        builder: (context) {
          final p = context.palette;
          return Scaffold(
            backgroundColor: p.pageBg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        if (showBack)
                          TapScale(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: p.accent, size: 26),
                            ),
                          )
                        else
                          const SizedBox(height: 50),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32)),
                            boxShadow: [
                              BoxShadow(
                                color: p.shadow,
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              24,
                              56,
                              24,
                              32 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: child,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(child: MipoPill(title)),
                        ),
                      ],
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
