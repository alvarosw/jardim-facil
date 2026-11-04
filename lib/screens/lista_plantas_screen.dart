import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../services/gerenciador_estado.dart';
import '../services/planta_repository.dart';
import '../widgets/planta_card.dart';

/// Tela inicial: lista paginada de plantas, com busca, filtro por dificuldade
/// e carregamento da próxima página ao rolar até o fim.
class ListaPlantasScreen extends StatefulWidget {
  const ListaPlantasScreen({super.key});

  @override
  State<ListaPlantasScreen> createState() => _ListaPlantasScreenState();
}

class _ListaPlantasScreenState extends State<ListaPlantasScreen> {
  static const _filtros = ['Todas', 'Fácil', 'Média', 'Difícil'];

  final _rolagem = ScrollController();
  final List<Planta> _plantas = [];
  int _pagina = 0; // última página carregada
  bool _temMais = true;
  bool _carregando = false;
  bool _erro = false;
  String _busca = '';
  String _filtro = 'Todas';
  int _geracao = 0; // muda a cada nova busca; respostas antigas são ignoradas
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(_verificarFim);
    _reiniciar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rolagem.dispose();
    super.dispose();
  }

  // Volta à página 1 (busca, filtro ou puxar para atualizar).
  Future<void> _reiniciar() {
    _geracao++;
    _pagina = 0;
    _temMais = true;
    _carregando = false;
    return _carregarPagina();
  }

  // Perto do fim da lista (ou lista sem rolagem): busca a próxima página.
  void _verificarFim() {
    if (_rolagem.hasClients && _rolagem.position.extentAfter < 300) {
      _carregarPagina();
    }
  }

  Future<void> _carregarPagina() async {
    if (_carregando || !_temMais) return;
    final geracao = _geracao;
    final proxima = _pagina + 1;
    setState(() => _carregando = true);
    try {
      final pagina = await context.read<PlantaRepository>().listar(
        pagina: proxima,
        busca: _busca.trim(),
        dificuldade: _filtro == 'Todas' ? null : _filtro,
      );
      if (!mounted || geracao != _geracao) return;
      setState(() {
        if (proxima == 1) _plantas.clear();
        _plantas.addAll(pagina.itens);
        _pagina = proxima;
        _temMais = pagina.temMais;
        _erro = false;
      });
      // Primeira página nova (busca, filtro ou atualização): volta ao topo
      if (proxima == 1 && _rolagem.hasClients) _rolagem.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _verificarFim());
    } catch (_) {
      if (!mounted || geracao != _geracao) return;
      if (proxima == 1) {
        setState(() {
          _plantas.clear();
          _erro = true;
        });
      } else {
        Toast.show(
          'Não foi possível carregar mais plantas',
          duration: Toast.lengthLong,
          gravity: Toast.bottom,
        );
      }
    } finally {
      if (mounted && geracao == _geracao) {
        setState(() => _carregando = false);
      }
    }
  }

  void _aoDigitarBusca(String valor) {
    _busca = valor;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reiniciar);
  }

  Future<void> _alternarFavorito(Planta planta) async {
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
            onChanged: _aoDigitarBusca,
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
                    onSelected: (_) {
                      setState(() => _filtro = f);
                      _reiniciar();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _lista(auth, favoritos)),
      ],
    );
  }

  Widget _lista(AuthService auth, FavoritosService favoritos) {
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
              onPressed: _reiniciar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_carregando && _plantas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _reiniciar,
      child: _plantas.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('Nenhuma planta encontrada')),
                ),
              ],
            )
          : ListView.builder(
              controller: _rolagem,
              padding: const EdgeInsets.symmetric(vertical: 8),
              // Um item extra no fim: indicador enquanto a próxima página chega
              itemCount: _plantas.length + 1,
              itemBuilder: (context, i) {
                if (i == _plantas.length) return _rodape();
                final planta = _plantas[i];
                return PlantaCard(
                  planta: planta,
                  onTap: () => context.read<GerenciadorEstado>().exibirDetalhes(
                    planta.id,
                  ),
                  favorita: favoritos.isFavorita(planta.id),
                  onFavoritar: auth.estaLogado
                      ? () => _alternarFavorito(planta)
                      : null,
                );
              },
            ),
    );
  }

  Widget _rodape() {
    if (!_carregando) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
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
