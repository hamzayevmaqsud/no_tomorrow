import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/jelly_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.length < 6) {
      setState(() => _error = 'email + password (6+ chars)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      if (_isRegister) {
        await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      } else {
        await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      // On web, use signInWithPopup for best UX.
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _prettyError(e));
    } catch (e) {
      setState(() => _error = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _prettyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'invalid email';
      case 'user-not-found': return 'no account with that email';
      case 'wrong-password':
      case 'invalid-credential': return 'wrong password';
      case 'email-already-in-use': return 'email already registered';
      case 'weak-password': return 'password too weak';
      case 'network-request-failed': return 'network error';
      default: return e.message ?? e.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF6B35);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Logo
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('NO ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 38, fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 6, color: const Color(0xFFF0E6D3),
                    height: 1)),
                Text('TOMORROW',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 38, fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 6, color: accent, height: 1)),
              ]),
              const SizedBox(height: 8),
              Text('SIGN  IN  TO  CONTINUE',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  color: Colors.white.withAlpha(80))),

              const SizedBox(height: 48),

              // Google button
              JellyButton(
                onTap: _loading ? null : _signInWithGoogle,
                pressScale: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    Text('Continue with Google',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F))),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              Row(children: [
                Expanded(child: Container(height: 1, color: Colors.white.withAlpha(25))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white.withAlpha(80))),
                ),
                Expanded(child: Container(height: 1, color: Colors.white.withAlpha(25))),
              ]),

              const SizedBox(height: 20),

              // Email
              _Field(
                controller: _emailCtrl,
                hint: 'email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _Field(
                controller: _passCtrl,
                hint: 'password',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                onSubmit: _submitEmail,
              ),

              const SizedBox(height: 16),

              // Submit
              JellyButton(
                onTap: _loading ? null : _submitEmail,
                pressScale: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: accent.withAlpha(120),
                      blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : Text(_isRegister ? 'CREATE ACCOUNT' : 'SIGN IN',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            letterSpacing: 2, color: Colors.white)),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626))),
              ],

              const SizedBox(height: 20),

              // Toggle
              Center(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isRegister = !_isRegister;
                    _error = null;
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white.withAlpha(140)),
                      children: [
                        TextSpan(text: _isRegister
                          ? 'Already have account? '
                          : 'New here? '),
                        TextSpan(
                          text: _isRegister ? 'Sign in' : 'Create account',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: accent)),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmit;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(35))),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.white.withAlpha(140)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: Colors.white),
            cursorColor: const Color(0xFFFF6B35),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13, color: Colors.white.withAlpha(100))),
          ),
        ),
      ]),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Simple coloured "G" via text, since Canvas icon drawing is complex.
    final tp = TextPainter(
      text: TextSpan(text: 'G',
        style: TextStyle(
          fontSize: size.height * 0.95,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
          height: 1)),
      textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

