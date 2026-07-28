import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/dto/internal_movement_dto.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
import 'package:izi_kiosco/domain/dto/paid_charge_dto.dart';
import 'package:izi_kiosco/domain/models/item.dart';

void main() {
  group('AddKioskDto.toJson', () {
    test('maps to Spanish keys and hardcodes tipo/activo', () {
      final json = AddKioskDto(
        name: 'Kiosco 1',
        branchOffice: 5,
        cashRegister: 3,
        business: 9,
      ).toJson();
      expect(json, {
        'nombre': 'Kiosco 1',
        'sucursal': 5,
        'caja': 3,
        'contribuyente': 9,
        'tipo': 'Kiosko',
        'activo': true,
      });
    });
  });

  group('PaidChargeDto.toJson', () {
    test('maps orden -> pedido and keeps monetary fields', () {
      final json = PaidChargeDto(
        orden: 100,
        metodoPago: 1,
        monto: 42.5,
        moneda: 'BOB',
        monedaId: 150,
        contribuyente: 7,
      ).toJson();
      expect(json['pedido'], 100);
      expect(json['metodoPago'], 1);
      expect(json['monto'], 42.5);
      expect(json['moneda'], 'BOB');
      expect(json['monedaId'], 150);
      expect(json['contribuyente'], 7);
    });
  });

  group('NewSaleLinkDto.toJson', () {
    test('maps each item to {item, cantidad}', () {
      final item = Item.fromJson({'id': 'i1', 'nombre': 'A', 'cantidad': 3});
      final json = NewSaleLinkDto(dispositivo: 2, listaItems: [item]).toJson();
      expect(json['listaItems'], [
        {'item': 'i1', 'cantidad': 3}
      ]);
    });
  });

  group('FiltersComanda.toJson', () {
    test('formats dates as YYYY-MM-DD and passes through filters', () {
      final json = FiltersComanda(
        status: 'ABIERTA',
        searchStr: 'abc',
        sucursal: 4,
        dateStart: DateTime(2024, 1, 2),
        dateEnd: DateTime(2024, 2, 3),
      ).toJson();
      expect(json['estado'], 'ABIERTA');
      expect(json['searchStr'], 'abc');
      expect(json['sucursal'], 4);
      expect(json['desde'], '2024-01-02');
      expect(json['hasta'], '2024-02-03');
    });
    test('null dates map to null', () {
      final json = FiltersComanda(status: 'X').toJson();
      expect(json['desde'], isNull);
      expect(json['hasta'], isNull);
    });
  });

  group('InternalMovementDto.toJson', () {
    test('hardcodes tipoMovimiento and formats fecha in UTC ISO', () {
      final json = InternalMovementDto(
        comandaId: 1,
        almacen: 8,
        fecha: DateTime.utc(2024, 5, 6, 7, 8),
      ).toJson();
      expect(json['tipoMovimiento'], 'interna');
      expect(json['almacen'], 8);
      expect(json['fecha'], '2024-05-06T07:08:00.000Z');
    });
  });
}
