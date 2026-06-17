import 'package:cloud_firestore/cloud_firestore.dart';

import '../game/reversi_game.dart';
import '../models/online_game.dart';

/// Live online game sync over Firestore. Both clients render from the shared
/// game document; the player whose turn it is writes the resulting board. The
/// server validates the result and awards XP by replaying the move log
/// (REV-50), and the rules are tightened in REV-51.
class OnlineGameService {
  OnlineGameService._();
  static final OnlineGameService instance = OnlineGameService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _db.collection('games').doc(id);

  static const _turnSeconds = 40;

  Stream<OnlineGame> watch(String gameId) => _doc(gameId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => OnlineGame.fromDoc(gameId, s.data()!));

  /// Applies [position] to the current board and writes the new state. Caller
  /// must ensure it is [byUid]'s turn; invalid moves are ignored.
  Future<void> submitMove(OnlineGame g, Position position, String byUid) async {
    final move = g.game.play(position);
    if (!move.result.isValid) return;
    final next = move.game;
    final finished = move.result.gameOver;

    final data = <String, dynamic>{
      'board': encodeBoard(next.board),
      'currentPlayer': next.currentPlayer == Disc.black ? 'black' : 'white',
      'lastMove': {'row': position.row, 'col': position.col},
      'moves': FieldValue.arrayUnion([
        {'row': position.row, 'col': position.col, 'by': byUid},
      ]),
      'moveCount': g.moveCount + 1,
      'turnDeadline': Timestamp.fromDate(
        DateTime.now().add(const Duration(seconds: _turnSeconds)),
      ),
    };
    if (finished) {
      final w = next.winner;
      data['status'] = 'finished';
      data['winner'] =
          w == null ? 'draw' : (w == Disc.black ? 'black' : 'white');
    }
    await _doc(g.id).update(data);
  }

  /// Forfeits the game so the opponent wins. Refined (timeouts/disconnect) in
  /// REV-48.
  Future<void> resign(OnlineGame g, String byUid) async {
    final opponentColor = g.colorFor(g.opponentUid(byUid));
    await _doc(g.id).update({
      'status': 'finished',
      'winner': opponentColor == Disc.black ? 'black' : 'white',
    });
  }
}
