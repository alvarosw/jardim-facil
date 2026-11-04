import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/usuario.dart';
import 'api_config.dart';

/// Falha no login, com a mensagem que vai para a tela.
class ErroAutenticacao implements Exception {
  final String mensagem;

  const ErroAutenticacao(this.mensagem);

  @override
  String toString() => mensagem;
}

class AuthService extends ChangeNotifier {
  final http.Client _client;
  Usuario? _usuarioLogado;
  String? _token;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Usuario? get usuarioLogado => _usuarioLogado;

  bool get estaLogado => _usuarioLogado != null;

  String? get token => _token;

  /// Entra no servidor. Lança [ErroAutenticacao] se as credenciais forem
  /// recusadas ou o servidor não responder.
  Future<void> login(String email, String senha) async {
    final http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse('${ApiConfig.usuariosApi}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'senha': senha}),
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {
      throw const ErroAutenticacao('Não foi possível conectar ao servidor');
    }
    if (resp.statusCode == 401) {
      throw const ErroAutenticacao('E-mail ou senha inválidos');
    }
    if (resp.statusCode != 200) {
      throw ErroAutenticacao('Erro no servidor (${resp.statusCode})');
    }
    final dados =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    _token = dados['token'] as String;
    _usuarioLogado = Usuario.fromJson(dados['usuario'] as Map<String, dynamic>);
    notifyListeners();
  }

  void logout() {
    _usuarioLogado = null;
    _token = null;
    notifyListeners();
  }
}
