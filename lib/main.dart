import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const WordSearchApp());

class WordSearchApp extends StatelessWidget {
  const WordSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.zenStone,
      title: 'Word Search',
      tagline: 'Find hidden words in themed letter grids!',
      emoji: '🔍',
      slug: 'wordsearch',
      howToPlay:
          '• 8 sneaky animal names are hiding in the letter jungle. 🦁\n• Press on a letter and DRAG across it — go straight in any direction (even diagonally!).\n• Release on the last letter: if it\'s a word, it lights up and gets crossed off.\n• Words can run forwards, backwards, up, down or diagonal. Tricky!\n• Find all 8 as fast as you can — the clock is ticking! ⏱️',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => WordSearchScreen(players: players, callbacks: cb),
    );
  }
}
