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
      version: 'v1.7',
      date: '2026-04-20',
      title: t('Custom Avatar & Profile', 'Кастомный аватар и профиль'),
      items: [
        t('🖼 CUSTOM PHOTO AVATAR: Open the app → swipe wheel to PROFILE → tap your avatar circle → tap "UPLOAD PHOTO" → choose a photo from your device. The photo is saved to the cloud.',
          '🖼 СВОЯ ФОТОГРАФИЯ: Открой приложение → крути колесо до ПРОФИЛЬ → нажми на кружок аватара → нажми "ЗАГРУЗИТЬ ФОТО" → выбери фото с устройства. Фото сохраняется в облако.'),
        t('😎 EMOJI AVATAR: Same place — tap your avatar → scroll down and pick any emoji from the grid (24 options). Choosing emoji removes the photo.',
          '😎 ЭМОДЗИ АВАТАР: Там же — нажми на аватар → пролистай вниз и выбери любой эмодзи из сетки (24 варианта). Выбор эмодзи убирает фото.'),
        t('👤 USERNAME DISPLAY: Your chosen username now shows in the home screen header (next to avatar) and in the profile screen.',
          '👤 ИМЯ ПОЛЬЗОВАТЕЛЯ: Твоё имя теперь отображается в шапке главного меню (рядом с аватаром) и на экране профиля.'),
      ],
    ),
    _PatchNote(
      version: 'v1.6',
      date: '2026-04-20',
      title: t('Localization & Patch Notes', 'Локализация и Патч Ноуты'),
      items: [
        t('🌐 LANGUAGE SELECTION: Every time you open the app, after the splash screen you choose English 🇬🇧 or Russian 🇷🇺. All screens switch instantly.',
          '🌐 ВЫБОР ЯЗЫКА: При каждом запуске, после заставки, выбираешь English 🇬🇧 или Русский 🇷🇺. Все экраны переключаются мгновенно.'),
        t('⚙️ CHANGE LANGUAGE LATER: Home screen → tap ⚙️ Settings (top right) → tap the language tile under "APPEARANCE" → toggles between EN and RU.',
          '⚙️ СМЕНИТЬ ЯЗЫК ПОТОМ: Главный экран → нажми ⚙️ Настройки (вверху справа) → нажми на плитку языка в разделе "ВНЕШНИЙ ВИД" → переключает EN и RU.'),
        t('📋 PATCH NOTES ON LAUNCH: After picking language, patch notes appear automatically. Tap "CONTINUE" to proceed.',
          '📋 ПАТЧ НОУТЫ ПРИ ЗАПУСКЕ: После выбора языка автоматически появляются патч ноуты. Нажми "ПРОДОЛЖИТЬ" чтобы продолжить.'),
        t('📋 PATCH NOTES FROM SETTINGS: Home → ⚙️ Settings → scroll to "PATCH NOTES" section → tap "VIEW PATCH NOTES".',
          '📋 ПАТЧ НОУТЫ ИЗ НАСТРОЕК: Главная → ⚙️ Настройки → пролистай до "ПАТЧ НОУТЫ" → нажми "ПОСМОТРЕТЬ ПАТЧ НОУТЫ".'),
        t('🔤 17 screens fully translated to Russian: home, tasks, habits, workouts, abstain, reading, budget, food, collection, profile, settings, login, onboarding, and more.',
          '🔤 17 экранов полностью переведены на русский: главная, задания, привычки, тренировки, воздержание, чтение, бюджет, питание, коллекция, профиль, настройки, вход, онбординг и другие.'),
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
