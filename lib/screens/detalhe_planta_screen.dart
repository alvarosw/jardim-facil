import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toast/toast.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../services/gerenciador_estado.dart';
import '../services/planta_repository.dart';
import '../widgets/dificuldade_chip.dart';
import '../widgets/info_card.dart';

/// Detalhes de uma planta (GET /plantas/{id}), com opção de adicionar ao jardim.
class DetalhePlantaScreen extends StatefulWidget {
  const DetalhePlantaScreen({super.key});

  @override
  State<DetalhePlantaScreen> createState() => _DetalhePlantaScreenState();
}

class _DetalhePlantaScreenState extends State<DetalhePlantaScreen> {
  Planta? _planta;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final id = context.read<GerenciadorEstado>().idPlanta;
    try {
      final planta = await context.read<PlantaRepository>().buscarPorId(id);
      if (!mounted) return;
      setState(() {
        _planta = planta;
        _erro = planta == null;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    }
  }

  Future<void> _alternar(Planta planta) async {
    if (!context.read<AuthService>().estaLogado) {
      Toast.show(
        'Faça login para favoritar',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
      return;
    }
    try {
      final agoraFavorita = await context.read<FavoritosService>().alternar(
        planta.id,
      );
      Toast.show(
        agoraFavorita
            ? '${planta.nome} adicionada ao seu jardim'
            : '${planta.nome} removida do seu jardim',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
    } catch (_) {
      Toast.show(
        'Não foi possível atualizar seus favoritos',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
    }
  }

  void _compartilhar(Planta planta) {
    final texto =
        '${planta.nome} (${planta.nomeCientifico})\n\n'
        'Luminosidade: ${planta.luminosidade}\n'
        'Rega: ${planta.rega}\n'
        'Dificuldade: ${planta.dificuldade}\n'
        'Dica de cuidado: ${planta.dica}\n\n'
        'Enviado pelo Jardim Fácil';
    SharePlus.instance.share(ShareParams(title: 'Jardim Fácil', text: texto));
  }

  @override
  Widget build(BuildContext context) {
    final planta = _planta;
    final voltar = IconButton(
      tooltip: 'Voltar',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.read<GerenciadorEstado>().exibirPlantas(),
    );
    if (planta == null) {
      return Scaffold(
        appBar: AppBar(leading: voltar),
        body: Center(
          child: _erro
              ? const Text('Não foi possível carregar a planta')
              : const CircularProgressIndicator(),
        ),
      );
    }

    final auth = context.watch<AuthService>();
    final favoritos = context.watch<FavoritosService>();
    final cores = Theme.of(context).colorScheme;
    final favorita = auth.estaLogado && favoritos.isFavorita(planta.id);
    return Scaffold(
      appBar: AppBar(
        leading: voltar,
        title: Text(planta.nome),
        actions: [
          IconButton(
            tooltip: 'Compartilhar cuidados',
            icon: const Icon(Icons.share),
            onPressed: () => _compartilhar(planta),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _alternar(planta),
        icon: Icon(favorita ? Icons.favorite : Icons.favorite_border),
        label: Text(
          favorita ? 'Remover do meu jardim' : 'Adicionar ao meu jardim',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: cores.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(planta.emoji, style: const TextStyle(fontSize: 88)),
          ),
          const SizedBox(height: 16),
          Text(planta.nome, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            planta.nomeCientifico,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(planta.descricao, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          InfoCard(
            icone: Icons.wb_sunny,
            titulo: 'Luminosidade',
            valor: planta.luminosidade,
          ),
          InfoCard(icone: Icons.water_drop, titulo: 'Rega', valor: planta.rega),
          InfoCard(
            icone: Icons.signal_cellular_alt,
            titulo: 'Dificuldade',
            conteudo: Align(
              alignment: Alignment.centerLeft,
              child: DificuldadeChip(dificuldade: planta.dificuldade),
            ),
          ),
          InfoCard(
            icone: Icons.lightbulb,
            titulo: 'Dica de cuidado',
            valor: planta.dica,
            destaque: true,
          ),
        ],
      ),
    );
  }
}
