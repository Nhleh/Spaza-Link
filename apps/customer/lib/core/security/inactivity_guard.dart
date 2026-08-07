import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../router/app_router.dart';

/// How long the app may sit idle before the session is invalidated (spec #2).
const Duration kInactivityTimeout = Duration(minutes: 5);

const String _kLastActiveKey = 'last_active_at_ms';

Box<dynamic>? _settingsBox() => Hive.isBoxOpen(AppConstants.hiveBoxSettings)
    ? Hive.box<dynamic>(AppConstants.hiveBoxSettings)
    : null;

/// Stamp "now" as the last time the user interacted with the app.
void recordActivityNow() {
  _settingsBox()?.put(_kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
}

DateTime? _lastActiveAt() {
  final ms = _settingsBox()?.get(_kLastActiveKey);
  return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
}

/// True when a previous session has been idle past [kInactivityTimeout].
/// A missing timestamp is treated as *not* stale so a just-registered user is
/// never bounced straight back to Login.
bool isSessionStale() {
  final last = _lastActiveAt();
  if (last == null) return false;
  return DateTime.now().difference(last) >= kInactivityTimeout;
}

/// Called from `main()` before `runApp`: if a session was restored from disk but
/// has been idle too long, sign it out so reopening the app requires a fresh
/// login (spec #1 — "never access protected screens because the app was
/// previously opened").
Future<void> enforceFreshSessionOnStartup() async {
  try {
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;
    if (hasSession && isSessionStale()) {
      await Supabase.instance.client.auth.signOut();
    }
  } catch (_) {
    // Never let a security check crash startup.
  }
}

/// Wraps the whole app (via `MaterialApp.router`'s builder). Tracks pointer
/// activity + app lifecycle and signs the user out after [kInactivityTimeout]
/// of inactivity, whether the app is left open, minimised, or reopened.
class InactivityGuard extends ConsumerStatefulWidget {
  const InactivityGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends ConsumerState<InactivityGuard>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    recordActivityNow();
    // Poll rather than a single long timer so a drifted/slept timer still
    // catches the "app left open and untouched" case.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Freeze the clock at the moment we leave the foreground; time spent
        // backgrounded then counts toward the timeout on resume.
        recordActivityNow();
      case AppLifecycleState.resumed:
        _check();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onActivity([PointerEvent? _]) => recordActivityNow();

  void _check() {
    final signedIn = ref.read(authUidProvider).valueOrNull != null;
    if (signedIn && isSessionStale()) {
      unawaited(_logout());
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Even if the network sign-out fails, drop the user to Login below.
    }
    if (!mounted) return;
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentShopProvider);
    recordActivityNow(); // reset so we don't re-fire on the next tick
    ref.read(customerRouterProvider).go(RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onActivity,
      onPointerMove: _onActivity,
      child: widget.child,
    );
  }
}
