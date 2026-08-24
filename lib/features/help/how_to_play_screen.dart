import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/rank.dart';
import '../../core/models/wallet.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/info_card.dart';
import '../menu/widgets/menu_button.dart';
import '../settings/settings_screen.dart';
import '../settings/widgets/settings_header.dart';
import 'widgets/capture_diagram.dart';

/// The permanent rules-and-features reference (REV-103).
///
/// The first-launch tour ([WelcomeTour]) is the short, one-time version of this
/// page; this is the version that stays. Anyone who skipped the tour, forgot a
/// rule, or never knew Reversi in the first place can reach it from the menu's
/// "?" button and from Settings.
///
/// It covers features as well as rules on purpose: "the board and the discs are
/// yours to choose" is invisible otherwise, and a player who never opens
/// Settings never learns it.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wood = SettingsScope.of(context).settings.appTheme == AppThemeId.wood;

    return Scaffold(
      backgroundColor: wood ? WoodTheme.surface : GameColors.creamTop,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: wood ? WoodTheme.pageBackground : creamShellGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: const HeaderClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: wood ? WoodTheme.buttonGradient : bannerGradient,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SettingsHeader(
                    title: strings.howToPlay,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        InfoCard(
                          title: strings.htpGoalTitle,
                          child: InfoText(strings.htpGoalBody),
                        ),
                        InfoCard(
                          title: strings.htpMoveTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoText(strings.htpMoveBody),
                              const SizedBox(height: 14),
                              const CaptureDiagram(),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.htpHintsTitle,
                          child: InfoText(strings.htpHintsBody),
                        ),
                        InfoCard(
                          title: strings.htpPassTitle,
                          child: InfoText(strings.htpPassBody),
                        ),
                        InfoCard(
                          title: strings.htpEndTitle,
                          child: InfoText(strings.htpEndBody),
                        ),
                        InfoCard(
                          title: strings.htpCustomizeTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoText(strings.htpCustomizeBody),
                              const SizedBox(height: 12),
                              MenuButton(
                                label: strings.htpOpenSettings,
                                icon: Icons.tune_rounded,
                                onTap: () {
                                  // Replaces rather than stacks: arriving from
                                  // Settings and pushing Settings again would
                                  // leave two of them on the stack.
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.htpOnlineTitle,
                          child: InfoText(strings.htpOnlineBody),
                        ),
                        InfoCard(
                          title: strings.htpEarnTitle,
                          child: _TrophyRules(strings: strings),
                        ),
                        InfoCard(
                          title: strings.htpCoinsTitle,
                          child: _CoinRules(strings: strings),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How trophies are won and lost, in the same numbers the server uses
/// (Mustafa, 2026-08-24).
///
/// It used to be that a player could see their trophy count move and had no way
/// to find out why: the ladder, the margin bonus and the per-rank loss penalty
/// were only in `functions/src/trophy.ts`. A reward nobody can predict is not a
/// reward, and a penalty nobody can predict is worse.
///
/// Every number here comes from [TrophyRewards] and [kRanks], which are checked
/// against the TypeScript in `test/trophy_rules_test.dart` — so this page is
/// wrong only if the mirror is, and the mirror cannot drift silently.
class _TrophyRules extends StatelessWidget {
  const _TrophyRules({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoText(strings.htpEarnIntro),
        const SizedBox(height: 12),
        _RuleRow(
          label: strings.htpTrophyWin,
          value: strings.htpTrophyWinValue(
            TrophyRewards.winBase,
            TrophyRewards.maxWinBonus,
          ),
        ),
        _RuleRow(
          label: strings.htpTrophyDraw,
          value: strings.htpTrophyDrawValue(TrophyRewards.drawGain),
        ),
        _RuleRow(
          label: strings.htpTrophyLoss,
          value: strings.htpTrophyLossValue,
        ),
        const SizedBox(height: 10),
        _Fine(strings.htpTrophyMargin(
          TrophyRewards.scoreDiffPerBonus,
          TrophyRewards.maxWinBonus,
        )),
        const SizedBox(height: 6),
        _Fine(strings.htpTrophyFloor),
        const SizedBox(height: 14),
        _RankLadderTable(strings: strings),
        const SizedBox(height: 10),
        _Fine(strings.htpRankHoldNote),
      ],
    );
  }
}

/// The ladder as a table: where each rank starts, what a defeat costs there,
/// and the win rate that holds it.
///
/// A table rather than a paragraph because the point is the *shape* — the cost
/// of losing grows as you climb, and that is visible in a column and invisible
/// in prose.
class _RankLadderTable extends StatelessWidget {
  const _RankLadderTable({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    final labelColor = wood ? WoodTheme.inkName : GameColors.inkSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.htpRankTableTitle,
          style: TextStyle(
            fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.2),
          },
          children: [
            TableRow(
              children: [
                _Head(strings.htpRankColRank),
                _Head(strings.htpRankColFrom),
                _Head(strings.htpRankColLoss),
                _Head(strings.htpRankColHold),
              ],
            ),
            for (final rank in kRanks)
              TableRow(
                children: [
                  _Cell(strings.rankTitle(rank.id), color: rank.color),
                  _Cell('${rank.minTrophies}'),
                  _Cell(_lossLabel(rank.id)),
                  _Cell(_holdLabel(rank.id)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// A rank that costs nothing to lose says so with a dash, not a "0" — the
  /// point is that nothing happens, not that a zero is subtracted.
  String _lossLabel(RankId id) {
    final penalty = TrophyRewards.lossPenalty[id] ?? 0;
    return penalty == 0 ? '—' : '-$penalty';
  }

  String _holdLabel(RankId id) {
    final rate = TrophyRewards.breakEvenWinRatePercent(id);
    return rate == 0 ? '—' : '%$rate';
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: wood ? WoodTheme.inkName : GameColors.inkSoft,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.color});

  final String text;

  /// Set for the rank name, which carries its own identity colour (REV-60) —
  /// the same colour the badge and the avatar frame use, so the table reads as
  /// the same ladder rather than a second list.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
          fontWeight: color == null ? FontWeight.w700 : FontWeight.w800,
          fontSize: 12.5,
          color: color ?? (wood ? WoodTheme.inkScore : GameColors.ink),
        ),
      ),
    );
  }
}

/// Where coins come from, in one place — the rates, the evening window and the
/// waiting bonus, which until now were spread across a profile card, a menu
/// line and a result screen.
class _CoinRules extends StatelessWidget {
  const _CoinRules({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleRow(
          label: strings.htpTrophyWin,
          value: strings.htpCoinsWinValue(CoinRewards.win),
        ),
        _RuleRow(
          label: strings.htpTrophyDraw,
          value: strings.htpCoinsWinValue(CoinRewards.draw),
        ),
        _RuleRow(
          label: strings.htpTrophyLoss,
          value: strings.htpCoinsWinValue(CoinRewards.loss),
        ),
        const SizedBox(height: 10),
        _Fine(strings.htpCoinsHappy(
          HappyHour.startLabel,
          HappyHour.endLabel,
          HappyHour.multiplier,
        )),
        const SizedBox(height: 6),
        _Fine(strings.htpCoinsWait(
          CoinRewards.waitBonusPerMinute,
          CoinRewards.waitBonusCap,
        )),
        const SizedBox(height: 6),
        _Fine(strings.htpCoinsSpend),
      ],
    );
  }
}

/// "Galibiyet ......... +3" — the label on the left, the number on the right,
/// so three rules can be compared down the right edge.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: wood ? WoodTheme.inkScore : GameColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.35,
                color: wood
                    ? WoodTheme.inkName
                    : GameColors.ink.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The qualifications: true, needed, and not the first thing to read.
class _Fine extends StatelessWidget {
  const _Fine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final wood = isWoodTheme(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
        fontWeight: FontWeight.w600,
        fontSize: 12,
        height: 1.4,
        color: wood ? WoodTheme.inkName : GameColors.inkSoft,
      ),
    );
  }
}
