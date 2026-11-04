import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/planta.dart';
import 'api_config.dart';

/// Uma página de plantas devolvida pelo plantas-service.
class PaginaPlantas {
  final List<Planta> itens;
  final int pagina;
  final bool temMais;

  const PaginaPlantas({
    required this.itens,
    required this.pagina,
    required this.temMais,
  });
}

/// Acesso às plantas no plantas-service (ver backend/API.md).
class PlantaRepository {
  final http.Client _client;

  PlantaRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Uma página do catálogo, já filtrada pela busca e pela dificuldade.
  Future<PaginaPlantas> listar({
    required int pagina,
    int tamanho = 10,
    String busca = '',
    String? dificuldade,
  }) {
    return _listar({
      'pagina': '$pagina',
      'tamanho': '$tamanho',
      if (busca.isNotEmpty) 'busca': busca,
      'dificuldade': ?dificuldade,
    });
  }

  /// Plantas com os ids dados, em lotes de 50 (máximo aceito pela API).
  Future<List<Planta>> buscarPorIds(List<String> ids) async {
    final plantas = <Planta>[];
    for (var i = 0; i < ids.length; i += 50) {
      final lote = ids.skip(i).take(50).join(',');
      final pagina = await _listar({'ids': lote, 'tamanho': '50'});
      plantas.addAll(pagina.itens);
    }
    return plantas;
  }

  /// Uma planta pelo id, ou null se não existir.
  Future<Planta?> buscarPorId(String id) async {
    final resp = await ApiConfig.repetirSeConexaoFechada(
      () => _client
          .get(Uri.parse('${ApiConfig.plantasApi}/plantas/$id'))
          .timeout(ApiConfig.timeout),
    );
    if (resp.statusCode == 404) return null;
    _verificar(resp);
    return Planta.fromJson(_decodificar(resp) as Map<String, dynamic>);
  }

  Future<PaginaPlantas> _listar(Map<String, String> parametros) async {
    final uri = Uri.parse('${ApiConfig.plantasApi}/plantas')
        .replace(queryParameters: parametros);
    final resp = await ApiConfig.repetirSeConexaoFechada(
      () => _client.get(uri).timeout(ApiConfig.timeout),
    );
    _verificar(resp);
    final dados = _decodificar(resp) as Map<String, dynamic>;
    return PaginaPlantas(
      itens: (dados['itens'] as List<dynamic>)
          .map((e) => Planta.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagina: dados['pagina'] as int,
      temMais: dados['temMais'] as bool,
    );
  }

  void _verificar(http.Response resp) {
    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode} ao consultar plantas');
    }
  }

  dynamic _decodificar(http.Response resp) =>
      jsonDecode(utf8.decode(resp.bodyBytes));
}
