import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/session.dart';

/// Runs one throttled, app-wide reconciliation whenever the process resumes.
///
/// The session owns request deduplication and the performance cooldown. Keeping
/// lifecycle observation here means account access changes are detected even
/// when the user resumes on a detail screen rather than a specific tab.
class AppLifecycleReconciler extends StatefulWidget {
  const AppLifecycleReconciler({
    super.key,
    required this.child,
    this.appSession,
  });

  final Widget child;
  final AppSession? appSession;

  @override
  State<AppLifecycleReconciler> createState() => _AppLifecycleReconcilerState();
}

class _AppLifecycleReconcilerState extends State<AppLifecycleReconciler>
    with WidgetsBindingObserver {
  AppSession get _session => widget.appSession ?? session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      _session.reconcileAfterResume().catchError((_) {
        // The current screen remains usable and manual refresh can retry. The
        // session has already retained a user-facing error for shared UI.
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
