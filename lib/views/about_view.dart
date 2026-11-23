import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/soft_ui.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  final _feedback = TextEditingController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_feedback.text.trim().isEmpty) {
      showSoftSnack(context, 'Tulis feedback dulu ya.');
      return;
    }
    FocusScope.of(context).unfocus();
    await showSoftNotice(context, message: 'Feedback Send');
    if (mounted) _feedback.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SoftPage(
      title: 'About Application',
      child: Column(
        children: [
          SoftFadeIn(
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_mipo.png',
                    height: 130,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      'MiPo',
                      style: softText(44, weight: FontWeight.w700, color: AppColors.tersier),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'MiPO is an interactive productivity platform designed to help students '
                    'manage their schedules, track daily tasks, and monitor their study '
                    'progress in a fun way. Accompanied by an adaptive virtual mascot, MiPO '
                    'makes time management routines feel lighter, more structured, and far '
                    'from tedious.',
                    textAlign: TextAlign.center,
                    style: softText(12.5, height: 1.55),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftFadeIn(
            delayMs: 80,
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Feedback', style: softText(14, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SoftField(
                    controller: _feedback,
                    hint: 'Type Here...',
                    minLines: 6,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  SoftButton(
                    label: 'Send Feedback',
                    icon: Icons.send_rounded,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
