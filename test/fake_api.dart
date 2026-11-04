import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Catálogo dos testes, na ordem em que a API devolve (por nome).
final List<Map<String, dynamic>> plantasFake = [
  _p('alecrim', 'Alecrim', 'Fácil'),
  _p('babosa', 'Babosa', 'Fácil'),
  _p('begonia', 'Begônia', 'Média'),
  _p('boa-noiva', 'Boa-noiva', 'Média'),
  _p('cacto', 'Cacto', 'Fácil'),
  _p('clorofito', 'Clorofito', 'Fácil'),
  _p('copo-de-leite', 'Copo-de-leite', 'Média'),
  _p('dinheiro-em-penca', 'Dinheiro-em-penca', 'Fácil'),
  _p('espada-de-sao-jorge', 'Espada-de-são-jorge', 'Fácil'),
  _p('hortela', 'Hortelã', 'Fácil'),
  _p('jiboia', 'Jiboia', 'Média'),
  _p('lavanda', 'Lavanda', 'Difícil'),
  _p('lirio-da-paz', 'Lírio-da-paz', 'Média'),
  _p('manjericao', 'Manjericão', 'Fácil'),
  _p('orquidea', 'Orquídea', 'Difícil'),
  _p('peperomia', 'Peperômia', 'Fácil'),
  _p('samambaia', 'Samambaia', 'Fácil'),
  _p('suculenta', 'Suculenta', 'Fácil'),
  _p('tradescantia', 'Tradescântia', 'Média'),
  _p('violeta-africana', 'Violeta-africana', 'Difícil'),
  _p('zamioculca', 'Zamioculca', 'Difícil'),
];

const usuariosFake = [
  {
    'id': '1',
    'nome': 'Maria Silva',
    'email': 'maria@jardim.com',
    'senha': '123456',
  },
  {
    'id': '2',
    'nome': 'João Souza',
    'email': 'joao@jardim.com',
    'senha': '123456',
  },
];

Map<String, dynamic> _p(String id, String nome, String dificuldade) => {
  'id': id,
  'nome': nome,
  'nomeCientifico': 'Nome científico de $nome',
  'emoji': '🌱',
  'descricao': 'Descrição de $nome',
  'luminosidade': 'Luz indireta',
  'rega': 'Uma vez por semana',
  'dificuldade': dificuldade,
  'dica': 'Dica de cuidado de $nome',
};

/// Servidor falso das duas APIs (contrato em backend/API.md), sem rede.
/// Guarda os favoritos em memória e registra cada requisição feita.
class FakeApi {
  final List<http.Request> requisicoes = [];
  final List<Map<String, dynamic>> plantas;
  final Map<String, Set<String>> favoritos = {
    '1': {'samambaia', 'manjericao'},
    '2': {'cacto'},
  };

  bool falharPlantas = false;
  bool falharFavoritos = false;
  bool offline = false;
  Completer<void>? atrasoLogin;

  late final http.Client client = MockClient(_responder);

  FakeApi({List<Map<String, dynamic>>? plantas})
    : plantas = plantas ?? plantasFake;

  /// Páginas pedidas na listagem (sem as buscas por ids).
  List<int> get paginasSolicitadas => requisicoes
      .where(
        (r) =>
            r.url.path == '/plantas' &&
            !r.url.queryParameters.containsKey('ids'),
      )
      .map((r) => int.parse(r.url.queryParameters['pagina']!))
      .toList();

  Future<http.Response> _responder(http.Request req) async {
    requisicoes.add(req);
    if (offline) throw http.ClientException('Sem conexão', req.url);
    final caminho = req.url.path;
    if (caminho == '/auth/login') {
      await atrasoLogin?.future;
      return _login(req);
    }
    if (caminho.startsWith('/plantas')) return _plantas(req);
    if (caminho.startsWith('/favoritos')) return _favoritos(req);
    return _json(404, {'detail': 'Não encontrado'});
  }

  http.Response _login(http.Request req) {
    final corpo = jsonDecode(req.body) as Map<String, dynamic>;
    final email = (corpo['email'] as String).trim().toLowerCase();
    final usuario = usuariosFake.where(
      (u) => u['email'] == email && u['senha'] == corpo['senha'],
    );
    if (usuario.isEmpty) {
      return _json(401, {'detail': 'E-mail ou senha inválidos'});
    }
    final u = usuario.first;
    return _json(200, {
      'token': 'token-${u['id']}',
      'usuario': {'id': u['id'], 'nome': u['nome'], 'email': u['email']},
    });
  }

  http.Response _plantas(http.Request req) {
    if (falharPlantas) return _json(500, {'detail': 'Erro interno'});
    final caminho = req.url.path;
    final q = req.url.queryParameters;
    if (caminho != '/plantas') {
      final id = caminho.substring('/plantas/'.length);
      final achadas = plantas.where((p) => p['id'] == id);
      if (achadas.isEmpty) {
        return _json(404, {'detail': 'Planta não encontrada'});
      }
      return _json(200, achadas.first);
    }
    final ids = q['ids']?.split(',');
    final busca = (q['busca'] ?? '').toLowerCase();
    final dificuldade = q['dificuldade'];
    final lista = plantas.where((p) {
      return (p['nome'] as String).toLowerCase().contains(busca) &&
          (ids == null || ids.contains(p['id'])) &&
          (dificuldade == null || p['dificuldade'] == dificuldade);
    }).toList()..sort((a, b) => (a['nome'] as String).compareTo(b['nome']));
    final pagina = int.parse(q['pagina'] ?? '1');
    final tamanho = int.parse(q['tamanho'] ?? '10');
    return _json(200, {
      'itens': lista.skip((pagina - 1) * tamanho).take(tamanho).toList(),
      'pagina': pagina,
      'tamanho': tamanho,
      'total': lista.length,
      'temMais': pagina * tamanho < lista.length,
    });
  }

  http.Response _favoritos(http.Request req) {
    final uid = req.headers['authorization']?.replaceFirst('Bearer token-', '');
    if (!usuariosFake.any((u) => u['id'] == uid)) {
      return _json(401, {'detail': 'Não autenticado'});
    }
    final ids = favoritos.putIfAbsent(uid!, () => <String>{});
    if (req.url.path == '/favoritos' && req.method == 'GET') {
      return _json(200, {'ids': ids.toList()});
    }
    if (falharFavoritos) return _json(500, {'detail': 'Erro interno'});
    final plantaId = req.url.path.substring('/favoritos/'.length);
    if (req.method == 'PUT') ids.add(plantaId);
    if (req.method == 'DELETE') ids.remove(plantaId);
    return http.Response('', 204);
  }

  http.Response _json(int status, Object corpo) => http.Response(
    jsonEncode(corpo),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
