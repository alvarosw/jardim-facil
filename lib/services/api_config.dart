import 'package:http/http.dart' as http;

/// Endereços dos dois serviços da API. Mude com --dart-define (ver README).
class ApiConfig {
  static const plantasApi = String.fromEnvironment(
    'PLANTAS_API',
    defaultValue: 'http://localhost:8001',
  );
  static const usuariosApi = String.fromEnvironment(
    'USUARIOS_API',
    defaultValue: 'http://localhost:8002',
  );

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
