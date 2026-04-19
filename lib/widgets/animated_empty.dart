import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated empty state — float + pulse icon with title & subtitle.
class AnimatedEmpty extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const AnimatedEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  @override
  State<AnimatedEmpty> createState() => _AnimatedEmptyState();
}

class _AnimatedEmptyState extends State<AnimatedEmpty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.iconColor ?? Colors.white.withAlpha(180);
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final y = sin(_ctrl.value * pi) * 10;
          final opacity = 0.7 + 0.3 * sin(_ctrl.value * pi);
          return Transform.translate(
            offset: Offset(0, -y),
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withAlpha(15),
                border: Border.all(color: c.withAlpha(60), width: 1.5),
              ),
              child: Icon(widget.icon, size: 32, color: c),
            ),
            const SizedBox(height: 20),
            Text(widget.title,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(200),
              )),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white.withAlpha(140),
                )),
            ],
          ],
        ),
      ),
    );
  }
}
