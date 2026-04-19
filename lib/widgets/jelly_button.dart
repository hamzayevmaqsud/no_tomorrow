import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tactile "jelly" button — press scales down with spring bounce-back.
/// Pro Max Tactile Digital / Deformable UI spec.
class JellyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final HitTestBehavior behavior;
  final bool haptic;
  final Duration pressDuration;
  final Duration releaseDuration;

  const JellyButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.93,
    this.behavior = HitTestBehavior.opaque,
    this.haptic = true,
    this.pressDuration = const Duration(milliseconds: 90),
    this.releaseDuration = const Duration(milliseconds: 400),
  });

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
      value: 0.0,
    );
    // cubic-bezier(0.34, 1.56, 0.64, 1) spring for bounce-back
    _scale = Tween(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _press() {
    if (widget.haptic) HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _release() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _press() : null,
      onTapUp: enabled ? (_) => _release() : null,
      onTapCancel: enabled ? _release : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
