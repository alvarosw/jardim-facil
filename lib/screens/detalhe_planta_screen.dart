import 'package:flutter/material.dart';

import '../models/planta.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../widgets/dificuldade_chip.dart';
import '../widgets/info_card.dart';
import 'login_screen.dart';

/// Detalhes de uma planta, com opção de adicionar ao jardim (usuário logado).
class DetalhePlantaScreen extends StatefulWidget {
  final Planta planta;
  final AuthService auth;
  final FavoritosService favoritos;

  const DetalhePlantaScreen({
    super.key,
    required this.planta,
    required this.auth,
    required this.favoritos,
  });

  @override
  State<DetalhePlantaScreen> createState() => _DetalhePlantaScreenState();
}

class _DetalhePlantaScreenState extends State<DetalhePlantaScreen> {
  Future<void> _entrar() async {
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

  void _alternar() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (!widget.auth.estaLogado) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Faça login para favoritar'),
        action: SnackBarAction(label: 'Entrar', onPressed: _entrar),
      ));
      return;
    }
    final agoraFavorita = widget.favoritos.alternar(widget.planta.id);
    messenger.showSnackBar(SnackBar(
      content: Text(agoraFavorita
          ? '${widget.planta.nome} adicionada ao seu jardim'
          : '${widget.planta.nome} removida do seu jardim'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final planta = widget.planta;
    final cores = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.auth, widget.favoritos]),
      builder: (context, _) {
        final favorita = widget.auth.estaLogado &&
            widget.favoritos.isFavorita(planta.id);
        return Scaffold(
          appBar: AppBar(title: Text(planta.nome)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _alternar,
            icon: Icon(favorita ? Icons.favorite : Icons.favorite_border),
            label: Text(favorita
                ? 'Remover do meu jardim'
                : 'Adicionar ao meu jardim'),
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
              Text(
                planta.nome,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                planta.nomeCientifico,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Text(planta.descricao,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              InfoCard(
                icone: Icons.wb_sunny,
                titulo: 'Luminosidade',
                valor: planta.luminosidade,
              ),
              InfoCard(
                icone: Icons.water_drop,
                titulo: 'Rega',
                valor: planta.rega,
              ),
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
      },
    );
  }
}
