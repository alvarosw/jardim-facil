import 'package:flutter/material.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../services/planta_repository.dart';
import '../widgets/planta_card.dart';
import 'detalhe_planta_screen.dart';
import 'login_screen.dart';
import 'meu_jardim_screen.dart';

/// Tela inicial: lista de plantas com busca e filtro por dificuldade.
class ListaPlantasScreen extends StatefulWidget {
  final PlantaRepository repository;
  final AuthService auth;
  final FavoritosService favoritos;

  const ListaPlantasScreen({
    super.key,
    required this.repository,
    required this.auth,
    required this.favoritos,
  });

  @override
  State<ListaPlantasScreen> createState() => _ListaPlantasScreenState();
}

class _ListaPlantasScreenState extends State<ListaPlantasScreen> {
  static const _filtros = ['Todas', 'Fácil', 'Média', 'Difícil'];

  late Future<List<Planta>> _futuro;
  String _busca = '';
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Planta>> _carregar() async {
    final plantas = await widget.repository.carregarPlantas();
    await widget.favoritos.carregar();
    return plantas;
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _abrirLogin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(auth: widget.auth)),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bem-vindo(a), ${widget.auth.usuarioLogado?.nome}!'),
      ));
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
    if (sair == true) widget.auth.logout();
  }

  void _abrirDetalhe(Planta planta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhePlantaScreen(
          planta: planta,
          auth: widget.auth,
          favoritos: widget.favoritos,
        ),
      ),
    );
  }

  void _abrirMeuJardim(List<Planta> plantas) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeuJardimScreen(
          plantas: plantas,
          auth: widget.auth,
          favoritos: widget.favoritos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.auth, widget.favoritos]),
      builder: (context, _) {
        return FutureBuilder<List<Planta>>(
          future: _futuro,
          builder: (context, snapshot) {
            final plantas = snapshot.data;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Jardim Fácil'),
                actions: _acoes(plantas),
              ),
              body: Column(
                children: [
                  _banner(),
                  Expanded(child: _corpo(snapshot)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _acoes(List<Planta>? plantas) {
    if (widget.auth.estaLogado) {
      return [
        IconButton(
          tooltip: 'Meu jardim',
          icon: const Icon(Icons.yard),
          onPressed: plantas == null ? null : () => _abrirMeuJardim(plantas),
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
        onPressed: _abrirLogin,
        icon: const Icon(Icons.login),
        label: const Text('Entrar'),
      ),
    ];
  }

  Widget _banner() {
    final cores = Theme.of(context).colorScheme;
    final logado = widget.auth.estaLogado;
    final nome = widget.auth.usuarioLogado?.nome.split(' ').first ?? '';
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

  Widget _corpo(AsyncSnapshot<List<Planta>> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            const Text('Não foi possível carregar as plantas'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _recarregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    final todas = snapshot.data ?? [];
    final busca = _busca.trim().toLowerCase();
    final filtradas = todas.where((p) {
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
          child: filtradas.isEmpty
              ? const Center(child: Text('Nenhuma planta encontrada'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtradas.length,
                  itemBuilder: (context, i) {
                    final planta = filtradas[i];
                    return PlantaCard(
                      planta: planta,
                      onTap: () => _abrirDetalhe(planta),
                      favorita: widget.favoritos.isFavorita(planta.id),
                      onFavoritar: widget.auth.estaLogado
                          ? () => widget.favoritos.alternar(planta.id)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
