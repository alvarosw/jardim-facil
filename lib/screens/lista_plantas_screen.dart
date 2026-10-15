import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../services/gerenciador_estado.dart';
import '../services/planta_repository.dart';
import '../widgets/planta_card.dart';

/// Tela inicial: lista de plantas com busca e filtro por dificuldade.
class ListaPlantasScreen extends StatefulWidget {
  const ListaPlantasScreen({super.key});

  @override
  State<ListaPlantasScreen> createState() => _ListaPlantasScreenState();
}

class _ListaPlantasScreenState extends State<ListaPlantasScreen> {
  static const _filtros = ['Todas', 'Fácil', 'Média', 'Difícil'];

  List<Planta> _plantas = [];
  bool _carregando = true;
  bool _erro = false;
  String _busca = '';
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    final repository = context.read<PlantaRepository>();
    final favoritos = context.read<FavoritosService>();
    setState(() {
      _carregando = true;
      _erro = false;
    });
    repository
        .carregarPlantas()
        .then((plantas) async {
          await favoritos.carregar();
          if (!mounted) return;
          setState(() {
            _plantas = plantas;
            _carregando = false;
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _carregando = false;
            _erro = true;
          });
        });
  }

  Future<void> _atualizar() async {
    try {
      final plantas = await context
          .read<PlantaRepository>()
          .recarregarPlantas();
      if (!mounted) return;
      setState(() {
        _plantas = plantas;
        _erro = false;
      });
    } catch (_) {
      if (!mounted) return;
      Toast.show(
        'Não foi possível atualizar a lista',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
    }
  }

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair == true && mounted) {
      context.read<AuthService>().logout();
      Toast.show(
        'Você foi desconectado com sucesso',
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
    }
  }

  List<Widget> _acoes(AuthService auth) {
    if (auth.estaLogado) {
      return [
        IconButton(
          tooltip: 'Meu jardim',
          icon: const Icon(Icons.yard),
          onPressed: () => context.read<GerenciadorEstado>().exibirMeuJardim(),
        ),
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout),
          onPressed: _confirmarSaida,
        ),
      ];
    }
    return [
      TextButton.icon(
        onPressed: () => context.read<GerenciadorEstado>().exibirLogin(),
        icon: const Icon(Icons.login),
        label: const Text('Entrar'),
      ),
    ];
  }

  Widget _banner(AuthService auth) {
    final cores = Theme.of(context).colorScheme;
    final logado = auth.estaLogado;
    final nome = auth.usuarioLogado?.nome.split(' ').first ?? '';
    return Container(
      width: double.infinity,
      color: logado ? cores.primaryContainer : cores.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        logado ? 'Olá, $nome!' : 'Entre para salvar suas plantas favoritas',
        style: TextStyle(
          fontWeight: logado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _corpo(AuthService auth, FavoritosService favoritos) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            const Text('Não foi possível carregar as plantas'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final busca = _busca.trim().toLowerCase();
    final filtradas = _plantas.where((p) {
      final nomeOk = p.nome.toLowerCase().contains(busca);
      final nivelOk = _filtro == 'Todas' || p.dificuldade == _filtro;
      return nomeOk && nivelOk;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar planta',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (valor) => setState(() => _busca = valor),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final f in _filtros)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filtro == f,
                    onSelected: (_) => setState(() => _filtro = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _atualizar,
            child: filtradas.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: Text('Nenhuma planta encontrada')),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtradas.length,
                    itemBuilder: (context, i) {
                      final planta = filtradas[i];
                      return PlantaCard(
                        planta: planta,
                        onTap: () => context
                            .read<GerenciadorEstado>()
                            .exibirDetalhes(planta.id),
                        favorita: favoritos.isFavorita(planta.id),
                        onFavoritar: auth.estaLogado
                            ? () => favoritos.alternar(planta.id)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final favoritos = context.watch<FavoritosService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Jardim Fácil'), actions: _acoes(auth)),
      body: Column(
        children: [
          _banner(auth),
          Expanded(child: _corpo(auth, favoritos)),
        ],
      ),
    );
  }
}
