import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_locale.dart';
import '../theme/app_colors.dart';
import '../widgets/swipe_to_pop.dart';

class PatchNotesScreen extends StatelessWidget {
  /// If provided, shows a "CONTINUE" button instead of a back arrow.
  final VoidCallback? onContinue;
  const PatchNotesScreen({super.key, this.onContinue});

  static List<_PatchNote> get _notes => [
    _PatchNote(
      version: 'v2.2',
      date: '2026-04-21',
      title: t('Square Calendars With Category Fill', 'Квадратный календарь с заливкой по категориям'),
      items: [
        t('Habit calendars now use rounded square cells instead of circles — cleaner, denser, more modern',
          'Календари привычек теперь используют скруглённые квадраты вместо кругов — чище, плотнее, современнее'),
        t('Main Habits calendar keeps the category-colored fill logic: each day cell is split into vertical stripes proportional to how many habits of each category you completed that day (Health green, Mindset purple, Productivity orange, Social blue). All habits done → solid success green',
          'Главный календарь Habits сохраняет логику заливки по категориям: каждая ячейка дня делится на вертикальные полосы пропорционально количеству выполненных привычек каждой категории (Здоровье зелёный, Мышление фиолетовый, Продуктивность оранжевый, Общение синий). Все привычки сделаны → сплошной зелёный'),
        t('Habit detail calendar: done days fill with the habit’s category color + soft glow, today outlined, future faded',
          'Детальный календарь привычки: выполненные дни заливаются цветом категории привычки + мягкое свечение, сегодня в обводке, будущие затемнены'),
      ],
    ),
    _PatchNote(
      version: 'v2.1',
      date: '2026-04-21',
      title: t('Data Visualization & Trust', 'Визуализация данных и надёжность'),
      items: [
        t('Waffle view for habit calendars — toggle the grid icon in the top calendar of Habits (aggregate heatmap across all habits) and in the detail view of any single habit (GitHub-style per-day grid)',
          'Waffle-вид для календарей привычек — переключи иконку сетки в верхнем календаре Habits (агрегированная тепловая карта по всем привычкам) и в детальном просмотре любой привычки (GitHub-style сетка по дням)'),
        t('Donut chart in Weekly Review — tap a slice to see the exact count, central total shows tasks completed that week',
          'Donut-диаграмма в Weekly Review — нажми на сектор чтобы увидеть точное количество, в центре общее число задач за неделю'),
        t('Save-failure banner with Retry — if sync to cloud fails, a red bar appears at the bottom of the app with a one-tap retry',
          'Баннер ошибки сохранения с кнопкой Retry — если синк в облако падает, внизу приложения появляется красная полоса с кнопкой повтора'),
        t('Undo snackbar when you delete a habit from the edit sheet — 4 seconds to restore',
          'Undo-уведомление при удалении привычки через лист редактирования — 4 секунды чтобы вернуть'),
        t('Smart default due date for new tasks — today before 5pm, tomorrow after',
          'Умная дата по умолчанию для новых задач — сегодня до 17:00, завтра после'),
        t('Animated empty states added to Workouts, Reading, Food, Abstain, Collection, Budget — no more lifeless "nothing here"',
          'Анимированные пустые состояния добавлены в Тренировки, Чтение, Питание, Воздержание, Коллекцию, Бюджет — больше никаких безжизненных "тут ничего"'),
      ],
    ),
    _PatchNote(
      version: 'v2.0',
      date: '2026-04-20',
      title: t('Tasks Header & Home Dock Polish', 'Полировка шапки задач и дока главной'),
      items: [
        t('Filter chips (All / Today / Priority) moved inline between the search toggle and sort button — saves a whole row above the calendar',
          'Чипы фильтра (Все / Сегодня / Приоритет) переехали в одну строку между поиском и сортировкой — экономия целого ряда над календарём'),
        t('Calendar strip days are now perfect circles (AspectRatio 1:1) instead of ovals',
          'Дни в календаре теперь идеально круглые (AspectRatio 1:1), а не овальные'),
        t('Home dock: selected section no longer shows a text label — just enlarges the icon (AnimatedScale x1.6)',
          'Док главного экрана: выбранная секция больше не показывает текстовый лейбл — только увеличивает иконку (AnimatedScale x1.6)'),
      ],
    ),
    _PatchNote(
      version: 'v1.9',
      date: '2026-04-20',
      title: t('Routine Slots — Vertical List', 'Слоты распорядка — вертикальный список'),
      items: [
        t('Routine picker in Add and Edit habit sheets is now a full-width vertical list — one slot per row with a check mark on the selected row',
          'Выбор распорядка в листах добавления и редактирования привычки теперь вертикальный список на всю ширину — один слот на строку с галочкой на выбранном'),
        t('Bigger icons and text (15px / 11px) for easier tapping on phones',
          'Иконки и текст больше (15px / 11px) — удобнее нажимать на телефонах'),
      ],
    ),
    _PatchNote(
      version: 'v1.8',
      date: '2026-04-20',
      title: t('Habits Polish & Editing', 'Привычки: полировка и редактирование'),
      items: [
        t('Five routine slots: Morning, Afternoon, Evening, Night, Before Sleep — habits group by slot in the list',
          'Пять слотов распорядка: Утро, День, Вечер, Ночь, Перед сном — привычки группируются в списке'),
        t('Compact habit card — category icon merged with title, timer and routine as inline icons, less vertical space',
          'Компактная карточка привычки — иконка категории рядом с названием, таймер и распорядок как иконки, меньше высота'),
        t('Weekly progress bar respects schedule: Mon/Tue/Wed habit shows 0/3, non-scheduled days rendered dim',
          'Недельный прогресс учитывает расписание: Пн/Вт/Ср привычка показывает 0/3, непланируемые дни приглушены'),
        t('Edit habit sheet — tap pencil in detail view to change title, category, schedule, routine slot, timer, or delete',
          'Редактирование привычки — нажми карандаш в детальном просмотре для смены названия, категории, расписания, распорядка, таймера, или удаления'),
        t('Quick change task priority and category — tap the chips in task detail to cycle',
          'Быстрая смена приоритета и категории задачи — нажми на чипы в детальном просмотре задачи для переключения'),
        t('Collapsible monthly calendar at top of Habits — tap month name to expand/collapse',
          'Сворачиваемый календарь вверху Привычек — нажми на месяц чтобы развернуть/свернуть'),
        t('Compact headers across the app — back button left, small title right, stats moved to second row',
          'Компактные шапки по всему приложению — кнопка назад слева, маленький заголовок справа, статистика ниже'),
      ],
    ),
    _PatchNote(
      version: 'v1.7',
      date: '2026-04-20',
      title: t('Custom Avatar & Profile', 'Кастомный аватар и профиль'),
      items: [
        t('Custom photo avatar — Profile → tap avatar circle → Upload Photo, stored in the cloud',
          'Фото аватар — Профиль → нажми на кружок аватара → Загрузить фото, хранится в облаке'),
        t('Emoji avatar — same picker, 24 emojis to choose from; picking one removes the photo',
          'Эмодзи аватар — тот же выбор, 24 варианта; выбор эмодзи убирает фото'),
        t('Username shown in home header (next to avatar) and on Profile screen',
          'Имя пользователя в шапке главного экрана (рядом с аватаром) и на экране профиля'),
      ],
    ),
    _PatchNote(
      version: 'v1.6',
      date: '2026-04-20',
      title: t('Localization & Patch Notes', 'Локализация и патч ноуты'),
      items: [
        t('Language selection on every launch (English or Russian) right after the splash screen',
          'Выбор языка при каждом запуске (English или Русский) сразу после заставки'),
        t('Change language later — Home → Settings (top right) → language tile under "Appearance"',
          'Сменить язык позже — Главный экран → Настройки (справа вверху) → плитка языка в разделе "Внешний вид"'),
        t('Patch notes appear automatically after language pick; also reachable via Settings',
          'Патч ноуты появляются автоматически после выбора языка; также доступны в Настройках'),
        t('17 screens fully translated to Russian',
          '17 экранов полностью переведены на русский'),
      ],
    ),
    _PatchNote(
      version: 'v1.5',
      date: '2026-04-19',
      title: t('Cloud Sync', 'Облачная синхронизация'),
      items: [
        t('Firestore persistence — per-user save', 'Firestore — сохранение для каждого юзера'),
        t('Firebase Auth — login & sign-out', 'Firebase Auth — вход и выход'),
        t('GitHub Pages deploy with phone frame', 'Деплой на GitHub Pages с рамкой телефона'),
      ],
    ),
    _PatchNote(
      version: 'v1.4',
      date: '2026-04-18',
      title: t('Tasks Big Wave', 'Большое обновление задач'),
      items: [
        t('Swipe, quick-add, reorder, focus mode', 'Свайп, быстрое добавление, сортировка, режим фокуса'),
        t('Combo system & activity heatmap', 'Система комбо и карта активности'),
        t('Weekly review panel', 'Панель недельного обзора'),
        t('Jelly buttons & animated empty states', 'Желейные кнопки и анимированные пустые состояния'),
      ],
    ),
    _PatchNote(
      version: 'v1.3',
      date: '2026-04-17',
      title: t('Habits Boost', 'Привычки+'),
      items: [
        t('Habit timer, routine grouping', 'Таймер привычек, группировка рутин'),
        t('Celebration animation, notes, presets', 'Анимация празднования, заметки, пресеты'),
        t('Progress bar & milestones', 'Прогресс бар и вехи'),
        t('14-day calendar strip', '14-дневная календарная полоса'),
      ],
    ),
    _PatchNote(
      version: 'v1.2',
      date: '2026-04-16',
      title: t('Visual Polish', 'Визуальная полировка'),
      items: [
        t('Unified Soft UI across all screens', 'Единый Soft UI по всем экранам'),
        t('Earthy color palette', 'Земляная цветовая палитра'),
        t('Calendar redesigns — beige, embossed, pie charts', 'Редизайн календаря — бежевый, тиснёный, круговые диаграммы'),
        t('Monthly calendar with mini pie charts per day', 'Месячный календарь с мини-диаграммами'),
      ],
    ),
    _PatchNote(
      version: 'v1.1',
      date: '2026-04-15',
      title: t('Feature Wave', 'Волна фич'),
      items: [
        t('Subtasks, tags, recurring tasks, search & sort', 'Подзадачи, теги, повторяющиеся задачи, поиск и сортировка'),
        t('Full profile screen — stats, achievements, milestones', 'Полный профиль — статистика, достижения, вехи'),
        t('Daily quests as popup', 'Ежедневные квесты как попап'),
        t('All 5 remaining screens — workouts, abstain, reading, budget, food', 'Все 5 экранов — тренировки, воздержание, чтение, бюджет, питание'),
        t('Skeleton loading & swipe glow', 'Скелетон загрузки и свечение при свайпе'),
      ],
    ),
    _PatchNote(
      version: 'v1.0',
      date: '2026-04-14',
      title: t('Initial Release', 'Первый релиз'),
      items: [
        t('Pizza wheel navigation with 9 sections', 'Навигация-колесо с 9 секциями'),
        t('Tasks with XP, levels & collectibles', 'Задачи с XP, уровнями и коллекционными предметами'),
        t('Habits screen with streaks', 'Экран привычек с сериями'),
        t('Collection gallery — Epic, Rare, Uncommon', 'Галерея коллекций — Эпик, Редкие, Необычные'),
        t('Dark & light themes', 'Тёмная и светлая темы'),
        t('Motivational quotes', 'Мотивационные цитаты'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFBEC1DC);
    final cardColor = isDark ? Colors.white.withAlpha(8) : Colors.white.withAlpha(180);
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(20);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subColor = isDark ? Colors.white.withAlpha(140) : Colors.black.withAlpha(140);

    return SwipeToPop(
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (onContinue == null)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 15, color: textColor),
                        ),
                      ),
                    if (onContinue == null) const SizedBox(width: 14),
                    Text(t('PATCH NOTES', 'ПАТЧ НОУТЫ'),
                      style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, color: AppColors.action,
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: borderColor),
              const SizedBox(height: 8),

              // Notes list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: _notes.length,
                  itemBuilder: (ctx, i) {
                    final note = _notes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Version + date row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.action.withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.action.withAlpha(80)),
                                ),
                                child: Text(note.version,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.action,
                                  )),
                              ),
                              const SizedBox(width: 8),
                              Text(note.date,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9, fontWeight: FontWeight.w500,
                                  color: subColor,
                                )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Title
                          Text(note.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: textColor,
                            )),
                          const SizedBox(height: 8),
                          // Items
                          ...note.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.action.withAlpha(180),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(item,
                                    style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w500,
                                      height: 1.4, color: subColor,
                                    )),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Continue button (only on launch flow)
              if (onContinue != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.action,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: AppColors.action.withAlpha(80),
                          blurRadius: 20, offset: const Offset(0, 6),
                        )],
                      ),
                      child: Center(
                        child: Text(t('CONTINUE', 'ПРОДОЛЖИТЬ'),
                          style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            letterSpacing: 2, color: Colors.white,
                          )),
                      ),
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

class _PatchNote {
  final String version;
  final String date;
  final String title;
  final List<String> items;

  const _PatchNote({
    required this.version,
    required this.date,
    required this.title,
    required this.items,
  });
}
