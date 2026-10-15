import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/planta.dart';

class PlantaRepository {
  final AssetBundle bundle;
  List<Planta>? _cache;

  PlantaRepository({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  Future<List<Planta>> carregarPlantas() async {
    if (_cache != null) return _cache!;
    final texto = await bundle.loadString('assets/data/plantas.json');
    final lista = jsonDecode(texto) as List<dynamic>;
    _cache = lista
        .map((e) => Planta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  // Descarta o cache e lê o JSON de novo (usado ao puxar a lista para atualizar).
  Future<List<Planta>> recarregarPlantas() {
    _cache = null;
    return carregarPlantas();
  }

  Future<Planta?> buscarPorId(String id) async {
    final plantas = await carregarPlantas();
    for (final p in plantas) {
      if (p.id == id) return p;
    }
    return null;
  }
}
