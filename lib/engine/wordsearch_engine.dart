import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../theme/wordsearch_themes.dart';

/// Phases of a Word Search round. The engine (never the UI) owns every
/// timer: the deal animation, the game clock, and the found-word reveal.
/// A watchdog re-arms any phase timer that ever dies without progress, so a
/// stuck board is impossible by construction.
enum GamePhase { dealing, playing, reveal, over }

class PlacedWord {
  final String word;
  final List<int> cells;
  bool found = false;
  double reveal = 0.0; // 0..1 animated ribbon when found

  PlacedWord({required this.word, required this.cells});
}

class WordSearchEngine extends ChangeNotifier {
  static const _dirs = [
    [0, 1], [1, 0], [1, 1], [1, -1],
    [0, -1], [-1, 0], [-1, -1], [-1, 1],
  ];

  final _rand = Random();
  final void Function(String sound) sfx;
  final Future<void> Function(
      {required bool won, required int seconds, required int tier}) onRoundEnd;

  int tier = 0;
  int mode = 0; // 0 relaxed (count up), 1 timed (count down)
  int category = 0;

  int gridSize = 8;
  List<String> letters = const [];
  List<PlacedWord> words = const [];

  GamePhase phase = GamePhase.dealing;
  List<int> selection = const [];
  int dealProgress = 0; // cells flipped in so far
  int elapsed = 0; // relaxed seconds
  int timeLeft = 0; // timed seconds remaining
  int hintsLeft = 3;
  int? hintCell; // flashing hint cell, null when inactive
  bool won = false;
  bool paused = false;
  bool get over => phase == GamePhase.over;

  // Engine-owned timers — one per phase concern.
  Timer? _dealTimer;
  Timer? _clockTimer;
  Timer? _revealTimer;
  Timer? _hintTimer;
  Timer? _watchdog; // stuck-state recovery
  int _heartbeat = 0;
  int _lastWatchdogSeen = 0;
  bool _disposed = false;

  WordSearchEngine({required this.sfx, required this.onRoundEnd});

  /// Start a fresh round. All previous timers are cancelled first so two
  /// rounds can never interleave.
  void start({required int tier, required int mode, required int category,
      required int hints}) {
    _cancelAll();
    this.tier = tier.clamp(0, 2);
    this.mode = mode.clamp(0, 1);
    this.category = category.clamp(0, WordCategories.names.length - 1);
    gridSize = DifficultyTiers.gridSize[this.tier];
    hintsLeft = hints;
    won = false;
    paused = false;
    elapsed = 0;
    timeLeft = DifficultyTiers.timeLimitSec[this.tier];
    hintCell = null;
    selection = const [];
    _generate();
    dealProgress = 0;
    _setPhase(GamePhase.dealing);
    // Letter tiles flip in one by one — never pop in all at once.
    _dealTimer = Timer.periodic(const Duration(milliseconds: 14), (_) {
      if (_disposed) return;
      _heartbeat++;
      dealProgress++;
      if (dealProgress >= gridSize * gridSize) {
        dealProgress = gridSize * gridSize;
        _dealTimer?.cancel();
        _dealTimer = null;
        _beginPlay();
      }
      notifyListeners();
    });
    _armWatchdog();
  }

