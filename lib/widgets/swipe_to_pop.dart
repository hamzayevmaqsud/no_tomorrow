import 'package:flutter/material.dart';

/// Wraps any screen so that a left-to-right swipe pops the route.
class SwipeToPop extends StatelessWidget {
  final Widget child;
  const SwipeToPop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 250) Navigator.maybePop(context);
      },
      child: child,
    );
  }
}
