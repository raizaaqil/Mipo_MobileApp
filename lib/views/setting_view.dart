import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mipo_ui.dart';
import '../widgets/panel_scaffold.dart';
import '../widgets/tap_scale.dart';
import 'login_view.dart' show ErrorBanner;

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await showMipoConfirm(
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
      _TileData(Icons.person_outline_rounded, 'account',
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AccountSettingView()))),
      _TileData(Icons.notifications_none_rounded, 'notification',
          () => showMipoDialog<void>(context,
              builder: (_) => const _NotificationDialog())),
      _TileData(Icons.brightness_6_outlined, 'display',
          () => showMipoDialog<void>(context,
              builder: (_) => const _DisplayDialog())),
      _TileData(Icons.lock_outline_rounded, 'privacy',
          () => showMipoDialog<void>(context,
              builder: (_) => const _PrivacyDialog())),
      _TileData(Icons.translate_rounded, 'language',
          () => showMipoDialog<void>(context,
              builder: (_) => const _LanguageDialog())),
      _TileData(Icons.logout_rounded, 'logout', () => _logout(context)),
    ];

    return PanelScaffold(
      title: context.tr('setting'),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 60 * i),
              beginOffset: const Offset(0.1, 0),
              child: _SettingTile(data: items[i]),
            ),
        ],
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String titleKey;
  final VoidCallback onTap;
  const _TileData(this.icon, this.titleKey, this.onTap);
}

class _SettingTile extends StatelessWidget {
  final _TileData data;
  const _SettingTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TapScale(
      onTap: data.onTap,
      pressedScale: 0.97,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: p.panelSoft, shape: BoxShape.circle),
              child: Icon(data.icon, color: p.accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.tr(data.titleKey),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.accent, size: 28),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Dialog

class _DialogActions extends StatelessWidget {
  final VoidCallback onSave;
  final bool loading;
  const _DialogActions({required this.onSave, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MipoButton(
            label: context.tr('cancel'),
            filled: false,
            onPressed: loading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MipoButton(
            label: context.tr('save'),
            loading: loading,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}

class _DialogTitle extends StatelessWidget {
  final String text;
  const _DialogTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Center(child: MipoPill(text, fontSize: 16));
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
    final p = context.palette;
    return Row(
      children: [
        Icon(icon, color: p.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                color: p.text, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accent : p.panel,
          ),
          trackOutlineColor:
              const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
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
    return MipoDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTitle(context.tr('notification')),
          const SizedBox(height: 22),
          _SwitchRow(
            icon: _on
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            title: context.tr('notif_on'),
            value: _on,
            onChanged: (v) => setState(() => _on = v),
          ),
          const SizedBox(height: 24),
          _DialogActions(onSave: () async {
            final settings = context.read<SettingsProvider>();
            final navigator = Navigator.of(context);
            final messenger = context.trNow('settings_saved');
            await settings.setNotifications(_on);
            navigator.pop();
            if (navigator.mounted) {
              showMipoSnack(navigator.context, messenger);
            }
          }),
        ],
      ),
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
    final p = context.palette;
    return MipoDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTitle(context.tr('display')),
          const SizedBox(height: 22),
          _SwitchRow(
            icon: _dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: context.tr('dark_mode'),
            value: _dark,
            onChanged: (v) => setState(() => _dark = v),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('dark_mode_note'),
            style: TextStyle(color: p.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          _DialogActions(onSave: () async {
            final settings = context.read<SettingsProvider>();
            final navigator = Navigator.of(context);
            await settings.setDarkMode(_dark);
            navigator.pop();
          }),
        ],
      ),
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
    return MipoDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTitle(context.tr('language')),
          const SizedBox(height: 22),
          LanguageSwitch(
            value: _lang,
            onChanged: (v) => setState(() => _lang = v),
          ),
          const SizedBox(height: 24),
          _DialogActions(onSave: () async {
            final settings = context.read<SettingsProvider>();
            final navigator = Navigator.of(context);
            await settings.setLanguage(_lang);
            navigator.pop();
            if (navigator.mounted) {
              showMipoSnack(
                navigator.context,
                AppStrings.get(_lang, 'settings_saved'),
              );
            }
          }),
        ],
      ),
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
    final confirmErr =
        _confirm.text != _new.text ? 'err_password_mismatch' : null;
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
      if (navigator.mounted) showMipoSnack(navigator.context, okMessage);
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
    return MipoDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTitle(context.tr('privacy')),
          const SizedBox(height: 18),
          MipoTextField(
            label: context.tr('old_password'),
            controller: _old,
            obscure: true,
            textInputAction: TextInputAction.next,
            errorText: _oldErr == null ? null : context.tr(_oldErr!),
          ),
          const SizedBox(height: 12),
          MipoTextField(
            label: context.tr('new_password'),
            controller: _new,
            obscure: true,
            textInputAction: TextInputAction.next,
            errorText: _newErr == null ? null : context.tr(_newErr!),
          ),
          const SizedBox(height: 12),
          MipoTextField(
            label: context.tr('confirm_password'),
            controller: _confirm,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            errorText: _confirmErr == null ? null : context.tr(_confirmErr!),
          ),
          const SizedBox(height: 14),
          ErrorBanner(errorKey: _serverErr),
          _DialogActions(onSave: _save, loading: _loading),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- Akun (profil)

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
      showMipoSnack(context, context.trNow('profile_saved'));
    } else {
      setState(() => _serverErr = result.errorKey);
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final ok = await showMipoConfirm(
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
    final p = context.palette;
    Widget gap(Widget w) =>
        Padding(padding: const EdgeInsets.only(bottom: 14), child: w);

    return PanelScaffold(
      title: context.tr('account'),
      child: Column(
        children: [
          gap(MipoTextField(
            label: context.tr('email'),
            controller: _email,
            enabled: false,
          )),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('email_readonly'),
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
            ),
          ),
          gap(MipoTextField(
            label: context.tr('name'),
            controller: _name,
            textInputAction: TextInputAction.next,
            errorText: _err('name'),
          )),
          gap(MipoTextField(
            label: context.tr('age'),
            controller: _age,
            keyboardType: TextInputType.number,
            maxLength: 3,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            errorText: _err('age'),
          )),
          gap(MipoTextField(
            label: context.tr('education'),
            controller: _edu,
            textInputAction: TextInputAction.next,
            errorText: _err('edu'),
          )),
          gap(MipoTextField(
            label: context.tr('pet_name'),
            controller: _pet,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            errorText: _err('pet'),
          )),
          ErrorBanner(errorKey: _serverErr),
          MipoButton(
            label: context.tr('save'),
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: 18),
          TapScale(
            onTap: _delete,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                context.tr('delete_account'),
                style: const TextStyle(
                  color: AppColors.urgencyPanic,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
