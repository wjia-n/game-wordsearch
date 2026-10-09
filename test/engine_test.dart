import 'package:flutter_test/flutter_test.dart';
import 'package:wordsearch/engine/wordsearch_engine.dart';

void main() {
  test('deal completes, words are findable, full round wins', () async {
    final sounds = <String>[];
    var ended = false;
    var endedWon = false;
    final e = WordSearchEngine(
      sfx: sounds.add,
      onRoundEnd: ({required bool won, required int seconds, required int tier}) async {
        ended = true;
        endedWon = won;
      },
    );
    e.start(tier: 0, mode: 0, category: 0, hints: 3);
    expect(e.phase, GamePhase.dealing);
    // 8x8 tiles at 14ms each ≈ 0.9s.
    await Future.delayed(const Duration(seconds: 2));
    expect(e.phase, GamePhase.playing);
    expect(e.dealProgress, 64);
    expect(e.words.length, 6);
    // Every placed word's cells actually spell the word in the grid.
    for (final w in e.words) {
      final str = w.cells.map((i) => e.letters[i]).join();
      expect(str == w.word || str.split('').reversed.join() == w.word, isTrue);
    }
    // Straight-line selection math: horizontal line on the 8x8 grid.
    expect(e.line(0, 3), [0, 1, 2, 3]);
    expect(e.line(0, 9), [0, 9]); // diagonal step is a line
    // Find every word by dragging exactly across its cells.
    for (final w in List.of(e.words)) {
      expect(e.phase, GamePhase.playing);
      e.dragStart(w.cells.first);
      e.selection = List.of(w.cells);
      e.dragEnd();
      expect(e.phase, GamePhase.reveal);
      // 14 ticks × 40ms ≈ 560ms reveal animation.
      await Future.delayed(const Duration(milliseconds: 800));
    }
    expect(e.over, isTrue);
    expect(e.won, isTrue);
    expect(ended, isTrue);
    expect(endedWon, isTrue);
    expect(sounds, contains('found'));
    expect(sounds, contains('win'));
    e.dispose();
  });

  test('invalid drag clears selection with no penalty', () async {
    final e = WordSearchEngine(
      sfx: (_) {},
      onRoundEnd: ({required bool won, required int seconds, required int tier}) async {},
    );
    e.start(tier: 0, mode: 0, category: 0, hints: 3);
    await Future.delayed(const Duration(seconds: 2));
    expect(e.phase, GamePhase.playing);
    // Drag a line that cannot be a word (reversed garbage of length 2).
    e.dragStart(0);
    e.selection = [0, 1];
    final before = e.words.where((w) => w.found).length;
    e.dragEnd();
    expect(e.phase, GamePhase.playing);
    expect(e.words.where((w) => w.found).length, before);
    expect(e.selection, isEmpty);
    // Bent drags snap to a straight line.
    e.dragStart(0);
    e.dragUpdate(9); // (1,1) diagonal from (0,0)
    expect(e.selection, [0, 9]);
    e.dispose();
  });
}
