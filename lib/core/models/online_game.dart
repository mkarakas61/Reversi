import 'package:cloud_firestore/cloud_firestore.dart';

import '../game/reversi_game.dart';

/// Decodes a 64-char row-major board string ("b"/"w"/"-") into a board grid.
/// Matches the encoding written by the matchmaking function and [encodeBoard].
List<List<Disc?>> decodeBoard(String s) {
  return List.generate(
    ReversiGame.size,
    (r) => List.generate(ReversiGame.size, (c) {
      switch (s[r * ReversiGame.size + c]) {
        case 'b':
          return Disc.black;
        case 'w':
          return Disc.white;
        default:
          return null;
      }
    }),
  );
}

/// Encodes a board grid into the 64-char row-major string used in Firestore.
String encodeBoard(List<List<Disc?>> board) {
  final sb = StringBuffer();
  for (final row in board) {
    for (final cell in row) {
      sb.write(cell == null ? '-' : (cell == Disc.black ? 'b' : 'w'));
    }
  }
  return sb.toString();
}

enum OnlineStatus { active, finished, cancelled }

enum RematchStatus { pending, accepted, declined }

/// A rematch offer riding on the finished game document (REV-98).
///
/// Both players already listen to that document, so the offer, the answer and
/// the handoff to the new game arrive over the stream they are both on — no
/// second channel to keep in sync. Only the server writes it: the rules make a
/// finished game read-only to clients, and the new game has to be created the
/// same way matchmaking creates one.
class RematchOffer {
  const RematchOffer({
    required this.by,
    required this.status,
    this.expiresAt,
    this.gameId,
  });

  /// Who offered.
  final String by;
  final RematchStatus status;

  /// When an unanswered offer stops standing. Null on offers written before
  /// the field existed, which then simply never expire.
  final DateTime? expiresAt;

  /// The rematch game, once the offer is accepted.
  final String? gameId;

  bool get isExpired {
    final e = expiresAt;
    return e != null && e.isBefore(DateTime.now());
  }

  /// Still awaiting an answer. An expired offer is not live, so the buttons go
  /// back to offering rather than waiting for something nobody will answer.
  bool get isLive => status == RematchStatus.pending && !isExpired;

  bool offeredBy(String uid) => by == uid;

  /// Seconds left before the offer lapses, floored at zero.
  int get secondsLeft {
    final e = expiresAt;
    if (e == null) return 0;
    final s = e.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  static RematchOffer? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final by = m['by'] as String?;
    if (by == null) return null;
    final status = switch (m['status'] as String?) {
      'accepted' => RematchStatus.accepted,
      'declined' => RematchStatus.declined,
      'pending' => RematchStatus.pending,
      _ => null,
    };
    if (status == null) return null;
    return RematchOffer(
      by: by,
      status: status,
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      gameId: m['gameId'] as String?,
    );
  }
}

/// A snapshot of an online game from the Firestore `games/{id}` document. The
/// board is reconstructed into a [ReversiGame] so the shared rules engine drives
/// move validation and rendering, exactly like the local game.
class OnlineGame {
  const OnlineGame({
    required this.id,
    required this.game,
    required this.blackUid,
    required this.whiteUid,
    required this.playerUids,
    required this.playerInfo,
    required this.status,
    required this.winner,
    required this.isDraw,
    required this.moveCount,
    this.lastSeen = const {},
    this.rematch,
  });

  final String id;
  final ReversiGame game;
  final String blackUid;
  final String whiteUid;
  final List<String> playerUids;
  final Map<String, dynamic> playerInfo;
  final OnlineStatus status;
  final Disc? winner;
  final bool isDraw;
  final int moveCount;

  /// The rematch offer on this game, or null when nobody has offered (REV-98).
  final RematchOffer? rematch;

  /// Server timestamp of each player's most recent in-game heartbeat, keyed by
  /// uid. Used to detect a disconnected opponent (REV-48).
  final Map<String, DateTime> lastSeen;

  bool get isFinished => status == OnlineStatus.finished;

  /// Aborted before play started (e.g. a player left the opponent preview).
  /// Neither side is penalised and no rewards are granted.
  bool get isCancelled => status == OnlineStatus.cancelled;

  Disc colorFor(String uid) => uid == blackUid ? Disc.black : Disc.white;

  String opponentUid(String myUid) => myUid == blackUid ? whiteUid : blackUid;

  /// Most recent heartbeat for [uid], or null if they've never checked in.
  DateTime? lastSeenFor(String uid) => lastSeen[uid];

  Map<String, dynamic> infoFor(String uid) =>
      playerInfo[uid] as Map<String, dynamic>? ?? const {};

  factory OnlineGame.fromDoc(String id, Map<String, dynamic> d) {
    final boardStr = d['board'] as String?;
    final board = (boardStr != null && boardStr.length == 64)
        ? decodeBoard(boardStr)
        : ReversiGame.newGame().board;
    final current =
        (d['currentPlayer'] as String?) == 'white' ? Disc.white : Disc.black;
    final lm = d['lastMove'] as Map<String, dynamic>?;
    final lastMove =
        lm == null ? null : Position(lm['row'] as int, lm['col'] as int);

    final winnerStr = d['winner'] as String?;
    final players = d['players'] as Map<String, dynamic>? ?? const {};

    final lastSeenRaw = d['lastSeen'] as Map<String, dynamic>? ?? const {};
    final lastSeen = <String, DateTime>{};
    lastSeenRaw.forEach((k, v) {
      if (v is Timestamp) lastSeen[k] = v.toDate();
    });

    return OnlineGame(
      id: id,
      game: ReversiGame.restore(
        board: board,
        currentPlayer: current,
        lastMove: lastMove,
      ),
      blackUid: players['black'] as String? ?? '',
      whiteUid: players['white'] as String? ?? '',
      playerUids:
          (d['playerUids'] as List<dynamic>? ?? const []).cast<String>(),
      playerInfo: d['playerInfo'] as Map<String, dynamic>? ?? const {},
      status: switch (d['status'] as String?) {
        'finished' => OnlineStatus.finished,
        'cancelled' => OnlineStatus.cancelled,
        _ => OnlineStatus.active,
      },
      winner: winnerStr == 'black'
          ? Disc.black
          : (winnerStr == 'white' ? Disc.white : null),
      isDraw: winnerStr == 'draw',
      moveCount: (d['moveCount'] as num?)?.toInt() ?? 0,
      lastSeen: lastSeen,
      rematch: RematchOffer.fromMap(d['rematch'] as Map<String, dynamic>?),
    );
  }
}
