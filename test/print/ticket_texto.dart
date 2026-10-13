import 'package:izi_kiosco/domain/utils/print_utils.dart';

/// Render textual de un ticket a 40 columnas, para los goldens: no valida la impresora, fija el layout para que cualquier
/// cambio de anchos, orden o etiquetas salte en la revisión. Es el mismo render de los goldens del backbone
/// (test/cajas/helpers/renderTicket.js). La fecha se enmascara porque el ticket la imprime en la hora local de la máquina.
const _ancho = 40;

String ticketTexto(List<IziPrintItem> items) {
  final lineas = <String>[];
  for (final item in items) {
    if (item is IziPrintText) {
      for (final linea in _ajustar(_sinFecha(item.text), _ancho)) {
        lineas.add(_alinear(linea, _ancho, item.align));
      }
    } else if (item is IziPrintRow) {
      lineas.add(_fila(item));
    } else if (item is IziPrintSeparator) {
      lineas.add((item.dotted ? '.' : '-') * _ancho);
    } else if (item is IziPrintLineWrap) {
      for (var i = 0; i < item.lines; i++) {
        lineas.add('');
      }
    } else if (item is IziPrintQR) {
      lineas.add('[QR ${item.size}] ${item.qrContent}');
    } else if (item is IziPrintImage) {
      lineas.add('[IMAGEN]');
    } else if (item is IziPrintCut) {
      lineas.add('>8-----');
    }
  }
  return lineas.join('\n');
}

String _sinFecha(String texto) => texto.startsWith('FECHA:') ? 'FECHA: <fecha>' : texto;

List<String> _ajustar(String texto, int ancho) {
  final salida = <String>[];
  for (final cruda in texto.split('\n')) {
    if (cruda.length <= ancho) {
      salida.add(cruda);
      continue;
    }
    var actual = '';
    for (final palabra in cruda.split(' ')) {
      final candidata = actual.isEmpty ? palabra : '$actual $palabra';
      if (candidata.length > ancho) {
        salida.add(actual);
        actual = palabra;
      } else {
        actual = candidata;
      }
    }
    if (actual.isNotEmpty) salida.add(actual);
  }
  return salida.isEmpty ? [''] : salida;
}

String _alinear(String texto, int ancho, IziPrintAlign align) {
  final t = texto.length > ancho ? texto.substring(0, ancho) : texto;
  final relleno = ancho - t.length;
  if (align == IziPrintAlign.right) return ' ' * relleno + t;
  if (align == IziPrintAlign.center) {
    final izq = relleno ~/ 2;
    return ' ' * izq + t + ' ' * (relleno - izq);
  }
  return t + ' ' * relleno;
}

String _fila(IziPrintRow fila) {
  var restante = _ancho;
  final total = fila.values.fold<int>(0, (acc, c) => acc + c.width);
  final partes = <String>[];
  for (var i = 0; i < fila.values.length; i++) {
    final col = fila.values[i];
    final ultima = i == fila.values.length - 1;
    final chars = ultima ? restante : (_ancho * col.width) ~/ (total == 0 ? 1 : total);
    if (!ultima) restante -= chars;
    partes.add(_alinear(col.text, chars, col.align));
  }
  return partes.join();
}
