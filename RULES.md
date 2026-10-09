# Word Search — Rules

## 1. Objective
Find every hidden word in the letter grid by dragging a straight line across
its letters, from the first letter to the last, in any of the 8 directions.
The round ends in victory when all words are found; in Timed mode it ends in
defeat if the countdown reaches zero first.

## 2. Setup
- Choose a difficulty tier: **Cozy** (8×8 grid, 6 words, ≤5 letters),
  **Clever** (10×10, 8 words, ≤7 letters) or **Master** (12×12, 10 words,
  ≤9 letters — PRO).
- Choose a mode: **Relaxed** (timer counts up) or **Timed** (countdown —
  180s / 240s / 300s per tier — PRO).
- Choose a word category (Animals, Food, Nature, Space, Sports, Mixed).
- The engine places words at random positions and directions; empty cells
  are filled with random letters. Tiles flip in one by one (animated deal).

## 3. Turn order
Single-player game; there are no turns. Play proceeds continuously until the
round ends.

## 4. Legal moves
- Press on any letter and drag in a straight line: horizontal, vertical or
  diagonal (8 directions).
- The selection always forms the straight line from the press cell to the
  current drag cell; changing direction mid-drag re-computes the line.
- Release to submit. If the selected letters (forwards or backwards) match
  an unfound hidden word, the word is marked found with an animated ribbon.

## 5. Illegal moves
- Non-straight drags are impossible: the selection snaps to the straight
  line from the press cell, so a bent path can never be submitted.
- Submitting letters that do not match an unfound word: the selection is
  cleared with an "invalid" sound; no penalty.
- Submitting an already-found word: ignored (cleared, invalid sound).
- Input during the deal animation, the found-word reveal, pause, or after
  the round ends is ignored.

## 6. Captures
Not applicable — no captures in Word Search.

## 7. Special rules
- Words may be placed forwards or backwards in any of the 8 directions;
  words may cross and share letters where letters agree.
- **Hints:** each game grants 3 hints (unlimited for PRO). A hint flashes
  the first letter of a random unfound word for 1.5 seconds.
- **Pause:** pausing freezes the clock and all input. The engine watchdog
  never fires a phase transition while paused.
- The deal animation, selection, found-word reveal and hint flash are all
  animated; nothing appears or disappears instantly.

## 8. Scoring
There is no score. Performance is measured by completion time in Relaxed
mode (per-tier best times are kept) and by wins.

## 9. Winning conditions
All hidden words found before time runs out (Relaxed: always achievable —
the only way to stop is quitting). A win plays the win fanfare and records
the game; Relaxed wins update the per-tier best time.

## 10. Draw conditions
Not applicable — no draws.

## 11. AI strategy
Not applicable — no AI opponents in Word Search.

## 12. Edge cases
- A placed word that shares all its letters with crossing words is still
  findable: any drag covering exactly its cells matches it.
- If a word fails to place after 250 random attempts (extremely dense
  grids), it is skipped and the round runs with the placed words; the word
  list always reflects what was actually placed.
- Grid letters are case-consistent (uppercase); matching is exact.
- Timed mode reaching 0:00 ends the round immediately as a loss, even
  mid-drag.

## 13. Test cases
1. Start Cozy/Relaxed/Animals: 8×8 grid, 6 animal words listed, tiles flip
   in one by one, clock counts up.
2. Drag across a listed word forwards: ribbon animates across the cells,
   word chip struck through, count increments, found sound plays.
3. Drag across the same word backwards: also matches.
4. Drag a bent path: selection snaps to a straight line only.
5. Drag letters that form no word: selection clears, invalid sound, no
   penalty.
6. Use a hint: first letter of an unfound word flashes ~1.5s, hint count
   decreases.
7. Find all words: win overlay appears with time; best time updates.
8. Timed mode at 0:00: loss overlay appears; no input accepted afterwards.
9. Pause mid-game: clock freezes; resume continues; no stuck state.
10. Background the app mid-game: music pauses; game shows pause overlay on
    return; engine clock did not advance while backgrounded.
11. Master difficulty / Timed mode / extra categories as a free player:
    locked; tapping opens the PRO screen.
12. Restart mid-round: old timers cancelled, new round deals cleanly, no
    double clocks (watchdog would recover a dead one anyway).
