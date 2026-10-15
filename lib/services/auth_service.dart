import 'package:flutter/foundation.dart';

import '../models/usuario.dart';

class AuthService extends ChangeNotifier {
  static const List<Usuario> usuariosMock = [
    Usuario(
        id: '1', nome: 'Maria Silva', email: 'maria@jardim.com', senha: '123456'),
    Usuario(
        id: '2', nome: 'João Souza', email: 'joao@jardim.com', senha: '123456'),
  ];

  Usuario? _usuarioLogado;

  Usuario? get usuarioLogado => _usuarioLogado;

  bool get estaLogado => _usuarioLogado != null;

  bool login(String email, String senha) {
    final emailNormalizado = email.trim().toLowerCase();
    for (final u in usuariosMock) {
      if (u.email == emailNormalizado && u.senha == senha) {
        _usuarioLogado = u;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }
}
