import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/soft_ui.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  final _search = TextEditingController();

  static const _faq = [
    'How do I change my profile and account information?',
    'Page failed to load or a feature is experiencing an error',
    'How to download or save project data/files',
    'How do I create or add a new project?',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openForm({required String title, required String successMsg}) {
    showSoftDialog<void>(
      context,
      builder: (_) => _FormDialog(
        title: title,
        onSent: () => showSoftNotice(context, message: successMsg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final shown = _faq.where((e) => e.toLowerCase().contains(q)).toList();

    return SoftPage(
      title: 'Help & Support',
      child: Column(
        children: [
          SoftFadeIn(
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SoftField(
                    controller: _search,
                    hint: 'Ask Anything',
                    prefixIcon: Icons.search_rounded,
                    pill: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Tidak ada pertanyaan yang cocok.',
                        textAlign: TextAlign.center,
                        style: softText(12, color: AppColors.textDark.withValues(alpha: 0.5)),
                      ),
                    )
                  else
                    for (final item in shown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SoftBar(
                          onTap: () => setState(() {
                            _search.value = TextEditingValue(
                              text: item,
                              selection: TextSelection.collapsed(offset: item.length),
                            );
                          }),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: softText(12.5, weight: FontWeight.w600, height: 1.35),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textDark.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SoftButton(
                    label: 'Chat Support',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: () => _openForm(
                      title: 'Chat Support',
                      successMsg: 'Chat Send',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SoftButton(
                    label: 'Send Email',
                    icon: Icons.mail_outline_rounded,
                    filled: false,
                    onPressed: () => _openForm(
                      title: 'Send Email',
                      successMsg: 'Email Send',
                    ),
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

/// Isi dialog form. Dibuat sebagai widget sendiri supaya controller
/// ikut dibuang (dispose) saat dialog ditutup.
class _FormDialog extends StatefulWidget {
  final String title;
  final VoidCallback onSent;
  const _FormDialog({required this.title, required this.onSent});

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _message = TextEditingController();
  bool _empty = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _send() {
    if (_message.text.trim().isEmpty) {
      setState(() => _empty = true);
      return;
    }
    Navigator.of(context).pop();
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftDialogTitle(widget.title),
        const SizedBox(height: 16),
        SoftField(
          controller: _message,
          hint: 'Type Here...',
          minLines: 6,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          errorText: _empty ? 'Pesan tidak boleh kosong' : null,
          onChanged: (_) {
            if (_empty) setState(() => _empty = false);
          },
        ),
        const SizedBox(height: 18),
        SoftDialogActions(
          cancelLabel: 'Cancel',
          okLabel: 'Send',
          onOk: _send,
        ),
      ],
    );
  }
}
