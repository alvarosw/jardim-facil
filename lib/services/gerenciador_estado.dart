import 'package:flutter/foundation.dart';

enum EmExibicao { telaPlantas, telaDetalhes, telaLogin, telaMeuJardim }

/// Diz qual tela está em exibição. Substitui a navegação por rotas.
class GerenciadorEstado extends ChangeNotifier {
  EmExibicao _exibicao = EmExibicao.telaPlantas;
  EmExibicao get exibicao => _exibicao;

  String _idPlanta = '';
  String get idPlanta => _idPlanta;

  void exibirPlantas() {
    _exibicao = EmExibicao.telaPlantas;
    notifyListeners();
  }

  void exibirDetalhes(String idPlanta) {
    _exibicao = EmExibicao.telaDetalhes;
    _idPlanta = idPlanta;
    notifyListeners();
  }

  void exibirLogin() {
    _exibicao = EmExibicao.telaLogin;
    notifyListeners();
  }

  void exibirMeuJardim() {
    _exibicao = EmExibicao.telaMeuJardim;
    notifyListeners();
  }
}
