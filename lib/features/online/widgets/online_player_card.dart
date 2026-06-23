import 'package:flutter/material.dart';

import '../online_tokens.dart';

/// Cream/parchment player card with a wood-disc avatar, serif name, live
/// status line and Marcellus score. Gold border when it is this player's turn.
class OnlinePlayerCard extends StatelessWidget {
  const OnlinePlayerCard({
    super.key,
    required this.discAsset,
    required this.name,
    required this.score,
    required this.active,
    required this.statusText,
  });

  final String discAsset;
  final String name;
  final int score;
  final bool active;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OnlineTokens.cardTop, OnlineTokens.cardBottom],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? OnlineTokens.gold : OnlineTokens.cardIdleBorder,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x213E2A1E), // rgba(62,42,30,.13)
            offset: Offset(0, 2),
            blurRadius: 7,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x33000000), blurRadius: 3),
              ],
            ),
            child: ClipOval(child: Image.asset(discAsset, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: OnlineTokens.inkName,
                  ),
                ),
                // Reserve 16px so the layout doesn't jump when status toggles.
                SizedBox(
                  height: 16,
                  child: Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.3,
                      color: OnlineTokens.goldText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 42),
            child: Text(
              '$score',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Marcellus',
                fontSize: 28,
                color: OnlineTokens.inkScore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
