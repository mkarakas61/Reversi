import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../services/matchmaking_service.dart';
import '../services/online_game_service.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';
import 'online_game_screen.dart';
import 'opponent_preview_screen.dart';

/// "Finding an opponent…" lobby. On open it joins the matchmaking queue and
/// listens to its own ticket; when the server pairs it (status → matched), it
/// hands off to the opponent preview. Leaving (cancel or back) removes the
/// ticket so the player isn't matched while away.
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _pinger;
  String? _uid;
  bool _matched = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final profile = ProfileScope.of(context).profile;
    if (profile == null) {
      Navigator.of(context).maybePop();
      return;
    }
    _uid = profile.uid;

    // If the player has an ongoing active game (e.g. returned after a
    // disconnect), send them back instead of opening a new match (REV-48).
    final existingGameId =
        await OnlineGameService.instance.findActiveGame(_uid!);
    if (existingGameId != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OnlineGameScreen(gameId: existingGameId),
        ),
      );
      return;
    }

    try {
      await MatchmakingService.instance.joinQueue(profile, profile.online);
    } catch (_) {
      if (mounted) setState(() => _error = true);
      return;
    }
    _sub = MatchmakingService.instance.watchTicket(_uid!).listen((snap) {
      final data = snap.data();
      if (data == null || _matched || !mounted) return;
      if (data['status'] == 'matched' && data['gameId'] != null) {
        _matched = true;
        _pinger?.cancel();
        final gameId = data['gameId'] as String;
        SoundService.instance.playSfx(Sfx.win);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OpponentPreviewScreen(gameId: gameId),
          ),
        );
      }
    });

    // Re-stamp the ticket every few seconds so the pairing function re-runs; it
    // self-heals a simultaneous join where both initial create-triggers queried
    // before the other's ticket was visible (otherwise both sit waiting).
    _pinger = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_matched && _uid != null) {
        MatchmakingService.instance.touch(_uid!);
      }
    });
  }

  Future<void> _leave() async {
    final uid = _uid;
    if (uid != null && !_matched) {
      await MatchmakingService.instance.cancel(uid);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pinger?.cancel();
    // Best-effort: drop the ticket if we left without matching.
    if (!_matched && _uid != null) {
      unawaited(MatchmakingService.instance.cancel(_uid!));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _leave();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: bannerGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 12),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_error) ...[
                            const Icon(Icons.wifi_off_rounded,
                                size: 44, color: Color(0xFFE0312B)),
                            const SizedBox(height: 16),
                            Text(
                              strings.signInError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: GameColors.ink,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(
                              width: 54,
                              height: 54,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: GameColors.accent,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              strings.searchingOpponent,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: GameColors.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _CancelButton(
                      label: strings.cancel,
                      onTap: () {
                        SoundService.instance.playSfx(Sfx.button);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
