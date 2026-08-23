import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/profile/profile_scope.dart';
import '../../core/services/purchase_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/store/entitlements.dart';
import '../../core/store/store_catalog.dart';
import '../../core/theme/game_colors.dart'
    show GameColors, bannerGradient, creamShellGradient;
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/board_preview.dart';
import '../../shared/widgets/coin_amount.dart';
import '../../shared/widgets/disc_preview.dart';
import '../../shared/widgets/info_card.dart';
import '../settings/widgets/settings_header.dart';

/// The store (REV-69/71): everything that can be bought, and the only place a
/// locked item is ever shown.
///
/// Settings lists what the player owns; the shop window lives here. That split
/// is deliberate — a settings screen full of padlocks nags at someone every
/// time they change a colour, while a store they chose to open does not.
///
/// An item bought here can be used here too: after paying, the natural next
/// thought is "let me see it", and sending the player to another screen to act
/// on what they just bought would be a strange reward.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settingsController = SettingsScope.of(context);
    final settings = settingsController.settings;
    final wood = settings.appTheme == AppThemeId.wood;

    final profile = ProfileScope.of(context).profile;
    final entitlements = profile?.entitlements ?? Entitlements.freeOnly;
    final coins = profile?.coins ?? 0;
    final isGuest = profile?.isGuest ?? true;

    final boards = coinItems.where((i) => i.kind == StoreItemKind.board);
    final discs = coinItems.where((i) => i.kind == StoreItemKind.disc);

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
                    title: strings.storeTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  _Balance(coins: coins),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        InfoCard(
                          title: strings.storeBoards,
                          child: Column(
                            children: [
                              for (final item in boards)
                                _StoreTile(
                                  item: item,
                                  owned: entitlements.ownsItem(item),
                                  inUse: item.boards.contains(settings.board),
                                  coins: coins,
                                  isGuest: isGuest,
                                ),
                            ],
                          ),
                        ),
                        InfoCard(
                          title: strings.storeDiscs,
                          child: Column(
                            children: [
                              for (final item in discs)
                                _StoreTile(
                                  item: item,
                                  owned: entitlements.ownsItem(item),
                                  inUse:
                                      item.discs.contains(settings.yourCoin) ||
                                          item.discs
                                              .contains(settings.opponentCoin),
                                  coins: coins,
                                  isGuest: isGuest,
                                ),
                            ],
                          ),
                        ),
                        // What money will buy once Play Billing is wired up.
                        // Shown rather than hidden: a shop window that quietly
                        // omits the plan makes the coin items look like the
                        // whole game, and the subscription arrives as a
                        // surprise later.
                        InfoCard(
                          title: strings.storeComingTitle,
                          child: Column(
                            children: [
                              for (final item in moneyItems)
                                _ComingSoonTile(item: item),
                            ],
                          ),
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

/// A real-money item that cannot be bought yet: named, described, and clearly
/// not for sale — no button that does nothing.
class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.item});

  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isTheme = item.kind == StoreItemKind.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: 0.72,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coinGold.withValues(alpha: 0.14),
              ),
              child: Icon(
                isTheme
                    ? Icons.palette_rounded
                    : Icons.workspace_premium_rounded,
                color: coinGold,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTheme
                        ? strings.storeGuzelsiName
                        : strings.storePremiumName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: GameColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTheme
                        ? strings.storeGuzelsiDesc
                        : strings.storePremiumDesc,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: GameColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GameColors.inkSoft.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                strings.storeComingSoon,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: GameColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The balance, shown where the prices are — a price means nothing without it.
class _Balance extends StatelessWidget {
  const _Balance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CoinAmount(text: '$coins'),
          ),
        ],
      ),
    );
  }
}

/// One row of the shop window: what it looks like, what it costs, what you can
/// do with it right now.
class _StoreTile extends StatefulWidget {
  const _StoreTile({
    required this.item,
    required this.owned,
    required this.inUse,
    required this.coins,
    required this.isGuest,
  });

  final StoreItem item;
  final bool owned;
  final bool inUse;
  final int coins;
  final bool isGuest;

  @override
  State<_StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<_StoreTile> {
  bool _busy = false;

  /// Set for a moment right after a successful purchase. A bought thing should
  /// visibly arrive — a line that silently changes its button is a receipt,
  /// not a reward.
  bool _celebrating = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedScale(
        scale: _celebrating ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _celebrating
                ? coinGold.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
          child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: _preview(item)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(strings, item),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: GameColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.owned ? strings.storeOwned : '${item.coinPrice} coin',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: widget.owned ? GameColors.inkSoft : coinGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _action(strings),
        ],
          ),
        ),
      ),
    );
  }

  Widget _preview(StoreItem item) {
    if (item.boards.isNotEmpty) return BoardPreview(theme: item.boards.first);
    return Center(child: DiscPreview(color: item.discs.first, size: 44));
  }

  String _label(AppStrings strings, StoreItem item) {
    if (item.boards.isNotEmpty) {
      return strings.boardThemeLabel(item.boards.first);
    }
    return strings.coinColorLabel(item.discs.first);
  }

  Widget _action(AppStrings strings) {
    if (_busy) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      );
    }

    if (widget.owned) {
      if (widget.inUse) {
        return Text(
          strings.storeInUse,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: GameColors.accent,
          ),
        );
      }
      return FilledButton(
        onPressed: _apply,
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(strings.storeApply),
      );
    }

    return FilledButton(
      onPressed: _buy,
      style: FilledButton.styleFrom(
        backgroundColor: coinGold,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(strings.storeBuy),
    );
  }

  /// Applies an owned item. A board becomes the board; a disc becomes *your*
  /// disc — the opponent's side stays a settings-screen decision, since that is
  /// the one place both sides are shown together.
  void _apply() {
    final strings = AppStrings.of(context);
    final controller = SettingsScope.of(context);
    final item = widget.item;

    if (item.boards.isNotEmpty) {
      controller.setBoard(item.boards.first);
      _say(strings.storeAppliedBoard);
      return;
    }
    controller.setYourCoin(item.discs.first);
    _say(strings.storeAppliedDisc);
  }

  Future<void> _buy() async {
    final strings = AppStrings.of(context);
    final item = widget.item;
    final price = item.coinPrice ?? 0;

    if (widget.isGuest) {
      _say(strings.storeSignInNeeded);
      return;
    }
    // Checked here only to save a round trip and to say the honest thing
    // early. The balance that decides is the server's.
    if (widget.coins < price) {
      _say(strings.storeNotEnough);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.storeConfirmTitle),
        content: Text(strings.storeConfirmBody(
          _label(strings, item),
          price,
          widget.coins,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.storeBuy),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await PurchaseService.instance.buy(item.id);
    if (!mounted) return;
    setState(() => _busy = false);

    // Nothing is written locally: the profile document is streamed, so the new
    // balance and the new item arrive from the server on their own.
    switch (result.failure) {
      case null:
      case PurchaseFailure.alreadyOwned:
        _say(strings.storeBought(_label(strings, item)));
        _celebrate();
      case PurchaseFailure.notEnoughCoins:
        _say(strings.storeNotEnough);
      case PurchaseFailure.notSignedIn:
        _say(strings.storeSignInNeeded);
      case PurchaseFailure.unknownItem:
      case PurchaseFailure.failed:
        _say(strings.storeFailed);
    }
  }

  /// A short flourish: the game's win chime and a beat of gold on the row.
  /// Deliberately brief — the player came to shop, not to watch an animation.
  Future<void> _celebrate() async {
    SoundService.instance.playSfx(Sfx.win);
    setState(() => _celebrating = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _celebrating = false);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
