import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/reversi_game.dart';
import 'package:reversi/models/online_game.dart';

void main() {
  group('board codec', () {
    test('encode then decode round-trips the opening position', () {
      final board = ReversiGame.newGame().board;
      final encoded = encodeBoard(board);
      expect(encoded.length, 64);
      final decoded = decodeBoard(encoded);
      for (var r = 0; r < ReversiGame.size; r++) {
        for (var c = 0; c < ReversiGame.size; c++) {
          expect(decoded[r][c], board[r][c]);
        }
      }
    });

    test('encodes discs and empties as b/w/-', () {
      final encoded = encodeBoard(ReversiGame.newGame().board);
      // 4 starting discs, 60 empties.
      expect('-'.allMatches(encoded).length, 60);
      expect('b'.allMatches(encoded).length, 2);
      expect('w'.allMatches(encoded).length, 2);
      // Center layout: (3,3)=w (3,4)=b (4,3)=b (4,4)=w.
      expect(encoded[3 * 8 + 3], 'w');
      expect(encoded[3 * 8 + 4], 'b');
      expect(encoded[4 * 8 + 3], 'b');
      expect(encoded[4 * 8 + 4], 'w');
    });

    test('survives a played move via the engine', () {
      final start = ReversiGame.newGame();
      final played = start.play(const Position(2, 3)).game; // a legal opening
      final restored = ReversiGame.restore(
        board: decodeBoard(encodeBoard(played.board)),
        currentPlayer: played.currentPlayer,
      );
      expect(encodeBoard(restored.board), encodeBoard(played.board));
      expect(restored.scoreFor(Disc.black), played.scoreFor(Disc.black));
      expect(restored.scoreFor(Disc.white), played.scoreFor(Disc.white));
    });
  });

  group('OnlineGame.fromDoc', () {
    test('parses players, colors and status', () {
      final g = OnlineGame.fromDoc('g1', {
        'board': encodeBoard(ReversiGame.newGame().board),
        'currentPlayer': 'black',
        'players': {'black': 'uidA', 'white': 'uidB'},
        'playerUids': ['uidA', 'uidB'],
        'playerInfo': {
          'uidA': {'name': 'Ada'},
          'uidB': {'name': 'Bora'},
        },
        'status': 'active',
        'moveCount': 0,
      });
      expect(g.blackUid, 'uidA');
      expect(g.whiteUid, 'uidB');
      expect(g.colorFor('uidA'), Disc.black);
      expect(g.colorFor('uidB'), Disc.white);
      expect(g.opponentUid('uidA'), 'uidB');
      expect(g.isFinished, false);
      expect(g.game.currentPlayer, Disc.black);
    });

    test('parses a finished game with a winner', () {
      final g = OnlineGame.fromDoc('g2', {
        'board': encodeBoard(ReversiGame.newGame().board),
        'currentPlayer': 'white',
        'players': {'black': 'uidA', 'white': 'uidB'},
        'playerUids': ['uidA', 'uidB'],
        'status': 'finished',
        'winner': 'white',
        'moveCount': 30,
      });
      expect(g.isFinished, true);
      expect(g.winner, Disc.white);
      expect(g.isDraw, false);
    });

    test('falls back to the opening board when board is missing', () {
      final g = OnlineGame.fromDoc('g3', {
        'currentPlayer': 'black',
        'players': {'black': 'uidA', 'white': 'uidB'},
        'playerUids': ['uidA', 'uidB'],
        'status': 'active',
      });
      expect(
          encodeBoard(g.game.board), encodeBoard(ReversiGame.newGame().board));
    });
  });
}
