import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import '../theme/workshop.dart';

/// Settings: music/SFX toggles, volume, stats.
class SettingsScreen extends StatelessWidget {
  final WordSearchAudio audio;
  final WordSearchSettings settings;

  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  WorkshopThemeDef get _t =>
      WorkshopThemes.byId(settings.themeId, custom: settings.customTheme);

  String _fmt(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) => Scaffold(
        backgroundColor: t.paper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ink),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('SETTINGS', style: Workshop.label(15, theme: t)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Workshop.sectionTitle('Sound', theme: t),
              _switchRow(
                t,
                icon: Icons.music_note,
                label: 'Music',
                value: settings.musicOn,
                onChanged: (v) async {
                  await settings.setMusic(v);
                  audio.configure(
                      musicOn: settings.musicOn,
                      sfxOn: settings.sfxOn,
                      volume: settings.volume);
                  if (v) {
                    audio.startMenuMusic();
                  }
                },
              ),
              _switchRow(
                t,
                icon: Icons.volume_up,
                label: 'Sound effects',
                value: settings.sfxOn,
                onChanged: (v) async {
                  await settings.setSfx(v);
                  audio.configure(
                      musicOn: settings.musicOn,
                      sfxOn: settings.sfxOn,
                      volume: settings.volume);
                  if (v) audio.click();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.tune, color: t.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: settings.volume,
                      activeColor: t.accentDark,
                      inactiveColor: t.tileEdge,
                      onChanged: (v) {
                        settings.setVolume(v);
                        audio.configure(
                            musicOn: settings.musicOn,
                            sfxOn: settings.sfxOn,
                            volume: settings.volume);
                      },
                      onChangeEnd: (_) => audio.click(),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      '${(settings.volume * 100).round()}%',
                      style: Workshop.body(14, theme: t),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Workshop.sectionTitle('My stats', theme: t),
              _statRow(t, 'Games played', '${settings.gamesPlayed}'),
              _statRow(t, 'Puzzles solved', '${settings.wins}'),
              for (int i = 0; i < 3; i++)
                _statRow(
                  t,
                  'Best · ${DifficultyTiers.names[i]}',
                  settings.bestTimes[i] > 0
                      ? _fmt(settings.bestTimes[i])
                      : '—',
                ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Word Search · by WAJIHA',
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

  Widget _switchRow(
    WorkshopThemeDef t, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: t.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.tileEdge, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: t.ink),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Workshop.body(16, theme: t))),
          Switch(
            value: value,
            activeThumbColor: t.accentDark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _statRow(WorkshopThemeDef t, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.tile,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.tileEdge, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Workshop.body(15, theme: t))),
          Text(value,
              style: Workshop.body(15, theme: t)
                  .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
