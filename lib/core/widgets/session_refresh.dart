import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/session.dart';
import '../../l10n/core_strings.dart';

typedef SessionRefreshCallback = Future<void> Function();

Future<void> runSessionRefresh(
  BuildContext context, {
  SessionRefreshCallback? onRefresh,
}) async {
  try {
    await (onRefresh ?? session.refreshAllData)();
  } catch (_) {
    if (!context.mounted) return;
    final message = session.lastError?.trim();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message == null || message.isEmpty
                ? CoreStrings.refreshFailed
                : message,
          ),
        ),
      );
  }
}

/// Pull-to-refresh wrapper shared by backend-driven scrollable screens.
class SessionRefreshIndicator extends StatelessWidget {
  const SessionRefreshIndicator({
    super.key,
    required this.child,
    this.onRefresh,
  });

  final Widget child;
  final SessionRefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.goldDark,
      onRefresh: () => runSessionRefresh(context, onRefresh: onRefresh),
      child: child,
    );
  }
}

/// Explicit refresh action for forms and other screens where a pull gesture is
/// not practical. Repeated taps are ignored until the first request settles.
class SessionRefreshButton extends StatefulWidget {
  const SessionRefreshButton({super.key, this.onRefresh});

  final SessionRefreshCallback? onRefresh;

  @override
  State<SessionRefreshButton> createState() => _SessionRefreshButtonState();
}

class _SessionRefreshButtonState extends State<SessionRefreshButton> {
  bool _running = false;

  Future<void> _refresh() async {
    if (_running || session.isRefreshing) return;
    setState(() => _running = true);
    try {
      await runSessionRefresh(context, onRefresh: widget.onRefresh);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final loading = _running || session.isRefreshing;
        return IconButton(
          key: const ValueKey('session_refresh_button'),
          tooltip: CoreStrings.refreshTooltip,
          onPressed: loading ? null : _refresh,
          icon: loading
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.goldDark,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
        );
      },
    );
  }
}
