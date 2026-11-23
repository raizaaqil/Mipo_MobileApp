import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_strings.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_ui.dart';
import '../widgets/mipo_ui.dart' show showMipoSnack;
import 'register_view.dart';

/// Kotak pesan error dari server (muncul dengan animasi).
class ErrorBanner extends StatelessWidget {
  final String? errorKey;
  const ErrorBanner({super.key, required this.errorKey});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: errorKey == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.urgencyPanic.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.urgencyPanic.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Text(
                context.tr(errorKey!),
                style: authText(12.5, weight: FontWeight.w600),
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
    return AuthScaffold(
      child: AuthCard(
        title: context.tr('login'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: context.tr('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailErr == null ? null : context.tr(_emailErr!),
              onChanged: (_) {
                if (_emailErr != null) setState(() => _emailErr = null);
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
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
            const SizedBox(height: 18),
            ErrorBanner(errorKey: _serverErr),
            AuthButton(
              label: context.tr('login'),
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 6),
            Center(
              child: AuthTextLink(
                label: context.tr('forgot_password'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
                ),
              ),
            ),
            AuthLinkRow(
              text: context.tr('no_account'),
              action: context.tr('register'),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RegisterAccountView()),
              ),
            ),
          ],
        ),
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
    return AuthScaffold(
      child: AuthCard(
        title: context.tr('forgot_title'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('forgot_hint'),
              textAlign: TextAlign.center,
              style: authText(
                13,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ).copyWith(height: 1.4),
            ),
            const SizedBox(height: 18),
            AuthTextField(
              label: context.tr('email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              errorText: _emailErr == null ? null : context.tr(_emailErr!),
              onChanged: (_) {
                if (_emailErr != null) setState(() => _emailErr = null);
              },
            ),
            const SizedBox(height: 18),
            ErrorBanner(errorKey: _serverErr),
            AuthButton(
              label: context.tr('send_link'),
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
