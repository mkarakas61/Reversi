import 'dart:math';

import 'game_settings.dart';
import 'reversi_game.dart';

class ReversiAi {
  ReversiAi({required this.difficulty, Random? random})
      : _random = random ?? Random();

  final Difficulty difficulty;
  final Random _random;

  static const double _infinity = 1e9;
  static const int _endgameEmptyThreshold = 12;

  static const List<List<int>> _weights = [
    [100, -25, 10, 5, 5, 10, -25, 100],
    [-25, -50, 1, 1, 1, 1, -50, -25],
    [10, 1, 3, 2, 2, 3, 1, 10],
    [5, 1, 2, 1, 1, 2, 1, 5],
    [5, 1, 2, 1, 1, 2, 1, 5],
    [10, 1, 3, 2, 2, 3, 1, 10],
    [-25, -50, 1, 1, 1, 1, -50, -25],
    [100, -25, 10, 5, 5, 10, -25, 100],
  ];

  Position chooseMove(ReversiGame game) {
    final moves = game.validMoves.toList();
    assert(moves.isNotEmpty, 'chooseMove requires at least one legal move');
    if (moves.length == 1) return moves.first;

    switch (difficulty) {
      case Difficulty.easy:
        return _chooseEasy(moves);
      case Difficulty.normal:
        return _chooseNormal(game, moves);
      case Difficulty.hard:
        return _chooseHard(game, moves);
    }
  }

  Position _chooseEasy(List<Position> moves) =>
      moves[_random.nextInt(moves.length)];

  Position _chooseNormal(ReversiGame game, List<Position> moves) {
    if (_random.nextDouble() < 0.3) {
      return moves[_random.nextInt(moves.length)];
    }
    final aiDisc = game.currentPlayer;
    var bestScore = -_infinity;
    final best = <Position>[];
    for (final move in moves) {
      final next = game.play(move).game;
      final score = _evaluateNormal(next, aiDisc);
      if (score > bestScore) {
        bestScore = score;
        best..clear()..add(move);
      } else if (score == bestScore) {
        best.add(move);
      }
    }
    return best[_random.nextInt(best.length)];
  }

  Position _chooseHard(ReversiGame game, List<Position> moves) {
    if (_emptyCount(game) <= _endgameEmptyThreshold) {
      return _chooseBySearch(game, moves,
          depth: _endgameEmptyThreshold,
          evaluate: _evaluateHard,
          randomTieBreak: false);
    }
    return _chooseBySearch(game, moves,
        depth: 5, evaluate: _evaluateHard, randomTieBreak: false);
  }

  Position _chooseBySearch(
    ReversiGame game,
    List<Position> moves, {
    required int depth,
    required double Function(ReversiGame, Disc) evaluate,
    required bool randomTieBreak,
  }) {
    final aiDisc = game.currentPlayer;
    var bestScore = -_infinity;
    final best = <Position>[];

    for (final move in _ordered(moves)) {
      final next = game.play(move).game;
      final score =
          _minimax(next, depth - 1, -_infinity, _infinity, aiDisc, evaluate);
      if (score > bestScore) {
        bestScore = score;
        best..clear()..add(move);
      } else if (score == bestScore && randomTieBreak) {
        best.add(move);
      }
    }
    return randomTieBreak ? best[_random.nextInt(best.length)] : best.first;
  }

  double _minimax(
    ReversiGame game,
    int depth,
    double alpha,
    double beta,
    Disc aiDisc,
    double Function(ReversiGame, Disc) evaluate,
  ) {
    if (game.phase == GamePhase.gameOver) return _terminalScore(game, aiDisc);
    if (depth <= 0) return evaluate(game, aiDisc);

    final maximizing = game.currentPlayer == aiDisc;
    var value = maximizing ? -_infinity : _infinity;

    for (final move in _ordered(game.validMoves.toList())) {
      final next = game.play(move).game;
      final score = _minimax(next, depth - 1, alpha, beta, aiDisc, evaluate);
      if (maximizing) {
        value = max(value, score);
        alpha = max(alpha, value);
      } else {
        value = min(value, score);
        beta = min(beta, value);
      }
      if (beta <= alpha) break;
    }
    return value;
  }

  double _terminalScore(ReversiGame game, Disc aiDisc) {
    final diff = game.scoreFor(aiDisc) - game.scoreFor(_opponentOf(aiDisc));
    if (diff > 0) return 100000 + diff.toDouble();
    if (diff < 0) return -100000 + diff.toDouble();
    return 0;
  }

  double _evaluateNormal(ReversiGame game, Disc aiDisc) =>
      _positionalScore(game, aiDisc) + 8.0 * _mobilityScore(game, aiDisc);

  double _evaluateHard(ReversiGame game, Disc aiDisc) {
    final empties = _emptyCount(game);
    final discWeight = empties > 32 ? 0.0 : 2.0;
    final discDiff = game.scoreFor(aiDisc) - game.scoreFor(_opponentOf(aiDisc));
    return _positionalScore(game, aiDisc) +
        8.0 * _mobilityScore(game, aiDisc) -
        6.0 * _frontierScore(game, aiDisc) +
        discWeight * discDiff;
  }

  double _positionalScore(ReversiGame game, Disc aiDisc) {
    var score = 0;
    for (var row = 0; row < ReversiGame.size; row++) {
      for (var col = 0; col < ReversiGame.size; col++) {
        final disc = game.board[row][col];
        if (disc == aiDisc) {
          score += _weights[row][col];
        } else if (disc != null) {
          score -= _weights[row][col];
        }
      }
    }
    return score.toDouble();
  }

  double _mobilityScore(ReversiGame game, Disc aiDisc) {
    final own = game.validMovesFor(aiDisc).length;
    final opp = game.validMovesFor(_opponentOf(aiDisc)).length;
    return (own - opp).toDouble();
  }

  double _frontierScore(ReversiGame game, Disc aiDisc) {
    var own = 0;
    var opp = 0;
    for (var row = 0; row < ReversiGame.size; row++) {
      for (var col = 0; col < ReversiGame.size; col++) {
        final disc = game.board[row][col];
        if (disc == null) continue;
        if (_touchesEmpty(game.board, row, col)) {
          if (disc == aiDisc) own++; else opp++;
        }
      }
    }
    return (own - opp).toDouble();
  }

  bool _touchesEmpty(List<List<Disc?>> board, int row, int col) {
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = row + dr;
        final c = col + dc;
        if (r >= 0 && r < ReversiGame.size &&
            c >= 0 && c < ReversiGame.size &&
            board[r][c] == null) {
          return true;
        }
      }
    }
    return false;
  }

  int _emptyCount(ReversiGame game) =>
      ReversiGame.size * ReversiGame.size -
      game.scoreFor(Disc.black) -
      game.scoreFor(Disc.white);

  List<Position> _ordered(List<Position> moves) {
    final sorted = List<Position>.of(moves);
    sorted.sort((a, b) => _weights[b.row][b.col].compareTo(_weights[a.row][a.col]));
    return sorted;
  }

  static Disc _opponentOf(Disc disc) =>
      disc == Disc.black ? Disc.white : Disc.black;
}
