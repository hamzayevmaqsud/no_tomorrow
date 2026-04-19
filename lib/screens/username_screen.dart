import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sync_service.dart';
import '../widgets/jelly_button.dart';

class UsernameScreen extends StatefulWidget {
  final VoidCallback onDone;
  const UsernameScreen({super.key, required this.onDone});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'at least 2 characters');
      return;
    }
    if (name.length > 20) {
      setState(() => _error = 'max 20 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await SyncService.instance.createInitialBag(username: name);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      setState(() { _loading = false; _error = 'failed to save, try again'; });
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

              // Icon
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withAlpha(20),
                    border: Border.all(color: accent.withAlpha(70), width: 2)),
                  child: const Icon(Icons.person_rounded,
                    size: 38, color: accent),
                ),
              ),
              const SizedBox(height: 28),

              Text('CHOOSE YOUR NAME',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2, color: Colors.white)),
              const SizedBox(height: 10),
              Text('This is how friends will see you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(160))),

              const SizedBox(height: 32),

              // Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(35))),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(Icons.badge_outlined, size: 18,
                    color: Colors.white.withAlpha(140)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      maxLength: 20,
                      onSubmitted: (_) => _submit(),
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: Colors.white),
                      cursorColor: accent,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        hintText: 'username',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withAlpha(100))),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Submit
              JellyButton(
                onTap: _loading ? null : _submit,
                pressScale: 0.96,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: accent.withAlpha(120),
                      blurRadius: 20, offset: const Offset(0, 6))]),
                  child: Center(
                    child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : Text('BEGIN',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            letterSpacing: 3, color: Colors.white)),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626))),
              ],

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
