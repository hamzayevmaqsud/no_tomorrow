import 'package:flutter/widgets.dart';

/// Typographic scale.
///
/// The codebase used 25+ distinct font sizes (down to 6–9px, which are below
/// the readable / accessibility floor). This scale defines a small set of
/// semantic styles with a hard minimum of [minReadable] (11px) for any text a
/// user is expected to read.
///
/// Styles intentionally omit `fontFamily` so they inherit the app font
/// (Outfit) from the active [TextTheme]; override per-use when a different
/// family (e.g. JetBrains Mono for numerals) is required.
class AppType {
  AppType._();

  /// Hard minimum size for any human-readable text.
  static const double minReadable = 11;

  // Display & headings
  static const display = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.5,
  );
  static const h1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w800, height: 1.1,
  );
  static const h2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800, height: 1.15,
  );
  static const h3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, height: 1.2,
  );

  // Body
  static const bodyLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500, height: 1.4,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
  );
  static const bodySm = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.35,
  );

  // Labels & captions (floor = 11px)
  static const label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static const caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3,
  );

  /// All-caps eyebrow / overline label (e.g. section headers).
  static const overline = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
  );
}
