import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/planta.dart';
import 'auth_service.dart';

class FavoritosService extends ChangeNotifier {
  final AuthService auth;
  final AssetBundle _bundle;
  final Map<String, Set<String>> _favoritos = {};
  bool _carregado = false;

  FavoritosService(this.auth, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle {
    // Atualiza a interface quando o usuário entra ou sai
    auth.addListener(notifyListeners);
  }

  @override
  void dispose() {
    auth.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> carregar() async {
    if (_carregado) return;
    final texto = await _bundle.loadString('assets/data/favoritos.json');
    final mapa = jsonDecode(texto) as Map<String, dynamic>;
    mapa.forEach((userId, ids) {
      _favoritos.putIfAbsent(userId, () => <String>{}).addAll(
            (ids as List<dynamic>).cast<String>(),
          );
    });
    _carregado = true;
    notifyListeners();
  }

  Set<String> get idsFavoritos {
    final usuario = auth.usuarioLogado;
    if (usuario == null) return <String>{};
    return Set.unmodifiable(_favoritos[usuario.id] ?? <String>{});
  }

  bool isFavorita(String plantaId) => idsFavoritos.contains(plantaId);

  bool alternar(String plantaId) {
    final usuario = auth.usuarioLogado;
    if (usuario == null) {
      throw StateError('É necessário estar logado para favoritar plantas.');
    }
    final ids = _favoritos.putIfAbsent(usuario.id, () => <String>{});
    final novoEstado = !ids.contains(plantaId);
    if (novoEstado) {
      ids.add(plantaId);
    } else {
      ids.remove(plantaId);
    }
    notifyListeners();
    return novoEstado;
  }

  List<Planta> filtrarFavoritas(List<Planta> todas) {
    final ids = idsFavoritos;
    return todas.where((p) => ids.contains(p.id)).toList();
  }
}
