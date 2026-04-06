import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
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
      home: _SplashGate(onToggleTheme: _toggleTheme),
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
