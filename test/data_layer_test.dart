import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jardim_facil/models/planta.dart';
import 'package:jardim_facil/services/auth_service.dart';
import 'package:jardim_facil/services/favoritos_service.dart';
import 'package:jardim_facil/services/planta_repository.dart';

import 'fake_api.dart';

void main() {
  group('PlantaRepository', () {
    late FakeApi api;
    late PlantaRepository repo;

    setUp(() {
      api = FakeApi();
      repo = PlantaRepository(client: api.client);
    });

    test('primeira página tem 10 plantas e indica que há mais', () async {
      final pagina = await repo.listar(pagina: 1);
      expect(pagina.itens.length, 10);
      expect(pagina.pagina, 1);
      expect(pagina.temMais, isTrue);
      expect(api.requisicoes.last.url.queryParameters, {
        'pagina': '1',
        'tamanho': '10',
      });
    });

    test('última página não tem mais itens', () async {
      final pagina = await repo.listar(pagina: 3);
      expect(pagina.itens.map((p) => p.nome), ['Zamioculca']);
      expect(pagina.temMais, isFalse);
    });

    test('busca e dificuldade são enviadas ao servidor', () async {
      final pagina = await repo.listar(
        pagina: 1,
        busca: 'manjer',
        dificuldade: 'Fácil',
      );
      expect(pagina.itens.map((p) => p.id), ['manjericao']);
      final query = api.requisicoes.last.url.queryParameters;
      expect(query['busca'], 'manjer');
      expect(query['dificuldade'], 'Fácil');
    });

    test('buscarPorId devolve a planta ou null se não existir', () async {
      expect((await repo.buscarPorId('cacto'))?.nome, 'Cacto');
      expect(await repo.buscarPorId('inexistente'), isNull);
    });

    test('buscarPorIds pede só as plantas indicadas', () async {
      final plantas = await repo.buscarPorIds(['samambaia', 'manjericao']);
      expect(plantas.map((p) => p.id), ['manjericao', 'samambaia']);

      final antes = api.requisicoes.length;
      expect(await repo.buscarPorIds([]), isEmpty);
      expect(api.requisicoes.length, antes);
    });

    test('erro do servidor vira exceção', () async {
      api.falharPlantas = true;
      await expectLater(repo.listar(pagina: 1), throwsException);
    });

    test('repete a requisição uma vez se a conexão foi fechada', () async {
      var tentativas = 0;
      final repo = PlantaRepository(
        client: MockClient((req) async {
          tentativas++;
          if (tentativas == 1) {
            throw http.ClientException('Connection closed', req.url);
          }
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'itens': plantasFake.take(2).toList(),
                'pagina': 1,
                'temMais': false,
              }),
            ),
            200,
          );
        }),
      );
      final pagina = await repo.listar(pagina: 1);
      expect(tentativas, 2);
      expect(pagina.itens.length, 2);
    });

    test('falha de conexão repetida chega ao chamador', () async {
      var tentativas = 0;
      final repo = PlantaRepository(
        client: MockClient((req) async {
          tentativas++;
          throw http.ClientException('Connection refused', req.url);
        }),
      );
      await expectLater(
        repo.listar(pagina: 1),
        throwsA(isA<http.ClientException>()),
      );
      expect(tentativas, 2);
    });

    test('Planta.fromJson e toJson são consistentes', () {
      final json = plantasFake.first;
      expect(Planta.fromJson(json).toJson(), json);
    });
  });

  group('AuthService', () {
    late FakeApi api;
    late AuthService auth;

    setUp(() {
      api = FakeApi();
      auth = AuthService(client: api.client);
    });

    test('login válido guarda usuário e token', () async {
      await auth.login('  Maria@jardim.com ', '123456');
      expect(auth.estaLogado, isTrue);
      expect(auth.usuarioLogado!.id, '1');
      expect(auth.usuarioLogado!.nome, 'Maria Silva');
      expect(auth.token, 'token-1');
      final corpo = jsonDecode(api.requisicoes.last.body) as Map;
      expect(corpo['email'], 'Maria@jardim.com');
    });

    test('senha errada lança erro com a mensagem da API', () async {
      await expectLater(
        auth.login('maria@jardim.com', 'errada'),
        throwsA(
          isA<ErroAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'E-mail ou senha inválidos',
          ),
        ),
      );
      expect(auth.estaLogado, isFalse);
      expect(auth.token, isNull);
    });

    test('falha de rede vira erro de conexão', () async {
      api.offline = true;
      await expectLater(
        auth.login('maria@jardim.com', '123456'),
        throwsA(
          isA<ErroAutenticacao>().having(
            (e) => e.mensagem,
            'mensagem',
            'Não foi possível conectar ao servidor',
          ),
        ),
      );
    });

    test('logout limpa usuário e token e notifica', () async {
      var chamadas = 0;
      auth.addListener(() => chamadas++);
      await auth.login('maria@jardim.com', '123456');
      auth.logout();
      expect(auth.estaLogado, isFalse);
      expect(auth.token, isNull);
      expect(chamadas, 2);
    });
  });

  group('FavoritosService', () {
    late FakeApi api;
    late AuthService auth;
    late FavoritosService favoritos;

    setUp(() {
      api = FakeApi();
      auth = AuthService(client: api.client);
      favoritos = FavoritosService(auth, client: api.client);
    });

    test('vazio e sem requisições quando não logado', () async {
      await favoritos.carregar();
      expect(favoritos.idsFavoritos, isEmpty);
      expect(api.requisicoes, isEmpty);
    });

    test('carregar traz os favoritos do usuário logado', () async {
      await auth.login('maria@jardim.com', '123456');
      await favoritos.carregar();
      expect(favoritos.idsFavoritos, {'samambaia', 'manjericao'});
      expect(favoritos.isFavorita('samambaia'), isTrue);
    });

    test('alternar envia PUT para favoritar e DELETE para desfazer', () async {
      await auth.login('maria@jardim.com', '123456');
      await favoritos.carregar();

      expect(await favoritos.alternar('cacto'), isTrue);
      expect(api.requisicoes.last.method, 'PUT');
      expect(api.favoritos['1'], contains('cacto'));

      expect(await favoritos.alternar('cacto'), isFalse);
      expect(api.requisicoes.last.method, 'DELETE');
      expect(favoritos.isFavorita('cacto'), isFalse);
      expect(api.favoritos['1'], isNot(contains('cacto')));
    });

    test('falha no servidor desfaz a mudança e relança o erro', () async {
      await auth.login('maria@jardim.com', '123456');
      await favoritos.carregar();
      api.falharFavoritos = true;

      await expectLater(favoritos.alternar('cacto'), throwsException);
      expect(favoritos.isFavorita('cacto'), isFalse);
      expect(favoritos.isFavorita('samambaia'), isTrue);
    });

    test('alternar sem login lança StateError', () async {
      await expectLater(favoritos.alternar('cacto'), throwsStateError);
    });

    test(
      'logout limpa favoritos e o login seguinte traz os do outro',
      () async {
        await auth.login('maria@jardim.com', '123456');
        await favoritos.carregar();
        auth.logout();
        expect(favoritos.idsFavoritos, isEmpty);

        await auth.login('joao@jardim.com', '123456');
        await favoritos.carregar();
        expect(favoritos.idsFavoritos, {'cacto'});
      },
    );

    test('filtrarFavoritas mantém a ordem da lista', () async {
      await auth.login('maria@jardim.com', '123456');
      await favoritos.carregar();
      final todas = plantasFake.map(Planta.fromJson).toList();
      expect(favoritos.filtrarFavoritas(todas).map((p) => p.id), [
        'manjericao',
        'samambaia',
      ]);
    });
  });
}
