import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/app_colors.dart';
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
  bool _hasHardware = false;
  bool _enrolled = false;
  List<BiometricType> _biometrics = const [];

  /// Whether App Lock can be enabled — hardware present AND a biometric enrolled
  /// (mirrors RN's `available = hasHw && enrolled`).
  bool get _available => _hasHardware && _enrolled;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final enabled = ref.read(prefsProvider).getBool(Prefs.kAppLock);

    var hasHardware = false;
    var enrolled = false;
    var biometrics = const <BiometricType>[];
    try {
      // `isDeviceSupported()` reports whether the device has the sensor/OS
      // support; `getAvailableBiometrics()` reports what is actually enrolled.
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      hasHardware = deviceSupported || canCheck;
      biometrics = await _auth.getAvailableBiometrics();
      enrolled = biometrics.isNotEmpty;
    } catch (_) {
      // local_auth unavailable (e.g. web/unsupported platform) — stay disabled.
      hasHardware = false;
      enrolled = false;
      biometrics = const [];
    }

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _hasHardware = hasHardware;
      _enrolled = enrolled;
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

    if (!_available) {
      showAppSnack(context, 'No biometrics enrolled on this device',
          error: true);
      return;
    }

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

  /// Human label for a biometric type, mirroring RN's `labelForType`.
  String _labelFor(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint/Touch ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
      case BiometricType.weak:
        return 'Biometrics';
    }
  }

  /// Distinct supported-method labels for display (dedupes the `strong`/`weak`
  /// class entries that map to the same generic label).
  List<String> get _methodLabels {
    final seen = <String>{};
    final labels = <String>[];
    for (final b in _biometrics) {
      final label = _labelFor(b);
      if (seen.add(label)) labels.add(label);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Security'),
          Expanded(
            child: _loading
                ? const LoadingView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 60),
                    children: [
                      _capabilityCard(c),
                      const SizedBox(height: AppSpacing.lg),
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
                              onChanged: _available ? _toggle : null,
                              activeTrackColor: c.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'Test unlock',
                        variant: PillVariant.secondary,
                        leading: Icon(Icons.fingerprint,
                            size: 18, color: c.text),
                        onPressed: _available ? _testUnlock : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Capability summary card mirroring RN's available / no-hardware /
  /// not-enrolled states.
  Widget _capabilityCard(AppColors c) {
    if (_available) {
      final methods = _methodLabels;
      final body = methods.isNotEmpty
          ? 'This device supports ${methods.join(', ')}.'
          : 'This device supports biometric authentication.';
      return _infoCard(
        c,
        icon: Icons.verified_user_outlined,
        iconColor: c.primary,
        badgeColor: c.primary.withValues(alpha: 0.13),
        title: 'Biometric unlock available',
        body: body,
      );
    }

    final title = !_hasHardware ? 'No biometric hardware' : 'No biometrics enrolled';
    final body = !_hasHardware
        ? 'This device has no biometric sensor, so App Lock cannot be enabled.'
        : 'Add a fingerprint, Face ID, or device passcode in your system '
            'settings to use App Lock.';
    return _infoCard(
      c,
      icon: Icons.warning_amber_rounded,
      iconColor: c.warning,
      badgeColor: c.warning.withValues(alpha: 0.13),
      title: title,
      body: body,
      warn: true,
    );
  }

  Widget _infoCard(
    AppColors c, {
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required String title,
    required String body,
    bool warn = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title,
                  style: AppText.bodyMedium.copyWith(color: c.text)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: AppText.bodySm.copyWith(color: c.textSubtle)),
      ],
    );

    // Positive state reuses the standard surface card.
    if (!warn) return AppCard(child: content);

    // Warning state tints the card like RN's `warnCard` (soft bg + border).
    // Built bespoke because AppCard hardcodes the opaque surface fill.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.warning.withValues(alpha: 0.33)),
      ),
      child: content,
    );
  }
}
