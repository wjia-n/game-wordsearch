import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/wordsearch_themes.dart';

/// Persisted settings + stats for Word Search. Survives app restarts.
///
/// Stores: audio toggles, the renameable player name, theme/style choices
/// (incl. custom theme colors), game setup (difficulty, mode, category),
/// Pro unlock state, and lifetime stats.
class WordSearchSettings extends ChangeNotifier {
  static const _kMusic = 'wordsearch_music_on';
  static const _kSfx = 'wordsearch_sfx_on';
  static const _kVolume = 'wordsearch_volume';
  static const _kDifficulty = 'wordsearch_difficulty'; // 0 cozy, 1 clever, 2 master
  static const _kMode = 'wordsearch_mode'; // 0 relaxed, 1 timed
  static const _kCategory = 'wordsearch_category';
  static const _kNames = 'wordsearch_player_names'; // legacy unordered StringSet key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'wordsearch_player_names_json';
  static const _kTheme = 'wordsearch_theme_id';
  static const _kStyle = 'wordsearch_tile_style';
  static const _kGames = 'wordsearch_games_played';
  static const _kWins = 'wordsearch_wins';
  static const _kBestTimes = 'wordsearch_best_times_json'; // [cozy, clever, master] secs
  static const _kIsPro = 'wordsearch_is_pro';
  static const _kCustomPrefix = 'wordsearch_custom_';

  static const defaultNames = ['Player'];

  /// Encode the player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i % defaultNames.length] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.isNotEmpty) {
        return [for (int i = 0; i < d.length; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 0;
  int mode = 0; // 0 relaxed (count up), 1 timed (count down)
  int category = 0;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'pine';
  int tileStyle = 0;
  int gamesPlayed = 0;
  int wins = 0;
  List<int> bestTimes = [0, 0, 0]; // fastest relaxed seconds per tier
  bool isPro = false;

  String get playerName => playerNames.isEmpty ? defaultNames[0] : playerNames[0];

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Pine.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'paper': 0xFFE9D9B8,
    'paperDeep': 0xFF2A2016,
    'tile': 0xFFF5E9CF,
    'tileEdge': 0xFFC9A86A,
    'ink': 0xFF4A3319,
    'accent': 0xFF7A9B3F,
    'accentDark': 0xFF4E6A24,
    'pencil': 0xFFB4540A,
    'soft': 0xFFDFCDA3,
  };

  /// Builds the user-designed custom theme from stored colors.
  WorkshopThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return WorkshopThemeDef(
      id: 'custom',
      name: 'My Creation',
      paper: c('paper'),
      paperDeep: c('paperDeep'),
      tile: c('tile'),
      tileEdge: c('tileEdge'),
      ink: c('ink'),
      accent: c('accent'),
      accentDark: c('accentDark'),
      pencil: c('pencil'),
      soft: c('soft'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    category = (p.getInt(_kCategory) ?? 0).clamp(0, WordCategories.names.length - 1);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.isNotEmpty)
          ? [for (int i = 0; i < legacy.length; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'pine';
    tileStyle = (p.getInt(_kStyle) ?? 0).clamp(0, TileStyles.names.length - 1);
    gamesPlayed = p.getInt(_kGames) ?? 0;
    wins = p.getInt(_kWins) ?? 0;
    final rawTimes = p.getString(_kBestTimes);
    if (rawTimes != null) {
      try {
        final d = jsonDecode(rawTimes);
        if (d is List && d.length == 3) {
          bestTimes = [for (final v in d) (v as num).toInt().clamp(0, 1 << 30)];
        }
      } catch (_) {}
    }
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setInt(_kCategory, category);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kStyle, tileStyle);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kWins, wins);
    await p.setString(_kBestTimes, jsonEncode(bestTimes));
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || WorkshopThemes.isProTheme(themeId)) {
      themeId = 'pine';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    if (WordCategories.isPro(category)) {
      category = 0;
      changed = true;
    }
    if (DifficultyTiers.isPro(difficulty)) {
      difficulty = 1;
      changed = true;
    }
    if (mode == 1) {
      mode = 0; // timed mode is Pro
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && DifficultyTiers.isPro(v)) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    v = v.clamp(0, 1);
    if (!isPro && v == 1) return; // timed mode is Pro
    mode = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCategory(int v) async {
    v = v.clamp(0, WordCategories.names.length - 1);
    if (!isPro && WordCategories.isPro(v)) return;
    category = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerNames = [clean.isEmpty ? defaultNames[0] : clean];
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || WorkshopThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.names.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [seconds] is the relaxed-mode time; kept as the
  /// per-tier best. Timed wins count as wins too.
  Future<void> recordGame(
      {required bool won, required int seconds, required int tier}) async {
    gamesPlayed++;
    if (won) {
      wins++;
      final t = tier.clamp(0, 2);
      if (bestTimes[t] == 0 || seconds < bestTimes[t]) {
        bestTimes[t] = seconds;
      }
    }
    notifyListeners();
    await _save();
  }
}
