import 'package:flutter_test/flutter_test.dart';
import 'package:jardim_facil/models/planta.dart';
import 'package:jardim_facil/services/auth_service.dart';
import 'package:jardim_facil/services/favoritos_service.dart';
import 'package:jardim_facil/services/planta_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlantaRepository', () {
    test('carrega as 12 plantas com todos os campos', () async {
      final plantas = await PlantaRepository().carregarPlantas();
      expect(plantas.length, 12);
      final ids = plantas.map((p) => p.id).toSet();
      expect(ids.length, 12);
      expect(
        ids,
        containsAll([
          'suculenta',
          'samambaia',
          'espada-de-sao-jorge',
          'manjericao',
        ]),
      );
      for (final p in plantas) {
        expect(p.nome, isNotEmpty);
        expect(p.nomeCientifico, isNotEmpty);
        expect(p.emoji, isNotEmpty);
        expect(p.descricao, isNotEmpty);
        expect(p.luminosidade, isNotEmpty);
        expect(p.rega, isNotEmpty);
        expect(['Fácil', 'Média', 'Difícil'], contains(p.dificuldade));
        expect(p.dica, isNotEmpty);
      }
    });

    test('toJson e fromJson são consistentes', () async {
      final p = (await PlantaRepository().carregarPlantas()).first;
      expect(Planta.fromJson(p.toJson()).toJson(), p.toJson());
    });

    test('buscarPorId', () async {
      final repo = PlantaRepository();
      final p = await repo.buscarPorId('cacto');
      expect(p, isNotNull);
      expect(p!.nome, 'Cacto');
      expect(await repo.buscarPorId('inexistente'), isNull);
    });
  });

  group('AuthService', () {
    late AuthService auth;
    setUp(() => auth = AuthService());

    test('login válido', () {
      expect(auth.login('maria@jardim.com', '123456'), isTrue);
      expect(auth.estaLogado, isTrue);
      expect(auth.usuarioLogado!.id, '1');
    });

    test('login inválido', () {
      expect(auth.login('maria@jardim.com', 'errada'), isFalse);
      expect(auth.login('outro@jardim.com', '123456'), isFalse);
      expect(auth.estaLogado, isFalse);
    });

    test('e-mail ignora maiúsculas e espaços', () {
      expect(auth.login('  JOAO@Jardim.com ', '123456'), isTrue);
      expect(auth.usuarioLogado!.nome, 'João Souza');
    });

    test('logout notifica e limpa usuário', () {
      var chamadas = 0;
      auth.addListener(() => chamadas++);
      auth.login('maria@jardim.com', '123456');
      auth.logout();
      expect(auth.estaLogado, isFalse);
      expect(auth.usuarioLogado, isNull);
      expect(chamadas, 2);
    });
  });

  group('FavoritosService', () {
    late AuthService auth;
    late FavoritosService favoritos;

    setUp(() async {
      auth = AuthService();
      favoritos = FavoritosService(auth);
      await favoritos.carregar();
    });

    test('vazio quando não logado', () {
      expect(favoritos.idsFavoritos, isEmpty);
      expect(favoritos.isFavorita('samambaia'), isFalse);
    });

    test('carrega favoritos iniciais do usuário', () async {
      auth.login('maria@jardim.com', '123456');
      expect(favoritos.idsFavoritos, {'samambaia', 'manjericao'});
      await favoritos.carregar(); // idempotente
      expect(favoritos.idsFavoritos.length, 2);
    });

    test('alternar adiciona e remove', () {
      auth.login('maria@jardim.com', '123456');
      expect(favoritos.alternar('cacto'), isTrue);
      expect(favoritos.isFavorita('cacto'), isTrue);
      expect(favoritos.alternar('cacto'), isFalse);
      expect(favoritos.isFavorita('cacto'), isFalse);
    });

    test('alternar sem login lança StateError', () {
      expect(() => favoritos.alternar('cacto'), throwsStateError);
    });

    test('favoritos isolados por usuário e preservados no relogin', () {
      auth.login('maria@jardim.com', '123456');
      favoritos.alternar('babosa');
      auth.logout();
      auth.login('joao@jardim.com', '123456');
      expect(favoritos.idsFavoritos, {'cacto'});
      auth.logout();
      auth.login('maria@jardim.com', '123456');
      expect(favoritos.isFavorita('babosa'), isTrue);
    });

    test('notifica ao mudar autenticação', () {
      var chamadas = 0;
      favoritos.addListener(() => chamadas++);
      auth.login('maria@jardim.com', '123456');
      expect(chamadas, 1);
    });

    test('filtrarFavoritas mantém a ordem da lista', () async {
      final todas = await PlantaRepository().carregarPlantas();
      auth.login('maria@jardim.com', '123456');
      final ids = favoritos.filtrarFavoritas(todas).map((p) => p.id).toList();
      expect(ids, ['samambaia', 'manjericao']);
    });
  });
}
