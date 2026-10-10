import 'package:flutter/material.dart';

/// Card com ícone, título e valor (luminosidade, rega, etc.).
class InfoCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Widget? conteudo;
  final bool destaque;

  const InfoCard({
    super.key,
    required this.icone,
    required this.titulo,
    this.valor = '',
    this.conteudo,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: destaque ? cores.tertiaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icone, color: destaque ? cores.tertiary : cores.primary),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: conteudo ?? Text(valor),
      ),
    );
  }
}
