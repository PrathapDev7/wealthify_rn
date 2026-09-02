import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/align_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import 'session_controller.dart';

String errorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return error.message ?? 'Network error';
  }
  return 'Something went wrong';
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) => const AlignTheme(child: _AuthBody());
}

class _AuthBody extends ConsumerStatefulWidget {
  const _AuthBody();
  @override
  ConsumerState<_AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends ConsumerState<_AuthBody> {
  bool _isRegister = false;
  bool _obscure = true;
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    _username.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final mobile = _mobile.text.trim();
    final password = _password.text;
    if (mobile.isEmpty || password.isEmpty) {
      showAppSnack(context, 'Enter your mobile and password', error: true);
      return;
    }
    final notifier = ref.read(sessionProvider.notifier);
    if (_isRegister) {
      if (_username.text.trim().isEmpty) {
        showAppSnack(context, 'Enter your name', error: true);
        return;
      }
      if (password != _confirm.text) {
        showAppSnack(context, "Passwords don't match", error: true);
        return;
      }
      notifier.register(
          mobile: mobile, password: password, username: _username.text.trim());
    } else {
      notifier.login(mobile: mobile, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = ref.watch(sessionProvider);
    ref.listen(sessionProvider, (prev, next) {
      if (next.hasError) {
        showAppSnack(context, errorMessage(next.error), error: true);
      }
    });
    final loading = session.isLoading;

    return GradientScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl4),
            const AlignLogo(markSize: 76, fontSize: 24),
            const SizedBox(height: AppSpacing.xl2),
            Text(_isRegister ? 'Create your Align account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: AppText.titleLg.copyWith(color: c.text)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isRegister
                  ? 'Money, health and fitness — tracked in one place.'
                  : 'Log in to keep everything in balance.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl2),
            if (_isRegister) ...[
              AppTextField(
                  controller: _username,
                  label: 'Full name',
                  hint: 'Your name',
                  prefixIcon: Icons.person_outline),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              controller: _mobile,
              label: 'Mobile number',
              hint: '10-digit mobile',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _password,
              label: 'Password',
              hint: 'Enter password',
              obscureText: _obscure,
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: c.textSubtle),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            if (_isRegister) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _confirm,
                label: 'Confirm password',
                hint: 'Re-enter password',
                obscureText: _obscure,
                prefixIcon: Icons.lock_outline,
              ),
            ],
            const SizedBox(height: AppSpacing.xl2),
            PillButton(
              label: _isRegister ? 'Sign Up' : 'Log In',
              loading: loading,
              onPressed: loading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => setState(() => _isRegister = !_isRegister),
              child: RichText(
                text: TextSpan(
                  style: AppText.bodySm.copyWith(color: c.textSubtle),
                  children: [
                    TextSpan(
                        text: _isRegister
                            ? 'Already have an account? '
                            : "Don't have an account? "),
                    TextSpan(
                      text: _isRegister ? 'Log In' : 'Sign Up',
                      style: AppText.bodyMedium.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text.rich(
              TextSpan(
                style: AppText.caption.copyWith(color: c.textSubtle),
                children: [
                  const TextSpan(text: 'By continuing, you agree to our '),
                  TextSpan(
                      text: 'Terms',
                      style: AppText.caption.copyWith(color: c.primary)),
                  const TextSpan(text: ' and '),
                  TextSpan(
                      text: 'Privacy Policy',
                      style: AppText.caption.copyWith(color: c.primary)),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
