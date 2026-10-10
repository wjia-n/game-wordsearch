import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../engine/wordsearch_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import '../theme/workshop.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — wooden workshop edition.
/// Logo, PLAY, setup (difficulty / mode / category), player renaming,
/// theme + tile-style pickers, share, review, tip jar, settings.
class MenuScreen extends StatefulWidget {
  final WordSearchAudio audio;
  final WordSearchSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  WordSearchSettings get _s => widget.settings;
  WorkshopThemeDef get _t =>
      WorkshopThemes.byId(_s.themeId, custom: _s.customTheme);

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.wordsearch';

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _nameController.text = _s.playerName;
    // Commit the name when focus leaves the field.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        _s.setPlayerName(_nameController.text);
      }
    });
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Workshop.body(15, theme: _t)),
        backgroundColor: _t.paperDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise fall back to opening the store listing. No fake dialogs.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final engine = WordSearchEngine(
      sfx: (name) {
        switch (name) {
          case 'pencil':
            widget.audio.pencil();
          case 'select':
            widget.audio.select();
          case 'found':
            widget.audio.found();
          case 'invalid':
            widget.audio.invalid();
          case 'hint':
            widget.audio.hint();
          case 'win':
            widget.audio.win();
          case 'lose':
            widget.audio.lose();
        }
      },
      onRoundEnd: ({required bool won, required int seconds, required int tier}) async {
        await _s.recordGame(won: won, seconds: seconds, tier: tier);
        // Sensible review moment: every 3rd win.
        if (won && _s.wins % 3 == 0) {
          await _requestReview();
        }
      },
    );
    engine.start(
      tier: _s.difficulty,
      mode: _s.mode,
      category: _s.category,
      hints: _s.isPro ? 99 : 3,
    );
    // App-scoped music: keep playing across screens. GameScreen switches
    // to the game track on entry; we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Scaffold(
      backgroundColor: t.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('WORD SEARCH',
            style: Workshop.label(15, theme: t)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: t.ink),
            tooltip: 'Settings',
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsScreen(
                    audio: widget.audio, settings: _s),
              ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo.
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: t.tileEdge, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/wordsearch_logo.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Text('Find every hidden word.',
                  textAlign: TextAlign.center,
                  style: Workshop.body(15, theme: t)),
              const SizedBox(height: 4),
              if (_s.bestTimes[_s.difficulty] > 0)
                Text(
                  'Best on ${DifficultyTiers.names[_s.difficulty]}: '
                  '${_fmt(_s.bestTimes[_s.difficulty])}',
                  textAlign: TextAlign.center,
                  style: Workshop.body(13,
                      theme: t, color: t.accentDark),
                ),

              Workshop.sectionTitle('Player', theme: t),
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                maxLength: 14,
                // Save on every keystroke (order-preserving JSON string in
                // settings); focus-loss listener commits too.
                onChanged: (v) => _s.setPlayerName(v),
                style: Workshop.body(16, theme: t),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: t.tile,
                  hintText: 'Your name',
                  hintStyle: Workshop.body(14,
                      theme: t, color: t.ink.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check, color: t.accentDark),
                    onPressed: () {
                      _s.setPlayerName(_nameController.text);
                      widget.audio.click();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.tileEdge, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: t.accentDark, width: 2),
                  ),
                ),
                onSubmitted: (v) {
                  _s.setPlayerName(v);
                  widget.audio.click();
                },
              ),

              Workshop.sectionTitle('Difficulty', theme: t),
              Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 4, right: i == 2 ? 0 : 4),
                        child: _choiceChip(
                          label: DifficultyTiers.names[i],
                          sub:
                              '${DifficultyTiers.gridSize[i]}×${DifficultyTiers.gridSize[i]} · ${DifficultyTiers.wordCount[i]} words',
                          selected: _s.difficulty == i,
                          locked:
                              !_s.isPro && DifficultyTiers.isPro(i),
                          onTap: () {
                            widget.audio.click();
                            _s.setDifficulty(i);
                          },
                        ),
                      ),
                    ),
                ],
              ),

              Workshop.sectionTitle('Mode', theme: t),
              Row(
                children: [
                  Expanded(
                    child: _choiceChip(
                      label: 'Relaxed',
                      sub: 'No timer — hunt at your pace',
                      selected: _s.mode == 0,
                      locked: false,
                      onTap: () {
                        widget.audio.click();
                        _s.setMode(0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _choiceChip(
                      label: 'Timed',
                      sub: _s.isPro
                          ? 'Beat the clock!'
                          : 'PRO only',
                      selected: _s.mode == 1,
                      locked: !_s.isPro,
                      onTap: () {
                        widget.audio.click();
                        if (_s.isPro) {
                          _s.setMode(1);
                        } else {
                          _openPro();
                        }
                      },
                    ),
                  ),
                ],
              ),

              Workshop.sectionTitle('Words', theme: t),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < WordCategories.names.length; i++)
                    _categoryChip(i),
                ],
              ),

              Workshop.sectionTitle('Workshop theme', theme: t),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: WorkshopThemes.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final th = WorkshopThemes.all[i];
                    final selected = _s.themeId == th.id;
                    final locked =
                        !_s.isPro && WorkshopThemes.isProTheme(th.id);
                    return GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        if (locked) {
                          _openPro();
                        } else {
                          _s.setTheme(th.id);
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? t.accentDark
                                    : th.tileEdge,
                                width: selected ? 3 : 1.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: t.accentDark
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: [
                                      Expanded(
                                          child:
                                              Container(color: th.paper)),
                                      Expanded(
                                          child:
                                              Container(color: th.tile)),
                                    ],
                                  ),
                                ),
                                if (locked)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      color: Colors.black
                                          .withValues(alpha: 0.45),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.lock,
                                          size: 20, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 70,
                            child: Text(
                              th.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Workshop.body(11, theme: t),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              // Custom theme creator (PRO).
              OutlinedButton.icon(
                icon: Icon(Icons.palette,
                    size: 18,
                    color: _s.isPro ? t.accentDark : t.ink.withValues(alpha: 0.5)),
                label: Text(
                  _s.themeId == 'custom'
                      ? 'Custom theme: My Creation'
                      : _s.isPro
                          ? 'Design my own theme'
                          : 'Custom theme (PRO)',
                  style: Workshop.body(14, theme: t),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.tileEdge, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.audio.click();
                  if (!_s.isPro) {
                    _openPro();
                    return;
                  }
                  Navigator.of(context)
                      .push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                        audio: widget.audio, settings: _s),
                  ))
                      .then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),

              Workshop.sectionTitle('Tile style', theme: t),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < TileStyles.names.length; i++)
                    _styleChip(i),
                ],
              ),

              const SizedBox(height: 26),
              Center(
                child: Workshop.woodButton(
                  theme: t,
                  label: 'START HUNTING',
                  icon: Icons.play_arrow,
                  fontSize: 19,
                  onTap: _play,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Workshop.woodIconButton(
                    theme: t,
                    icon: Icons.workspace_premium,
                    tooltip: 'Word Search PRO',
                    onTap: _openPro,
                  ),
                  const SizedBox(width: 14),
                  Workshop.woodIconButton(
                    theme: t,
                    icon: Icons.share,
                    tooltip: 'Share',
                    onTap: () async {
                      widget.audio.click();
                      await SharePlus.instance.share(
                        ShareParams(
                          text: 'I\'m hunting hidden words in Word Search — '
                              'can you beat my time? $_storeUrl',
                          subject: 'Word Search',
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Workshop.woodIconButton(
                    theme: t,
                    icon: Icons.star_rate,
                    tooltip: 'Rate us',
                    onTap: () {
                      widget.audio.click();
                      _requestReview();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Wins: ${_s.wins} · Games: ${_s.gamesPlayed}',
                  style: Workshop.body(13,
                      theme: t, color: t.ink.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  void _openPro() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ));
  }

  Widget _choiceChip({
    required String label,
    required String sub,
    required bool selected,
    required bool locked,
    required VoidCallback onTap,
  }) {
    final t = _t;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.accent.withValues(alpha: 0.25) : t.tile,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.accentDark : t.tileEdge,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked) ...[
                  Icon(Icons.lock,
                      size: 13, color: t.ink.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Workshop.body(15, theme: t),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: Workshop.body(10,
                  theme: t, color: t.ink.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(int i) {
    final t = _t;
    final locked = !_s.isPro && WordCategories.isPro(i);
    final selected = _s.category == i;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (locked) {
          _openPro();
        } else {
          _s.setCategory(i);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accent.withValues(alpha: 0.3) : t.tile,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? t.accentDark : t.tileEdge,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(Icons.lock,
                  size: 13, color: t.ink.withValues(alpha: 0.6)),
              const SizedBox(width: 5),
            ],
            Text(WordCategories.names[i],
                style: Workshop.body(13, theme: t)),
          ],
        ),
      ),
    );
  }

  Widget _styleChip(int i) {
    final t = _t;
    final locked = !_s.isPro && TileStyles.isPro(i);
    final selected = _s.tileStyle == i;
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (locked) {
          _openPro();
        } else {
          _s.setTileStyle(i);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? t.accent.withValues(alpha: 0.3) : t.soft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? t.accentDark : t.tileEdge,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(Icons.lock,
                  size: 12, color: t.ink.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
            ],
            Text(TileStyles.names[i], style: Workshop.body(12, theme: t)),
          ],
        ),
      ),
    );
  }
}
