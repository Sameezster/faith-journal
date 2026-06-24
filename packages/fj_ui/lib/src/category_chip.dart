import 'package:flutter/material.dart';

/// A category tag chip. Suggested = outlined; selected = filled (gold).
/// Mirrors the design's outlined-vs-filled chip states for AI suggestions.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _gold = Color(0xFFC8962F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _gold.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: selected ? _gold : const Color(0xFFD9D6CC)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? _gold : const Color(0xFF8C8C8C),
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
