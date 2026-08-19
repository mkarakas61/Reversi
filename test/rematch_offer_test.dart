import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/online_game.dart';

// REV-98. The client reads the rematch offer straight off the game document
// both players already stream, so the parsing and the "is this offer still
// standing?" question are the whole client-side contract. Everything the
// buttons do keys off `isLive` and `offeredBy`.

const _alice = 'uid-alice';
const _bob = 'uid-bob';

Map<String, dynamic> _doc({Map<String, dynamic>? rematch}) => {
      'board': '-' * 64,
      'currentPlayer': 'black',
      'players': {'black': _alice, 'white': _bob},
      'playerUids': [_alice, _bob],
      'status': 'finished',
      'winner': 'black',
      'moveCount': 60,
      if (rematch != null) 'rematch': rematch,
    };

Timestamp _inSeconds(int s) =>
    Timestamp.fromDate(DateTime.now().add(Duration(seconds: s)));

void main() {
  group('RematchOffer parsing', () {
    test('a game with no rematch field has no offer', () {
      expect(OnlineGame.fromDoc('g', _doc()).rematch, isNull);
    });

    test('a malformed offer is ignored rather than crashing the result card', () {
      // Missing `by`, and an unknown status: a bad document must not take the
      // end-of-game screen down with it.
      expect(OnlineGame.fromDoc('g', _doc(rematch: {'status': 'pending'})).rematch,
          isNull);
      expect(
          OnlineGame.fromDoc('g', _doc(rematch: {'by': _bob, 'status': 'huh'}))
              .rematch,
          isNull);
    });

    test('reads who offered, the status and the new game id', () {
      final g = OnlineGame.fromDoc(
        'g',
        _doc(rematch: {
          'by': _bob,
          'status': 'accepted',
          'gameId': 'game-2',
        }),
      );
      final r = g.rematch!;
      expect(r.by, _bob);
      expect(r.status, RematchStatus.accepted);
      expect(r.gameId, 'game-2');
      expect(r.offeredBy(_bob), isTrue);
      expect(r.offeredBy(_alice), isFalse);
    });
  });

  group('RematchOffer.isLive', () {
    test('a pending offer with time left is live', () {
      final r = OnlineGame.fromDoc(
        'g',
        _doc(rematch: {
          'by': _bob,
          'status': 'pending',
          'expiresAt': _inSeconds(30),
        }),
      ).rematch!;
      expect(r.isLive, isTrue);
      expect(r.isExpired, isFalse);
      expect(r.secondsLeft, greaterThan(0));
    });

    test('a pending offer past its expiry is not live', () {
      // Otherwise the card would sit waiting on an answer nobody will give.
      final r = OnlineGame.fromDoc(
        'g',
        _doc(rematch: {
          'by': _bob,
          'status': 'pending',
          'expiresAt': _inSeconds(-1),
        }),
      ).rematch!;
      expect(r.isExpired, isTrue);
      expect(r.isLive, isFalse);
      expect(r.secondsLeft, 0, reason: 'countdown must not go negative');
    });

    test('declined and accepted offers are never live', () {
      for (final status in const ['declined', 'accepted']) {
        final r = OnlineGame.fromDoc(
          'g',
          _doc(rematch: {
            'by': _bob,
            'status': status,
            'expiresAt': _inSeconds(30),
          }),
        ).rematch!;
        expect(r.isLive, isFalse, reason: '$status must not read as standing');
      }
    });

    test('an offer with no expiry never lapses', () {
      // Defensive: a document written before expiresAt existed must not read as
      // already expired, which would disable the feature for it.
      final r = OnlineGame.fromDoc(
        'g',
        _doc(rematch: {'by': _bob, 'status': 'pending'}),
      ).rematch!;
      expect(r.isExpired, isFalse);
      expect(r.isLive, isTrue);
    });
  });
}
