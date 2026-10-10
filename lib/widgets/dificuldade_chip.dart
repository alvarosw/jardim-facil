import 'package:flutter/material.dart';

/// Chip colorido com o nível de dificuldade da planta.
class DificuldadeChip extends StatelessWidget {
  final String dificuldade;

  const DificuldadeChip({super.key, required this.dificuldade});

  static Color corDe(String dificuldade) {
    switch (dificuldade) {
      case 'Fácil':
        return Colors.green.shade700;
      case 'Média':
        return Colors.amber.shade800;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = corDe(dificuldade);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Text(
        dificuldade,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
