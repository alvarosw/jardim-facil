import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planta.dart';
import '../services/favoritos_service.dart';
import '../services/gerenciador_estado.dart';
import '../services/planta_repository.dart';
import '../widgets/planta_card.dart';

/// Lista apenas as plantas favoritadas pelo usuário logado.
class MeuJardimScreen extends StatefulWidget {
  const MeuJardimScreen({super.key});

  @override
  State<MeuJardimScreen> createState() => _MeuJardimScreenState();
}

class _MeuJardimScreenState extends State<MeuJardimScreen> {
  List<Planta> _plantas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    context.read<PlantaRepository>().carregarPlantas().then((plantas) {
      if (!mounted) return;
      setState(() {
        _plantas = plantas;
        _carregando = false;
      });
    });
  }

  Widget _vazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.yard,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Seu jardim está vazio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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

  @override
  Widget build(BuildContext context) {
    final favoritos = context.watch<FavoritosService>();
    final minhas = favoritos.filtrarFavoritas(_plantas);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<GerenciadorEstado>().exibirPlantas(),
        ),
        title: const Text('Meu jardim'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : minhas.isEmpty
          ? _vazio(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: minhas.length,
              itemBuilder: (context, i) {
                final planta = minhas[i];
                return PlantaCard(
                  planta: planta,
                  favorita: true,
                  onFavoritar: () => favoritos.alternar(planta.id),
                  onTap: () => context.read<GerenciadorEstado>().exibirDetalhes(
                    planta.id,
                  ),
                );
              },
            ),
    );
  }
}
