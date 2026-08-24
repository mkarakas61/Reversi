import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/l10n/app_strings.dart';

// The join window (REV-114). A matched game now waits for both players instead
// of starting on the spot, because one of them may have been notified with the
// app closed. Two things are worth pinning down without a device: that the app
// and the server agree on the shape of the notification, and that the screen
// has words for every state the window can be in.
void main() {
  final serverSource =
      File('functions/src/match_join.ts').readAsStringSync();
  final pushSource = File('functions/src/push.ts').readAsStringSync();

  group('client and server agree', () {
    test('the app opens the match named in the push payload', () {
      // The server sends {type: "match_found", gameId}; the app reads exactly
      // those two keys. A rename on one side alone makes every notification
      // open nothing at all, silently.
      final client =
          File('lib/core/services/notification_service.dart').readAsStringSync();
      expect(client.contains("data['type'] != 'match_found'"), isTrue);
      expect(client.contains("data['gameId']"), isTrue);

      final matchmaking =
          File('functions/src/matchmaking.ts').readAsStringSync();
      expect(matchmaking.contains('type: "match_found"'), isTrue);
      expect(matchmaking.contains('gameId: pairing.gameId'), isTrue);
    });

    test('the callables the app calls are the ones the server exports', () {
      final index = File('functions/src/index.ts').readAsStringSync();
      final service =
          File('lib/core/services/match_join_service.dart').readAsStringSync();
      for (final name in ['joinGame', 'leavePendingGame', 'abandonPendingGame']) {
        expect(service.contains("httpsCallable('$name')"), isTrue,
            reason: 'the app never calls $name');
        expect(index.contains(name), isTrue,
            reason: '$name is not exported from index.ts');
      }
    });

    test('a matched game opens pending, not active', () {
      // The whole point: a game that started the instant it was created would
      // be one the absent player is already losing.
      final matchmaking =
          File('functions/src/matchmaking.ts').readAsStringSync();
      expect(matchmaking.contains('status: "pending"'), isTrue);
      expect(matchmaking.contains('joinDeadline:'), isTrue);
    });

    test('the app watches the same deadline field the server writes', () {
      final screen =
          File('lib/features/online/screens/opponent_preview_screen.dart')
              .readAsStringSync();
      expect(screen.contains("data['joinDeadline']"), isTrue);
    });
  });

  group('the window is bounded on both ends', () {
    test('60 seconds to join, 24 hours in the queue', () {
      expect(serverSource.contains('JOIN_SECONDS = 60'), isTrue);
      expect(
        serverSource.contains('TICKET_TTL_MS = 24 * 60 * 60 * 1000'),
        isTrue,
      );
    });

    test('an un-joined match is cancelled by the sweep as well', () {
      // The player left waiting cancels it themselves — unless nobody is
      // there, which is exactly the case notified matchmaking creates.
      final sweep = File('functions/src/sweep.ts').readAsStringSync();
      expect(sweep.contains('sweepPendingGames'), isTrue);
      expect(sweep.contains('sweepStaleTickets'), isTrue);
    });

    test('the push says how long the player has', () {
      expect(pushSource.contains('opponentFoundText'), isTrue);
    });
  });

  group('every state of the window has words', () {
    for (final lang in const ['tr', 'en']) {
      test('in $lang', () {
        final strings = AppStrings(Locale(lang));
        // Counting down, waiting for the other side, and the two ways it ends.
        expect(strings.joinCountdown(42), contains('42'));
        expect(strings.joinWaitingOpponent, isNotEmpty);
        expect(strings.joinExpired, isNotEmpty);
        expect(strings.joinFailed, isNotEmpty);
        // The line that makes the queue worth leaving.
        expect(strings.queueCloseHint, isNotEmpty);
      });
    }

    test('the expiry message says nothing was lost', () {
      // A player who answered in time and was stood up must be told they were
      // not punished for it, or notified matchmaking reads as a trap.
      expect(AppStrings(const Locale('tr')).joinExpired.toLowerCase(),
          contains('kaybetmedin'));
      expect(AppStrings(const Locale('en')).joinExpired.toLowerCase(),
          contains('nothing was lost'));
    });
  });
}
