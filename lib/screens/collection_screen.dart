import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/collection_state.dart';
import '../theme/app_colors.dart';

// ── Entry screen — album list ─────────────────────────────────────────────────

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);

    return ListenableBuilder(
      listenable: CollectionState.instance,
      builder: (context, _) {
        final unlocked = CollectionState.instance.unlockedCount;
        final total    = CollectionState.instance.items.length;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────────────────
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COLLECTION',
                              style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                letterSpacing: 1.5, color: AppColors.collection,
                              )),
                            Text('$unlocked / $total unlocked',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Container(height: 1,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFB8BACD)),
                const SizedBox(height: 16),

                // ── Album list ──────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: Album.values.length,
                    separatorBuilder: (_, s) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) => _AlbumListCard(album: Album.values[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Horizontal album card ─────────────────────────────────────────────────────

class _AlbumListCard extends StatelessWidget {
  final Album album;
  const _AlbumListCard({required this.album});

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final cs       = CollectionState.instance;
    final complete = cs.isAlbumComplete(album);
    final items    = cs.byAlbum(album);
    final unlocked = items.where((i) => i.isUnlocked).length;
    final total    = items.length;
    final c        = Color(album.color);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (ctx, a, b) => _AlbumDetailScreen(album: album),
          transitionsBuilder: (ctx, a, b, child) {
            final c2 = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: c2,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(c2),
                child: child,
              ),
            );
          },
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Album cover — grayscale when locked, full color when complete
              if (complete)
                Image.asset(
                  cs.albumCoverPath(album),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) =>
                      Container(color: const Color(0xFF0D0D18)),
                )
              else
                ColorFiltered(
                  colorFilter: _grayscale,
                  child: Image.asset(
                    cs.albumCoverPath(album),
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) =>
                        Container(color: const Color(0xFF0D0D18)),
                  ),
                ),

              // Dark overlay
              Container(
                color: Colors.black.withAlpha(complete ? 100 : 160),
              ),

              // Subtle color tint on the bottom when complete
              if (complete)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          c.withAlpha(60),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

              // Neon border when complete
              if (complete)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.withAlpha(160), width: 1.5),
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: complete
                            ? c.withAlpha(50)
                            : Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: complete
                              ? c.withAlpha(150)
                              : Colors.white.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Text(album.tag,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: complete ? c : Colors.white.withAlpha(120),
                        )),
                    ),
                    const SizedBox(height: 6),
                    // Album title
                    Text(album.title,
                      style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        shadows: complete ? [
                          Shadow(color: c.withAlpha(180), blurRadius: 14),
                        ] : null,
                      )),
                    const SizedBox(height: 4),
                    // Card count
                    Row(
                      children: [
                        _dot(unlocked, total, c, complete),
                        const SizedBox(width: 8),
                        Text(
                          complete
                              ? 'COMPLETE'
                              : '$unlocked / $total cards',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: complete
                                ? c
                                : Colors.white.withAlpha(120),
                          )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int unlocked, int total, Color c, bool complete) {
    return Row(
      children: List.generate(total, (i) => Container(
        width: 6, height: 6,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < unlocked
              ? (complete ? c : Colors.white.withAlpha(160))
              : Colors.white.withAlpha(40),
        ),
      )),
    );
  }
}

// ── Album detail screen ───────────────────────────────────────────────────────

class _AlbumDetailScreen extends StatelessWidget {
  final Album album;
  const _AlbumDetailScreen({required this.album});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D16) : const Color(0xFFBEC1DC);
    final c  = Color(album.color);

    return ListenableBuilder(
      listenable: CollectionState.instance,
      builder: (context, _) {
        final cs       = CollectionState.instance;
        final items    = cs.byAlbum(album);
        final unlocked = items.where((i) => i.isUnlocked).length;
        final complete = cs.isAlbumComplete(album);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(album.title,
                              style: GoogleFonts.inter(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                letterSpacing: 1.5, color: c,
                              )),
                            Text('$unlocked / ${items.length} cards',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
                              )),
                          ],
                        ),
                      ),
                      if (complete)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.withAlpha(30),
                            border: Border.all(color: c.withAlpha(160)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('COMPLETE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 1, color: c,
                            )),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Container(height: 1,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFB8BACD)),
                const SizedBox(height: 12),

                // Banner — only when album is fully unlocked
                if (complete)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _AlbumBanner(album: album),
                  ),

                // Cards grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _CollectibleCard(item: items[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Album banner (inside detail screen) ──────────────────────────────────────

class _AlbumBanner extends StatelessWidget {
  final Album album;
  const _AlbumBanner({required this.album});

