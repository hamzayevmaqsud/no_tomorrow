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

class Book {
  final String id;
  String title;
  String author;
  int totalPages;
  int pagesRead;
  final DateTime addedAt;

  Book({required this.id, required this.title, this.author = '', this.totalPages = 200,
    this.pagesRead = 0, required this.addedAt});

  double get progress => totalPages == 0 ? 0.0 : (pagesRead / totalPages).clamp(0.0, 1.0);
  bool get isFinished => pagesRead >= totalPages;
  int get xp => (pagesRead / 10).floor() * 5;
}

class BookStore {
  static final List<Book> books = [];
  static int nextId = 1;
}

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  void _addPages(Book book, int pages) {
    HapticFeedback.mediumImpact();
    setState(() {
      book.pagesRead = (book.pagesRead + pages).clamp(0, book.totalPages);
    });
    GameState.instance.recordCompletion();
    GameState.instance.addXp(pages >= 10 ? 5 : 2);
  }

  void _delete(String id) {
    HapticFeedback.lightImpact();
    setState(() => BookStore.books.removeWhere((b) => b.id == id));
  }

  void _showAdd() {
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'dismiss',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, __) => _AddBookSheet(
        onAdd: (b) { setState(() => BookStore.books.insert(0, b)); Navigator.of(ctx).pop(); },
        nextId: '${BookStore.nextId++}',
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
    final books = BookStore.books;
    final reading = books.where((b) => !b.isFinished).toList();
    final finished = books.where((b) => b.isFinished).toList();
    final totalPages = books.fold(0, (s, b) => s + b.pagesRead);

    return SwipeToPop(child: Scaffold(
      backgroundColor: const Color(0xFF080E08),
      body: Stack(children: [
        Positioned.fill(child: Container(
          decoration: const BoxDecoration(gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF0E1A0E), Color(0xFF080E08)],
          )),
        )),
        SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(40))),
                  child: Icon(Icons.chevron_left_rounded, size: 22, color: Colors.white.withAlpha(200)))),
              const Spacer(),
              Text(t('READING', 'ЧТЕНИЕ'), style: GoogleFonts.playfairDisplay(
                fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                letterSpacing: 2, color: const Color(0xFFD0E8D0))),
            ])),
          if (books.isNotEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$totalPages ${t('pages read', 'страниц прочитано')}', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(160))),
              ])),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withAlpha(12)),
          const SizedBox(height: 16),
          Expanded(
            child: books.isEmpty
                ? AnimatedEmpty(
                    icon: Icons.menu_book_outlined,
                    title: t('Start reading', 'Начни читать'),
                    subtitle: t('Log pages to build your knowledge', 'Записывай страницы чтобы копить знания'))
                : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
                    ...reading.map((b) => _BookCard(book: b, onAddPages: (p) => _addPages(b, p), onDelete: () => _delete(b.id))),
                    if (finished.isNotEmpty) ...[
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: Text('${t('FINISHED', 'ЗАВЕРШЕНО')}  ${finished.length}', style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.success)))),
                      ...finished.map((b) => _BookCard(book: b, onAddPages: (_) {}, onDelete: () => _delete(b.id))),
                    ],
                  ]),
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
                      decoration: BoxDecoration(color: AppColors.reading, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.reading.withAlpha(100), blurRadius: 12)]),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Text(t('ADD  BOOK', 'ДОБАВИТЬ  КНИГУ'), style: GoogleFonts.playfairDisplay(
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

class _BookCard extends StatelessWidget {
  final Book book;
  final void Function(int) onAddPages;
  final VoidCallback onDelete;
  const _BookCard({required this.book, required this.onAddPages, required this.onDelete});

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
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title, style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
                height: 1.2, color: textCol)),
              if (book.author.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${t('by', 'автор:')} ${book.author}', style: GoogleFonts.inter(fontSize: 11, color: subCol)),
              ],
              const SizedBox(height: 10),
              // Progress bar
              Stack(children: [
                Container(height: 6, decoration: BoxDecoration(
                  color: textCol.withAlpha(15), borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(widthFactor: book.progress,
                  child: Container(height: 6, decoration: BoxDecoration(
                    color: book.isFinished ? AppColors.success : AppColors.reading,
                    borderRadius: BorderRadius.circular(3)))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Text('${book.pagesRead}/${book.totalPages} ${t('pages', 'стр.')}', style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, fontWeight: FontWeight.w600, color: subCol)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.gold.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: Text('+${book.xp} XP', style: GoogleFonts.jetBrainsMono(
                    fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gold))),
              ]),
              if (!book.isFinished) ...[
                const SizedBox(height: 10),
                Row(children: [
                  _PageBtn(label: '+10', onTap: () => onAddPages(10)),
                  const SizedBox(width: 6),
                  _PageBtn(label: '+25', onTap: () => onAddPages(25)),
                  const SizedBox(width: 6),
                  _PageBtn(label: '+50', onTap: () => onAddPages(50)),
                  const Spacer(),
                  GestureDetector(onTap: onDelete,
                    child: Icon(Icons.close_rounded, size: 14, color: subCol.withAlpha(100))),
                ]),
              ],
            ]))),
          // Right block
          Container(width: 56, color: (book.isFinished ? AppColors.success : AppColors.reading).withAlpha(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${(book.progress * 100).round()}', style: GoogleFonts.jetBrainsMono(
                fontSize: 22, fontWeight: FontWeight.w700, color: textCol)),
              Text('%', style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w700, color: subCol)),
            ])),
        ]))),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PageBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.reading.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.reading.withAlpha(50))),
        child: Text(label, style: GoogleFonts.jetBrainsMono(
          fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.reading)),
      ));
  }
}

