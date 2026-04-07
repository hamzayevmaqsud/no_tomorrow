import 'package:flutter/material.dart';

/// Wraps any screen so that a left-edge swipe pops the route,
/// with a visual edge glow indicator. Only activates from left 40px.
class SwipeToPop extends StatefulWidget {
  final Widget child;
  const SwipeToPop({super.key, required this.child});

  @override
  State<SwipeToPop> createState() => _SwipeToPopState();
}

class _SwipeToPopState extends State<SwipeToPop> {
  double _dragX = 0;
  bool _active = false;

  void _onStart(DragStartDetails d) {
    // Only activate if starting from left 40px edge
    _active = d.globalPosition.dx < 40;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!_active) return;
    if (d.delta.dx > 0) {
      setState(() => _dragX = (_dragX + d.delta.dx).clamp(0.0, 120.0));
    }
  }

  void _onEnd(DragEndDetails d) {
    if (!_active) { setState(() => _dragX = 0); return; }
    if ((d.primaryVelocity ?? 0) > 250 || _dragX > 80) {
      Navigator.maybePop(context);
    }
    setState(() { _dragX = 0; _active = false; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: () => setState(() { _dragX = 0; _active = false; }),
      child: Stack(
        children: [
          widget.child,
          if (_dragX > 5)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withAlpha((_dragX * 0.4).toInt().clamp(0, 40)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
