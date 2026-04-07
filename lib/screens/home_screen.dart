import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../models/section.dart';
import '../theme/app_colors.dart';
import '../models/game_state.dart';
import 'section_screen.dart';
import 'settings_screen.dart';
import 'tasks_menu_screen.dart';
import 'collection_screen.dart';
import 'habits_screen.dart';
import 'workouts_screen.dart';
import 'abstain_screen.dart';
import 'reading_screen.dart';
import 'budget_screen.dart';
import 'food_screen.dart';
import 'profile_screen.dart';

const _kQuotes = [
  '"There is no tomorrow — only today."',
  '"The quest is the reward."',
  '"Level up or stay still."',
  '"Discipline is the bridge between goals and accomplishment."',
  '"Small daily improvements lead to stunning results."',
  '"You are one task away from a better version of yourself."',
  '"Consistency beats intensity."',
  '"The grind never lies."',
  '"Your future self is watching."',
  '"Every rep counts. Every page counts. Every day counts."',
  '"Comfort is the enemy of progress."',
  '"Be the hero of your own story."',
  '"No XP is wasted."',
  '"The streak is sacred."',
  '"Rise. Grind. Level up. Repeat."',
  '"What you do today echoes in eternity."',
  '"Pain is temporary, glory is forever."',
  '"The only bad workout is the one that didn\'t happen."',
  '"Build habits, not wishes."',
  '"Champions are made when no one is watching."',
  '"Your potential is infinite — unlock it."',
  '"One more rep. One more page. One more day."',
  '"The map is not the territory — explore."',
  '"Embrace the grind."',
  '"Yesterday you said tomorrow."',
  '"Make it happen or make excuses."',
  '"The best time to start was yesterday. The next best time is now."',
  '"You didn\'t come this far to only come this far."',
  '"Trust the process."',
  '"Hard choices, easy life."',
  '"Be relentless."',
];

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
    Widget page;
    switch (section.id) {
      case 'tasks':    page = const TasksMenuScreen(); break;
      case 'habits':   page = const HabitsScreen(); break;
      case 'workouts': page = const WorkoutsScreen(); break;
      case 'abstain':  page = const AbstainScreen(); break;
      case 'reading':  page = const ReadingScreen(); break;
      case 'budget':   page = const BudgetScreen(); break;
      case 'food':     page = const FoodScreen(); break;
      case 'collect':  page = const CollectionScreen(); break;
      case 'profile':  page = const ProfileScreen(); break;
      default:         page = SectionScreen(section: section); break;
    }
    // Per-section unique transition
    final Offset slideBegin;
    final double scaleBegin;
    switch (section.id) {
      case 'tasks':    slideBegin = const Offset(-0.08, 0); scaleBegin = 0.92; break;
      case 'habits':   slideBegin = const Offset(0, 0.08);  scaleBegin = 0.92; break;
      case 'workouts': slideBegin = const Offset(0.08, 0);  scaleBegin = 0.90; break;
      case 'profile':  slideBegin = const Offset(0, 0);     scaleBegin = 0.80; break;
      case 'collect':  slideBegin = const Offset(0, -0.06); scaleBegin = 0.92; break;
      default:         slideBegin = const Offset(0, 0.04);  scaleBegin = 0.92; break;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, sec) => page,
        transitionsBuilder: (ctx, anim, sec, child) {
          final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOut))),
            child: SlideTransition(
              position: Tween(begin: slideBegin, end: Offset.zero).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: scaleBegin, end: 1.0).animate(curve),
                child: child,
              ),
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
          // ── Floating embers ──────────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(child: _FloatingEmbers()),
          ),

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
                painter: _GlowPainter(color: section.color, offset: _angle * 0.08),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // ── Compass ring around wheel focal ─────────────────────────────
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _CompassRingPainter(
                  color: section.color,
                  rotation: _angle * 1.15, // parallax — ring moves faster
                ),
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
                    // Avatar with XP ring
                    GestureDetector(
                      onTap: () => _goTo(8),
                      child: ListenableBuilder(
                        listenable: GameState.instance,
                        builder: (ctx, _) => SizedBox(
                          width: 58, height: 58,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // XP progress ring
                              SizedBox(
                                width: 58, height: 58,
                                child: CircularProgressIndicator(
                                  value: GameState.instance.levelProgress,
                                  strokeWidth: 2.5,
                                  backgroundColor: Colors.white.withAlpha(20),
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.action),
                                ),
                              ),
                              // Avatar
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.action.withAlpha(60),
                                      blurRadius: 10, spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/avatar.png',
                                    width: 48, height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(
                                      color: const Color(0xFF1A1008),
                                      child: Center(
                                        child: Text('H', style: GoogleFonts.outfit(
                                          color: Colors.white, fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        )),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                  color: AppColors.action,
                                  child: Text('LVL ${GameState.instance.level}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8, fontWeight: FontWeight.w900,
                                      letterSpacing: 1, color: Colors.white,
                                    )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${GameState.instance.xpInLevel} / ${GameState.instance.xpForNextLevel} XP',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white.withAlpha(120),
                              )),
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

          // ── Daily quote ──────────────────────────────────────────────────
          Positioned(
            top: size.height * 0.15,
            left: 24, right: 24,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  _kQuotes[DateTime.now().day % _kQuotes.length],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withAlpha(50),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),

          // ── Daily Quest popup (top, auto-dismiss) ───────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: _DailyQuestPopup()),
          ),

          // ── Weekly Summary (Mondays only) ──────────────────────────────
          if (DateTime.now().weekday == DateTime.monday)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(child: _WeeklySummaryPopup()),
            ),

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
                        horizontal: 48, vertical: 18),
                    decoration: BoxDecoration(
                      color: section.color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: section.color.withAlpha(120),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'OPEN  ${section.label}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
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
          style: GoogleFonts.playfairDisplay(
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

      // Active sector glow edge
      if (brightness > 0.85) {
        final glowPaint = Paint()
          ..color = c.withAlpha((brightness * 100).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        _drawSector(canvas, center, outerR * 0.25, outerR * 0.7,
            startAngle, sweepAngle, glowPaint);
      }
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
  final double offset;
  _GlowPainter({required this.color, this.offset = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final focal = Offset(
      size.width / 2 + sin(offset) * 20, // parallax shift
      size.height * 0.44 + cos(offset) * 10,
    );
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
  bool shouldRepaint(_GlowPainter old) => old.color != color || old.offset != offset;
}

// ── Compass ring (quest map decoration) ──────────────────────────────────────

class _CompassRingPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _CompassRingPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final focal = Offset(size.width / 2, size.height * 0.44);
    final radius = size.width * 0.38;

    // Outer ring
    canvas.drawCircle(
      focal, radius,
      Paint()
        ..color = color.withAlpha(35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner ring
    canvas.drawCircle(
      focal, radius * 0.88,
      Paint()
        ..color = color.withAlpha(20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Tick marks around the ring (like compass)
    final tickPaint = Paint()
      ..color = color.withAlpha(50)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = i * pi / 18 + rotation * 0.3;
      final isMajor = i % 9 == 0;
      final innerR = radius * (isMajor ? 0.90 : 0.94);
      final outerR = radius * 0.99;
      tickPaint.color = color.withAlpha(isMajor ? 80 : 35);
      tickPaint.strokeWidth = isMajor ? 1.5 : 0.8;
      canvas.drawLine(
        Offset(focal.dx + innerR * cos(angle), focal.dy + innerR * sin(angle)),
        Offset(focal.dx + outerR * cos(angle), focal.dy + outerR * sin(angle)),
        tickPaint,
      );
    }

    // Cardinal dots (N/E/S/W) — warm gold dots
    final dotPaint = Paint()..color = const Color(0xFFCA8A04).withAlpha(120);
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 + rotation * 0.3;
      final pos = Offset(
        focal.dx + radius * 1.04 * cos(angle),
        focal.dy + radius * 1.04 * sin(angle),
      );
      canvas.drawCircle(pos, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CompassRingPainter old) =>
      old.color != color || old.rotation != rotation;
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

// ── Weekly Summary popup (Mondays) ────────────────────────────────────────────

class _WeeklySummaryPopup extends StatefulWidget {
  const _WeeklySummaryPopup();
  @override
  State<_WeeklySummaryPopup> createState() => _WeeklySummaryPopupState();
}

class _WeeklySummaryPopupState extends State<_WeeklySummaryPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Delayed start — appears after daily quest fades
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 7000));

    _slide = TweenSequence<Offset>([
      // Wait for daily quest to finish (first 40%)
      TweenSequenceItem(tween: ConstantTween(const Offset(0, -1)), weight: 40),
      // Slide in
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 8),
      // Stay
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 35),
      // Slide out
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 17),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 17),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gs = GameState.instance;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => SlideTransition(
        position: _slide,
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: IgnorePointer(
            ignoring: _ctrl.value > 0.85 || _ctrl.value < 0.45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(210),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.action.withAlpha(40)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Icon(Icons.calendar_month_rounded, size: 16,
                          color: AppColors.action),
                      const SizedBox(width: 8),
                      Text('WEEKLY RECAP', style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: AppColors.action)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _RecapStat(value: '${gs.totalCompletions}', label: 'DONE'),
                      _RecapStat(value: '${gs.totalXp}', label: 'XP'),
                      _RecapStat(value: '${gs.bestStreak}d', label: 'STREAK'),
                      _RecapStat(value: 'LVL ${gs.level}', label: 'RANK'),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  final String value, label;
  const _RecapStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.jetBrainsMono(
        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(
        fontSize: 7, fontWeight: FontWeight.w600,
        letterSpacing: 1, color: Colors.white.withAlpha(100))),
    ]));
  }
}

