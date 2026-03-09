import 'dart:math';
import 'package:flutter/foundation.dart';

enum Rarity { uncommon, rare, epic }
enum Album   { op, jp, sp, pk }

extension RarityExt on Rarity {
  String get label {
    switch (this) {
      case Rarity.uncommon: return 'UNCOMMON';
      case Rarity.rare:     return 'RARE';
      case Rarity.epic:     return 'EPIC';
    }
  }
  int get color {
    switch (this) {
      case Rarity.uncommon: return 0xFF00E676;
      case Rarity.rare:     return 0xFF2979FF;
      case Rarity.epic:     return 0xFFAA00FF;
    }
  }
  int get weight {
    switch (this) {
      case Rarity.uncommon: return 60;
      case Rarity.rare:     return 30;
      case Rarity.epic:     return 10;
    }
  }
}

extension AlbumExt on Album {
  String get title {
    switch (this) {
      case Album.op: return 'ONE PIECE';
      case Album.jp: return 'JAPAN';
      case Album.sp: return 'STEAMPUNK';
      case Album.pk: return 'PINK';
    }
  }
  String get tag {
    switch (this) {
      case Album.op: return 'OP';
      case Album.jp: return 'JP';
      case Album.sp: return 'SP';
      case Album.pk: return 'PK';
    }
  }
  int get color {
    switch (this) {
      case Album.op: return 0xFFFF6B35; // orange-red
      case Album.jp: return 0xFFFF1744; // red
      case Album.sp: return 0xFFFFD600; // amber
      case Album.pk: return 0xFFFF4081; // pink
    }
  }
}

class CollectionItem {
  final String id;
  final String assetPath;
  final String name;
  final Rarity rarity;
  final Album  album;
  bool isUnlocked;

  CollectionItem({
    required this.id,
    required this.assetPath,
    required this.name,
    required this.rarity,
    required this.album,
    this.isUnlocked = false,
  });

  bool get isVideo => assetPath.toLowerCase().endsWith('.mp4');
}

class CollectionState extends ChangeNotifier {
  static final CollectionState instance = CollectionState._();
  CollectionState._();

  final _rng = Random();

  final List<CollectionItem> _items = [
    // ── One Piece ──────────────────────────────────────────────────────────
    CollectionItem(id: 'op_kaydzu',     assetPath: 'assets/collection/Epic/op_kaydzu.mp4',        name: 'KAYDZU',      rarity: Rarity.epic,     album: Album.op),
    CollectionItem(id: 'op_luffy',      assetPath: 'assets/collection/Epic/op_luffy.jpg',          name: 'LUFFY',       rarity: Rarity.epic,     album: Album.op),
    CollectionItem(id: 'op_luffygang',  assetPath: 'assets/collection/Rare/op_luffyrgang.jpg',     name: 'LUFFY GANG',  rarity: Rarity.rare,     album: Album.op),
    // ── Japan ──────────────────────────────────────────────────────────────
    CollectionItem(id: 'jp_hellboy',    assetPath: 'assets/collection/Epic/jp_hellboy.mp4',        name: 'HELLBOY',     rarity: Rarity.epic,     album: Album.jp),
    CollectionItem(id: 'jp_carnage',    assetPath: 'assets/collection/Uncommon/jp_carnage.jpg',    name: 'CARNAGE',     rarity: Rarity.uncommon, album: Album.jp),
    CollectionItem(id: 'jp_mask',       assetPath: 'assets/collection/Uncommon/jp_mask.jpg',       name: 'MASKED',      rarity: Rarity.uncommon, album: Album.jp),
    CollectionItem(id: 'jp_skull',      assetPath: 'assets/collection/Uncommon/jp_skull.jpg',      name: 'SKULL',       rarity: Rarity.uncommon, album: Album.jp),
    // ── Steampunk ──────────────────────────────────────────────────────────
    CollectionItem(id: 'sp_godji',      assetPath: 'assets/collection/Rare/sp_godji.jpg',          name: 'GODJI',       rarity: Rarity.rare,     album: Album.sp),
    CollectionItem(id: 'sp_hs',         assetPath: 'assets/collection/Rare/sp_hs.png',             name: 'HS',          rarity: Rarity.rare,     album: Album.sp),
    // ── Pink ───────────────────────────────────────────────────────────────
    CollectionItem(id: 'pk_fuck',       assetPath: 'assets/collection/Rare/pk_fuck.jpg',           name: 'FUCK',        rarity: Rarity.rare,     album: Album.pk),
    CollectionItem(id: 'pk_glasses',    assetPath: 'assets/collection/Rare/pk_glasses.jpg',        name: 'GLASSES',     rarity: Rarity.rare,     album: Album.pk),
    CollectionItem(id: 'pk_old',        assetPath: 'assets/collection/Rare/pk_old.jpg',            name: 'OLD',         rarity: Rarity.rare,     album: Album.pk),
  ];

  List<CollectionItem> get items => List.unmodifiable(_items);
  int get unlockedCount => _items.where((i) => i.isUnlocked).length;

  List<CollectionItem> byAlbum(Album a) =>
      _items.where((i) => i.album == a).toList();

  bool isAlbumComplete(Album a) =>
      byAlbum(a).every((i) => i.isUnlocked);

  String albumCoverPath(Album a) =>
      'assets/collection/Albums/${a.name}.jpg';

  /// Weighted-random drop. Returns newly unlocked item, or null if all collected.
  CollectionItem? onLevelUp() {
    final unowned = _items.where((i) => !i.isUnlocked).toList();
    if (unowned.isEmpty) return null;

    int totalWeight = unowned.fold(0, (s, i) => s + i.rarity.weight);
    int roll = _rng.nextInt(totalWeight);
    for (final item in unowned) {
      roll -= item.rarity.weight;
      if (roll < 0) {
        item.isUnlocked = true;
        notifyListeners();
        return item;
      }
    }
    unowned.first.isUnlocked = true;
    notifyListeners();
    return unowned.first;
  }
}
