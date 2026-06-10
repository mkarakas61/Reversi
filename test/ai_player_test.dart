import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/ai_player.dart';
import 'package:reversi/game/game_settings.dart';
import 'package:reversi/game/reversi_game.dart';

ReversiGame _selfPlay(ReversiAi black, ReversiAi white) {
  var game = ReversiGame.newGame();
  var guard = 0;
  while (game.phase == GamePhase.playing && guard < 200) {
    final ai = game.currentPlayer == Disc.black ? black : white;
    final move = ai.chooseMove(game);
    expect(game.validMoves, contains(move));
    game = game.play(move).game;
    guard++;
  }
  expect(game.phase, GamePhase.gameOver);
  return game;
}

void main() {
  group('ReversiAi', () {
    test('every difficulty returns a legal move from the opening position',
        () {
      for (final difficulty in Difficulty.values) {
        final ai = ReversiAi(difficulty: difficulty, random: Random(1));
        final game = ReversiGame.newGame();
        final move = ai.chooseMove(game);
        expect(game.validMoves, contains(move),
            reason: 'illegal move for $difficulty');
      }
    });

    test('easy AI plays a full self-play game with only legal moves', () {
      final game = _selfPlay(
        ReversiAi(difficulty: Difficulty.easy, random: Random(7)),
        ReversiAi(difficulty: Difficulty.easy, random: Random(8)),
      );
      expect(game.phase, GamePhase.gameOver);
    });

    test('normal AI beats easy AI', () {
      final game = _selfPlay(
        ReversiAi(difficulty: Difficulty.easy, random: Random(11)),
        ReversiAi(difficulty: Difficulty.normal, random: Random(12)),
      );
      expect(game.winner, Disc.white,
          reason: 'normal (white) should beat easy (black): '
              '${game.scoreFor(Disc.black)}-${game.scoreFor(Disc.white)}');
    });

    // Also exercises the exact endgame search, which kicks in for the
    // last 12 empty squares of a full game.
    test('hard AI beats easy AI', () {
      final game = _selfPlay(
        ReversiAi(difficulty: Difficulty.easy, random: Random(0)),
        ReversiAi(difficulty: Difficulty.hard, random: Random(100)),
      );
      expect(game.winner, Disc.white,
          reason: 'hard (white) should beat easy (black): '
              '${game.scoreFor(Disc.black)}-${game.scoreFor(Disc.white)}');
    });
  });
}
