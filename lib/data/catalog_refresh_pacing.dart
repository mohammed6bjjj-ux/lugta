/// Only automatic catalog invalidations are paced; manual refresh stays immediate.
Duration catalogRealtimeDelay(
  DateTime now,
  DateTime? nextAllowed,
  int spreadMs,
) {
  final jitter = Duration(milliseconds: 700 + spreadMs.clamp(0, 1200));
  final remaining = nextAllowed?.difference(now) ?? Duration.zero;
  return remaining > jitter ? remaining : jitter;
}
