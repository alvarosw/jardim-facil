import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

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
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Ids dos favoritos (usuarios-service) e depois as plantas (plantas-service).
  Future<void> _carregar() async {
    final favoritos = context.read<FavoritosService>();
    final repository = context.read<PlantaRepository>();
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      await favoritos.carregar();
      final plantas = await repository.buscarPorIds(
        favoritos.idsFavoritos.toList(),
      );
      if (!mounted) return;
      setState(() {
        _plantas = plantas;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Future<void> _alternar(Planta planta) async {
    try {
      await context.read<FavoritosService>().alternar(planta.id);
    } catch (_) {
      Toast.show(
        'Não foi possível atualizar seus favoritos',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
    }
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

  Widget _corpo(FavoritosService favoritos, List<Planta> minhas) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar seu jardim'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (minhas.isEmpty) return _vazio(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: minhas.length,
      itemBuilder: (context, i) {
        final planta = minhas[i];
        return PlantaCard(
          planta: planta,
          favorita: true,
          onFavoritar: () => _alternar(planta),
          onTap: () =>
              context.read<GerenciadorEstado>().exibirDetalhes(planta.id),
        );
      },
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
      body: _corpo(favoritos, minhas),
    );
  }
}
