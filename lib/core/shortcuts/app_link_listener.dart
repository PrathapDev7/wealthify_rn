import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'app_links.dart';
import '../../features/auth/session_controller.dart';

/// Listens for stashed deep links (quick actions / widget taps that arrive
/// while the app is already running) and navigates to them.
///
/// Cold starts and signed-out taps are handled by the router redirect instead,
/// which consumes the same stash — whoever gets there first wins.
class AppLinkListener extends ConsumerStatefulWidget {
  const AppLinkListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLinkListener> createState() => _AppLinkListenerState();
}

class _AppLinkListenerState extends ConsumerState<AppLinkListener> {
  @override
  void initState() {
    super.initState();
    AppLinks.pendingRoute.addListener(_onLink);
  }

  @override
  void dispose() {
    AppLinks.pendingRoute.removeListener(_onLink);
    super.dispose();
  }

  void _onLink() {
    final route = AppLinks.pendingRoute.value;
    if (route == null || !mounted) return;
    final authed = ref.read(sessionProvider).asData?.value != null;
    if (!authed) return;
    final router = ref.read(routerProvider);
    if (router.state.matchedLocation == Uri.parse(route).path) {
      AppLinks.consumeRoute();
      return;
    }
    AppLinks.consumeRoute();
    router.go(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
