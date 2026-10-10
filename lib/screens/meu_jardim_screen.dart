import 'package:flutter/material.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../widgets/planta_card.dart';
import 'detalhe_planta_screen.dart';

/// Lista apenas as plantas favoritadas pelo usuário logado.
class MeuJardimScreen extends StatefulWidget {
  final List<Planta> plantas;
  final AuthService auth;
  final FavoritosService favoritos;

  const MeuJardimScreen({
    super.key,
    required this.plantas,
    required this.auth,
    required this.favoritos,
  });

  @override
  State<MeuJardimScreen> createState() => _MeuJardimScreenState();
}

class _MeuJardimScreenState extends State<MeuJardimScreen> {
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_verificarLogin);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_verificarLogin);
    super.dispose();
  }

  // Se o usuário sair, não há jardim para mostrar: volta à tela anterior.
  void _verificarLogin() {
    if (!widget.auth.estaLogado && mounted) {
      Navigator.of(context).popUntil((rota) => rota.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu jardim')),
      body: ListenableBuilder(
        listenable: widget.favoritos,
        builder: (context, _) {
          final minhas = widget.favoritos.filtrarFavoritas(widget.plantas);
          if (minhas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.yard,
                        size: 72,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('Seu jardim está vazio',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Toque no coração de uma planta para adicioná-la aqui',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: minhas.length,
            itemBuilder: (context, i) {
              final planta = minhas[i];
              return PlantaCard(
                planta: planta,
                favorita: true,
                onFavoritar: () => widget.favoritos.alternar(planta.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalhePlantaScreen(
                      planta: planta,
                      auth: widget.auth,
                      favoritos: widget.favoritos,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
