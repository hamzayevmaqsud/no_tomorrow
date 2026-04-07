import 'package:flutter/material.dart';

/// Wraps any screen so that a left-to-right swipe pops the route,
/// with a visual edge glow indicator while swiping.
class SwipeToPop extends StatefulWidget {
  final Widget child;
  const SwipeToPop({super.key, required this.child});

  @override
  State<SwipeToPop> createState() => _SwipeToPopState();
}

class _SwipeToPopState extends State<SwipeToPop> {
  double _dragX = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        if (d.delta.dx > 0) {
          setState(() => _dragX = (_dragX + d.delta.dx).clamp(0.0, 120.0));
        }
      },
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 250 || _dragX > 80) {
          Navigator.maybePop(context);
        }
        setState(() => _dragX = 0);
      },
      onHorizontalDragCancel: () => setState(() => _dragX = 0),
      child: Stack(
        children: [
          widget.child,
          // Edge glow indicator
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
