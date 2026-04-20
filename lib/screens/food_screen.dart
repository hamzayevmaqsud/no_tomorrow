import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_locale.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../widgets/animated_empty.dart';

String _translateMealType(String type) {
  switch (type) {
    case 'Breakfast': return t('Breakfast', 'Завтрак');
    case 'Lunch':     return t('Lunch', 'Обед');
    case 'Dinner':    return t('Dinner', 'Ужин');
    case 'Snack':     return t('Snack', 'Перекус');
    default:          return type;
  }
}

class Meal {
  final String id;
  String title;
  String type; // Breakfast, Lunch, Dinner, Snack
  int calories;
  final DateTime date;

  Meal({required this.id, required this.title, this.type = 'Lunch',
    this.calories = 0, required this.date});
}

class FoodStore {
  static final List<Meal> meals = [];
  static int nextId = 1;
  static int dailyGoal = 2000;
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  static const _types = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => FoodStore.meals.removeWhere((m) => m.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, __) => _AddMealSheet(
        onAdd: (m) { setState(() => FoodStore.meals.insert(0, m)); Navigator.of(ctx).pop(); },
        nextId: '${FoodStore.nextId++}', types: _types,
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = FoodStore.meals;
    final now = DateTime.now();
    final todayMeals = meals.where((m) => m.date.day == now.day && m.date.month == now.month).toList();
    final todayCals = todayMeals.fold(0, (s, m) => s + m.calories);
    final goal = FoodStore.dailyGoal;
    final progress = goal == 0 ? 0.0 : (todayCals / goal).clamp(0.0, 1.5);

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0808),
      body: Stack(children: [
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF1A1012), Color(0xFF0A0808)],
          )),
        )),
        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Stack(alignment: Alignment.center, children: [
              Column(children: [
                Text(t('FOOD', 'ПИТАНИЕ'), style: GoogleFonts.playfairDisplay(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3,
                  color: const Color(0xFFF0D4D0))),
                const SizedBox(height: 3),
                Text('$todayCals / $goal ${t('kcal today', 'ккал сегодня')}', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(160))),
              ]),
              Align(alignment: Alignment.centerLeft,
                child: GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(40))),
                    child: Icon(Icons.chevron_left_rounded, size: 22, color: Colors.white.withAlpha(200))))),
            ])),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withAlpha(12)),
          // Dashboard
          _FoodDashboard(todayCals: todayCals, goal: goal, progress: progress, mealCount: todayMeals.length),
          Expanded(
            child: meals.isEmpty
                ? const AnimatedEmpty(
                    icon: Icons.restaurant_rounded,
                    title: t('no meals logged', 'нет записей о приёмах пищи'),
                    subtitle: t('tap + to log your first meal', 'нажмите + чтобы добавить первый приём пищи'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: meals.length,
                    itemBuilder: (ctx, i) => _MealCard(meal: meals[i], onDelete: () => _delete(meals[i].id)),
                  ),
          ),
        ])),
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
                      decoration: BoxDecoration(color: AppColors.food, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.food.withAlpha(100), blurRadius: 12)]),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Text(t('LOG  MEAL', 'ДОБАВИТЬ  ПРИЁМ'), style: GoogleFonts.playfairDisplay(
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

class _FoodDashboard extends StatelessWidget {
  final int todayCals, goal, mealCount;
  final double progress;
  const _FoodDashboard({required this.todayCals, required this.goal, required this.progress, required this.mealCount});

  @override
  Widget build(BuildContext context) {
    final over = todayCals > goal;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFF5F2EB), borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 5))]),
        child: Row(children: [
          SizedBox(width: 70, height: 70, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 70, height: 70, child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0), strokeWidth: 5,
              backgroundColor: const Color(0xFF2A2318).withAlpha(15),
              valueColor: AlwaysStoppedAnimation(over ? AppColors.danger : AppColors.food))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$todayCals', style: GoogleFonts.jetBrainsMono(
                fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2A2318))),
              Text(t('KCAL', 'ККАЛ'), style: GoogleFonts.jetBrainsMono(
                fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: const Color(0xFF8A8070))),
            ]),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.restaurant_rounded, size: 12, color: AppColors.food),
              const SizedBox(width: 5),
              Text('$mealCount ${t('MEALS TODAY', 'ПРИЁМОВ СЕГОДНЯ')}', style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.food)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.track_changes_rounded, size: 12, color: AppColors.gold),
              const SizedBox(width: 5),
              Text('${goal - todayCals > 0 ? goal - todayCals : 0} ${t('REMAINING', 'ОСТАЛОСЬ')}', style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.gold)),
            ]),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (over ? AppColors.danger : AppColors.success).withAlpha(12),
                borderRadius: BorderRadius.circular(10)),
              child: Text(over ? t('OVER LIMIT', 'ПРЕВЫШЕНИЕ') : t('ON TRACK', 'В НОРМЕ'), style: GoogleFonts.jetBrainsMono(
                fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                color: over ? AppColors.danger : AppColors.success))),
          ])),
        ]),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});

  IconData get _typeIcon {
    switch (meal.type) {
      case 'Breakfast': return Icons.wb_sunny_rounded;
      case 'Lunch':     return Icons.light_mode_rounded;
      case 'Dinner':    return Icons.nightlight_round;
      case 'Snack':     return Icons.cookie_rounded;
      default:          return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF5F2EB);
    const textCol = Color(0xFF2A2318);
    const subCol = Color(0xFF8A8070);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.food.withAlpha(20), shape: BoxShape.circle),
          child: Icon(_typeIcon, size: 18, color: AppColors.food)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meal.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textCol)),
          const SizedBox(height: 2),
          Text(_translateMealType(meal.type), style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: subCol)),
        ])),
        Text('${meal.calories}', style: GoogleFonts.jetBrainsMono(
          fontSize: 16, fontWeight: FontWeight.w700, color: textCol)),
        Text(' ${t('kcal', 'ккал')}', style: GoogleFonts.inter(fontSize: 9, color: subCol)),
        const SizedBox(width: 8),
        GestureDetector(onTap: onDelete,
          child: Icon(Icons.close_rounded, size: 14, color: subCol.withAlpha(100))),
      ]),
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  final void Function(Meal) onAdd;
  final String nextId;
  final List<String> types;
  const _AddMealSheet({required this.onAdd, required this.nextId, required this.types});
  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _titleCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  String _type = 'Lunch';

  void _submit() {
    final title = _titleCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text.trim()) ?? 0;
    if (title.isEmpty) return;
    widget.onAdd(Meal(id: widget.nextId, title: title, type: _type,
      calories: cal, date: DateTime.now()));
  }

  @override
  void dispose() { _titleCtrl.dispose(); _calCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    const bg = Color(0xFFF5F1E8); const cocoa = Color(0xFF594536); const divider = Color(0xFFDDD8CB);

    return Align(alignment: Alignment.centerLeft,
      child: Padding(padding: EdgeInsets.fromLTRB(12, 48, 40, kb > 0 ? kb + 12 : 48),
        child: Material(color: Colors.transparent,
          child: ClipRRect(borderRadius: BorderRadius.circular(36),
            child: Container(width: sw * 0.82,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(36),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 40, offset: const Offset(6, 8))]),
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.food.withAlpha(20),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36))),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.food, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 12),
                    Text(t('LOG MEAL', 'ДОБАВИТЬ ПРИЁМ'), style: GoogleFonts.playfairDisplay(
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
                    decoration: InputDecoration(hintText: t('What did you eat?', 'Что вы съели?'),
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onSubmitted: (_) => _submit())),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: TextField(controller: _calCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.w700, color: cocoa),
                    decoration: InputDecoration(hintText: t('0 kcal', '0 ккал'),
                      hintStyle: GoogleFonts.jetBrainsMono(fontSize: 24, color: cocoa.withAlpha(60)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Wrap(spacing: 6, runSpacing: 6,
                    children: widget.types.map((tp) {
                      final active = _type == tp;
                      return GestureDetector(onTap: () => setState(() => _type = tp),
                        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? AppColors.food.withAlpha(25) : const Color(0xFFEFEBE0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: active ? AppColors.food.withAlpha(140) : divider)),
                          child: Text(_translateMealType(tp), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                            color: active ? AppColors.food : cocoa.withAlpha(130)))));
                    }).toList())),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: GestureDetector(onTap: _submit,
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: AppColors.food, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.food.withAlpha(70), blurRadius: 14, offset: const Offset(0, 4))]),
                      child: Center(child: Text(t('LOG MEAL', 'ДОБАВИТЬ ПРИЁМ'), style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Colors.white)))))),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
