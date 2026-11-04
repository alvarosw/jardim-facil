import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardim_facil/main.dart';
import 'package:jardim_facil/services/auth_service.dart';
import 'package:jardim_facil/services/favoritos_service.dart';
import 'package:jardim_facil/services/planta_repository.dart';

import 'fake_api.dart';

// Sobe o app com os serviços apontando para o servidor falso.
Future<FakeApi> abrirApp(WidgetTester tester, {FakeApi? api}) async {
  final servidor = api ?? FakeApi();
  final auth = AuthService(client: servidor.client);
  await tester.pumpWidget(
    JardimFacil(
      repository: PlantaRepository(client: servidor.client),
      auth: auth,
      favoritos: FavoritosService(auth, client: servidor.client),
    ),
  );
  await tester.pumpAndSettle();
  return servidor;
}

// O toast some sozinho após 3s; esperamos para não deixar timer pendente.
Future<void> aguardarToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
}

// A busca tem debounce de 400ms.
Future<void> digitarBusca(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

// Abre o login e envia o formulário, sem esperar a resposta.
Future<void> enviarLogin(WidgetTester tester, String senha) async {
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('campoEmail')),
    'maria@jardim.com',
  );
  await tester.enterText(find.byKey(const Key('campoSenha')), senha);
  await tester.tap(find.byKey(const Key('botaoEntrar')));
}

Future<void> fazerLogin(WidgetTester tester, String senha) async {
  await enviarLogin(tester, senha);
  await tester.pumpAndSettle();
  await aguardarToast(tester);
}

// A lista de plantas (única ListView dentro do RefreshIndicator).
final lista = find.descendant(
  of: find.byType(RefreshIndicator),
  matching: find.byType(Scrollable),
);

