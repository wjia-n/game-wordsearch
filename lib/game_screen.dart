import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Word Search — drag across letters to hunt 8 hidden animal names.
class WordSearchScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const WordSearchScreen({super.key, required this.players, required this.callbacks});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  static const _n = 10;
  static const _words = [
    'LION', 'TIGER', 'ZEBRA', 'PANDA', 'KOALA', 'OTTER', 'LLAMA', 'SLOTH'
  ];
  static const _dirs = [
    [0, 1], [1, 0], [1, 1], [1, -1],
    [0, -1], [-1, 0], [-1, -1], [-1, 1],
  ];

  final _rand = Random();
  late List<String> grid; // 100 letters
  final Map<String, List<int>> placements = {}; // word -> cell indices
  final Set<String> found = {};
  final Set<int> foundCells = {};
  List<int> selection = [];
  Timer? _clock;
  int seconds = 0;
  bool over = false;

  @override
  void initState() {
    super.initState();
    _generate();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || over) return;
      setState(() => seconds++);
    });
  }

  void _generate() {
    grid = List.filled(_n * _n, '');
    for (final word in _words) {
      bool placed = false;
      for (int attempt = 0; attempt < 200 && !placed; attempt++) {
        final d = _dirs[_rand.nextInt(_dirs.length)];
        final r = _rand.nextInt(_n), c = _rand.nextInt(_n);
        final er = r + d[0] * (word.length - 1);
        final ec = c + d[1] * (word.length - 1);
        if (er < 0 || er >= _n || ec < 0 || ec >= _n) continue;
        bool ok = true;
        for (int k = 0; k < word.length; k++) {
          final rr = r + d[0] * k, cc = c + d[1] * k;
          final existing = grid[rr * _n + cc];
          if (existing.isNotEmpty && existing != word[k]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final cells = <int>[];
        for (int k = 0; k < word.length; k++) {
          final rr = r + d[0] * k, cc = c + d[1] * k;
          grid[rr * _n + cc] = word[k];
          cells.add(rr * _n + cc);
        }
        placements[word] = cells;
        placed = true;
      }
    }
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < _n * _n; i++) {
      if (grid[i].isEmpty) grid[i] = letters[_rand.nextInt(letters.length)];
    }
  }

  int _cellAt(Offset local, Size size) {
    final cw = size.width / _n, ch = size.height / _n;
    final c = (local.dx / cw).floor().clamp(0, _n - 1);
    final r = (local.dy / ch).floor().clamp(0, _n - 1);
    return r * _n + c;
  }

  /// Straight line of cells from [a] to [b] (8 directions). [] if not straight.
  List<int> _line(int a, int b) {
    final r0 = a ~/ _n, c0 = a % _n;
    final r1 = b ~/ _n, c1 = b % _n;
    final dr = (r1 - r0).sign, dc = (c1 - c0).sign;
    if (!(dr == 0 || dc == 0 || dr.abs() == dc.abs())) return [];
    final len = max((r1 - r0).abs(), (c1 - c0).abs());
    return [for (int k = 0; k <= len; k++) (r0 + dr * k) * _n + (c0 + dc * k)];
  }

  void _onStart(Offset local, Size size) {
    if (over) return;
    setState(() => selection = [_cellAt(local, size)]);
    Sfx.tap();
  }

  void _onMove(Offset local, Size size) {
    if (over || selection.isEmpty) return;
    final line = _line(selection.first, _cellAt(local, size));
    if (line.isNotEmpty) setState(() => selection = line);
  }

  void _onEnd() {
    if (over || selection.isEmpty) return;
    final str = selection.map((i) => grid[i]).join();
    final rev = str.split('').reversed.join();
    String? hit;
    for (final w in _words) {
      if (!found.contains(w) && (str == w || rev == w)) {
        hit = w;
        break;
      }
    }
    if (hit != null) {
      setState(() {
        found.add(hit!);
        foundCells.addAll(placements[hit]!);
        selection = [];
      });
      Sfx.move();
      widget.players[0].score = found.length;
      widget.callbacks.refreshHud();
      if (found.length == _words.length) _finish();
    } else {
      setState(() => selection = []);
      Sfx.tap();
    }
  }

  void _finish() {
    setState(() => over = true);
    _clock?.cancel();
    Sfx.win();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    widget.callbacks.finish(
      headline: 'All 8 words found! 🔍',
      subline: 'Time: $mm:$ss — certified word wizard 🧙',
    );
  }

  String get _time =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final me = widget.players[0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: t.radius,
                  border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Text('⏱️ $_time',
                    style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: t.radius,
                  border: Border.all(color: t.primary.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Text('${found.length}/8 🦁',
                    style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    final size = Size(c.maxWidth, c.maxHeight);
                    return GestureDetector(
                      onPanStart: (d) => _onStart(d.localPosition, size),
                      onPanUpdate: (d) => _onMove(d.localPosition, size),
                      onPanEnd: (_) => _onEnd(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: t.radius,
                          boxShadow: [
                            BoxShadow(
                              color: t.primary.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _n,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: _n * _n,
                          itemBuilder: (_, i) => _cell(i, t, me),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _words.map((w) => _wordChip(w, t, me)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _cell(int i, GameTheme t, Player me) {
    final isFound = foundCells.contains(i);
    final isSel = selection.contains(i);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: isFound
            ? t.accent.withValues(alpha: 0.85)
            : isSel
                ? me.color.withValues(alpha: 0.55)
                : t.background,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        grid[i],
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: isFound ? t.background : t.text,
        ),
      ),
    );
  }

  Widget _wordChip(String w, GameTheme t, Player me) {
    final isFound = found.contains(w);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFound ? t.accent.withValues(alpha: 0.2) : t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFound ? t.accent : t.muted.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Text(
        w,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: isFound ? t.accent : t.text,
          decoration: isFound ? TextDecoration.lineThrough : TextDecoration.none,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
