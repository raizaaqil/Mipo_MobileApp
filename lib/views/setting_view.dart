import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mipo_ui.dart' show LanguageSwitch;
import '../widgets/soft_ui.dart';
import '../widgets/tap_scale.dart';
import 'login_view.dart' show ErrorBanner;

// ============================================================================
// HALAMAN SETTING
// ============================================================================

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await showSoftConfirm(
      context,
      message: context.trNow('logout_confirm'),
      yesLabel: context.trNow('yes'),
      cancelLabel: context.trNow('cancel'),
    );
    if (!ok) return;
    await auth.signOut();
    // AuthGate kembali menampilkan Welcome; tutup semua halaman di atasnya.
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_TileData>[
      _TileData(
        Icons.person_outline_rounded,
        'account',
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountSettingView()),
        ),
      ),
      _TileData(
        Icons.notifications_none_rounded,
        'notification',
        () => showSoftDialog<void>(context, builder: (_) => const _NotificationDialog()),
      ),
      _TileData(
        Icons.brightness_6_outlined,
        'display',
        () => showSoftDialog<void>(context, builder: (_) => const _DisplayDialog()),
      ),
      _TileData(
        Icons.lock_outline_rounded,
        'privacy',
        () => showSoftDialog<void>(context, builder: (_) => const _PrivacyDialog()),
      ),
      _TileData(
        Icons.translate_rounded,
        'language',
        () => showSoftDialog<void>(context, builder: (_) => const _LanguageDialog()),
      ),
      _TileData(
        Icons.logout_rounded,
        'logout',
        () => _logout(context),
        danger: true,
      ),
    ];

    return SoftPage(
      title: context.tr('setting'),
      child: SoftFadeIn(
        child: SoftCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SoftFadeIn(
                  delayMs: 50 * i,
                  child: _SettingTile(data: items[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String titleKey;
  final VoidCallback onTap;
  final bool danger;
  const _TileData(this.icon, this.titleKey, this.onTap, {this.danger = false});
}

class _SettingTile extends StatelessWidget {
  final _TileData data;
  const _SettingTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.danger ? AppColors.urgencyPanic : AppColors.tersier;

    return SoftBar(
      onTap: data.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(data.titleKey),
              style: softText(
                14,
                weight: FontWeight.w700,
                color: data.danger ? AppColors.urgencyPanic : null,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textDark.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOG
// ============================================================================

class _Actions extends StatelessWidget {
  final VoidCallback onSave;
  final bool loading;
  const _Actions({required this.onSave, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SoftDialogActions(
      cancelLabel: context.tr('cancel'),
      okLabel: context.tr('save'),
      onOk: onSave,
      loading: loading,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SoftBar(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tersier, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: softText(13.5, weight: FontWeight.w700)),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.tersier
                  : const Color(0xFFD5E6F7),
            ),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _NotificationDialog extends StatefulWidget {
  const _NotificationDialog();

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  late bool _on = context.read<SettingsProvider>().notifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftDialogTitle(context.tr('notification')),
        const SizedBox(height: 18),
        _SwitchRow(
          icon: _on
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          title: context.tr('notif_on'),
          value: _on,
          onChanged: (v) => setState(() => _on = v),
        ),
        const SizedBox(height: 20),
        _Actions(onSave: () async {
          final settings = context.read<SettingsProvider>();
          final navigator = Navigator.of(context);
          final message = context.trNow('settings_saved');
          await settings.setNotifications(_on);
          navigator.pop();
          if (navigator.mounted) showSoftSnack(navigator.context, message);
        }),
      ],
    );
  }
}

class _DisplayDialog extends StatefulWidget {
  const _DisplayDialog();

  @override
  State<_DisplayDialog> createState() => _DisplayDialogState();
}

class _DisplayDialogState extends State<_DisplayDialog> {
  late bool _dark = context.read<SettingsProvider>().darkMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftDialogTitle(context.tr('display')),
        const SizedBox(height: 18),
        _SwitchRow(
          icon: _dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          title: context.tr('dark_mode'),
          value: _dark,
          onChanged: (v) => setState(() => _dark = v),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('dark_mode_note'),
          style: softText(11.5, color: AppColors.textDark.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 18),
        _Actions(onSave: () async {
          final settings = context.read<SettingsProvider>();
          final navigator = Navigator.of(context);
          await settings.setDarkMode(_dark);
          navigator.pop();
        }),
      ],
    );
  }
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late String _lang = context.read<SettingsProvider>().language;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftDialogTitle(context.tr('language')),
        const SizedBox(height: 18),
        LanguageSwitch(
          value: _lang,
          onChanged: (v) => setState(() => _lang = v),
        ),
        const SizedBox(height: 20),
        _Actions(onSave: () async {
          final settings = context.read<SettingsProvider>();
          final navigator = Navigator.of(context);
          await settings.setLanguage(_lang);
          navigator.pop();
          if (navigator.mounted) {
            showSoftSnack(navigator.context, AppStrings.get(_lang, 'settings_saved'));
          }
        }),
      ],
    );
  }
}

class _PrivacyDialog extends StatefulWidget {
  const _PrivacyDialog();

  @override
  State<_PrivacyDialog> createState() => _PrivacyDialogState();
}

class _PrivacyDialogState extends State<_PrivacyDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _oldErr, _newErr, _confirmErr, _serverErr;
  bool _loading = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final oldErr = Validators.required(_old.text);
    final newErr = Validators.password(_new.text);
    final confirmErr = _confirm.text != _new.text ? 'err_password_mismatch' : null;
    setState(() {
      _oldErr = oldErr;
      _newErr = newErr;
      _confirmErr = confirmErr;
      _serverErr = null;
    });
    if (oldErr != null || newErr != null || confirmErr != null) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final okMessage = context.trNow('password_changed');
    final result = await auth.changePassword(_old.text, _new.text);
    if (!mounted) return;
    if (result.isOk) {
      navigator.pop();
      if (navigator.mounted) showSoftSnack(navigator.context, okMessage);
      return;
    }
    setState(() {
      _loading = false;
      if (result.errorKey == 'err_old_password_wrong') {
        _oldErr = result.errorKey;
      } else {
        _serverErr = result.errorKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoftDialogTitle(context.tr('privacy')),
        const SizedBox(height: 18),
        SoftField(
          label: context.tr('old_password'),
          controller: _old,
          obscure: true,
          textInputAction: TextInputAction.next,
          errorText: _oldErr == null ? null : context.tr(_oldErr!),
        ),
        const SizedBox(height: 12),
        SoftField(
          label: context.tr('new_password'),
          controller: _new,
          obscure: true,
          textInputAction: TextInputAction.next,
          errorText: _newErr == null ? null : context.tr(_newErr!),
        ),
        const SizedBox(height: 12),
        SoftField(
          label: context.tr('confirm_password'),
          controller: _confirm,
          obscure: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          errorText: _confirmErr == null ? null : context.tr(_confirmErr!),
        ),
        const SizedBox(height: 14),
        ErrorBanner(errorKey: _serverErr),
        _Actions(onSave: _save, loading: _loading),
      ],
    );
  }
}

// ============================================================================
// HALAMAN AKUN (edit profil)
// ============================================================================

class AccountSettingView extends StatefulWidget {
  const AccountSettingView({super.key});

  @override
  State<AccountSettingView> createState() => _AccountSettingViewState();
}

class _AccountSettingViewState extends State<AccountSettingView> {
  late final AuthProvider _auth = context.read<AuthProvider>();
  late final _name = TextEditingController(text: _auth.name);
  late final _age = TextEditingController(text: _auth.age?.toString() ?? '');
  late final _edu = TextEditingController(text: _auth.education);
  late final _pet = TextEditingController(text: _auth.petName);
  final _email = TextEditingController();
  final Map<String, String?> _errors = {};
  String? _serverErr;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _email.text = _auth.email;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _edu.dispose();
    _pet.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _err(String f) => _errors[f] == null ? null : context.tr(_errors[f]!);

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final errors = <String, String?>{
      'name': Validators.required(_name.text),
      'age': Validators.age(_age.text),
      'edu': Validators.required(_edu.text),
      'pet': Validators.required(_pet.text),
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      _serverErr = null;
    });
    if (errors.values.any((e) => e != null)) return;

    setState(() => _saving = true);
    final result = await _auth.updateProfile(
      name: _name.text,
      age: int.parse(_age.text.trim()),
      education: _edu.text,
      petName: _pet.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isOk) {
      showSoftSnack(context, context.trNow('profile_saved'));
    } else {
      setState(() => _serverErr = result.errorKey);
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final ok = await showSoftConfirm(
      context,
      message: context.trNow('delete_confirm'),
      yesLabel: context.trNow('yes'),
      cancelLabel: context.trNow('cancel'),
    );
    if (!ok) return;
    final result = await _auth.deleteAccount();
    if (!mounted) return;
    if (result.isOk) {
      navigator.popUntil((r) => r.isFirst);
    } else {
      setState(() => _serverErr = result.errorKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w);

    return SoftPage(
      title: context.tr('account'),
      child: SoftFadeIn(
        child: SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            children: [
              SoftField(
                label: context.tr('email'),
                controller: _email,
                enabled: false,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6, bottom: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('email_readonly'),
                    style: softText(11.5, color: AppColors.textDark.withValues(alpha: 0.55)),
                  ),
                ),
              ),
              gap(SoftField(
                label: context.tr('name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                errorText: _err('name'),
              )),
              gap(SoftField(
                label: context.tr('age'),
                controller: _age,
                keyboardType: TextInputType.number,
                maxLength: 3,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                errorText: _err('age'),
              )),
              gap(SoftField(
                label: context.tr('education'),
                controller: _edu,
                textInputAction: TextInputAction.next,
                errorText: _err('edu'),
              )),
              gap(SoftField(
                label: context.tr('pet_name'),
                controller: _pet,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                errorText: _err('pet'),
              )),
              ErrorBanner(errorKey: _serverErr),
              SoftButton(
                label: context.tr('save'),
                loading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 6),
              TapScale(
                pressedScale: 0.96,
                onTap: _delete,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr('delete_account'),
                    style: softText(13, weight: FontWeight.w700, color: AppColors.urgencyPanic),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
