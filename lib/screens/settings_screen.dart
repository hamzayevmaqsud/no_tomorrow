import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Read from context so the screen reacts to theme changes live
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final sub = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;

    return SwipeToPop(child: Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: text),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 3, color: AppColors.primary, margin: const EdgeInsets.only(top: 12)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Appearance ───────────────────────────────────────────
                    _SectionTitle(label: 'APPEARANCE'),
                    const SizedBox(height: 12),
                    _SettingTile(
                      card: card, border: border, text: text, sub: sub,
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      label: isDark ? 'DARK MODE' : 'LIGHT MODE',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => onToggleTheme(),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withAlpha(80),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Support ──────────────────────────────────────────────
                    _SectionTitle(label: 'SUPPORT'),
                    const SizedBox(height: 12),
                    Text(
                      'No Tomorrow is built solo with no ads\nor subscriptions. If this app helps\nyou grow, consider supporting it.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.65,
                        color: sub,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DonateButton(),

                    const SizedBox(height: 48),

                    // ── About ────────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'NO TOMORROW',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                              color: sub,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'v1.0.0  ·  Made with ♥',
                            style: GoogleFonts.outfit(fontSize: 11, color: sub),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final Color card, border, text, sub;
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingTile({
    required this.card, required this.border,
    required this.text, required this.sub,
    required this.icon, required this.label, required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: sub),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: text,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _DonateButton extends StatelessWidget {
  const _DonateButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: replace with url_launcher → your donation link
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Donation link coming soon!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF1744)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'SUPPORT THE APP',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
