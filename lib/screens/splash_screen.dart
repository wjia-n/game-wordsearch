import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/wordsearch_themes.dart';
import 'menu_screen.dart';

/// Launch splash: game logo + name, animated loading line, and credits.
/// (Single splash only — the WAJIHA company logo appears in the credits row.)
class SplashScreen extends StatefulWidget {
  final WordSearchAudio audio;
  final WordSearchSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = WorkshopThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.paperDeep,
      body: _GameSplash(theme: theme, loader: _loader),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final WorkshopThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.paperDeep, const Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  Image.asset('assets/wordsearch_logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text(
              'Word Search',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: theme.tile,
                letterSpacing: 1,
                shadows: const [
                  Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'THE WOODEN LETTER HUNT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: theme.accent,
              ),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: theme.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loader.value < 1 ? 'Carving the tiles…' : 'Ready!',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.tile.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.tile.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
