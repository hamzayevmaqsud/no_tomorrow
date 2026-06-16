import 'package:flutter/widgets.dart';

/// Corner-radius scale.
///
/// Collapses the 19 distinct radius values previously used (2, 3, 4, 6, 7, 8,
/// 10, 12, 13, 14, 16, 18, 20, 22, 24, 28, 32, 36, 40) down to a deliberate
/// ladder. Use the named `r*` doubles or the pre-built `BorderRadius` helpers.
class AppRadius {
  AppRadius._();

  static const double rSm  = 8;   // chips, small controls, inputs
  static const double rMd  = 12;  // default card / button radius
  static const double rLg  = 16;  // large cards, sheets
  static const double rXl  = 24;  // hero surfaces, bottom sheets
  static const double rPill = 999; // fully rounded (pills, avatars)

  static const sm  = BorderRadius.all(Radius.circular(rSm));
  static const md  = BorderRadius.all(Radius.circular(rMd));
  static const lg  = BorderRadius.all(Radius.circular(rLg));
  static const xl  = BorderRadius.all(Radius.circular(rXl));
  static const pill = BorderRadius.all(Radius.circular(rPill));

  /// Rounded top corners only — for bottom sheets / panels that slide up.
  static const topLg = BorderRadius.vertical(top: Radius.circular(rLg));
  static const topXl = BorderRadius.vertical(top: Radius.circular(rXl));
}
