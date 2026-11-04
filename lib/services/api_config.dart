import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Endereços dos dois serviços da API. Mude com --dart-define (ver README).
class ApiConfig {
  /// No emulador Android, "localhost" é o próprio emulador; o PC é 10.0.2.2.
  static final _host =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';

  static final plantasApi = const String.fromEnvironment('PLANTAS_API').isEmpty
      ? 'http://$_host:8001'
      : const String.fromEnvironment('PLANTAS_API');
  static final usuariosApi =
      const String.fromEnvironment('USUARIOS_API').isEmpty
      ? 'http://$_host:8002'
      : const String.fromEnvironment('USUARIOS_API');

  /// Tempo máximo de espera por uma resposta da API.
  static const timeout = Duration(seconds: 10);

  /// Cabeçalho de autenticação das rotas de favoritos.
  static Map<String, String> autorizacao(String token) => {
    'Authorization': 'Bearer $token',
  };

  /// Repete uma requisição idempotente uma vez se a conexão reutilizada
  /// (keep-alive) já tinha sido fechada pelo servidor.
  static Future<T> repetirSeConexaoFechada<T>(
    Future<T> Function() requisicao,
  ) async {
    try {
      return await requisicao();
    } on http.ClientException {
      return requisicao();
    }
  }
}
