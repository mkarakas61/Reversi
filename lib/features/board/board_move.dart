import '../../core/game/reversi_game.dart';

class BoardMove {
  const BoardMove({
    required this.id,
    required this.placed,
    required this.flipped,
    required this.color,
  });

  final int id;
  final Position placed;
  final Set<Position> flipped;
  final Disc color;
}
