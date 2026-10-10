import 'package:flutter/material.dart';

import '../models/planta.dart';
import 'dificuldade_chip.dart';

/// Card de uma planta na lista. O coração só aparece se [onFavoritar] for informado.
class PlantaCard extends StatelessWidget {
  final Planta planta;
  final VoidCallback onTap;
  final bool favorita;
  final VoidCallback? onFavoritar;

  const PlantaCard({
    super.key,
    required this.planta,
    required this.onTap,
    this.favorita = false,
    this.onFavoritar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: cores.primaryContainer,
          child: Text(planta.emoji, style: const TextStyle(fontSize: 26)),
        ),
        title: Text(
          planta.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planta.nomeCientifico,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            DificuldadeChip(dificuldade: planta.dificuldade),
          ],
        ),
        trailing: onFavoritar == null
            ? null
            : IconButton(
                tooltip: favorita ? 'Remover dos favoritos' : 'Favoritar',
                onPressed: onFavoritar,
                icon: Icon(
                  favorita ? Icons.favorite : Icons.favorite_border,
                  color: favorita ? Colors.red : null,
                ),
              ),
      ),
    );
  }
}