  @override
  Widget build(BuildContext context) {
    final cs       = CollectionState.instance;
    final complete = cs.isAlbumComplete(album);
    final items    = cs.byAlbum(album);
    final unlocked = items.where((i) => i.isUnlocked).length;
    final total    = items.length;
    final c        = Color(album.color);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              cs.albumCoverPath(album),
              fit: BoxFit.cover,
              color: complete ? null : Colors.black.withAlpha(200),
              colorBlendMode: complete ? null : BlendMode.darken,
              errorBuilder: (_, e, s) => Container(color: const Color(0xFF070710)),
            ),
            if (complete)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.withAlpha(180), width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(complete ? 140 : 210),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            if (!complete)
              Center(child: Icon(Icons.lock_outline_rounded,
                  color: Colors.white.withAlpha(25), size: 30)),
            Positioned(
              left: 14, right: 14, bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(album.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: complete ? Colors.white : Colors.white.withAlpha(55),
                        shadows: complete ? [Shadow(color: c.withAlpha(200), blurRadius: 12)] : null,
                      )),
                  ),
                  Text('$unlocked / $total',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: complete ? c : Colors.white.withAlpha(50),
                      letterSpacing: 1,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _CollectibleCard extends StatefulWidget {
  final CollectionItem item;
  const _CollectibleCard({required this.item});

  @override
  State<_CollectibleCard> createState() => _CollectibleCardState();
}

class _CollectibleCardState extends State<_CollectibleCard>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _vpc;
  bool _videoReady = false;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    if (widget.item.isUnlocked && widget.item.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.item.assetPath);
    _vpc = c;
    await c.initialize();
    if (!mounted) return;
    await c.setLooping(true);
    await c.setVolume(0);
    await c.play();
    setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _vpc?.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _open() {
    if (!widget.item.isUnlocked) return;
    HapticFeedback.mediumImpact();
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      pageBuilder: (ctx, a, b) => _FullscreenView(item: widget.item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unlocked    = widget.item.isUnlocked;
    final rarityColor = Color(widget.item.rarity.color);
    final albumColor  = Color(widget.item.album.color);

    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (ctx, _) {
        final pulse = 0.4 + 0.6 * sin(_glowCtrl.value * pi);

        return GestureDetector(
          onTap: _open,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0A0A14),
              border: Border.all(
                color: unlocked
                    ? rarityColor.withAlpha((80 + (pulse * 150).round()))
                    : Colors.white.withAlpha(18),
                width: unlocked ? 1.8 : 1,
              ),
              boxShadow: unlocked ? [
                BoxShadow(
                  color: rarityColor.withAlpha((pulse * 70).round()),
                  blurRadius: 16 + pulse * 14,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (unlocked) ...[
                    if (widget.item.isVideo)
                      _videoReady && _vpc != null
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _vpc!.value.size.width,
                                height: _vpc!.value.size.height,
                                child: VideoPlayer(_vpc!),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator(
                              color: Colors.white24, strokeWidth: 1.5))
                    else
                      Image.asset(widget.item.assetPath, fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                            color: const Color(0xFF0A0A14),
                            child: Center(child: Text(e.toString(),
                              style: const TextStyle(
                                  color: Color(0xFFFF5252), fontSize: 8),
                              textAlign: TextAlign.center)),
                          )),
                  ] else
                    _LockedPlaceholder(item: widget.item),

                  if (unlocked)
                    Positioned(
                      top: 5, left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: rarityColor.withAlpha(160), width: 1),
                        ),
                        child: Text(widget.item.rarity.label[0], // E / R / U
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7, fontWeight: FontWeight.w700,
                            color: rarityColor,
                          )),
                      ),
                    ),

                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withAlpha(210), Colors.transparent],
                        ),
                      ),
                      child: Text(widget.item.name,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: unlocked ? albumColor : Colors.white.withAlpha(50),
                        )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Locked placeholder ────────────────────────────────────────────────────────

class _LockedPlaceholder extends StatelessWidget {
  final CollectionItem item;
  const _LockedPlaceholder({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070710),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              color: Colors.white.withAlpha(35), size: 28),
          const SizedBox(height: 8),
          Text(item.rarity.label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2,
              color: Color(item.rarity.color).withAlpha(60),
            )),
          const SizedBox(height: 4),
          Text('???',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11, letterSpacing: 2,
              color: Colors.white.withAlpha(25),
            )),
        ],
      ),
    );
  }
}

// ── Fullscreen view ───────────────────────────────────────────────────────────

class _FullscreenView extends StatefulWidget {
  final CollectionItem item;
  const _FullscreenView({required this.item});

  @override
  State<_FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<_FullscreenView> {
  VideoPlayerController? _vpc;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.item.assetPath);
    _vpc = c;
    await c.initialize();
    if (!mounted) return;
    await c.setLooping(true);
    await c.setVolume(1.0);
    await c.play();
    setState(() {});
  }

  @override
  void dispose() { _vpc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(widget.item.rarity.color);
    final albumColor  = Color(widget.item.album.color);
    final vpc = _vpc;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: widget.item.isVideo
                  ? (vpc != null && vpc.value.isInitialized
                      ? AspectRatio(aspectRatio: vpc.value.aspectRatio,
                          child: VideoPlayer(vpc))
                      : CircularProgressIndicator(color: rarityColor, strokeWidth: 1.5))
                  : Image.asset(widget.item.assetPath, fit: BoxFit.contain),
            ),
            Positioned(
              bottom: 48, left: 0, right: 0,
              child: Column(children: [
                Text(widget.item.name,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    letterSpacing: 3, color: albumColor,
                    shadows: [Shadow(color: albumColor.withAlpha(180), blurRadius: 12)],
                  )),
                const SizedBox(height: 4),
                Text('${widget.item.rarity.label}  ·  ${widget.item.album.title}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, letterSpacing: 2,
                    color: rarityColor.withAlpha(160),
                  )),
              ]),
            ),
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(child: Text('tap to close',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, letterSpacing: 2,
                  color: Colors.white.withAlpha(50)))),
            ),
          ],
        ),
      ),
    );
  }
}
