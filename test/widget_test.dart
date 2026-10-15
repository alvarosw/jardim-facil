import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardim_facil/main.dart';
import 'package:jardim_facil/services/auth_service.dart';
import 'package:jardim_facil/services/favoritos_service.dart';
import 'package:jardim_facil/services/planta_repository.dart';

// Sobe o app com serviços novos a cada teste, usando os JSON reais.
Future<void> abrirApp(WidgetTester tester) async {
  final auth = AuthService();
  final favoritos = FavoritosService(auth);
  final repository = PlantaRepository();
  // Os assets são lidos com I/O real: carregamos fora do relógio falso do teste.
  await tester.runAsync(() async {
    await repository.carregarPlantas();
    await favoritos.carregar();
  });
  await tester.pumpWidget(JardimFacil(
    repository: repository,
    auth: auth,
    favoritos: favoritos,
  ));
  await tester.pumpAndSettle();
}

// O toast some sozinho após 3s; esperamos para não deixar timer pendente.
Future<void> aguardarToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
}

Future<void> fazerLogin(WidgetTester tester, String senha) async {
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('campoEmail')), 'maria@jardim.com');
  await tester.enterText(find.byKey(const Key('campoSenha')), senha);
  await tester.tap(find.byKey(const Key('botaoEntrar')));
  await tester.pumpAndSettle();
  await aguardarToast(tester);
}

void main() {
  testWidgets('lista mostra as plantas carregadas do JSON', (tester) async {
    await abrirApp(tester);
    expect(find.text('Jardim Fácil'), findsOneWidget);
    expect(find.text('Suculenta'), findsOneWidget);
    expect(find.text('Manjericão'), findsOneWidget);
  });

  testWidgets('toque na planta abre os detalhes', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Suculenta'));
    await tester.pumpAndSettle();
    expect(find.text('Luminosidade'), findsOneWidget);
    expect(find.text('Rega'), findsOneWidget);
    expect(find.text('Dificuldade'), findsOneWidget);
    // A dica fica no fim da lista rolável.
    await tester.scrollUntilVisible(find.text('Dica de cuidado'), 200);
    expect(find.text('Dica de cuidado'), findsOneWidget);
  });

  testWidgets('busca filtra e mostra mensagem de vazio', (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byType(TextField), 'manjer');
    await tester.pumpAndSettle();
    expect(find.text('Manjericão'), findsOneWidget);
    expect(find.text('Suculenta'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma planta encontrada'), findsOneWidget);
  });

  testWidgets('usuário anônimo não vê coração nem Meu jardim', (tester) async {
    await abrirApp(tester);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.byTooltip('Meu jardim'), findsNothing);
    expect(find.text('Entre para salvar suas plantas favoritas'), findsOneWidget);
  });

  testWidgets('login com sucesso mostra Meu jardim', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, '123456');
    expect(find.byTooltip('Meu jardim'), findsOneWidget);
    expect(find.text('Olá, Maria!'), findsOneWidget);
  });

  testWidgets('senha errada mostra erro', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, 'errada');
    expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
    expect(find.byKey(const Key('botaoEntrar')), findsOneWidget);
  });

  testWidgets('favoritar nos detalhes aparece em Meu jardim', (tester) async {
    await abrirApp(tester);
    await fazerLogin(tester, '123456');
    await tester.tap(find.text('Suculenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar ao meu jardim'));
    await tester.pumpAndSettle();
    expect(find.text('Remover do meu jardim'), findsOneWidget);
    await aguardarToast(tester);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Meu jardim'));
    await tester.pumpAndSettle();
    expect(find.text('Suculenta'), findsOneWidget);
  });

  testWidgets('detalhe anônimo pede login ao favoritar', (tester) async {
    await abrirApp(tester);
    await tester.tap(find.text('Suculenta'));
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
