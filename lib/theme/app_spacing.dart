import 'package:flutter/widgets.dart';

/// Spacing scale — a single 4/8-based grid for all padding, margins and gaps.
///
/// Replaces the ad-hoc spacing values (1, 2, 3, 5, 6, 14, 28, 44, 70…) found
/// scattered across screens. Prefer these tokens over raw numbers so vertical
/// rhythm stays consistent.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Ready-made vertical / horizontal gaps for use inside Column / Row children.
  static const gapXs  = SizedBox(height: xs,  width: xs);
  static const gapSm  = SizedBox(height: sm,  width: sm);
  static const gapMd  = SizedBox(height: md,  width: md);
  static const gapLg  = SizedBox(height: lg,  width: lg);
  static const gapXl  = SizedBox(height: xl,  width: xl);

  static const vGapXs = SizedBox(height: xs);
  static const vGapSm = SizedBox(height: sm);
  static const vGapMd = SizedBox(height: md);
  static const vGapLg = SizedBox(height: lg);
  static const vGapXl = SizedBox(height: xl);

  static const hGapXs = SizedBox(width: xs);
  static const hGapSm = SizedBox(width: sm);
  static const hGapMd = SizedBox(width: md);
  static const hGapLg = SizedBox(width: lg);
  static const hGapXl = SizedBox(width: xl);

  // Common screen padding.
  static const screenH = EdgeInsets.symmetric(horizontal: lg);
  static const screenAll = EdgeInsets.all(lg);
  static const cardPad = EdgeInsets.all(md);
}