// ── Floating embers (firefly particles) ──────────────────────────────────────

// ── Daily Quest popup ─────────────────────────────────────────────────────────

class _DailyQuestPopup extends StatefulWidget {
  const _DailyQuestPopup();
  @override
  State<_DailyQuestPopup> createState() => _DailyQuestPopupState();
}

class _DailyQuestPopupState extends State<_DailyQuestPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000));

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => SlideTransition(
        position: _slide,
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: IgnorePointer(
            ignoring: _ctrl.value > 0.85,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withAlpha(50)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withAlpha(20),
                      blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withAlpha(80)),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          size: 14, color: AppColors.gold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('DAILY QUEST',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              letterSpacing: 1.5, color: AppColors.gold)),
                          const SizedBox(height: 2),
                          Text(GameState.instance.dailyQuest,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(200),
                            )),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withAlpha(50)),
                      ),
                      child: Text('+${GameState.instance.dailyQuestXp} XP',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating embers ──────────────────────────────────────────────────────────

class _FloatingEmbers extends StatefulWidget {
  const _FloatingEmbers();

  @override
  State<_FloatingEmbers> createState() => _FloatingEmbersState();
}

class _FloatingEmbersState extends State<_FloatingEmbers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _EmberPainter(time: _ctrl.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _EmberPainter extends CustomPainter {
  final double time;
  _EmberPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const count = 18;
    for (int i = 0; i < count; i++) {
      final seed = i * 73.7;
      final t = (time + seed / 360) % 1.0;

      // Slow float upward
      final x = (sin(seed + t * pi * 2) * 0.3 + 0.5) * size.width +
          sin(t * pi * 4 + seed) * 20;
      final y = size.height * (1.0 - t * 0.9) + sin(seed) * 40;

      // Pulse opacity
      final opacity = (sin(t * pi) * 0.6 + 0.1).clamp(0.0, 0.7);

      // Warm colors
      final isGold = i % 3 == 0;
      paint.color = isGold
          ? Color.fromRGBO(202, 138, 4, opacity)   // gold
          : Color.fromRGBO(255, 107, 53, opacity);  // orange

      final r = 1.2 + sin(seed * 0.5) * 0.8;
      canvas.drawCircle(Offset(x, y), r, paint);

      // Glow
      if (opacity > 0.3) {
        paint.color = paint.color.withAlpha((opacity * 40).toInt());
        canvas.drawCircle(Offset(x, y), r * 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => true;
}

