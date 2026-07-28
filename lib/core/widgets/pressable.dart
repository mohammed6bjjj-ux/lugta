import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// تفاعل لمس حديث: تصغير ناعم عند الضغط (Micro-interaction).
/// يلفّ أي ودجت ويعطيه إحساس الاستجابة الفورية بدل الـ Ripple التقليدي وحده.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = .97,
    this.enabled = true,
    this.semanticLabel,
    this.semanticToggled,
    this.minimumSize,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enabled;
  final String? semanticLabel;
  final bool? semanticToggled;
  final Size? minimumSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    final minimumSize = widget.minimumSize;
    if (minimumSize != null) {
      child = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimumSize.width,
          minHeight: minimumSize.height,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      );
    }
    if (!widget.enabled ||
        (widget.onTap == null && widget.onLongPress == null)) {
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        enabled: false,
        toggled: widget.semanticToggled,
        child: child,
      );
    }
    return Semantics(
      container: true,
      button: widget.onTap != null,
      enabled: true,
      label: widget.semanticLabel,
      toggled: widget.semanticToggled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? .9 : 1,
            duration: AppDurations.fast,
            child: child,
          ),
        ),
      ),
    );
  }
}
