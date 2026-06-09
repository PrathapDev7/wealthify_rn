import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';

/// App Lock settings — toggle biometric/passcode gating on app open.
///
/// The actual lock-on-resume gate is wired elsewhere; this screen only manages
/// the [Prefs.kAppLock] flag and surfaces device biometric capability.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _loading = true;
  bool _enabled = false;
  bool _supported = false;
  List<BiometricType> _biometrics = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final enabled = ref.read(prefsProvider).getBool(Prefs.kAppLock);

    var supported = false;
    var biometrics = const <BiometricType>[];
    try {
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      biometrics = await _auth.getAvailableBiometrics();
      supported = deviceSupported && canCheck && biometrics.isNotEmpty;
    } catch (_) {
      // local_auth unavailable (e.g. web/unsupported platform) — stay disabled.
      supported = false;
      biometrics = const [];
    }

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _supported = supported;
      _biometrics = biometrics;
      _loading = false;
    });
  }

  Future<void> _toggle(bool next) async {
    if (!next) {
      await ref.read(prefsProvider).setBool(Prefs.kAppLock, false);
      if (!mounted) return;
      setState(() => _enabled = false);
      return;
    }

    if (!_supported) return;

    bool ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Confirm to enable App Lock',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Could not enable App Lock', error: true);
      return;
    }

    if (!ok) return;
    await ref.read(prefsProvider).setBool(Prefs.kAppLock, true);
    if (!mounted) return;
    setState(() => _enabled = true);
    showAppSnack(context, 'App Lock enabled');
  }

  Future<void> _testUnlock() async {
    bool ok = false;
    try {
      ok = await _auth.authenticate(
        localizedReason: 'Test unlock',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Unlock failed', error: true);
      return;
    }
    if (!mounted) return;
    showAppSnack(context, ok ? 'Unlock successful' : 'Unlock failed',
        error: !ok);
  }

  String _labelFor(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong';
      case BiometricType.weak:
        return 'Weak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'App Lock'),
          Expanded(
            child: _loading
                ? const LoadingView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 60),
                    children: [
                      if (!_supported) ...[
                        AppCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: c.warning, size: 22),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Biometrics unavailable',
                                        style: AppText.bodyMedium
                                            .copyWith(color: c.text)),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'This device has no biometric sensor, so '
                                      'App Lock cannot be enabled.',
                                      style: AppText.bodySm
                                          .copyWith(color: c.textSubtle),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Text('App lock',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('App lock',
                                      style: AppText.bodyMedium
                                          .copyWith(color: c.text)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Require biometric/passcode each time you '
                                    'open Wealthify',
                                    style: AppText.bodySm
                                        .copyWith(color: c.textSubtle),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Switch(
                              value: _enabled,
                              onChanged: _supported ? _toggle : null,
                              activeTrackColor: c.primary,
                            ),
                          ],
                        ),
                      ),
                      if (_biometrics.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text('Available methods',
                            style: AppText.label.copyWith(color: c.textSubtle)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final b in _biometrics)
                              AppChip(label: _labelFor(b)),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PillButton(
                        label: 'Test unlock',
                        variant: PillVariant.secondary,
                        leading: Icon(Icons.fingerprint,
                            size: 18, color: c.text),
                        onPressed: _supported ? _testUnlock : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
