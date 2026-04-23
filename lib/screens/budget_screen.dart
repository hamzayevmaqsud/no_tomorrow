import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';
import '../widgets/jelly_button.dart';
import '../widgets/animated_empty.dart';
import '../l10n/app_locale.dart';

class Expense {
  final String id;
  String title;
  double amount;
  String category;
  final DateTime date;

  Expense({required this.id, required this.title, required this.amount,
    this.category = 'Other', required this.date});
}

class BudgetStore {
  static final List<Expense> expenses = [];
  static int nextId = 1;
  static double monthlyBudget = 1000;
}

String _catLabel(String c) {
  const ru = {
    'Food': 'Еда', 'Transport': 'Транспорт', 'Shopping': 'Покупки',
    'Bills': 'Счета', 'Health': 'Здоровье', 'Fun': 'Развлечения', 'Other': 'Другое',
  };
  return AppLocale.instance.isRu ? (ru[c] ?? c) : c;
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Health', 'Fun', 'Other'];

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => BudgetStore.expenses.removeWhere((e) => e.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, __) => _AddExpenseSheet(
        onAdd: (e) { setState(() => BudgetStore.expenses.insert(0, e)); Navigator.of(ctx).pop(); },
        nextId: '${BudgetStore.nextId++}', categories: _categories,
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
    final expenses = BudgetStore.expenses;
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => e.date.month == now.month && e.date.year == now.year).toList();
    final spent = thisMonth.fold(0.0, (s, e) => s + e.amount);
    final budget = BudgetStore.monthlyBudget;
    final remaining = budget - spent;
    final progress = budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final today = expenses.where((e) => e.date.day == now.day && e.date.month == now.month).toList();
    final todaySpent = today.fold(0.0, (s, e) => s + e.amount);

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF0A0A06),
      body: Stack(children: [
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF14140E), Color(0xFF0A0A06)],
          )),
        )),
        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(40))),
                  child: Icon(Icons.chevron_left_rounded, size: 24, color: Colors.white.withAlpha(200)))),
              const Spacer(),
              Text(t('BUDGET', 'БЮДЖЕТ'), style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                letterSpacing: 2, color: const Color(0xFFF0E8C8))),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('\$${remaining.toStringAsFixed(0)} ${t('remaining', 'осталось')}', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: remaining > 0 ? Colors.white.withAlpha(160) : AppColors.danger)),
            ])),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withAlpha(12)),
          // Dashboard
          _BudgetDashboard(spent: spent, budget: budget, progress: progress, todaySpent: todaySpent),
          Expanded(
            child: expenses.isEmpty
                ? AnimatedEmpty(
                    icon: Icons.account_balance_wallet_outlined,
                    title: t('No transactions yet', 'Нет транзакций'),
                    subtitle: t('Tap the + button to add your first one', 'Нажмите + чтобы добавить первую'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) => _ExpenseCard(expense: expenses[i], onDelete: () => _delete(expenses[i].id)),
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
                      decoration: BoxDecoration(color: AppColors.budget, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.budget.withAlpha(100), blurRadius: 12)]),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Text(t('ADD  EXPENSE', 'ДОБАВИТЬ  РАСХОД'), style: GoogleFonts.playfairDisplay(
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

class _BudgetDashboard extends StatelessWidget {
  final double spent, budget, todaySpent;
  final double progress;
  const _BudgetDashboard({required this.spent, required this.budget, required this.progress, required this.todaySpent});

  @override
  Widget build(BuildContext context) {
    final overBudget = spent > budget;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFF5F2EB), borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 5))]),
        child: Column(children: [
          Row(children: [
            SizedBox(width: 70, height: 70, child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(
                value: progress, strokeWidth: 5,
                backgroundColor: const Color(0xFF2A2318).withAlpha(15),
                valueColor: AlwaysStoppedAnimation(overBudget ? AppColors.danger : AppColors.budget))),
              Text('${(progress * 100).round()}%', style: GoogleFonts.jetBrainsMono(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: overBudget ? AppColors.danger : const Color(0xFF2A2318))),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.payments_rounded, size: 12, color: AppColors.budget),
                const SizedBox(width: 5),
                Text('\$${spent.toStringAsFixed(0)} ${t('SPENT', 'ПОТРАЧЕНО')}', style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.budget)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.today_rounded, size: 12, color: AppColors.action),
                const SizedBox(width: 5),
                Text('\$${todaySpent.toStringAsFixed(0)} ${t('TODAY', 'СЕГОДНЯ')}', style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.action)),
              ]),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (overBudget ? AppColors.danger : AppColors.success).withAlpha(12),
                  borderRadius: BorderRadius.circular(10)),
                child: Text(overBudget ? t('OVER BUDGET', 'ПЕРЕРАСХОД') : t('ON TRACK', 'В НОРМЕ'), style: GoogleFonts.jetBrainsMono(
                  fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                  color: overBudget ? AppColors.danger : AppColors.success))),
            ])),
          ]),
        ]),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  const _ExpenseCard({required this.expense, required this.onDelete});

  IconData get _catIcon {
    switch (expense.category) {
      case 'Food':      return Icons.restaurant_rounded;
      case 'Transport': return Icons.directions_car_rounded;
      case 'Shopping':  return Icons.shopping_bag_rounded;
      case 'Bills':     return Icons.receipt_long_rounded;
      case 'Health':    return Icons.favorite_rounded;
      case 'Fun':       return Icons.sports_esports_rounded;
      default:          return Icons.more_horiz_rounded;
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
          decoration: BoxDecoration(color: AppColors.budget.withAlpha(20), shape: BoxShape.circle),
          child: Icon(_catIcon, size: 18, color: AppColors.budget)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textCol)),
          const SizedBox(height: 2),
          Text(_catLabel(expense.category), style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: subCol)),
        ])),
        Text('\$${expense.amount.toStringAsFixed(0)}', style: GoogleFonts.jetBrainsMono(
          fontSize: 16, fontWeight: FontWeight.w700, color: textCol)),
        const SizedBox(width: 8),
        GestureDetector(onTap: onDelete,
          child: Icon(Icons.close_rounded, size: 14, color: subCol.withAlpha(100))),
      ]),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final void Function(Expense) onAdd;
  final String nextId;
  final List<String> categories;
  const _AddExpenseSheet({required this.onAdd, required this.nextId, required this.categories});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cat = 'Other';

  void _submit() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;
    widget.onAdd(Expense(id: widget.nextId, title: title, amount: amount,
      category: _cat, date: DateTime.now()));
  }

  @override
  void dispose() { _titleCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

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
                  decoration: BoxDecoration(color: AppColors.budget.withAlpha(25),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36))),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.budget, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.payments_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 12),
                    Text(t('ADD EXPENSE', 'ДОБАВИТЬ РАСХОД'), style: GoogleFonts.playfairDisplay(
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
                    decoration: InputDecoration(hintText: t('What did you spend on?', 'На что потратили?'),
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onSubmitted: (_) => _submit())),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: TextField(controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.w700, color: cocoa),
                    decoration: InputDecoration(hintText: '\$0',
                      hintStyle: GoogleFonts.jetBrainsMono(fontSize: 24, color: cocoa.withAlpha(60)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Wrap(spacing: 6, runSpacing: 6,
                    children: widget.categories.map((c) {
                      final active = _cat == c;
                      return GestureDetector(onTap: () => setState(() => _cat = c),
                        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.budget.withAlpha(25) : const Color(0xFFEFEBE0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: active ? AppColors.budget.withAlpha(140) : divider)),
                          child: Text(_catLabel(c), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                            color: active ? AppColors.budget : cocoa.withAlpha(130)))));
                    }).toList())),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: GestureDetector(onTap: _submit,
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: AppColors.budget, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.budget.withAlpha(70), blurRadius: 14, offset: const Offset(0, 4))]),
                      child: Center(child: Text(t('LOG EXPENSE', 'ЗАПИСАТЬ РАСХОД'), style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Colors.white)))))),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
