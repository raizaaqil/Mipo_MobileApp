import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_palette.dart';
import '../core/app_strings.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/mipo_ui.dart';
import '../widgets/panel_scaffold.dart';
import '../widgets/tap_scale.dart';
import 'register_view.dart';

/// Kotak pesan error dari server (muncul dengan animasi).
class ErrorBanner extends StatelessWidget {
  final String? errorKey;
  const ErrorBanner({super.key, required this.errorKey});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topCenter,
      child: errorKey == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.urgencyPanic.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.urgencyPanic.withValues(alpha: 0.6)),
              ),
              child: Text(
                context.tr(errorKey!),
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _emailErr;
  String? _passErr;
  String? _serverErr;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final eErr = Validators.email(_email.text);
    final pErr = Validators.required(_pass.text);
    setState(() {
      _emailErr = eErr;
      _passErr = pErr;
      _serverErr = null;
    });
    if (eErr != null || pErr != null) return;

    setState(() => _loading = true);
    final result =
        await context.read<AuthProvider>().signIn(_email.text, _pass.text);
    if (!mounted) return;
    if (result.isOk) {
      // AuthGate otomatis menampilkan Home; tutup halaman Welcome/Login di atasnya.
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
      title: context.tr('login'),
      child: Column(
        children: [
          FadeSlideIn(
            child: MipoTextField(
              label: context.tr('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailErr == null ? null : context.tr(_emailErr!),
              onChanged: (_) {
                if (_emailErr != null) setState(() => _emailErr = null);
              },
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: MipoTextField(
              label: context.tr('password'),
              controller: _pass,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _passErr == null ? null : context.tr(_passErr!),
              onChanged: (_) {
                if (_passErr != null) setState(() => _passErr = null);
              },
            ),
          ),
          const SizedBox(height: 20),
          ErrorBanner(errorKey: _serverErr),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: MipoButton(
              label: context.tr('login'),
              loading: _loading,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: TapScale(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.tr('forgot_password'),
                  style: TextStyle(
                    color: p.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.tr('no_account'),
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                TapScale(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const RegisterAccountView()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      context.tr('register'),
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
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _email = TextEditingController();
  String? _emailErr;
  String? _serverErr;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final err = Validators.email(_email.text);
    setState(() {
      _emailErr = err;
      _serverErr = null;
    });
    if (err != null) return;

    setState(() => _loading = true);
    final result =
        await context.read<AuthProvider>().sendResetEmail(_email.text);
    if (!mounted) return;
    if (result.isOk) {
      showMipoSnack(context, context.trNow('email_sent'));
      Navigator.of(context).pop();
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
      title: context.tr('forgot_title'),
      child: Column(
        children: [
          FadeSlideIn(
            child: Text(
              context.tr('forgot_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: MipoTextField(
              label: context.tr('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _emailErr == null ? null : context.tr(_emailErr!),
            ),
          ),
          const SizedBox(height: 20),
          ErrorBanner(errorKey: _serverErr),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: MipoButton(
              label: context.tr('send_link'),
              loading: _loading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
