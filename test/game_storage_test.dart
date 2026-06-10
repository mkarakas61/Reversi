import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/game_settings.dart';
import 'package:reversi/game/reversi_game.dart';
import 'package:reversi/services/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and restores an in-progress game', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    final played = ReversiGame.newGame().play(const Position(2, 3)).game;

    await storage.save(played, GameMode.singlePlayer, Difficulty.hard);
    final restored = await storage.load();

    expect(restored, isNotNull);
    expect(restored!.mode, GameMode.singlePlayer);
    expect(restored.difficulty, Difficulty.hard);
    expect(restored.game.currentPlayer, played.currentPlayer);
    expect(restored.game.lastMove, const Position(2, 3));
    expect(restored.game.board, played.board);
  });

  test('clear removes the saved game', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.save(
      ReversiGame.newGame(),
      GameMode.twoPlayer,
      null,
    );

    await storage.clear();
    expect(await storage.load(), isNull);
  });

  test('corrupt saved data is discarded instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'saved_game_v1': 'not json'});
    final storage = GameStorage();
    expect(await storage.load(), isNull);
  });
}
