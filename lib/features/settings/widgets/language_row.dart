import 'package:flutter/material.dart';

import '../../../core/theme/game_colors.dart';

class LanguageRow extends StatelessWidget {
  const LanguageRow({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _seg('tr', 'Türkçe'),
          const SizedBox(width: 4),
          _seg('en', 'English'),
        ],
      ),
    );
  }

  Widget _seg(String code, String label) {
    final active = current == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? GameColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: active ? Colors.white : GameColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
