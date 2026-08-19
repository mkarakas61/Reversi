import 'package:flutter/material.dart';

/// The coin currency's colour. One gold for every place a balance or a reward
/// is shown (menu, profile, match result) so the currency reads as one thing
/// (REV-102).
const Color coinGold = Color(0xFFE0A526);

/// A coin figure: the currency icon plus [text], already formatted by the
/// caller — a balance (`128`) or a reward (`+10`).
///
/// Deliberately dumb: it never formats, adds or fetches anything. Balances are
/// server-written and arrive through the profile stream (see [CoinRewards]).
class CoinAmount extends StatelessWidget {
  const CoinAmount({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = coinGold,
  });

  final String text;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on_rounded, size: fontSize + 3, color: color),
        SizedBox(width: fontSize * 0.35),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }
}
