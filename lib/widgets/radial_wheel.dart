import 'dart:math';
import 'package:flutter/material.dart';
import '../models/section.dart';
import '../theme/app_colors.dart';

class RadialWheel extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSectionTap;

  const RadialWheel({
    super.key,
    required this.selectedIndex,
    required this.onSectionTap,
  });

  @override
  State<RadialWheel> createState() => _RadialWheelState();
}

class _RadialWheelState extends State<RadialWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _tappedIndex = -1;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.reset();
        final tapped = _tappedIndex;
        setState(() => _tappedIndex = -1);
        if (tapped >= 0) widget.onSectionTap(tapped);
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details, Size size) {
    if (_bounceController.isAnimating) return;
    final center = Offset(size.width / 2, size.height / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final innerR = size.width * 0.16;
    final outerR = size.width * 0.46;
    if (distance < innerR || distance > outerR) return;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final n = kSections.length;
    final index = (angle / (2 * pi / n)).floor() % n;

    setState(() => _tappedIndex = index);
    _bounceController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleTap(details, box.size);
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, _) {
          return CustomPaint(
            painter: _WheelPainter(
              sections: kSections,
              selectedIndex: widget.selectedIndex,
              tappedIndex: _tappedIndex,
              bounceValue: _bounceAnimation.value,
              isDark: isDark,
            ),
            child: _WheelIcons(
              sections: kSections,
              selectedIndex: widget.selectedIndex,
            ),
          );
        },
      ),
    );
  }
}

// ── Icons overlay ────────────────────────────────────────────────────────────

class _WheelIcons extends StatelessWidget {
  final List<AppSection> sections;
  final int selectedIndex;

  const _WheelIcons({required this.sections, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final center = Offset(size.width / 2, size.height / 2);
      final innerR = size.width * 0.16;
      final outerR = size.width * 0.46;
      final midR = (innerR + outerR) / 2;
      final n = sections.length;
      final sectionAngle = 2 * pi / n;

      return Stack(children: [
        // Section icons + labels
        ...List.generate(n, (i) {
          final angle = i * sectionAngle - pi / 2 + sectionAngle / 2;
          final dx = center.dx + midR * cos(angle);
          final dy = center.dy + midR * sin(angle);
          final isSelected = i == selectedIndex;

          return Positioned(
            left: dx - 24,
            top: dy - 22,
            width: 48,
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sections[i].icon,
                  color: Colors.white.withAlpha(isSelected ? 255 : 130),
                  size: 18,
                ),
                const SizedBox(height: 3),
                Text(
                  sections[i].label.length > 6
                      ? sections[i].label.substring(0, 6)
                      : sections[i].label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(isSelected ? 230 : 110),
                    fontSize: 7,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),

        // Center logo
        Positioned(
          left: center.dx - innerR + 6,
          top: center.dy - innerR + 6,
          width: (innerR - 6) * 2,
          height: (innerR - 6) * 2,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NO',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
                Text(
                  'TMR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
    });
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final List<AppSection> sections;
  final int selectedIndex;
  final int tappedIndex;
  final double bounceValue;
  final bool isDark;

  _WheelPainter({
    required this.sections,
    required this.selectedIndex,
    required this.tappedIndex,
    required this.bounceValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerR = size.width * 0.16;
    final baseOuterR = size.width * 0.46;
    const gapAngle = 0.03;
    final n = sections.length;
    final sectionAngle = 2 * pi / n;

    for (int i = 0; i < n; i++) {
      final isSelected = i == selectedIndex;
      final isTapped = i == tappedIndex;
      final expand = isTapped ? bounceValue * baseOuterR * 0.07 : 0.0;
      final outerR = baseOuterR + expand;

      final startAngle = i * sectionAngle - pi / 2 + gapAngle / 2;
      final sweepAngle = sectionAngle - gapAngle;

      final Color fillColor;
      if (isSelected) {
        fillColor = sections[i].color;
      } else if (isDark) {
        fillColor = const Color(0xFF1C1C27);
      } else {
        fillColor = const Color(0xFFE8EAFF);
      }

      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      _drawSector(canvas, center, innerR, outerR, startAngle, sweepAngle, paint);

      if (!isSelected) {
        final borderPaint = Paint()
          ..color = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFCED2F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        _drawSector(canvas, center, innerR, outerR, startAngle, sweepAngle, borderPaint);
      }
    }

    // Center hole
    canvas.drawCircle(
      center,
      innerR - 2,
      Paint()
        ..color = isDark ? const Color(0xFF0A0A0F) : Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      innerR - 2,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawSector(Canvas canvas, Offset center, double innerR, double outerR,
      double startAngle, double sweepAngle, Paint paint) {
    final path = Path();
    path.moveTo(
      center.dx + innerR * cos(startAngle),
      center.dy + innerR * sin(startAngle),
    );
    path.lineTo(
      center.dx + outerR * cos(startAngle),
      center.dy + outerR * sin(startAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle,
      sweepAngle,
      false,
    );
    path.lineTo(
      center.dx + innerR * cos(startAngle + sweepAngle),
      center.dy + innerR * sin(startAngle + sweepAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerR),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.tappedIndex != tappedIndex ||
      old.bounceValue != bounceValue ||
      old.isDark != isDark;
}
