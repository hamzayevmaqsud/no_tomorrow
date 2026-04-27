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
      version: 'v4.1',
      date: '2026-04-23',
      title: t('Tasks Restored', 'Откат задач'),
      items: [
        t('Reverted the v4.0 task redesign — task cards are back to their pre-polish layout (right accent block, big title, full-width swipe actions). Other v4.0 changes (off-black backgrounds, desaturated accent, tinted shadows, dynamic-island timer, staggered list reveals, Outfit headers, etc.) stay in place',
          'Откат редизайна задач из v4.0 — карточки задач вернулись к своему виду до полировки (правый акцентный блок, крупный заголовок, swipe на всю ширину). Остальные изменения v4.0 (off-black фоны, приглушённый акцент, тинтированные тени, dynamic-island таймер, каскадные списки, Outfit-заголовки и т.д.) остаются'),
      ],
    ),
    _PatchNote(
      version: 'v4.0',
      date: '2026-04-23',
      title: t('Design Polish Pass', 'Дизайн-полировка'),
      items: [
        t('COMPACT TASK CARDS: Tasks are now minimal list items -- circle checkbox, title, time, priority dot. No more heavy cards with shadows and accent strips.',
          'КОМПАКТНЫЕ КАРТОЧКИ ЗАДАЧ: Задачи теперь минимальные элементы списка -- кружок-чекбокс, название, время, точка приоритета. Никаких тяжёлых карточек с тенями.'),
        t('COLLAPSIBLE CALENDAR: Monthly calendar hidden by default, tap month name to expand full grid. Navigate months with arrows. Task dots on days with tasks.',
          'СВОРАЧИВАЕМЫЙ КАЛЕНДАРЬ: Месячный календарь скрыт по умолчанию, нажми на название месяца чтобы раскрыть. Стрелки для навигации. Точки на днях с задачами.'),
        t('PROGRESSIVE ADD SHEET: New task form starts compact with just title field, expands as you type. "More options" link for priority, date, time, notes.',
          'ПРОГРЕССИВНАЯ ФОРМА: Новая задача начинается компактно -- только поле названия, раскрывается по мере ввода. Ссылка "больше опций" для приоритета, даты, времени, заметок.'),
        t('FILTERS HIDDEN: ALL/TODAY/PRIORITY filters moved from header into dashboard panel. Header is now clean -- just search and sort.',
          'ФИЛЬТРЫ СПРЯТАНЫ: Фильтры ВСЕ/СЕГОДНЯ/ПРИОРИТЕТ переехали из шапки в dashboard. Шапка теперь чистая -- только поиск и сортировка.'),
        t('OFF-BLACK BACKGROUNDS: Pure black replaced with warm off-black across home, collection, tasks menu screens.',
          'OFF-BLACK ФОНЫ: Чистый чёрный заменён на тёплый off-black по всем экранам.'),
        t('DESATURATED ACCENT: Orange accent toned down from neon to warm earthy tone across the entire app.',
          'ДЕСАТУРИРОВАННЫЙ АКЦЕНТ: Оранжевый акцент приглушён с неонового до тёплого земляного тона по всему приложению.'),
        t('TINTED SHADOWS: All shadows now tinted with section accent color instead of pure black. Task card shadows match priority color.',
          'ТИНТИРОВАННЫЕ ТЕНИ: Все тени теперь окрашены акцентом секции вместо чёрного. Тени задач соответствуют цвету приоритета.'),
        t('SUBTLE GLOWS: 33 neon outer glows replaced with subtle, low-alpha tinted shadows across all screens.',
          'МЯГКИЕ ТЕНИ: 33 неоновых свечения заменены на мягкие тинтированные тени с низкой альфой по всем экранам.'),
        t('DYNAMIC ISLAND TIMER: Workout rest timer redesigned as pill-shaped floating element at the top, like iPhone Dynamic Island.',
          'DYNAMIC ISLAND ТАЙМЕР: Таймер отдыха переделан в pill-shape плавающий элемент сверху, как Dynamic Island на iPhone.'),
        t('STAGGERED REVEALS: Task, habit, and workout lists now cascade in with 50ms delay between items instead of appearing all at once.',
          'КАСКАДНОЕ ПОЯВЛЕНИЕ: Списки задач, привычек и тренировок теперь появляются каскадом с задержкой 50мс вместо мгновенного появления.'),
        t('STANDARDIZED ANIMATIONS: All transitions unified -- 400ms/300ms for routes, 260ms for state changes, 160ms for taps. Consistent easeOutCubic everywhere.',
          'СТАНДАРТИЗИРОВАННЫЕ АНИМАЦИИ: Все переходы унифицированы -- 400мс/300мс для навигации, 260мс для смены состояний, 160мс для тапов. easeOutCubic везде.'),
        t('HAPTIC FEEDBACK: Added tactile feedback to language toggle, collection back buttons, wheel navigation, and other missing spots.',
          'HAPTIC FEEDBACK: Добавлена тактильная обратная связь на переключатель языка, кнопки назад в коллекции, навигацию колеса и другие места.'),
        t('TYPOGRAPHY: Inter font removed from headers, replaced with Outfit. Inter kept only for body text.',
          'ТИПОГРАФИКА: Шрифт Inter убран из заголовков, заменён на Outfit. Inter оставлен только для основного текста.'),
        t('BACK BUTTONS: All back buttons standardized to 44x44px touch target across all 11 screens.',
          'КНОПКИ НАЗАД: Все кнопки назад стандартизированы до 44x44px на всех 11 экранах.'),
        t('WORKOUT STATS: Dashboard stat boxes replaced with clean border-top dividers instead of card containers.',
          'СТАТИСТИКА ТРЕНИРОВОК: Карточки статов в дашборде заменены на чистые border-top разделители.'),
        t('FASTER SPLASH: App splash screen reduced from 2.2s to 1.5s.',
          'БЫСТРЫЙ СПЛЭШ: Заставка приложения сокращена с 2.2с до 1.5с.'),
      ],
    ),
    _PatchNote(
      version: 'v3.0',
      date: '2026-04-21',
      title: t('Workout Overhaul', 'Полный редизайн тренировок'),
      items: [
        t('EXERCISE CATALOG: Tap + to choose from 7 muscle groups (Chest, Back, Legs, Shoulders, Arms, Core, Cardio) with 40+ exercises. Tap any or type custom name, then configure sets/reps/weight/rest.',
          'КАТАЛОГ УПРАЖНЕНИЙ: Нажми + чтобы выбрать из 7 групп мышц (Грудь, Спина, Ноги, Плечи, Руки, Кор, Кардио) с 40+ упражнениями. Нажми на любое или введи своё, затем настрой подходы/повторы/вес/отдых.'),
        t('REST TIMER: Complete a set and rest timer starts automatically. Banner at the top with countdown and SKIP button. Rest time configurable per exercise (30s / 60s / 90s / 120s / 180s).',
          'ТАЙМЕР ОТДЫХА: Завершил подход — таймер отдыха стартует автоматически. Баннер сверху с обратным отсчётом и кнопкой ПРОПУСТИТЬ. Время отдыха настраивается для каждого упражнения (30с / 60с / 90с / 120с / 180с).'),
        t('EDITABLE SETS: Tap arrows to change kg (step 1) and reps (step 1) in each set row. Arrows disabled after completing a set.',
          'РЕДАКТИРУЕМЫЕ ПОДХОДЫ: Стрелками меняй кг (шаг 1) и повторы (шаг 1) в каждой строке. Стрелки блокируются после завершения подхода.'),
        t('DASHBOARD: Tap chart icon in header -- weekly volume bar chart (Mon-Sun), 4 stats (Workouts / Sets / Volume / Streak), best exercise of the week.',
          'ДАШБОРД: Нажми иконку графика в шапке -- бар-чарт недельного объёма (ПН-ВС), 4 стата (Тренировки / Подходы / Объём / Серия), лучшее упражнение недели.'),
        t('WEEKLY REVIEW: Tap REVIEW in dashboard -- hero card with total volume, change vs last week, exercise breakdown, stats grid.',
          'ОБЗОР НЕДЕЛИ: Нажми ОБЗОР в дашборде -- карта с общим объёмом, изменение относительно прошлой недели, разбивка упражнений, сетка статов.'),
        t('SCHEDULE WORKOUTS: Tap any day on the calendar (including tomorrow) to schedule a future workout. List filters by selected date.',
          'ПЛАНИРУЙ ТРЕНИРОВКИ: Нажми на любой день в календаре (включая завтра) чтобы запланировать тренировку. Список фильтруется по выбранному дню.'),
        t('PREVIOUS PERFORMANCE: Small gray numbers under current kg/reps show your last recorded values for each set.',
          'ПРЕДЫДУЩИЕ ПОКАЗАТЕЛИ: Мелкие серые цифры под текущими кг/повторами показывают прошлые значения для каждого подхода.'),
        t('BLACK + BURGUNDY: New dark color scheme with burgundy accent throughout the workout screen.',
          'ЧЁРНЫЙ + БОРДОВЫЙ: Новая тёмная цветовая схема с бордовым акцентом по всему экрану тренировок.'),
      ],
    ),
    _PatchNote(
      version: 'v2.5',
      date: '2026-04-21',
      title: t('Tasks Header Polish', 'Полировка шапки задач'),
      items: [
        t('Combo meter moved from above the task list to the header stats row, right next to the streak chip — compact mini-pill showing the multiplier, always visible without scrolling',
          'Combo-метр переехал из-над списка задач в шапку статистики, рядом с chip-серии — компактная мини-таблетка с множителем, всегда видна без скролла'),
        t('Timeline view: tasks without a time now grouped under "Anytime" instead of the technical-looking "NO TIME" label',
          'Timeline-вид: задачи без времени теперь под заголовком "Anytime" вместо технического "NO TIME"'),
      ],
    ),
    _PatchNote(
      version: 'v2.4',
      date: '2026-04-21',
      title: t('Honest Category Stripes', 'Честные полосы категорий'),
      items: [
        t('Removed the "all done = solid green" takeover — a fully completed day now stays colored by your actual category mix instead of overriding to green',
          'Убрал зелёную заливку для "всё выполнено" — полностью завершённый день теперь окрашен твоим реальным миксом категорий, а не перекрывается зелёным'),
        t('Category stripes now render for every non-future day with any habit data, including today. Incomplete portion is a neutral stripe so you see progress at a glance',
          'Полосы категорий теперь рисуются для любого прошедшего/текущего дня с данными, включая сегодня. Незавершённая часть — нейтральная полоса, прогресс виден сразу'),
      ],
    ),
    _PatchNote(
      version: 'v2.3',
      date: '2026-04-21',
      title: t('Cleaner Habit Calendars', 'Чище календари привычек'),
      items: [
        t('Removed the grid/waffle toggle button from both the main Habits calendar and the single-habit detail view — one mode only, no clutter',
          'Убрал кнопку переключения сетка/waffle с главного календаря Habits и с детального экрана привычки — один режим, без лишних иконок'),
        t('Square cells with category-stripe fill is now the only (and default) view: each day is split into colored stripes proportional to how many habits of each category you completed (Health green, Mindset purple, Productivity orange, Social blue)',
          'Квадратные ячейки с заливкой по категориям — теперь единственный вид: каждый день делится на цветные полосы пропорционально выполненным привычкам по категориям (Здоровье зелёный, Мышление фиолетовый, Продуктивность оранжевый, Общение синий)'),
      ],
    ),
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
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 24, color: textColor),
                        ),
                      ),
                    if (onContinue == null) const SizedBox(width: 14),
                    Text(t('PATCH NOTES', 'ПАТЧ НОУТЫ'),
                      style: GoogleFonts.outfit(
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