void main() {
  testWidgets('lista mostra a primeira página vinda da API', (tester) async {
    final api = await abrirApp(tester);
    expect(find.text('Jardim Fácil'), findsOneWidget);
    expect(find.text('Alecrim'), findsOneWidget);
    expect(api.paginasSolicitadas, [1]);
    expect(api.requisicoes.last.url.queryParameters, {
      'pagina': '1',
      'tamanho': '10',
    });
  });

  testWidgets('rolar até o fim carrega as próximas páginas, até acabar', (
    tester,
  ) async {
    final api = await abrirApp(tester);
    expect(api.paginasSolicitadas, [1]);

    await tester.scrollUntilVisible(
      find.text('Zamioculca'),
      500,
      scrollable: lista,
    );
    await tester.pumpAndSettle();
    expect(api.paginasSolicitadas, [1, 2, 3]);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('atualizar (puxar para baixo) volta à página 1', (tester) async {
    final api = await abrirApp(tester);
    await tester.scrollUntilVisible(
      find.text('Zamioculca'),
      500,
      scrollable: lista,
    );
    await tester.pumpAndSettle();
    expect(api.paginasSolicitadas, [1, 2, 3]);

    // O gesto de puxar chama o onRefresh do RefreshIndicator
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(api.paginasSolicitadas.last, 1);
    expect(find.text('Alecrim'), findsOneWidget);
  });

  testWidgets('busca vai ao servidor e mostra mensagem de vazio', (
    tester,
  ) async {
    final api = await abrirApp(tester);
    await digitarBusca(tester, 'manjer');
    expect(find.text('Manjericão'), findsOneWidget);
    expect(find.text('Alecrim'), findsNothing);
    expect(api.requisicoes.last.url.queryParameters['busca'], 'manjer');
    expect(api.paginasSolicitadas.last, 1);

    await digitarBusca(tester, 'zzz');
    expect(find.text('Nenhuma planta encontrada'), findsOneWidget);
  });

  testWidgets('filtro de dificuldade vai ao servidor', (tester) async {
    final api = await abrirApp(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Difícil'));
    await tester.pumpAndSettle();
    expect(api.requisicoes.last.url.queryParameters['dificuldade'], 'Difícil');
    expect(find.text('Orquídea'), findsOneWidget);
    expect(find.text('Alecrim'), findsNothing);
  });

  testWidgets('erro ao carregar mostra Tentar novamente', (tester) async {
    final api = FakeApi()..falharPlantas = true;
    await abrirApp(tester, api: api);
    expect(find.text('Não foi possível carregar as plantas'), findsOneWidget);

    api.falharPlantas = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Alecrim'), findsOneWidget);
  });

  testWidgets('toque na planta abre os detalhes da API', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Alecrim'));
    await tester.pumpAndSettle();
    expect(find.text('Luminosidade'), findsOneWidget);
    expect(find.text('Rega'), findsOneWidget);
    expect(find.text('Dificuldade'), findsOneWidget);
    // A dica fica no fim da lista rolável.
    await tester.scrollUntilVisible(find.text('Dica de cuidado'), 200);
    expect(find.text('Dica de cuidado'), findsOneWidget);
  });

  testWidgets('usuário anônimo não vê coração nem Meu jardim', (tester) async {
    await abrirApp(tester);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.byTooltip('Meu jardim'), findsNothing);
    expect(
      find.text('Entre para salvar suas plantas favoritas'),
      findsOneWidget,
    );
  });

  testWidgets('login com sucesso mostra Meu jardim', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, '123456');
    expect(find.byTooltip('Meu jardim'), findsOneWidget);
    expect(find.text('Olá, Maria!'), findsOneWidget);
  });

  testWidgets('botão Entrar mostra spinner enquanto espera o servidor', (
    tester,
  ) async {
    final api = await abrirApp(tester);
    api.atrasoLogin = Completer<void>();
    await enviarLogin(tester, '123456');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('botaoEntrar')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    api.atrasoLogin!.complete();
    await tester.pumpAndSettle();
    await aguardarToast(tester);
    expect(find.byTooltip('Meu jardim'), findsOneWidget);
  });

  testWidgets('senha errada mostra erro da API', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, 'errada');
    expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
    expect(find.byKey(const Key('botaoEntrar')), findsOneWidget);
  });

  testWidgets('falha de conexão no login mostra erro', (tester) async {
    final api = await abrirApp(tester);
    api.offline = true;
    await fazerLogin(tester, '123456');
    expect(find.text('Não foi possível conectar ao servidor'), findsOneWidget);
  });

  testWidgets('favoritos do usuário aparecem em Meu jardim', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, '123456');
    await tester.tap(find.byTooltip('Meu jardim'));
    await tester.pumpAndSettle();
    expect(find.text('Manjericão'), findsOneWidget);
    expect(find.text('Samambaia'), findsOneWidget);
    expect(find.text('Alecrim'), findsNothing);
  });

  testWidgets('favoritar nos detalhes aparece em Meu jardim', (tester) async {
    final api = await abrirApp(tester);
    await fazerLogin(tester, '123456');
    await tester.tap(find.text('Alecrim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao meu jardim'));
    await tester.pumpAndSettle();
    expect(find.text('Remover do meu jardim'), findsOneWidget);
    expect(api.favoritos['1'], contains('alecrim'));
    await aguardarToast(tester);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Meu jardim'));
    await tester.pumpAndSettle();
    expect(find.text('Alecrim'), findsOneWidget);
    expect(find.text('Manjericão'), findsOneWidget);
  });

  testWidgets('falha ao favoritar na lista desfaz e avisa', (tester) async {
    final api = await abrirApp(tester);
    await fazerLogin(tester, '123456');
    api.falharFavoritos = true;
    await tester.tap(find.byTooltip('Favoritar').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível atualizar seus favoritos'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.favorite), findsNothing);
    await aguardarToast(tester);
  });

  testWidgets('detalhe anônimo pede login ao favoritar', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Alecrim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao meu jardim'));
    await tester.pump();
    expect(find.text('Faça login para favoritar'), findsOneWidget);
    await aguardarToast(tester);
  });

  testWidgets('logout esconde Meu jardim', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, '123456');
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Meu jardim'), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
    await aguardarToast(tester);
  });
}
