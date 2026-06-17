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

  bool get isFinished => status == OnlineStatus.finished;

  /// Aborted before play started (e.g. a player left the opponent preview).
  /// Neither side is penalised and no rewards are granted.
  bool get isCancelled => status == OnlineStatus.cancelled;

  Disc colorFor(String uid) => uid == blackUid ? Disc.black : Disc.white;

  String opponentUid(String myUid) => myUid == blackUid ? whiteUid : blackUid;

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
    );
  }
}
