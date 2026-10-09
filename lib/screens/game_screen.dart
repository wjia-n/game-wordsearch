import 'package:flutter/material.dart';
import '../engine/wordsearch_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import '../theme/workshop.dart';

/// Word Search game screen: the engine owns all state; this widget only
/// paints it. Pseudo-3D wooden tiles, animated deal-in, selection stroke,
/// found-word ribbons, hint flash, pause and result overlays.
class GameScreen extends StatefulWidget {
  final WordSearchEngine engine;
  final WordSearchAudio audio;
  final WordSearchSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  WordSearchEngine get _e => widget.engine;
  WorkshopThemeDef get _t =>
      WorkshopThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.startGameMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine on interruption; the user resumes from the overlay.
    if (state == AppLifecycleState.paused) {
      _e.pause();
    }
  }

  void _restart() {
    widget.audio.click();
    _e.start(
      tier: widget.settings.difficulty,
      mode: widget.settings.mode,
      category: widget.settings.category,
      hints: widget.settings.isPro ? 99 : 3,
    );
  }

  String get _clock {
    if (_e.mode == 1) {
      final s = _e.timeLeft;
      return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    }
    final s = _e.elapsed;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ListenableBuilder(
      listenable: _e,
      builder: (_, _) {
        return Scaffold(
          backgroundColor: t.paper,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: t.ink),
              onPressed: () {
                widget.audio.click();
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              DifficultyTiers.names[_e.tier],
              style: Workshop.label(15, theme: t),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.restart_alt, color: t.ink),
                tooltip: 'New puzzle',
                onPressed: _restart,
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    children: [
                      _hudRow(t),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 7,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: LayoutBuilder(
                              builder: (ctx, c) {
                                final size = Size(c.maxWidth, c.maxHeight);
                                return GestureDetector(
                                  onPanStart: (d) =>
                                      _e.dragStart(_e.cellAt(d.localPosition, size)),
                                  onPanUpdate: (d) =>
                                      _e.dragUpdate(_e.cellAt(d.localPosition, size)),
                                  onPanEnd: (_) => _e.dragEnd(),
                                  child: CustomPaint(
                                    size: size,
                                    painter: _BoardPainter(
                                      engine: _e,
                                      theme: t,
                                      style: widget.settings.tileStyle,
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
                            children: [
                              for (final w in _e.words) _wordChip(w, t),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_e.paused && !_e.over) _pauseOverlay(t),
                if (_e.over) _resultOverlay(t),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hudRow(WorkshopThemeDef t) {
    final lowTime = _e.mode == 1 && _e.timeLeft <= 30;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pill(
          t,
          icon: _e.mode == 1 ? Icons.timer : Icons.hourglass_bottom,
          text: _clock,
          danger: lowTime,
        ),
        const SizedBox(width: 10),
        _pill(
          t,
          icon: Icons.search,
          text: '${_e.words.where((w) => w.found).length}/${_e.words.length}',
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _e.useHint(),
          child: _pill(
            t,
            icon: Icons.lightbulb,
            text: _e.hintsLeft >= 99 ? '∞' : '${_e.hintsLeft}',
            dim: _e.hintsLeft <= 0,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            widget.audio.click();
            _e.pause();
          },
          child: _pill(t, icon: Icons.pause, text: ''),
        ),
      ],
    );
  }

  Widget _pill(WorkshopThemeDef t,
      {required IconData icon, required String text, bool danger = false, bool dim = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: text.isEmpty ? 10 : 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.tile, t.soft],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: danger ? Colors.red.shade700 : t.tileEdge, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 17,
              color: danger
                  ? Colors.red.shade700
                  : t.ink.withValues(alpha: dim ? 0.4 : 1)),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: Workshop.body(15, theme: t).copyWith(
                color: danger
                    ? Colors.red.shade700
                    : t.ink.withValues(alpha: dim ? 0.4 : 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _wordChip(PlacedWord w, WorkshopThemeDef t) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: w.found ? t.accent.withValues(alpha: 0.28) : t.tile,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: w.found ? t.accentDark : t.tileEdge,
          width: w.found ? 2 : 1.5,
        ),
      ),
      child: Text(
        w.word,
        style: Workshop.body(13, theme: t).copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
          color: w.found ? t.accentDark : t.ink,
          decoration: w.found ? TextDecoration.lineThrough : TextDecoration.none,
          decorationThickness: 2,
        ),
      ),
    );
  }

  Widget _pauseOverlay(WorkshopThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.tileEdge, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused', style: Workshop.display(30, theme: t)),
              const SizedBox(height: 8),
              Text('The tiles are waiting…',
                  style: Workshop.body(14, theme: t)),
              const SizedBox(height: 20),
              Workshop.woodButton(
                theme: t,
                label: 'RESUME',
                icon: Icons.play_arrow,
                onTap: () {
                  widget.audio.click();
                  _e.resume();
                },
              ),
              const SizedBox(height: 10),
              Workshop.woodButton(
                theme: t,
                label: 'NEW PUZZLE',
                icon: Icons.refresh,
                onTap: _restart,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
                child: Text('Quit to menu',
                    style: Workshop.body(14, theme: t)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultOverlay(WorkshopThemeDef t) {
    final won = _e.won;
    final secs = _e.mode == 0
        ? _e.elapsed
        : DifficultyTiers.timeLimitSec[_e.tier] - _e.timeLeft;
    final best = widget.settings.bestTimes[_e.tier.clamp(0, 2)];
    final isRecord = won && secs > 0 && (best == 0 || secs <= best);
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: t.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.accentDark, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                won ? Icons.emoji_events : Icons.hourglass_empty,
                size: 56,
                color: won ? t.accentDark : t.ink.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                won ? 'Puzzle complete!' : 'Time ran out!',
                style: Workshop.display(28, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? '${widget.settings.playerName} found all ${_e.words.length} words in $secs seconds.'
                    : 'You found ${_e.words.where((w) => w.found).length}/${_e.words.length} words. Try Relaxed mode for no timer!',
                style: Workshop.body(14, theme: t),
                textAlign: TextAlign.center,
              ),
              if (isRecord) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.accentDark),
                  ),
                  child: Text('NEW BEST TIME!',
                      style: Workshop.body(13, theme: t)
                          .copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
              const SizedBox(height: 20),
              Workshop.woodButton(
                theme: t,
                label: 'PLAY AGAIN',
                icon: Icons.refresh,
                onTap: _restart,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
                child: Text('Back to menu',
                    style: Workshop.body(14, theme: t)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Board painter: pseudo-3D wooden tiles with bevels, selection pencil stroke,
// animated found-word ribbons, deal-in flip animation and hint pulse.
// ---------------------------------------------------------------------------
class _BoardPainter extends CustomPainter {
  final WordSearchEngine engine;
  final WorkshopThemeDef theme;
  final int style;

  _BoardPainter(
      {required this.engine, required this.theme, required this.style});

  static final Map<String, TextPainter> _letterCache = {};

  TextPainter _letter(String ch, double fontSize, Color color) {
    final key = '$ch|$fontSize|${color.toARGB32()}';
    return _letterCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = engine.gridSize;
    final m = 6.0; // board margin inside the paint area
    final bw = size.width - m * 2;
    final cell = bw / n;

    // Board panel: wooden frame with depth.
    final panel = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16));
    canvas.drawShadow(
        Path()..addRRect(panel), Colors.black.withValues(alpha: 0.4), 12, true);
    canvas.drawRRect(
        panel,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.tileEdge, theme.paperDeep],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(m * 0.6, m * 0.6, size.width - m * 1.2,
            size.height - m * 1.2),
        const Radius.circular(12));
    canvas.drawRRect(inner, Paint()..color = theme.paperDeep.withValues(alpha: 0.35));

    final styleDef = TileStyles.face[style.clamp(0, TileStyles.face.length - 1)];
    final radius = (styleDef['radius'] as int).toDouble();
    final faceColor = (styleDef['tile'] as int) == 0
        ? theme.tile
        : Color(styleDef['tile'] as int);
    final edgeColor = (styleDef['edge'] as int) == 0
        ? theme.tileEdge
        : Color(styleDef['edge'] as int);

    Offset centerOf(int i) => Offset(
        m + (i % n) * cell + cell / 2, m + (i ~/ n) * cell + cell / 2);

    // Found-cell lookup for letter contrast.
    final foundCells = <int>{};
    for (final w in engine.words) {
      if (w.found) foundCells.addAll(w.cells);
    }
    final sel = engine.selection.toSet();

    // 1) Tiles.
    for (int i = 0; i < n * n; i++) {
      final cx = m + (i % n) * cell;
      final cy = m + (i ~/ n) * cell;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 1.5, cy + 1.5, cell - 3, cell - 3),
          Radius.circular(radius * (cell / 48).clamp(0.5, 1.2)));
      final dealt = i < engine.dealProgress;
      if (!dealt) {
        // Face-down tile back.
        canvas.drawRRect(rect, Paint()..color = edgeColor);
        canvas.drawRRect(
            rect,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        continue;
      }
      // Bevel: light top-left, dark bottom-right.
      canvas.drawRRect(rect, Paint()..color = edgeColor);
      final face = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 3.5, cy + 3.5, cell - 7, cell - 7),
          Radius.circular(radius * (cell / 48).clamp(0.5, 1.2)));
      canvas.drawRRect(
          face,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [faceColor, Color.lerp(faceColor, edgeColor, 0.35)!],
            ).createShader(Rect.fromLTWH(cx, cy, cell, cell)));
      // Hint pulse on the hint cell.
      if (engine.hintCell == i) {
        final t = DateTime.now().millisecondsSinceEpoch / 300;
        final pulse = 0.35 + 0.3 * (0.5 + 0.5 * (t % (2 * 3.14159)));
        canvas.drawRRect(
            face, Paint()..color = theme.accent.withValues(alpha: pulse));
      }
    }

    // 2) Found ribbons (animated reveal sweep).
    for (final w in engine.words) {
      if (!w.found && w.reveal <= 0) continue;
      final prog = w.found ? 1.0 : w.reveal;
      final count = (w.cells.length * prog).ceil().clamp(1, w.cells.length);
      final pts = [for (int k = 0; k < count; k++) centerOf(w.cells[k])];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = theme.accent.withValues(alpha: 0.85)
            ..strokeWidth = cell * 0.72
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
      canvas.drawPath(
          path,
          Paint()
            ..color = theme.accentDark.withValues(alpha: 0.9)
            ..strokeWidth = cell * 0.72
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round);
      // Dark inner line for carved look.
      canvas.drawPath(
          path,
          Paint()
            ..color = theme.accent.withValues(alpha: 0.85)
            ..strokeWidth = cell * 0.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }

    // 3) Selection pencil stroke.
    if (engine.selection.isNotEmpty) {
      final path = Path();
      final c0 = centerOf(engine.selection.first);
      path.moveTo(c0.dx, c0.dy);
      for (final i in engine.selection.skip(1)) {
        final c = centerOf(i);
        path.lineTo(c.dx, c.dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = theme.pencil.withValues(alpha: 0.55)
            ..strokeWidth = cell * 0.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }

    // 4) Letters.
    final fontSize = cell * 0.52;
    for (int i = 0; i < n * n; i++) {
      if (i >= engine.dealProgress) continue;
      final isFound = foundCells.contains(i);
      final isSel = sel.contains(i);
      final color = isFound
          ? theme.tile
          : isSel
              ? theme.paperDeep
              : theme.ink;
      final tp = _letter(engine.letters[i], fontSize, color);
      final c = centerOf(i);
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
