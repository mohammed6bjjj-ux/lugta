import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// دخول متدرج للعناصر (Staggered entrance): تلاشٍ + انزلاق ناعم للأعلى.
/// مرر [index] لعناصر القوائم فيتأخر كل عنصر قليلاً عن سابقه.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 55),
    this.duration = AppDurations.slow,
    this.offsetY = 26,
  });

  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double offsetY;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: AppCurves.emphasized,
  );

  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    // تأخير متدرج بحسب ترتيب العنصر (بحد أقصى ~500ms كي لا يتأخر ذيل القوائم).
    final delayMs = (widget.baseDelay.inMilliseconds * widget.index).clamp(
      0,
      500,
    );
    if (delayMs == 0) {
      _controller.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
