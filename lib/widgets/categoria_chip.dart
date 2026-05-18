import 'package:flutter/material.dart';
import '../config/theme.dart';

class CategoriaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const CategoriaChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? MinimarketTheme.primaryYellow : MinimarketTheme.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        selected: selected,
        selectedColor: MinimarketTheme.secondaryNavy,
        backgroundColor: Colors.grey.shade100,
        checkmarkColor: MinimarketTheme.primaryYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? MinimarketTheme.secondaryNavy : Colors.grey.shade300,
          ),
        ),
        onSelected: onSelected,
      ),
    );
  }
}
