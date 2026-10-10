import 'package:flutter/material.dart';

import 'screens/lista_plantas_screen.dart';
import 'services/auth_service.dart';
import 'services/favoritos_service.dart';
import 'services/planta_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JardimFacilApp());
}

class JardimFacilApp extends StatelessWidget {
  // Serviços opcionais: permitem injetar instâncias novas nos testes.
  final PlantaRepository? repository;
  final AuthService? auth;
  final FavoritosService? favoritos;

  const JardimFacilApp({super.key, this.repository, this.auth, this.favoritos});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jardim Fácil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: ListaPlantasScreen(
        repository: repository ?? PlantaRepository(),
        auth: auth ?? AuthService.instance,
        favoritos: favoritos ?? FavoritosService.instance,
      ),
    );
  }
}
