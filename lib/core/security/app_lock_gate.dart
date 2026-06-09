import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../providers.dart';
import '../storage/prefs.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/buttons.dart';

/// Wraps the app and, when App Lock is enabled, requires biometric/passcode
/// authentication on launch and whenever the app returns from the background.
/// Wire via MaterialApp.router's `builder`.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = false;
  bool _authenticating = false;

  bool get _lockEnabled => ref.read(prefsProvider).getBool(Prefs.kAppLock);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_lockEnabled) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_locked) setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    _authenticating = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Wealthify',
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      // If auth is unavailable (e.g. no hardware), don't lock the user out.
      if (mounted) setState(() => _locked = false);
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: ColoredBox(
              color: c.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          c.primaryGradientStart,
                          c.primaryGradientEnd
                        ]),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.primaryGlow,
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Wealthify is locked',
                        style: AppText.subtitle.copyWith(color: c.text)),
                    const SizedBox(height: AppSpacing.xl2),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl4),
                      child: PillButton(
                          label: 'Unlock', onPressed: _authenticate),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
