import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Wraps [child] in an iPhone-style frame when running on web at desktop widths.
/// On phone-sized screens or native platforms the child is returned unchanged,
/// so friends testing on iOS/Android see a real full-screen app.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  // iPhone 14 Pro logical size
  static const double _phoneW = 393;
  static const double _phoneH = 852;
  static const double _breakpoint = 600; // below this → fullscreen (mobile)

  @override
  Widget build(BuildContext context) {
    // Only frame on web desktop. On real iOS/Android/Windows desktop apps,
    // use fullscreen. On web when window is narrow, also fullscreen.
    if (!kIsWeb) return child;
    final size = MediaQuery.of(context).size;
    if (size.width < _breakpoint) return child;

    return Material(
      color: const Color(0xFF0A0A0F),
      child: Stack(children: [
        // Ambient background glow
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [Color(0xFF1A1A24), Color(0xFF000000)],
              ),
            ),
          ),
        ),
        // Centered phone
        Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _PhoneChassis(
                width: _phoneW,
                height: _phoneH,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(_phoneW, _phoneH),
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    viewPadding: const EdgeInsets.only(top: 14, bottom: 24),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PhoneChassis extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  const _PhoneChassis({
    required this.width, required this.height, required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const bezel = 12.0;
    const radius = 56.0;
    return Container(
      width: width + bezel * 2,
      height: height + bezel * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        borderRadius: BorderRadius.circular(radius + 4),
        border: Border.all(color: const Color(0xFF22222A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(200),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.white.withAlpha(10),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(bezel),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - bezel),
          child: Stack(children: [
            SizedBox(width: width, height: height, child: child),
            // Dynamic island
            Positioned(
              top: 11, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 110, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
