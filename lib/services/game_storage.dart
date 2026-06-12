import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_settings.dart';
import '../game/reversi_game.dart';

class SavedGame {
  const SavedGame({
    required this.game,
    required this.mode,
    required this.difficulty,
    this.timeLimit = TimeLimit.none,
  });

  final ReversiGame game;
  final GameMode mode;
  final Difficulty? difficulty;
  final TimeLimit timeLimit;
}

/// Persists the in-progress game so it survives the app being killed.
class GameStorage {
  static const _key = 'saved_game_v1';

  Future<void> save(
    ReversiGame game,
    GameMode mode,
    Difficulty? difficulty, {
    TimeLimit timeLimit = TimeLimit.none,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_encode(game, mode, difficulty, timeLimit)));
  }

  Future<SavedGame?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return null;
    }
    try {
      return _decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Map<String, dynamic> _encode(
    ReversiGame game,
    GameMode mode,
    Difficulty? difficulty,
    TimeLimit timeLimit,
  ) {
    final cells = StringBuffer();
    for (final row in game.board) {
      for (final cell in row) {
        cells.write(cell == null ? '-' : (cell == Disc.black ? 'b' : 'w'));
      }
    }
    return {
      'board': cells.toString(),
      'current': game.currentPlayer.name,
      'mode': mode.name,
      'difficulty': difficulty?.name,
      'timeLimit': timeLimit.name,
      'lastMoveRow': game.lastMove?.row,
      'lastMoveCol': game.lastMove?.col,
    };
  }

  SavedGame _decode(Map<String, dynamic> data) {
    final cells = data['board'] as String;
    if (cells.length != ReversiGame.size * ReversiGame.size) {
      throw const FormatException('Unexpected board length');
    }
    final board = List<List<Disc?>>.generate(ReversiGame.size, (row) {
      return List<Disc?>.generate(ReversiGame.size, (col) {
        switch (cells[row * ReversiGame.size + col]) {
          case 'b':
            return Disc.black;
          case 'w':
            return Disc.white;
          default:
            return null;
        }
      });
    });

    final lastMoveRow = data['lastMoveRow'] as int?;
    final lastMoveCol = data['lastMoveCol'] as int?;
    final difficultyName = data['difficulty'] as String?;
    // Older saves predate timed games; treat them as untimed.
    final timeLimitName = data['timeLimit'] as String?;

    return SavedGame(
      game: ReversiGame.restore(
        board: board,
        currentPlayer: Disc.values.byName(data['current'] as String),
        lastMove: lastMoveRow != null && lastMoveCol != null
            ? Position(lastMoveRow, lastMoveCol)
            : null,
      ),
      mode: GameMode.values.byName(data['mode'] as String),
      difficulty: difficultyName == null
          ? null
          : Difficulty.values.byName(difficultyName),
      timeLimit: timeLimitName == null
          ? TimeLimit.none
          : TimeLimit.values.byName(timeLimitName),
    );
  }
}
