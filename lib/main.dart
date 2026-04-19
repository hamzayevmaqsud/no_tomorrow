import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/phone_frame.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NoTomorrowApp());
}

class NoTomorrowApp extends StatefulWidget {
  const NoTomorrowApp({super.key});

  @override
  State<NoTomorrowApp> createState() => _NoTomorrowAppState();
}

class _NoTomorrowAppState extends State<NoTomorrowApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Tomorrow',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (ctx, child) => PhoneFrame(child: child ?? const SizedBox()),
      home: _AuthGate(onToggleTheme: _toggleTheme),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const _AuthGate({required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0F),
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFFF6B35))),
          );
        }
        if (!snap.hasData) return const LoginScreen();
        return _SplashGate(onToggleTheme: onToggleTheme);
      },
    );
  }
}

class _SplashGate extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const _SplashGate({required this.onToggleTheme});

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));

    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.70, 1.0, curve: Curves.easeIn)));

    _ctrl.forward().then((_) {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_done && !_OnboardingState.hasSeenOnboarding) {
      return _Onboarding(onComplete: () {
        _OnboardingState.hasSeenOnboarding = true;
        setState(() {});
      });
    }
    if (_done) return HomeScreen(onToggleTheme: widget.onToggleTheme);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Opacity(
            opacity: (_fadeIn.value * _fadeOut.value).clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NO',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 52, fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 8,
                    color: const Color(0xFFF0E6D3),
                    height: 1,
                  )),
                Text('TOMORROW',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 52, fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 8,
                    color: const Color(0xFFFF6B35),
                    height: 1,
                  )),
                const SizedBox(height: 16),
                Text('YOUR  RPG  LIFE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: Colors.white.withAlpha(80),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Onboarding ───────────────────────────────────────────────────────────────

class _OnboardingState {
  static bool hasSeenOnboarding = false;
}

class _Onboarding extends StatefulWidget {
  final VoidCallback onComplete;
  const _Onboarding({required this.onComplete});
  @override
  State<_Onboarding> createState() => __OnboardingState();
}

class __OnboardingState extends State<_Onboarding> {
  int _page = 0;

  static const _steps = [
    (
      icon: Icons.explore_rounded,
      title: 'SPIN THE WHEEL',
      sub: 'Swipe to explore sections.\nTasks, Habits, Workouts and more.',
    ),
    (
      icon: Icons.add_circle_outline_rounded,
      title: 'CREATE MISSIONS',
      sub: 'Add tasks and habits.\nEach completion earns XP.',
    ),
    (
      icon: Icons.emoji_events_rounded,
      title: 'LEVEL UP',
      sub: 'Earn XP, build streaks,\nunlock achievements. No tomorrow.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];
    final isLast = _page == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B35).withAlpha(18),
                  border: Border.all(
                      color: const Color(0xFFFF6B35).withAlpha(60), width: 2),
                ),
                child: Icon(step.icon, size: 40,
                    color: const Color(0xFFFF6B35)),
              ),
              const SizedBox(height: 32),
              // Title
              Text(step.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2, color: Colors.white,
                )),
              const SizedBox(height: 16),
              // Subtitle
              Text(step.sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  height: 1.5, color: Colors.white.withAlpha(160),
                )),
              const Spacer(flex: 2),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page
                        ? const Color(0xFFFF6B35)
                        : Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              // Button
              GestureDetector(
                onTap: () {
                  if (isLast) {
                    widget.onComplete();
                  } else {
                    setState(() => _page++);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFFFF6B35).withAlpha(80),
                      blurRadius: 20, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Center(
                    child: Text(isLast ? 'BEGIN' : 'NEXT',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 2, color: Colors.white,
                      )),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isLast)
                GestureDetector(
                  onTap: widget.onComplete,
                  child: Text('SKIP',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      letterSpacing: 2, color: Colors.white.withAlpha(80),
                    )),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
