import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import 'tasks_screen.dart';
import '../widgets/swipe_to_pop.dart';

class TasksMenuScreen extends StatelessWidget {
  const TasksMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = (isDark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC))
        .withAlpha(170);

    return SwipeToPop(child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── Blurred split background ──────────────────────────────────
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Row(
                children: [
                  Expanded(child: Image.asset(
                    'assets/collection/Tasks menu/Work.jpg',
                    fit: BoxFit.cover, height: double.infinity,
                  )),
                  Expanded(child: Image.asset(
                    'assets/collection/Tasks menu/Live.jpg',
                    fit: BoxFit.cover, height: double.infinity,
                  )),
                ],
              ),
            ),
          ),

          // ── Dark tint over blur ───────────────────────────────────────
          Positioned.fill(
            child: ColoredBox(color: overlayColor),
          ),

          // ── Cards — fullscreen side by side ─────────────────────────
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _CategoryCard(
                      category: TaskCategory.work,
                      label: 'WORK',
                      imagePath: 'assets/collection/Tasks menu/Work.jpg',
                      color: const Color(0xFF2979FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CategoryCard(
                      category: TaskCategory.live,
                      label: 'LIVE',
                      imagePath: 'assets/collection/Tasks menu/Live.jpg',
                      color: const Color(0xFF00E676),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ────────────────────────────────────
          Positioned(
            top: 0, left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: Icon(Icons.chevron_left_rounded,
                        size: 24, color: Colors.white.withAlpha(220)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _CategoryCard extends StatefulWidget {
  final TaskCategory category;
  final String label;
  final String imagePath;
  final Color color;

  const _CategoryCard({
    required this.category,
    required this.label,
    required this.imagePath,
    required this.color,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  void _open() {
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a, b) => TasksScreen(category: widget.category),
      transitionsBuilder: (ctx, a, b, child) {
        final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: a,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut))),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = TaskStore.tasks.where((t) => t.category == widget.category).toList();
    final pending  = allTasks.where((t) => !t.isCompleted).toList();
    final total    = allTasks.length;
    final done     = allTasks.where((t) => t.isCompleted).length;

    return GestureDetector(
      onTap: _open,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
            Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) =>
                  Container(color: const Color(0xFF0D0D18)),
            ),
            Container(color: Colors.black.withAlpha(80)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      widget.color.withAlpha(55),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(widget.label,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: widget.color.withAlpha(160), blurRadius: 14),
                        ],
                      )),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PriorityDots(pending: pending),
                        const SizedBox(width: 10),
                        Text(
                          total == 0
                              ? 'no tasks'
                              : '$done / $total done',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.white.withAlpha(140),
                          )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}



class _PriorityDots extends StatelessWidget {
  final List<Task> pending;
  const _PriorityDots({required this.pending});

  @override
  Widget build(BuildContext context) {
    final dotData = [
      (TaskPriority.high,   AppColors.abstinences),
      (TaskPriority.medium, AppColors.budget),
      (TaskPriority.low,    AppColors.reading),
    ];

    return Row(
      children: dotData.expand((entry) {
        final count = pending.where((t) => t.priority == entry.$1).length;
        if (count == 0) return <Widget>[];
        return List.generate(count.clamp(0, 5), (i) => Container(
          width: 7, height: 7,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: entry.$2,
            boxShadow: [
              BoxShadow(color: entry.$2.withAlpha(160), blurRadius: 5),
            ],
          ),
        ));
      }).toList(),
    );
  }
}
