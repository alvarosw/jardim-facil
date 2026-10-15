import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import 'screens/detalhe_planta_screen.dart';
import 'screens/lista_plantas_screen.dart';
import 'screens/login_screen.dart';
import 'screens/meu_jardim_screen.dart';
import 'services/auth_service.dart';
import 'services/favoritos_service.dart';
import 'services/gerenciador_estado.dart';
import 'services/planta_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JardimFacil());
}

class JardimFacil extends StatelessWidget {
  // Serviços opcionais: permitem injetar instâncias pré-carregadas nos testes.
  final PlantaRepository? repository;
  final AuthService? auth;
  final FavoritosService? favoritos;

  const JardimFacil({super.key, this.repository, this.auth, this.favoritos});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GerenciadorEstado()),
        ChangeNotifierProvider(create: (_) => auth ?? AuthService()),
        ChangeNotifierProvider(
          create: (context) =>
              favoritos ?? FavoritosService(context.read<AuthService>()),
        ),
        Provider(create: (_) => repository ?? PlantaRepository()),
      ],
      child: MaterialApp(
        title: 'Jardim Fácil',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        ),
        home: const TelaPrincipal(),
      ),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  @override
  void initState() {
    super.initState();
    ToastContext().init(context);
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<GerenciadorEstado>();

    Widget tela = const SizedBox.shrink();
    switch (estado.exibicao) {
      case EmExibicao.telaPlantas:
        tela = const ListaPlantasScreen();
      case EmExibicao.telaDetalhes:
        tela = const DetalhePlantaScreen();
      case EmExibicao.telaLogin:
        tela = const LoginScreen();
      case EmExibicao.telaMeuJardim:
        tela = const MeuJardimScreen();
    }

    // Botão voltar do sistema volta para a lista, como antes com as rotas.
    return PopScope(
      canPop: estado.exibicao == EmExibicao.telaPlantas,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) estado.exibirPlantas();
      },
      child: tela,
    );
  }
}
