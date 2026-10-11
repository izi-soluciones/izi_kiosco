import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/customer.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';

void main() {
  group('Currency', () {
    test('fromJson applies sensible defaults', () {
      final c = Currency.fromJson({});
      expect(c.id, 0);
      expect(c.simbolo, 'Bs');
      expect(c.monedaReferencia, 150);
      expect(c.exRate, 1);
      expect(c.exRatePrincipal, 1);
    });
    test('fromJson reads provided values', () {
      final c = Currency.fromJson(
          {'id': 3, 'nombre': 'Peso', 'simbolo': r'$', 'exRate': 4200});
      expect(c.id, 3);
      expect(c.nombre, 'Peso');
      expect(c.simbolo, r'$');
      expect(c.exRate, 4200);
    });
    test('toJson exposes all fields', () {
      final c = Currency.fromJson({'id': 1, 'simbolo': 'US'});
      final json = c.toJson();
      expect(json['id'], 1);
      expect(json['simbolo'], 'US');
      expect(json.keys, containsAll(['exRate', 'monedaReferencia', 'nombre']));
    });
  });

  group('Payment', () {
    test('fromJson defaults', () {
      final p = Payment.fromJson({});
      expect(p.id, 0);
      expect(p.metodoPago, 1);
      expect(p.terminosPago, '');
      expect(p.monto, 0);
      expect(p.moneda, 150);
      expect(p.loading, isFalse);
    });
    test('toJson injects the contribuyente id and a fechaPago', () {
      final p = Payment.fromJson({'metodoPago': 2, 'monto': 99});
      final json = p.toJson(77);
      expect(json['contribuyente'], 77);
      expect(json['metodoPago'], 2);
      expect(json['monto'], 99);
      expect(json['fechaPago'], isA<String>());
    });
    test('copyWith only toggles loading', () {
      final p = Payment.fromJson({'monto': 10});
      final copy = p.copyWith(loading: true);
      expect(copy.loading, isTrue);
      expect(copy.monto, 10);
    });
  });

  group('Customer', () {
    test('parses numeric id directly', () {
      final c = Customer.fromJson({'id': 5, 'nit': '123'});
      expect(c.id, 5);
      expect(c.nit, '123');
    });
    test('parses string id via tryParse', () {
      expect(Customer.fromJson({'id': '42'}).id, 42);
    });
    test('non-numeric string id becomes null', () {
      expect(Customer.fromJson({'id': 'abc'}).id, isNull);
    });
    test('coerces nested numeric fields to strings', () {
      final c = Customer.fromJson({'nit': 900, 'razonSocial': 12});
      expect(c.nit, '900');
      expect(c.razonSocial, '12');
    });
    test('parses nested CO custom block', () {
      final c = Customer.fromJson({
        'custom': {
          'CO': {'tipoPersona': '1', 'responsabilidadIva': 'O-13'}
        }
      });
      expect(c.custom?.co?.tipoPersona, '1');
      expect(c.custom?.co?.responsabilidadIva, 'O-13');
    });
  });

  group('User', () {
    test('fromJson defaults names and booleans', () {
      final u = User.fromJson({'id': 'u1'});
      expect(u.id, 'u1');
      expect(u.nombres, '');
      expect(u.apellidos, '');
      expect(u.legalCheck, isFalse);
      expect(u.emailCheck, isFalse);
    });
    test('non-bool check values fall back to false', () {
      final u = User.fromJson({'id': 'u1', 'legalCheck': 'yes'});
      expect(u.legalCheck, isFalse);
    });
    test('toJson and toJsonUpdate', () {
      final u = User.fromJson(
          {'id': 'u1', 'nombres': 'Ana', 'apellidos': 'Paz', 'avatar': 2});
      final json = u.toJson();
      expect(json['nombres'], 'Ana');
      expect(json['avatar'], 2);
      expect(u.toJsonUpdate(), {'nombres': 'Ana', 'apellidos': 'Paz'});
    });
  });

  group('Login models', () {
    test('LoginRequest.init defaults + toJson', () {
      final req = LoginRequest.init();
      expect(req.cadena, 'Chrome');
      expect(req.correoElectronico, '');
      expect(req.toJson(),
          {'cadena': 'Chrome', 'contrasena': '', 'correoElectronico': ''});
    });
    test('LoginResponse.fromJson parses token and nested user', () {
      final res = LoginResponse.fromJson({
        'token': 'tok',
        'refreshToken': 'rt',
        'usuario': {'id': 'u1', 'nombres': 'Ana'},
      });
      expect(res.token, 'tok');
      expect(res.refreshToken, 'rt');
      expect(res.user.nombres, 'Ana');
    });
  });
}