  void _generate() {
    final n = gridSize;
    final grid = List<String>.filled(n * n, '');
    final placed = <PlacedWord>[];
    final want = DifficultyTiers.wordCount[tier];
    final maxLen = DifficultyTiers.maxWordLen[tier];
    final bank = WordCategories.pick(category, want + 6, maxLen);
    for (final word in bank) {
      if (placed.length >= want) break;
      bool done = false;
      for (int attempt = 0; attempt < 250 && !done; attempt++) {
        final d = _dirs[_rand.nextInt(_dirs.length)];
        final r = _rand.nextInt(n), c = _rand.nextInt(n);
        final er = r + d[0] * (word.length - 1);
        final ec = c + d[1] * (word.length - 1);
        if (er < 0 || er >= n || ec < 0 || ec >= n) continue;
        bool ok = true;
        for (int k = 0; k < word.length; k++) {
          final existing = grid[(r + d[0] * k) * n + (c + d[1] * k)];
          if (existing.isNotEmpty && existing != word[k]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final cells = <int>[];
        for (int k = 0; k < word.length; k++) {
          final idx = (r + d[0] * k) * n + (c + d[1] * k);
          grid[idx] = word[k];
          cells.add(idx);
        }
        placed.add(PlacedWord(word: word, cells: cells));
        done = true;
      }
    }
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < n * n; i++) {
      if (grid[i].isEmpty) grid[i] = alphabet[_rand.nextInt(alphabet.length)];
    }
    letters = grid;
    words = placed;
  }

  void _setPhase(GamePhase p) {
    phase = p;
    _heartbeat++;
  }

  void _beginPlay() {
    _setPhase(GamePhase.playing);
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || paused || phase != GamePhase.playing) return;
      _heartbeat++;
      if (mode == 0) {
        elapsed++;
      } else {
        timeLeft--;
        if (timeLeft <= 0) {
          timeLeft = 0;
          _finish(false); // time ran out
        }
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Runs for the whole round; cheap enough to be permanent.
  void _armWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || paused) return;
      _recover();
    });
  }

  /// Recover a phase whose timer died: re-arm it from current state.
  void _recover() {
    if (_heartbeat == _lastWatchdogSeen) {
      // No progress since the last check — a phase timer must have died.
      switch (phase) {
        case GamePhase.dealing:
          if (_dealTimer == null || !_dealTimer!.isActive) {
            if (dealProgress < gridSize * gridSize) {
              start(tier: tier, mode: mode, category: category, hints: hintsLeft);
              return;
            }
          }
          break;
        case GamePhase.playing:
          if ((_clockTimer == null || !_clockTimer!.isActive) && !over) {
            _beginPlay();
            return;
          }
          break;
        case GamePhase.reveal:
          if (_revealTimer == null || !_revealTimer!.isActive) {
            _settleReveal();
            return;
          }
          break;
        case GamePhase.over:
          break;
      }
    }
    _lastWatchdogSeen = _heartbeat;
  }

  // -------------------------------------------------------------- selection
  int cellAt(Offset local, Size size) {
    final n = gridSize;
    final cw = size.width / n, ch = size.height / n;
    final c = (local.dx / cw).floor().clamp(0, n - 1);
    final r = (local.dy / ch).floor().clamp(0, n - 1);
    return r * n + c;
  }

  /// Straight line of cells from [a] to [b] (8 directions). [] if not straight.
  List<int> line(int a, int b) {
    final n = gridSize;
    final r0 = a ~/ n, c0 = a % n;
    final r1 = b ~/ n, c1 = b % n;
    final dr = (r1 - r0).sign, dc = (c1 - c0).sign;
    if (!(dr == 0 || dc == 0 || dr.abs() == dc.abs())) return [];
    final len = max((r1 - r0).abs(), (c1 - c0).abs());
    return [for (int k = 0; k <= len; k++) (r0 + dr * k) * n + (c0 + dc * k)];
  }

  void dragStart(int cell) {
    if (phase != GamePhase.playing || paused || over) return;
    selection = [cell];
    sfx('pencil');
    notifyListeners();
  }

  void dragUpdate(int cell) {
    if (phase != GamePhase.playing || paused || over || selection.isEmpty) {
      return;
    }
    final l = line(selection.first, cell);
    if (l.isNotEmpty && l.length != selection.length) {
      selection = l;
      notifyListeners();
    }
  }

  void dragEnd() {
    if (phase != GamePhase.playing || paused || over || selection.isEmpty) {
      selection = const [];
      return;
    }
    final str = selection.map((i) => letters[i]).join();
    final rev = str.split('').reversed.join();
    PlacedWord? hit;
    for (final w in words) {
      if (!w.found && (str == w.word || rev == w.word)) {
        hit = w;
        break;
      }
    }
    if (hit != null) {
      final found = hit;
      _setPhase(GamePhase.reveal);
      selection = const [];
      sfx('found');
      // Animate the ribbon across the word — never pop it instantly.
      var t = 0;
      _revealTimer?.cancel();
      _revealTimer = Timer.periodic(const Duration(milliseconds: 40), (tm) {
        if (_disposed) {
          tm.cancel();
          return;
        }
        _heartbeat++;
        t++;
        found.reveal = (t / 14).clamp(0.0, 1.0);
        notifyListeners();
        if (t >= 14) {
          tm.cancel();
          _revealTimer = null;
          _settleReveal();
        }
      });
    } else {
      selection = const [];
      sfx('invalid');
      notifyListeners();
    }
  }

  /// Settle a finished (or watchdog-recovered) reveal.
  void _settleReveal() {
    _revealTimer?.cancel();
    _revealTimer = null;
    for (final w in words) {
      if (w.reveal > 0) {
        w.found = true;
        w.reveal = 1.0;
      }
    }
    if (words.every((w) => w.found)) {
      won = true;
      _finish(true);
      return;
    }
    _setPhase(GamePhase.playing);
    notifyListeners();
  }

  // ------------------------------------------------------------------ hints
  /// Flash the first letter of a random unfound word.
  void useHint() {
    if (phase != GamePhase.playing || paused || over || hintsLeft <= 0) return;
    final remaining = words.where((w) => !w.found).toList();
    if (remaining.isEmpty) return;
    hintsLeft--;
    final pick = remaining[_rand.nextInt(remaining.length)];
    hintCell = pick.cells.first;
    sfx('hint');
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_disposed) return;
      hintCell = null;
      notifyListeners();
    });
    notifyListeners();
  }

  // -------------------------------------------------------------- pause etc
  void pause() {
    if (over) return;
    paused = true;
    notifyListeners();
  }

  void resume() {
    if (over) return;
    paused = false;
    _heartbeat++;
    // Clock ticks are guarded by [paused]; the watchdog re-arms a dead one.
    _recover();
    notifyListeners();
  }

  void _finish(bool didWin) {
    won = didWin;
    _setPhase(GamePhase.over);
    _clockTimer?.cancel();
    _clockTimer = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    sfx(didWin ? 'win' : 'lose');
    notifyListeners();
    onRoundEnd(won: didWin, seconds: mode == 0 ? elapsed
        : DifficultyTiers.timeLimitSec[tier] - timeLeft, tier: tier);
  }

  void _cancelAll() {
    _dealTimer?.cancel();
    _dealTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
    _revealTimer?.cancel();
    _revealTimer = null;
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAll();
    _watchdog?.cancel();
    _watchdog = null;
    super.dispose();
  }
}
