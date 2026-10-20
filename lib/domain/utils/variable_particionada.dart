// Variable particionada en el kiosco (ClickUp 86e3qauf1, pizzas de Elis).
//
// Una variable particionada divide el ítem en `partes` (1, 2 o 4) y cada sabor elegido ocupa
// algunas. Es la misma regla que izi-pos (lib/domain/utils/variable_particionada.dart) e
// izi-backbone (librerias/inventario/variableParticionada.js): cada sabor recibe las mismas partes
// y las que sobran van a los primeros en el orden de selección. Si se cambia acá, hay que
// cambiarla allá.

import 'package:izi_kiosco/domain/models/item.dart';

const String tipoParticionada = 'particionada';

/// Partes de cada sabor, en orden de selección. Interminable (4) con 3 sabores: [2, 1, 1].
List<int> repartirPartes(int partes, int sabores) {
  if (sabores <= 0) return [];
  final base = partes ~/ sabores;
  final sobran = partes % sabores;
  return List.generate(sabores, (i) => base + (i < sobran ? 1 : 0));
}

/// Texto de la porción de un sabor: «1/2», «1/4», «2 × 1/2» o «entera» (XS).
String etiquetaPorciones(int partesSabor, int partesTotal) {
  if (partesTotal == 1) return 'entera';
  final cuartos = (partesSabor * 4) ~/ partesTotal;
  final medias = cuartos ~/ 2;
  final resto = cuartos - medias * 2;
  return [
    if (medias > 0) medias > 1 ? '$medias × 1/2' : '1/2',
    if (resto > 0) resto > 1 ? '$resto × 1/4' : '1/4',
  ].join(' + ');
}

extension ModifierParticionada on Modifier {
  bool get isParticionada => tipo == tipoParticionada && (partes ?? 0) > 0;

  /// Sabores elegidos en el orden en que se eligieron.
  List<ModifierItem> get seleccionOrdenada {
    final elegidos = caracteristicas.where((c) => c.check).toList();
    elegidos.sort((a, b) => (a.orden ?? 1 << 30).compareTo(b.orden ?? 1 << 30));
    return elegidos;
  }

  /// Deja la selección consistente: cada sabor elegido una vez, numerado 1..n sin huecos y sin
  /// pasar de las partes (si sobran, se quedan los primeros).
  void normalizarSeleccion() {
    final ordenados = seleccionOrdenada;
    final maximo = partes ?? 0;
    for (var i = maximo; i < ordenados.length; i++) {
      ordenados[i].check = false;
    }
    for (final c in caracteristicas) {
      if (!c.check) c.orden = null;
    }
    for (var i = 0; i < ordenados.length && i < maximo; i++) {
      ordenados[i].orden = i + 1;
    }
  }

  /// Toca un sabor: si estaba elegido lo quita y renumera; si no, lo agrega al final si hay lugar.
  /// Devuelve false si no se pudo agregar porque ya se llegó al máximo.
  bool alternarSabor(ModifierItem sabor) {
    if (sabor.check) {
      sabor.check = false;
      normalizarSeleccion();
      return true;
    }
    if (seleccionOrdenada.length >= (partes ?? 0)) return false;
    sabor.check = true;
    sabor.orden = seleccionOrdenada.length + 1;
    normalizarSeleccion();
    return true;
  }

  /// Partes de cada sabor elegido, en orden.
  Map<ModifierItem, int> get reparto {
    final elegidos = seleccionOrdenada;
    final partesSabor = repartirPartes(partes ?? 0, elegidos.length);
    return {for (var i = 0; i < elegidos.length; i++) elegidos[i]: partesSabor[i]};
  }
}
