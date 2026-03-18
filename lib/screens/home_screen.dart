import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/section.dart';
import '../models/game_state.dart';
import 'section_screen.dart';
import 'settings_screen.dart';
import 'tasks_menu_screen.dart';
import 'collection_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Static so TweenAnimationBuilder never gets a new object → no restart on setState
  static final _launchTween = Tween<double>(begin: 0.0, end: 1.0);

  int _currentIndex = 0;

  // Isolated so only the CustomPaint repaints during drag
  final _angleNotifier = ValueNotifier<double>(0.0);

  late AnimationController _snapCtrl;
  double _snapFrom = 0.0;
  double _snapTo = 0.0;

  static const _n = 9;
  static const _sensitivity = 0.007;

  double get _sectionAngle => 2 * pi / _n;
  double get _angle => _angleNotifier.value;
  set _angle(double v) => _angleNotifier.value = v;

  @override
  void initState() {
    super.initState();
    _angle = -_sectionAngle / 2;
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    // expo-like ease-out: fast start, silky deceleration
    const snapCurve = Cubic(0.16, 1.0, 0.3, 1.0);
    _snapCtrl.addListener(() {
      _angle = _snapFrom + (_snapTo - _snapFrom) *
          snapCurve.transform(_snapCtrl.value);
    });
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    _angleNotifier.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _snapCtrl.stop();
    _angle += d.delta.dx * _sensitivity;
  }

  void _onDragEnd(DragEndDetails d) {
    final momentum = d.velocity.pixelsPerSecond.dx * _sensitivity * 0.04;
    final projected = _angle + momentum;
    int idx =
        (-(projected + _sectionAngle / 2) / _sectionAngle).round() % _n;
    if (idx < 0) idx += _n;
    _snapFrom = _angle;
    _snapTo = -(idx + 0.5) * _sectionAngle;
    if (_currentIndex != idx) {
      _currentIndex = idx;
      HapticFeedback.selectionClick();
      setState(() {});
    }
    _snapCtrl.forward(from: 0);
  }

  void _goTo(int index) {
    _snapFrom = _angle;
    _snapTo = -(index + 0.5) * _sectionAngle;
    if (_currentIndex != index) {
      _currentIndex = index;
      setState(() {});
    }
    _snapCtrl.forward(from: 0);
  }

  void _open() {
    final section = kSections[_currentIndex];
    final page = section.id == 'tasks'
        ? const TasksMenuScreen()
        : section.id == 'collect'
            ? const CollectionScreen()
            : SectionScreen(section: section);
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, sec) => page,
        transitionsBuilder: (ctx, anim, sec, child) {
          final c =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(c),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, sec) => SettingsScreen(
          onToggleTheme: widget.onToggleTheme,
        ),
        transitionsBuilder: (ctx, anim, sec, child) {
          final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(c),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final section = kSections[_currentIndex];

    return TweenAnimationBuilder<double>(
      tween: _launchTween,
      duration: const Duration(milliseconds: 700),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 80),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Pizza wheel ────────────────────────────────────────────────────
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onTap: _open,
            child: ValueListenableBuilder<double>(
              valueListenable: _angleNotifier,
              builder: (_, angle, _) => SizedBox.expand(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _PizzaPainter(
                      sections: kSections,
                      rotation: angle,
                      screenSize: size,
                    ),
                  ),
                ),
              ),
            ),
          ),


          // ── Magical glow at focal point ───────────────────────────────────
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GlowPainter(color: section.color),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // ── Gradient top ──────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.30,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(200), Colors.transparent],
                ),
              ),
            )),
          ),

          // ── Gradient bottom ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.40,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(220), Colors.transparent],
                ),
              ),
            )),
          ),

          // ── Gradient left ─────────────────────────────────────────────────
          Positioned(
            top: 0, bottom: 0, left: 0,
            width: size.width * 0.40,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withAlpha(210), Colors.transparent],
                ),
              ),
            )),
          ),

          // ── Gradient right ────────────────────────────────────────────────
          Positioned(
            top: 0, bottom: 0, right: 0,
            width: size.width * 0.40,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.black.withAlpha(210), Colors.transparent],
                ),
              ),
            )),
          ),

          // ── Comic overlay (speed lines + halftone) ────────────────────────
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ComicOverlayPainter(sectionColor: section.color),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(170),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Row(
                  children: [
                    // Circle avatar with neon glow
                    GestureDetector(
                      onTap: () => _goTo(8),
                      child: Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3D1464), Color(0xFF0F2060)],
                          ),
                          border: Border.all(
                              color: const Color(0xFF00EEFF), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00EEFF).withAlpha(90),
                              blurRadius: 14, spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/avatar.png',
                            width: 54, height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Center(
                              child: Text('H', style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 24,
                                fontWeight: FontWeight.w900,
                              )),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Name + level + XP bar
                    Expanded(
                      child: ListenableBuilder(
                        listenable: GameState.instance,
                        builder: (ctx, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('HAMZA',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13, fontWeight: FontWeight.w900,
                                    letterSpacing: 2, color: Colors.white,
                                  )),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  color: kSections[8].color,
                                  child: Text('LVL ${GameState.instance.level}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8, fontWeight: FontWeight.w900,
                                      letterSpacing: 1, color: Colors.white,
                                    )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(children: [
                                    Container(height: 4,
                                        color: Colors.white.withAlpha(20)),
                                    FractionallySizedBox(
                                      widthFactor: GameState.instance.levelProgress,
                                      child: Container(
                                          height: 4, color: kSections[8].color),
                                    ),
                                  ]),
                                ),
                                const SizedBox(width: 8),
                                Text('${GameState.instance.xpInLevel}/${GameState.instance.xpForNextLevel}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8, fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: Colors.white.withAlpha(140),
                                  )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Settings
                    GestureDetector(
                      onTap: () => _openSettings(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withAlpha(35)),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),        // closes SafeArea
          ),        // closes Positioned (header)

          // ── Section label ─────────────────────────────────────────────────
          Positioned(
            top: size.height * 0.20,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                  ));
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _SectionLabel(
                  key: ValueKey(_currentIndex),
                  section: section,
                ),
              ),
            ),
          ),

          // ── Section animation (budget: wallet) ───────────────────────────
          Positioned(
            top: size.height * 0.43,
            left: size.width * 0.08,
            right: size.width * 0.08,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                reverseDuration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: section.id == 'budget'
                    ? SizedBox(
                        key: const ValueKey('budget_anim'),
                        height: 300,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 0, left: 30, right: 30,
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  boxShadow: [BoxShadow(
                                    color: Colors.black.withAlpha(100),
                                    blurRadius: 30, spreadRadius: 10,
                                  )],
                                ),
                              ),
                            ),
                            Lottie.asset('assets/animations/wallet.json',
                                fit: BoxFit.contain),
                          ],
                        ),
                      )
                    : section.id == 'tasks'
                        ? const SizedBox(
                            key: ValueKey('tasks_anim'),
                            height: 300,
                            child: _SisyphusAnim(),
                          )
                        : const SizedBox(key: ValueKey('no_anim')),
              ),
            ),
          ),

          // ── Open button ───────────────────────────────────────────────────
          Positioned(
            bottom: size.height * 0.13,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                ),
                child: GestureDetector(
                  key: ValueKey(_currentIndex),
                  onTap: _open,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 13),
                    decoration: BoxDecoration(
                      color: section.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OPEN  ${section.label}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Color nav bar ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _ColorNavBar(
                sections: kSections,
                currentIndex: _currentIndex,
                onTap: _goTo,
              ),
            ),
          ),
        ],
      ),
    ),   // closes Scaffold (child of TweenAnimationBuilder)
    );   // closes TweenAnimationBuilder
  }
}

