enum Disc { black, white }

enum GamePhase { playing, gameOver }

class Position {
  const Position(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Position($row, $col)';
}

class MoveResult {
  const MoveResult({
    required this.isValid,
    required this.flipped,
    required this.passOccurred,
    required this.gameOver,
  });

  final bool isValid;
  final List<Position> flipped;
  final bool passOccurred;
  final bool gameOver;
}

class ReversiGame {
  ReversiGame._({
    required this.board,
    required this.currentPlayer,
    required this.phase,
    required this.lastMove,
    required this.lastPassPlayer,
  });

  factory ReversiGame.newGame() {
    final board = List<List<Disc?>>.generate(
      size,
      (_) => List<Disc?>.filled(size, null),
    );
    board[3][3] = Disc.white;
    board[3][4] = Disc.black;
    board[4][3] = Disc.black;
    board[4][4] = Disc.white;

    return ReversiGame._(
      board: board,
      currentPlayer: Disc.black,
      phase: GamePhase.playing,
      lastMove: null,
      lastPassPlayer: null,
    );
  }

  factory ReversiGame.restore({
    required List<List<Disc?>> board,
    required Disc currentPlayer,
    Position? lastMove,
  }) {
    return ReversiGame._(
      board: board.map((row) => List<Disc?>.of(row)).toList(),
      currentPlayer: currentPlayer,
      phase: GamePhase.playing,
      lastMove: lastMove,
      lastPassPlayer: null,
    );
  }

  static const int size = 8;

  final List<List<Disc?>> board;
  final Disc currentPlayer;
  final GamePhase phase;
  final Position? lastMove;
  final Disc? lastPassPlayer;

  Disc get opponent => currentPlayer == Disc.black ? Disc.white : Disc.black;

  int scoreFor(Disc disc) {
    var total = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell == disc) total++;
      }
    }
    return total;
  }

  Map<Disc, int> get scores => {
        Disc.black: scoreFor(Disc.black),
        Disc.white: scoreFor(Disc.white),
      };

  Set<Position> get validMoves {
    if (phase == GamePhase.gameOver) return {};
    final moves = <Position>{};
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final position = Position(row, col);
        if (_flipsFor(position, currentPlayer).isNotEmpty) {
          moves.add(position);
        }
      }
    }
    return moves;
  }

  bool get hasValidMove => validMoves.isNotEmpty;

  Set<Position> validMovesFor(Disc player) => _validMovesFor(board, player);

  Disc? get winner {
    if (phase != GamePhase.gameOver) return null;
    final black = scoreFor(Disc.black);
    final white = scoreFor(Disc.white);
    if (black == white) return null;
    return black > white ? Disc.black : Disc.white;
  }

  bool get isDraw =>
      phase == GamePhase.gameOver &&
      scoreFor(Disc.black) == scoreFor(Disc.white);

  ReversiGame forfeitTurn() {
    if (phase == GamePhase.gameOver) return this;
    final next = opponent;
    if (_validMovesFor(board, next).isNotEmpty) {
      return copyWith(currentPlayer: next, clearLastPassPlayer: true);
    }
    if (validMoves.isNotEmpty) {
      return copyWith(lastPassPlayer: next);
    }
    return copyWith(phase: GamePhase.gameOver);
  }

  ReversiGame copyWith({
    List<List<Disc?>>? board,
    Disc? currentPlayer,
    GamePhase? phase,
    Position? lastMove,
    Disc? lastPassPlayer,
    bool clearLastMove = false,
    bool clearLastPassPlayer = false,
  }) {
    return ReversiGame._(
      board: board ?? cloneBoard(),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      phase: phase ?? this.phase,
      lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
      lastPassPlayer:
          clearLastPassPlayer ? null : lastPassPlayer ?? this.lastPassPlayer,
    );
  }

  List<List<Disc?>> cloneBoard() =>
      board.map((row) => List<Disc?>.of(row)).toList();

  ({ReversiGame game, MoveResult result}) play(Position position) {
    if (phase == GamePhase.gameOver) {
      return (
        game: this,
        result: const MoveResult(
          isValid: false,
          flipped: [],
          passOccurred: false,
          gameOver: true,
        ),
      );
    }

    final flipped = _flipsFor(position, currentPlayer);
    if (flipped.isEmpty) {
      return (
        game: this,
        result: const MoveResult(
          isValid: false,
          flipped: [],
          passOccurred: false,
          gameOver: false,
        ),
      );
    }

    final nextBoard = cloneBoard();
    nextBoard[position.row][position.col] = currentPlayer;
    for (final flip in flipped) {
      nextBoard[flip.row][flip.col] = currentPlayer;
    }

    final nextPlayer = opponent;
    final nextPlayerMoves = _validMovesFor(nextBoard, nextPlayer);
    if (nextPlayerMoves.isNotEmpty) {
      return (
        game: copyWith(
          board: nextBoard,
          currentPlayer: nextPlayer,
          lastMove: position,
          clearLastPassPlayer: true,
        ),
        result: MoveResult(
          isValid: true,
          flipped: flipped,
          passOccurred: false,
          gameOver: false,
        ),
      );
    }

    final currentPlayerStillHasMoves = _validMovesFor(nextBoard, currentPlayer);
    final isOver = currentPlayerStillHasMoves.isEmpty;
    return (
      game: copyWith(
        board: nextBoard,
        currentPlayer: currentPlayer,
        phase: isOver ? GamePhase.gameOver : GamePhase.playing,
        lastMove: position,
        lastPassPlayer: isOver ? null : nextPlayer,
        clearLastPassPlayer: isOver,
      ),
      result: MoveResult(
        isValid: true,
        flipped: flipped,
        passOccurred: !isOver,
        gameOver: isOver,
      ),
    );
  }

  List<Position> _flipsFor(Position position, Disc player) =>
      _flipsForBoard(board, position, player);

  static Set<Position> _validMovesFor(List<List<Disc?>> board, Disc player) {
    final moves = <Position>{};
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final position = Position(row, col);
        if (_flipsForBoard(board, position, player).isNotEmpty) {
          moves.add(position);
        }
      }
    }
    return moves;
  }

  static List<Position> _flipsForBoard(
    List<List<Disc?>> board,
    Position position,
    Disc player,
  ) {
    if (!_isOnBoard(position.row, position.col) ||
        board[position.row][position.col] != null) {
      return [];
    }

    final opponent = player == Disc.black ? Disc.white : Disc.black;
    const directions = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),           (0, 1),
      (1, -1),  (1, 0),  (1, 1),
    ];

    final allFlips = <Position>[];
    for (final (rowStep, colStep) in directions) {
      final line = <Position>[];
      var row = position.row + rowStep;
      var col = position.col + colStep;

      while (_isOnBoard(row, col) && board[row][col] == opponent) {
        line.add(Position(row, col));
        row += rowStep;
        col += colStep;
      }

      if (line.isNotEmpty && _isOnBoard(row, col) && board[row][col] == player) {
        allFlips.addAll(line);
      }
    }
    return allFlips;
  }

  static bool _isOnBoard(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;
}
