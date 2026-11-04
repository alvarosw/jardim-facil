import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/planta.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Favoritos do usuário logado, sincronizados com o usuarios-service.
class FavoritosService extends ChangeNotifier {
  final AuthService auth;
  final http.Client _client;
  Set<String> _ids = <String>{};

  FavoritosService(this.auth, {http.Client? client})
    : _client = client ?? http.Client() {
    // Carrega ao entrar e limpa ao sair
    auth.addListener(_aoMudarAutenticacao);
  }

  @override
  void dispose() {
    auth.removeListener(_aoMudarAutenticacao);
    super.dispose();
  }

  void _aoMudarAutenticacao() {
    if (auth.estaLogado) {
      carregar().catchError((_) {}); // sem favoritos, a lista fica vazia
    } else {
      _ids = <String>{};
      notifyListeners();
    }
  }

  /// Busca os ids favoritos do usuário logado (GET /favoritos).
  Future<void> carregar() async {
    final token = auth.token;
    if (token == null) return;
    final resp = await ApiConfig.repetirSeConexaoFechada(
      () => _client
          .get(
            Uri.parse('${ApiConfig.usuariosApi}/favoritos'),
            headers: ApiConfig.autorizacao(token),
          )
          .timeout(ApiConfig.timeout),
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode} ao carregar favoritos');
    }
    // Ignora a resposta se o usuário saiu ou trocou enquanto esperava
    if (auth.token != token) return;
    final dados =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    _ids = (dados['ids'] as List<dynamic>).cast<String>().toSet();
    notifyListeners();
  }

  Set<String> get idsFavoritos => Set.unmodifiable(_ids);

  bool isFavorita(String plantaId) => _ids.contains(plantaId);

  /// Favorita ou desfavorita a planta. A mudança aparece na hora; se o
  /// servidor recusar, volta ao estado anterior e o erro é relançado.
  Future<bool> alternar(String plantaId) async {
    final token = auth.token;
    if (token == null) {
      throw StateError('É necessário estar logado para favoritar plantas.');
    }
    final novoEstado = !_ids.contains(plantaId);
    _marcar(plantaId, novoEstado);
    try {
      final uri = Uri.parse('${ApiConfig.usuariosApi}/favoritos/$plantaId');
      final headers = ApiConfig.autorizacao(token);
      final resp = await ApiConfig.repetirSeConexaoFechada(
        () => novoEstado
            ? _client.put(uri, headers: headers).timeout(ApiConfig.timeout)
            : _client.delete(uri, headers: headers).timeout(ApiConfig.timeout),
      );
      if (resp.statusCode >= 300) {
        throw Exception('Erro ${resp.statusCode} ao atualizar favorito');
      }
    } catch (_) {
      _marcar(plantaId, !novoEstado);
      rethrow;
    }
    return novoEstado;
  }

  void _marcar(String plantaId, bool favorita) {
    if (favorita) {
      _ids.add(plantaId);
    } else {
      _ids.remove(plantaId);
    }
    notifyListeners();
  }

  List<Planta> filtrarFavoritas(List<Planta> todas) {
    return todas.where((p) => _ids.contains(p.id)).toList();
  }
}
