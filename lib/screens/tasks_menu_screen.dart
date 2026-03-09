import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import 'tasks_screen.dart';

class TasksMenuScreen extends StatelessWidget {
  const TasksMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFB8BACD),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 15,
                          color: isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('MISSIONS',
                    style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: AppColors.tasks,
                    )),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Container(height: 1,
                color: isDark ? AppColors.darkBorder : const Color(0xFFB8BACD)),
            const SizedBox(height: 16),

            // ── Cards — side by side ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                    const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Count pending tasks per priority for this category
    final allTasks = TaskStore.tasks.where((t) => t.category == category).toList();
    final pending  = allTasks.where((t) => !t.isCompleted).toList();
    final total    = allTasks.length;
    final done     = allTasks.where((t) => t.isCompleted).length;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (ctx, a, b) => TasksScreen(category: category),
          transitionsBuilder: (ctx, a, b, child) {
            final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
            fit: StackFit.expand,
            children: [
              // Full color cover image
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) =>
                    Container(color: const Color(0xFF0D0D18)),
              ),

              // Slight dark overlay for readability
              Container(color: Colors.black.withAlpha(80)),

              // Color tint at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        color.withAlpha(55),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(label,
                      style: GoogleFonts.outfit(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: color.withAlpha(160), blurRadius: 14),
                        ],
                      )),
                    const SizedBox(height: 8),
                    // Priority dots + task count
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
            ],
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
    // Colors matching _pColor in tasks_screen.dart
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
