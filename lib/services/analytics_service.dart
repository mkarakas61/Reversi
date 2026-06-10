import 'package:firebase_analytics/firebase_analytics.dart';

import '../game/reversi_game.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics}) : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  bool get isEnabled => _analytics != null;

  Future<void> logGameStarted({
    required String locale,
    String? mode,
    String? difficulty,
  }) async {
    await _analytics?.logEvent(
      name: 'game_started',
      parameters: {
        'locale': locale,
        if (mode != null) 'mode': mode,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
  }

  Future<void> logMove({
    required Disc player,
    required Position position,
    required int flippedCount,
  }) async {
    await _analytics?.logEvent(
      name: 'move_played',
      parameters: {
        'player': player.name,
        'row': position.row,
        'col': position.col,
        'flipped_count': flippedCount,
      },
    );
  }

  Future<void> logPass({required Disc player}) async {
    await _analytics?.logEvent(
      name: 'pass_forced',
      parameters: {'player': player.name},
    );
  }

  Future<void> logGameEnded({
    required int blackScore,
    required int whiteScore,
    required Disc? winner,
  }) async {
    await _analytics?.logEvent(
      name: 'game_ended',
      parameters: {
        'black_score': blackScore,
        'white_score': whiteScore,
        'winner': winner?.name ?? 'draw',
      },
    );
  }

  Future<void> logLanguageChanged({required String locale}) async {
    await _analytics?.logEvent(
      name: 'language_changed',
      parameters: {'locale': locale},
    );
  }
}
