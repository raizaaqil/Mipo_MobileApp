import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/mipo_ui.dart';
import '../widgets/panel_scaffold.dart';
import '../widgets/tap_scale.dart';
import 'login_view.dart';

class RegisterData {
  final String email;
  final String password;
  final String name;
  final int age;
  final String education;
  const RegisterData({
    required this.email,
    required this.password,
    required this.name,
    required this.age,
    required this.education,
  });
}

/// Langkah 1: data akun dan profil pengguna.
class RegisterAccountView extends StatefulWidget {
  const RegisterAccountView({super.key});

  @override
  State<RegisterAccountView> createState() => _RegisterAccountViewState();
}

class _RegisterAccountViewState extends State<RegisterAccountView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _edu = TextEditingController();
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _name.dispose();
    _age.dispose();
    _edu.dispose();
    super.dispose();
  }

  String? _err(String field) =>
      _errors[field] == null ? null : context.tr(_errors[field]!);

  void _clear(String field) {
    if (_errors[field] != null) setState(() => _errors[field] = null);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final errors = <String, String?>{
      'email': Validators.email(_email.text),
      'pass': Validators.password(_pass.text),
      'name': Validators.required(_name.text),
      'age': Validators.age(_age.text),
      'edu': Validators.required(_edu.text),
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.values.any((e) => e != null)) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterPetView(
          data: RegisterData(
            email: _email.text.trim(),
            password: _pass.text,
            name: _name.text.trim(),
            age: int.parse(_age.text.trim()),
            education: _edu.text.trim(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget field(int i, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FadeSlideIn(
            delay: Duration(milliseconds: 60 * i),
            child: child,
          ),
        );

    return PanelScaffold(
      title: context.tr('register'),
      child: Column(
        children: [
          field(
            0,
            MipoTextField(
              label: context.tr('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _err('email'),
              onChanged: (_) => _clear('email'),
            ),
          ),
          field(
            1,
            MipoTextField(
              label: context.tr('password'),
              controller: _pass,
              obscure: true,
              textInputAction: TextInputAction.next,
              errorText: _err('pass'),
              onChanged: (_) => _clear('pass'),
            ),
          ),
          field(
            2,
            MipoTextField(
              label: context.tr('name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              errorText: _err('name'),
              onChanged: (_) => _clear('name'),
            ),
          ),
          field(
            3,
            MipoTextField(
              label: context.tr('age'),
              controller: _age,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: _err('age'),
              onChanged: (_) => _clear('age'),
            ),
          ),
          field(
            4,
            MipoTextField(
              label: context.tr('education'),
              controller: _edu,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
              errorText: _err('edu'),
              onChanged: (_) => _clear('edu'),
            ),
          ),
          const SizedBox(height: 6),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: MipoButton(label: context.tr('next'), onPressed: _next),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.tr('have_account'),
                  style: TextStyle(color: p.textMuted, fontSize: 13)),
              TapScale(
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    context.tr('login'),
                    style: TextStyle(
                      color: p.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Langkah 2: beri nama Pet, lalu akun dibuat.
class RegisterPetView extends StatefulWidget {
  final RegisterData data;
  const RegisterPetView({super.key, required this.data});

  @override
  State<RegisterPetView> createState() => _RegisterPetViewState();
}

class _RegisterPetViewState extends State<RegisterPetView> {
  final _petName = TextEditingController();
  String? _petErr;
  String? _serverErr;
  bool _loading = false;

  @override
  void dispose() {
    _petName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final err = Validators.required(_petName.text);
    setState(() {
      _petErr = err;
      _serverErr = null;
    });
    if (err != null) return;

    setState(() => _loading = true);
    final d = widget.data;
    final result = await context.read<AuthProvider>().signUp(
          email: d.email,
          password: d.password,
          name: d.name,
          age: d.age,
          education: d.education,
          petName: _petName.text,
        );
    if (!mounted) return;

    if (result.needsEmailConfirm) {
      await showMipoDialog<void>(
        context,
        builder: (ctx) => MipoDialogCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctx.trNow('confirm_email_info'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ctx.palette.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              MipoButton(
                label: ctx.trNow('ok'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    if (result.isOk) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      _loading = false;
      _serverErr = result.errorKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PanelScaffold(
      title: context.tr('pet_profile'),
      child: Column(
        children: [
          FadeSlideIn(
            child: Floating(
              child: Image.asset(
                'assets/images/mipo_kuning.png',
                height: 130,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.bubble_chart_rounded, size: 100, color: p.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text(
              context.tr('pet_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: MipoTextField(
              label: context.tr('pet_name'),
              controller: _petName,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _petErr == null ? null : context.tr(_petErr!),
              onChanged: (_) {
                if (_petErr != null) setState(() => _petErr = null);
              },
            ),
          ),
          const SizedBox(height: 20),
          ErrorBanner(errorKey: _serverErr),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: MipoButton(
              label: context.tr('register'),
              loading: _loading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
