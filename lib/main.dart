import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/wordsearch_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = WordSearchSettings();
  await settings.load();
  final audio = WordSearchAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(WordSearchApp(settings: settings, audio: audio));
}

class WordSearchApp extends StatefulWidget {
  final WordSearchSettings settings;
  final WordSearchAudio audio;
  const WordSearchApp({super.key, required this.settings, required this.audio});

  @override
  State<WordSearchApp> createState() => _WordSearchAppState();
}

class _WordSearchAppState extends State<WordSearchApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = WorkshopThemes.byId(
          widget.settings.themeId,
          custom: widget.settings.customTheme,
        );
        return MaterialApp(
          title: 'Word Search',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.paper,
            colorScheme: ColorScheme.fromSeed(seedColor: theme.accent),
            useMaterial3: true,
          ),
          home: SplashScreen(audio: widget.audio, settings: widget.settings),
        );
      },
    );
  }
}
