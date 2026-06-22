import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/game/reversi_game.dart';

void main() {
  group('ReversiGame', () {
    test('starts with the standard board and black to move', () {
      final game = ReversiGame.newGame();

      expect(game.currentPlayer, Disc.black);
      expect(game.scoreFor(Disc.black), 2);
      expect(game.scoreFor(Disc.white), 2);
      expect(game.board[3][3], Disc.white);
      expect(game.board[3][4], Disc.black);
      expect(game.board[4][3], Disc.black);
      expect(game.board[4][4], Disc.white);
    });

    test('finds the four legal opening moves for black', () {
      final game = ReversiGame.newGame();

      expect(
        game.validMoves,
        containsAll(
          const [
            Position(2, 3),
            Position(3, 2),
            Position(4, 5),
            Position(5, 4),
          ],
        ),
      );
      expect(game.validMoves.length, 4);
    });

    test('plays a legal move, flips discs, and changes turn', () {
      final game = ReversiGame.newGame();
      final move = game.play(const Position(2, 3));

      expect(move.result.isValid, true);
      expect(move.result.flipped, const [Position(3, 3)]);
      expect(move.game.board[2][3], Disc.black);
      expect(move.game.board[3][3], Disc.black);
      expect(move.game.currentPlayer, Disc.white);
      expect(move.game.scoreFor(Disc.black), 4);
      expect(move.game.scoreFor(Disc.white), 1);
    });

    test('rejects illegal moves without mutating the game', () {
      final game = ReversiGame.newGame();
      final move = game.play(const Position(0, 0));

      expect(move.result.isValid, false);
      expect(identical(move.game, game), true);
      expect(game.scoreFor(Disc.black), 2);
      expect(game.scoreFor(Disc.white), 2);
    });

    test('forces a pass when the next player has no legal move', () {
      final board = List<List<Disc?>>.generate(
        ReversiGame.size,
        (_) => List<Disc?>.filled(ReversiGame.size, Disc.black),
      );
      board[0][0] = null;
      board[0][1] = Disc.white;
      board[7][7] = null;
      board[7][6] = Disc.white;

      final game = ReversiGame.newGame().copyWith(
        board: board,
        currentPlayer: Disc.black,
      );
      final move = game.play(const Position(0, 0));

      expect(move.result.isValid, true);
      expect(move.result.passOccurred, true);
      expect(move.result.gameOver, false);
      expect(move.game.currentPlayer, Disc.black);
      expect(move.game.lastPassPlayer, Disc.white);
      expect(move.game.validMoves, {const Position(7, 7)});
    });

    test('ends the game when neither player has a legal move', () {
      final board = List<List<Disc?>>.generate(
        ReversiGame.size,
        (_) => List<Disc?>.filled(ReversiGame.size, Disc.black),
      );
      board[0][0] = null;
      board[0][1] = Disc.white;

      final game = ReversiGame.newGame().copyWith(
        board: board,
        currentPlayer: Disc.black,
      );
      final move = game.play(const Position(0, 0));

      expect(move.result.isValid, true);
      expect(move.result.gameOver, true);
      expect(move.game.phase, GamePhase.gameOver);
      expect(move.game.winner, Disc.black);
    });

    test('reports a draw when the final score is tied', () {
      final board = List<List<Disc?>>.generate(
        ReversiGame.size,
        (row) => List<Disc?>.generate(
          ReversiGame.size,
          (col) => row < 4 ? Disc.black : Disc.white,
        ),
      );

      final game = ReversiGame.newGame().copyWith(
        board: board,
        phase: GamePhase.gameOver,
      );

      expect(game.scoreFor(Disc.black), 32);
      expect(game.scoreFor(Disc.white), 32);
      expect(game.winner, null);
      expect(game.isDraw, true);
    });
  });
}
