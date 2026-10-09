import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import '../theme/workshop.dart';

/// Custom theme creator (PRO): pick workshop colors and preview live.
class CustomThemeScreen extends StatefulWidget {
  final WordSearchAudio audio;
  final WordSearchSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  static const _swatches = [
    0xFF3B2A1A, 0xFF5C3A21, 0xFF8B5E34, 0xFFC9A86A, 0xFFE9D9B8, 0xFFF5E9CF,
    0xFFA3392B, 0xFFB5502A, 0xFFC0872E, 0xFFC9A227, 0xFF7A9B3F, 0xFF6E7F2E,
    0xFF2E6F8E, 0xFF4A6FA5, 0xFF2E3138, 0xFF23252B, 0xFFF2EEE2, 0xFFFAFCFD,
    0xFF2E8B7A, 0xFFB03A4A, 0xFF6E4A8E, 0xFF2A463E,
  ];

  static const _labels = {
    'paper': 'Paper',
    'paperDeep': 'Backdrop',
    'tile': 'Tile face',
    'tileEdge': 'Tile edge',
    'ink': 'Letter ink',
    'accent': 'Found ribbon',
    'accentDark': 'Found edge',
    'pencil': 'Pencil stroke',
    'soft': 'Cards',
  };

  WorkshopThemeDef get _t => widget.settings.customTheme;

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => Scaffold(
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
          title: Text('MY THEME', style: Workshop.label(15, theme: t)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: t.ink),
              tooltip: 'Reset colors',
              onPressed: () {
                widget.audio.click();
                widget.settings.resetCustomColors();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live preview: a few tiles + a found ribbon sample.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.paperDeep.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.tileEdge, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final ch in ['W', 'O', 'R', 'D'])
                          Container(
                            width: 44,
                            height: 44,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: t.tile,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: t.tileEdge, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.25),
                                  offset: const Offset(0, 3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(ch,
                                style: Workshop.body(20, theme: t).copyWith(
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: t.accentDark, width: 2),
                      ),
                      child: Text('FOUND',
                          style: Workshop.body(13, theme: t).copyWith(
                              color: t.tile,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      width: 160,
                      decoration: BoxDecoration(
                        color: t.pencil.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final key in _labels.keys) _colorRow(key),
              const SizedBox(height: 20),
              Center(
                child: Workshop.woodButton(
                  theme: WorkshopThemes.byId('pine'),
                  label: 'USE THIS THEME',
                  icon: Icons.check,
                  onTap: () {
                    widget.audio.click();
                    widget.settings.setTheme('custom');
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorRow(String key) {
    final t = _t;
    final current = widget.settings.customColors[key] ?? 0xFF000000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_labels[key]!, style: Workshop.body(14, theme: t)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _swatches)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    widget.settings.setCustomColor(key, 0xFF000000 | c);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(0xFF000000 | c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: current == (0xFF000000 | c)
                            ? t.accentDark
                            : Colors.black26,
                        width: current == (0xFF000000 | c) ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
