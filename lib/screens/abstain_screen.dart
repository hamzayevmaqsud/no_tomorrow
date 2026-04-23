import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../widgets/animated_empty.dart';
import '../l10n/app_locale.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class Abstinence {
  final String id;
  String title;
  final DateTime startDate;
  String reason;

  Abstinence({required this.id, required this.title, required this.startDate, this.reason = ''});

  int get daysClean => DateTime.now().difference(startDate).inDays;
  int get hoursClean => DateTime.now().difference(startDate).inHours;
  int get xp => daysClean * 5;

  String get milestone {
    if (daysClean >= 365) return t('LEGENDARY', 'ЛЕГЕНДА');
    if (daysClean >= 90)  return t('MASTER', 'МАСТЕР');
    if (daysClean >= 30)  return t('WARRIOR', 'ВОИН');
    if (daysClean >= 7)   return t('SURVIVOR', 'ВЫЖИВШИЙ');
    if (daysClean >= 1)   return t('STARTED', 'НАЧАЛО');
    return t('DAY ZERO', 'ДЕНЬ НОЛЬ');
  }

  Color get milestoneColor {
    if (daysClean >= 365) return AppColors.gold;
    if (daysClean >= 90)  return AppColors.action;
    if (daysClean >= 30)  return AppColors.success;
    if (daysClean >= 7)   return const Color(0xFF3B82F6);
    return Colors.white.withAlpha(140);
  }
}

class AbstainStore {
  static final List<Abstinence> items = [];
  static int nextId = 1;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class AbstainScreen extends StatefulWidget {
  const AbstainScreen({super.key});
  @override
  State<AbstainScreen> createState() => _AbstainScreenState();
}

class _AbstainScreenState extends State<AbstainScreen> {
  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => AbstainStore.items.removeWhere((a) => a.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, __) => _AddSheet(
        onAdd: (a) { setState(() => AbstainStore.items.insert(0, a)); Navigator.of(ctx).pop(); },
        nextId: '${AbstainStore.nextId++}',
      ),
      transitionBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = AbstainStore.items;
    final totalDays = items.fold(0, (s, a) => s + a.daysClean);

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0808),
      body: Stack(children: [
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF1A0E0E), Color(0xFF0A0808)],
          )),
        )),
        SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(40))),
                  child: Icon(Icons.chevron_left_rounded, size: 24, color: Colors.white.withAlpha(200)))),
              const Spacer(),
              Text(t('ABSTAIN', 'ВОЗДЕРЖАНИЕ'), style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                letterSpacing: 2, color: const Color(0xFFF0D0D0))),
            ])),
          if (items.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$totalDays ${t('total days clean', 'всего дней чистоты')}', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(160))),
              ])),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withAlpha(12)),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? AnimatedEmpty(
                    icon: Icons.block_rounded,
                    title: t('Nothing to abstain from', 'Не от чего воздерживаться'),
                    subtitle: t('Add a habit you want to break', 'Добавь привычку от которой хочешь избавиться'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _AbstainCard(item: items[i], onDelete: () => _delete(items[i].id)),
                  ),
          ),
        ])),
        // FAB
        Positioned(bottom: 36, left: 52, right: 52,
          child: ClipRRect(borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: JellyButton(onTap: _showAdd,
                child: Container(height: 56,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(22),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withAlpha(40))),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.abstinences, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.abstinences.withAlpha(100), blurRadius: 12)]),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Text(t('NEW  ABSTINENCE', 'НОВОЕ  ВОЗДЕРЖАНИЕ'), style: GoogleFonts.playfairDisplay(
                      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white.withAlpha(200))),
                  ])),
                ),
              ),
            ),
          ),
        ),
      ]),
    ));
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _AbstainCard extends StatelessWidget {
  final Abstinence item;
  final VoidCallback onDelete;
  const _AbstainCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 5))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Left content
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: item.milestoneColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item.milestoneColor.withAlpha(60))),
                  child: Text(item.milestone, style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: item.milestoneColor))),
                const Spacer(),
                GestureDetector(onTap: onDelete,
                  child: Icon(Icons.close_rounded, size: 14, color: subCol.withAlpha(100))),
              ]),
              const SizedBox(height: 10),
              Text(item.title, style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                height: 1.2, color: textCol)),
              if (item.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.reason, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: subCol)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.gold.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: Text('+${item.xp} XP', style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gold))),
              ]),
            ]))),
          // Right — day counter
          Container(width: 72, color: AppColors.abstinences.withAlpha(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${item.daysClean}', style: GoogleFonts.jetBrainsMono(
                fontSize: 28, fontWeight: FontWeight.w700, color: textCol)),
              Text(t('DAYS', 'ДНЕЙ'), style: GoogleFonts.jetBrainsMono(
                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: subCol)),
            ])),
        ]))),
    );
  }
}

// ── Add sheet ────────────────────────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final void Function(Abstinence) onAdd;
  final String nextId;
  const _AddSheet({required this.onAdd, required this.nextId});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(Abstinence(
      id: widget.nextId, title: title, startDate: DateTime.now(),
      reason: _reasonCtrl.text.trim(),
    ));
  }

  @override
  void dispose() { _titleCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    const bg = Color(0xFFF5F1E8);
    const cocoa = Color(0xFF594536);
    const divider = Color(0xFFDDD8CB);

    return Align(alignment: Alignment.centerLeft,
      child: Padding(padding: EdgeInsets.fromLTRB(12, 48, 40, kb > 0 ? kb + 12 : 48),
        child: Material(color: Colors.transparent,
          child: ClipRRect(borderRadius: BorderRadius.circular(36),
            child: Container(width: sw * 0.82,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(36),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 40, offset: const Offset(6, 8))]),
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.abstinences.withAlpha(20),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36))),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.abstinences, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 12),
                    Text(t('QUIT SOMETHING', 'БРОСИТЬ ПРИВЫЧКУ'), style: GoogleFonts.playfairDisplay(
                      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: cocoa)),
                    const Spacer(),
                    GestureDetector(onTap: () => Navigator.pop(context),
                      child: Container(width: 28, height: 28,
                        decoration: BoxDecoration(color: divider, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close_rounded, color: cocoa.withAlpha(150), size: 14))),
                  ])),
                Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: TextField(controller: _titleCtrl, autofocus: true,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: cocoa),
                    decoration: InputDecoration(hintText: t('e.g. Smoking, Sugar, Social Media', 'напр. Курение, Сахар, Соцсети'),
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: TextField(controller: _reasonCtrl, maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 12, color: cocoa.withAlpha(190)),
                    decoration: InputDecoration(hintText: t('Why are you quitting? (optional)', 'Почему вы бросаете? (необязательно)'),
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: GestureDetector(onTap: _submit,
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: AppColors.abstinences, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.abstinences.withAlpha(70), blurRadius: 14, offset: const Offset(0, 4))]),
                      child: Center(child: Text(t('START ABSTINENCE', 'НАЧАТЬ ВОЗДЕРЖАНИЕ'), style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Colors.white)))))),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