// ── Section label with per-section font style ─────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final AppSection section;
  const _SectionLabel({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final style = _labelStyle(section.id);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (style.prefixWidget != null) ...[
              style.prefixWidget!,
              const SizedBox(width: 10),
            ],
            Icon(section.icon, size: 48, color: Colors.white),
            if (style.suffixWidget != null) ...[
              const SizedBox(width: 10),
              style.suffixWidget!,
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(
          section.label,
          style: GoogleFonts.outfit(
            fontSize: style.fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: style.letterSpacing,
            fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section.description.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: Colors.white.withAlpha(160),
          ),
        ),
        const SizedBox(height: 10),
        if (style.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: section.color.withAlpha(80),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: section.color.withAlpha(120)),
            ),
            child: Text(
              style.badge!,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ),
      ],
    );
  }

  _LabelStyle _labelStyle(String id) {
    switch (id) {
      case 'tasks':
        return _LabelStyle(
          fontSize: 52, letterSpacing: 1, badge: '✓  TODAY\'S TASKS',
          prefixWidget: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 22),
          suffixWidget: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 22),
        );
      case 'habits':
        return _LabelStyle(
          fontSize: 50, letterSpacing: 1, badge: '↻  DAILY STREAK',
          prefixWidget: const Icon(Icons.loop_rounded, color: Colors.white70, size: 22),
        );
      case 'workouts':
        return _LabelStyle(
          fontSize: 48, letterSpacing: 1, badge: '🔥  KEEP THE GRIND',
          prefixWidget: const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 26),
        );
      case 'abstain':
        return _LabelStyle(
          fontSize: 48, letterSpacing: 1, badge: '✕  DAYS CLEAN', italic: true,
          suffixWidget: const Icon(Icons.block_rounded, color: Colors.white60, size: 22),
        );
      case 'reading':
        return _LabelStyle(
          fontSize: 50, letterSpacing: 1, badge: '📖  PAGES READ',
          prefixWidget: const Text('"', style: TextStyle(color: Colors.white60, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
          suffixWidget: const Text('"', style: TextStyle(color: Colors.white60, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
        );
      case 'budget':
        return _LabelStyle(
          fontSize: 52, letterSpacing: 1, badge: '\$  TRACK MONEY',
          prefixWidget: const Text('\$', style: TextStyle(color: Colors.white70, fontSize: 28, fontWeight: FontWeight.w900)),
          suffixWidget: Text('¢', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 22, fontWeight: FontWeight.w900)),
        );
      case 'food':
        return _LabelStyle(
          fontSize: 54, letterSpacing: 1, badge: '🥗  KCAL TODAY',
          prefixWidget: const Text('🥦', style: TextStyle(fontSize: 24)),
          suffixWidget: const Text('🍎', style: TextStyle(fontSize: 24)),
        );
      case 'collect':
        return _LabelStyle(
          fontSize: 48, letterSpacing: 1, badge: '⭐  YOUR REWARDS',
          prefixWidget: const Text('⭐', style: TextStyle(fontSize: 22)),
          suffixWidget: const Text('💎', style: TextStyle(fontSize: 22)),
        );
      case 'profile':
        return _LabelStyle(
          fontSize: 50, letterSpacing: 1, badge: '◈  LEVEL 1  XP',
          prefixWidget: const Icon(Icons.military_tech_rounded, color: Colors.white70, size: 24),
        );
      default:
        return _LabelStyle(fontSize: 52, letterSpacing: 1);
    }
  }
}