class _AddBookSheet extends StatefulWidget {
  final void Function(Book) onAdd;
  final String nextId;
  const _AddBookSheet({required this.onAdd, required this.nextId});
  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  int _pages = 200;

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(Book(id: widget.nextId, title: title, author: _authorCtrl.text.trim(),
      totalPages: _pages, addedAt: DateTime.now()));
  }

  @override
  void dispose() { _titleCtrl.dispose(); _authorCtrl.dispose(); super.dispose(); }

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
                  decoration: BoxDecoration(color: AppColors.reading.withAlpha(25),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36))),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.reading, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 12),
                    Text(t('ADD BOOK', 'ДОБАВИТЬ КНИГУ'), style: GoogleFonts.playfairDisplay(
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
                    decoration: InputDecoration(hintText: t('Book title', 'Название книги'),
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onSubmitted: (_) => _submit())),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                  child: TextField(controller: _authorCtrl,
                    style: GoogleFonts.inter(fontSize: 13, color: cocoa.withAlpha(180)),
                    decoration: InputDecoration(hintText: t('Author (optional)', 'Автор (необязательно)'),
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: cocoa.withAlpha(100)),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.all(18),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(t('PAGES:', 'СТРАНИЦ:'), style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: cocoa.withAlpha(140))),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: _pages > 50 ? () => setState(() => _pages -= 50) : null,
                      child: Icon(Icons.remove_circle_outline_rounded, size: 20,
                        color: _pages > 50 ? cocoa : cocoa.withAlpha(50))),
                    const SizedBox(width: 8),
                    Text('$_pages', style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w700, color: cocoa)),
                    const SizedBox(width: 8),
                    GestureDetector(onTap: () => setState(() => _pages += 50),
                      child: Icon(Icons.add_circle_outline_rounded, size: 20, color: cocoa)),
                  ])),
                Divider(height: 1, thickness: 1, color: divider),
                Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: GestureDetector(onTap: _submit,
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: AppColors.reading, borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.reading.withAlpha(70), blurRadius: 14, offset: const Offset(0, 4))]),
                      child: Center(child: Text(t('START READING', 'НАЧАТЬ ЧТЕНИЕ'), style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Colors.white)))))),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
