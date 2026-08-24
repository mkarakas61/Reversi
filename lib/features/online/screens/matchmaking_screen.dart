import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/profile/profile_scope.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/wallet.dart';
import '../../../core/services/matchmaking_service.dart';
import '../../../core/services/notification_prefs.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/online_game_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';
import '../../menu/widgets/menu_button.dart';
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

  /// Whether this player has notifications on, so the queue can honestly say
  /// the app may be closed (REV-114).
  bool _canBeNotified = false;

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
    final existing = await OnlineGameService.instance.findActiveGame(_uid!);
    if (existing != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => existing.pending
              ? OpponentPreviewScreen(gameId: existing.id)
              : OnlineGameScreen(gameId: existing.id),
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

    // Asked here and nowhere else (REV-111). This is the one moment in the app
    // where a notification obviously earns its keep — the player is waiting
    // with nothing to do — and the platform gives us exactly one prompt, so
    // spending it at launch, before anyone knows what the app is, would waste
    // it on a refusal that can never be revisited.
    unawaited(_refreshNotifiable());
    unawaited(_maybeAskForNotifications(profile));
  }

  /// Offers the permission, once, to a signed-in player who has not been asked.
  ///
  /// The in-app sheet comes first and the system prompt only follows a "yes":
  /// the system dialog is the irreversible one, so the reversible question is
  /// asked first. Declining here is remembered exactly like declining there —
  /// see [NotificationPrefs.markAsked].
  Future<void> _maybeAskForNotifications(Profile profile) async {
    final asked = await const NotificationPrefs().hasAsked();
    final granted = await NotificationService.instance.isGranted();
    if (!shouldAskForNotifications(
      signedIn: true,
      isGuest: profile.isGuest,
      alreadyAsked: asked,
      alreadyGranted: granted,
    )) {
      return;
    }
    if (!mounted || _matched) return;

    final wants = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationAskSheet(),
    );
    // Closing the sheet without answering is not an answer: nothing is
    // recorded, and the question can come back on a later queue.
    if (wants != true || !mounted) return;

    final ok = await NotificationService.instance.requestPermission();
    if (!ok || !mounted) return;
    await NotificationService.instance.registerDevice(
      uid: profile.uid,
      isGuest: profile.isGuest,
      lang: Localizations.localeOf(context).languageCode,
    );
    if (mounted) setState(() => _canBeNotified = true);
  }

  /// Checked on open so the "you can close the app" line reflects reality for a
  /// player who granted permission on an earlier visit.
  Future<void> _refreshNotifiable() async {
    final granted = await NotificationService.instance.isGranted();
    if (mounted) setState(() => _canBeNotified = granted);
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
          decoration: BoxDecoration(gradient: headerGradient(context)),
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
                            // Waiting is the worst moment of a thin player
                            // pool, so it is also where the two coin bonuses
                            // are explained (REV-109/110): the wait is not
                            // wasted, and there is an hour when more people
                            // are here. Both lines are text only — the server
                            // owns every coin decision.
                            // The headline change of REV-114: the queue no
                            // longer needs anyone to sit and watch it. Shown
                            // only to players who can actually be reached —
                            // telling someone with notifications off that they
                            // may close the app would be a lie.
                            if (_canBeNotified) ...[
                              const SizedBox(height: 14),
                              Text(
                                strings.queueCloseHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: GameColors.accent,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              strings.waitBonusNote(CoinRewards.waitBonusCap),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: GameColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              HappyHour.isActive(DateTime.now())
                                  ? strings.happyHourNow
                                  : strings.happyHourWindow(
                                      HappyHour.startLabel,
                                      HappyHour.endLabel,
                                    ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: GameColors.accent,
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

/// The in-app half of the permission ask (REV-111).
///
/// A sheet before the system prompt, because the two are not the same kind of
/// question: this one can be asked again, the system one cannot. It also says
/// what the permission is *for*, which the platform dialog has no room to —
/// and what it will not be used for, which is the part people actually want
/// answered.
class _NotificationAskSheet extends StatelessWidget {
  const _NotificationAskSheet();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = isWoodTheme(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: wood ? WoodTheme.cardTop : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: wood ? Border.all(color: WoodTheme.gold, width: 1.2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 34,
                color: wood ? WoodTheme.gold : GameColors.accent,
              ),
              const SizedBox(height: 12),
              Text(
                strings.notifyAskTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.displayFont : 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: wood ? WoodTheme.inkTitle : GameColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.notifyAskBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.4,
                  color: wood ? WoodTheme.inkName : GameColors.inkSoft,
                ),
              ),
              const SizedBox(height: 20),
              MenuButton(
                label: strings.notifyAskAccept,
                icon: Icons.notifications_none_rounded,
                primary: true,
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  strings.notifyAskDecline,
                  style: TextStyle(
                    fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: wood ? WoodTheme.inkName : GameColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