class _LabelStyle {
  final double fontSize;
  final double letterSpacing;
  final bool italic;
  final String? badge;
  final Widget? prefixWidget;
  final Widget? suffixWidget;

  const _LabelStyle({
    required this.fontSize,
    required this.letterSpacing,
    this.italic = false,
    this.badge,
    this.prefixWidget,
    this.suffixWidget,
  });
}

// ── Color nav bar ─────────────────────────────────────────────────────────────

class _ColorNavBar extends StatelessWidget {
  final List<AppSection> sections;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ColorNavBar({
    required this.sections,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: List.generate(sections.length, (i) {
          final isSelected = i == currentIndex;
          final section = sections[i];
          return Expanded(
            flex: isSelected ? 3 : 1,
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: isSelected ? 36 : 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? section.color
                      : section.color.withAlpha(70),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Center(
                        child: Text(
                          section.label.length > 4
                              ? section.label.substring(0, 4)
                              : section.label,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          section.icon,
                          size: 12,
                          color: Colors.white.withAlpha(160),
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Pizza wheel painter ───────────────────────────────────────────────────────

class _PizzaPainter extends CustomPainter {
  final List<AppSection> sections;
  final double rotation;
  final Size screenSize;

  _PizzaPainter({
    required this.sections,
    required this.rotation,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = sections.length;
    final sectionAngle = 2 * pi / n;
    const gap = 0.016;

    final center = Offset(size.width / 2, size.height * 1.12);
    final outerR = size.height * 1.55;
    const innerR = 0.0;

    for (int i = 0; i < n; i++) {
      final startAngle = i * sectionAngle - pi / 2 + rotation + gap / 2;
      final sweepAngle = sectionAngle - gap;
      final midAngle = startAngle + sweepAngle / 2;

      double dist = ((midAngle + pi / 2) % (2 * pi));
      if (dist > pi) dist = 2 * pi - dist;
      final brightness = (1.0 - dist / pi * 1.8).clamp(0.0, 1.0);

      final c = sections[i].color;
      final adjusted = Color.fromRGBO(
        ((c.r * 255.0).round().clamp(0, 255) * brightness).round(),
        ((c.g * 255.0).round().clamp(0, 255) * brightness).round(),
        ((c.b * 255.0).round().clamp(0, 255) * brightness).round(),
        1,
      );

      _drawSector(canvas, center, innerR, outerR, startAngle, sweepAngle,
          Paint()..color = adjusted);
    }
  }

  void _drawSector(Canvas canvas, Offset c, double iR, double oR,
      double start, double sweep, Paint paint) {
    final path = Path()
      ..moveTo(c.dx + iR * cos(start), c.dy + iR * sin(start))
      ..lineTo(c.dx + oR * cos(start), c.dy + oR * sin(start))
      ..arcTo(Rect.fromCircle(center: c, radius: oR), start, sweep, false)
      ..lineTo(
          c.dx + iR * cos(start + sweep), c.dy + iR * sin(start + sweep))
      ..arcTo(
          Rect.fromCircle(center: c, radius: iR), start + sweep, -sweep, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PizzaPainter old) => old.rotation != rotation;
}

// ── Magical glow painter ──────────────────────────────────────────────────────

class _GlowPainter extends CustomPainter {
  final Color color;
  _GlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final focal = Offset(size.width / 2, size.height * 0.44);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha(85),
          color.withAlpha(28),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: focal, radius: size.width * 0.68));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color;
}

// ── Comic book overlay (speed lines + halftone dots) ─────────────────────────

class _ComicOverlayPainter extends CustomPainter {
  final Color sectionColor;

  _ComicOverlayPainter({required this.sectionColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.12);
    _drawSpeedLines(canvas, size, center);
    _drawHalftone(canvas, size);
  }

  void _drawSpeedLines(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = sectionColor.withAlpha(22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final outerR = size.height * 1.65;
    final innerR = size.height * 0.28;
    const lineCount = 90;
    for (int i = 0; i < lineCount; i++) {
      final angle = (i / lineCount) * 2 * pi;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        paint,
      );
    }
  }

  void _drawHalftone(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = sectionColor.withAlpha(30)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const dotR = 1.6;
    for (double y = 0; y < size.height; y += spacing) {
      final rowOffset = ((y / spacing).round() % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(Offset(x + rowOffset, y), dotR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ComicOverlayPainter old) =>
      old.sectionColor != sectionColor;
}

// ── Sisyphus animation (tasks section) ───────────────────────────────────────

class _SisyphusAnim extends StatefulWidget {
  const _SisyphusAnim();

  @override
  State<_SisyphusAnim> createState() => _SisyphusAnimState();
}

class _SisyphusAnimState extends State<_SisyphusAnim>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _SisyphusPainter(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SisyphusPainter extends CustomPainter {
  final double t; // 0..1

  _SisyphusPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawBg(canvas, w, h);
    _drawMountain(canvas, w, h);
    final dy = -t * 4.0;
    _drawBoulder(canvas, w, h, dy);
    _drawPerson(canvas, w, h, t, dy);
  }

  void _drawBg(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCEE2EC), Color(0xFFB8CFD9)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // Glow circle
    canvas.drawCircle(
      Offset(w * 0.47, h * 0.26),
      h * 0.38,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFEAF5FA).withAlpha(160), Colors.transparent],
        ).createShader(Rect.fromCircle(
            center: Offset(w * 0.47, h * 0.26), radius: h * 0.38)),
    );
  }

  void _drawMountain(Canvas canvas, double w, double h) {
    final peak = Offset(w * 0.50, h * 0.29);

    // Facets — light to dark
    _tri(canvas, peak, Offset(w * 0.30, h * 0.46), Offset(w * 0.42, h * 0.43), const Color(0xFF2C5468));
    _tri(canvas, peak, Offset(w * 0.42, h * 0.43), Offset(w * 0.56, h * 0.41), const Color(0xFF234D62));
    _tri(canvas, peak, Offset(w * 0.22, h * 0.54), Offset(w * 0.30, h * 0.46), const Color(0xFF1E4456));
    _tri(canvas, peak, Offset(w * 0.56, h * 0.41), Offset(w * 0.70, h * 0.56), const Color(0xFF1B3D50));
    _tri(canvas, peak, Offset(w * 0.70, h * 0.56), Offset(w * 1.0, h * 0.76), const Color(0xFF162E3E));

    // Lower fill
    final body = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(w * 0.22, h * 0.54)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(w * 0.70, h * 0.56)
      ..lineTo(w, h * 0.76)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF102030));

    // Dark left face
    _tri(canvas, Offset(w * 0.22, h * 0.54), Offset(0, h * 0.72), Offset(0, h), const Color(0xFF0C1C28));
    _tri(canvas, Offset(w * 0.22, h * 0.54), Offset(0, h), Offset(w * 0.35, h), const Color(0xFF122434));
  }

  void _tri(Canvas canvas, Offset a, Offset b, Offset c, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  void _drawBoulder(Canvas canvas, double w, double h, double dy) {
    final center = Offset(w * 0.445, h * 0.200 + dy);
    final r = w * 0.138;

    canvas.drawCircle(
      center, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: const [Color(0xFFE83535), Color(0xFFC01818), Color(0xFF880A0A)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - r * 0.20, center.dy - r * 0.24),
      r * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withAlpha(55), Colors.transparent],
        ).createShader(Rect.fromCircle(
            center: Offset(center.dx - r * 0.20, center.dy - r * 0.24),
            radius: r * 0.52)),
    );
    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + r * 0.04, center.dy + r * 1.04),
        width: r * 1.0, height: r * 0.18,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.black.withAlpha(55), Colors.transparent],
        ).createShader(Rect.fromCircle(
            center: Offset(center.dx, center.dy + r),
            radius: r * 0.6)),
    );
  }

  void _drawPerson(Canvas canvas, double w, double h, double t, double dy) {
    const c = Color(0xFF0D1E2A);
    final stroke = Paint()
      ..color = c
      ..strokeWidth = w * 0.023
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = c..style = PaintingStyle.fill;

    final lean = t * 1.5;
    final footR = Offset(w * 0.598, h * 0.382);
    final footL = Offset(w * 0.570, h * 0.368);
    final hip    = Offset(w * 0.575 - lean * 0.003, h * 0.350);
    final shoulder = Offset(w * 0.556 - lean * 0.003, h * 0.322);
    final handContact = Offset(w * 0.468, h * 0.306 + dy * 0.75);

    canvas.drawLine(hip, footR, stroke);
    canvas.drawLine(hip, footL, stroke);
    canvas.drawLine(hip, shoulder, stroke);
    canvas.drawLine(shoulder, handContact, stroke);
    canvas.drawCircle(Offset(w * 0.549, h * 0.309), w * 0.019, fill);
  }

  @override
  bool shouldRepaint(_SisyphusPainter old) => old.t != t;
}
