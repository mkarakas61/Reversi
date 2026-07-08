import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/models/game_stats.dart';
import 'package:reversi/core/services/stats_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load returns empty stats when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StatsStorage();
    final stats = await storage.load();
    expect(stats.totalGames, 0);
  });

  test('saves and restores stats', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StatsStorage();
    final stats = GameStats.empty.recordGame(
      mode: StatsMode.singlePlayerNormal,
      outcome: GameOutcome.win,
      scoreDiff: 12,
      flippedDiscs: 22,
      durationSeconds: 45,
    );

    await storage.save(stats);
    final restored = await storage.load();

    expect(restored.overall.wins, 1);
    expect(restored.totalFlippedDiscs, 22);
    expect(restored.totalPlayTimeSeconds, 45);
  });

  test('reset clears saved stats', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StatsStorage();
    await storage.save(GameStats.empty.recordGame(
      mode: StatsMode.singlePlayerNormal,
      outcome: GameOutcome.win,
      scoreDiff: 1,
      flippedDiscs: 1,
      durationSeconds: 1,
    ));

    await storage.reset();
    final stats = await storage.load();
    expect(stats.totalGames, 0);
  });

  test('corrupt saved data is discarded instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'game_stats_v1': 'not json'});
    final storage = StatsStorage();
    final stats = await storage.load();
    expect(stats.totalGames, 0);
  });
}
