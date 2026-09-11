import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';

void main() {
  group('nombre del cliente', () {
    InputError? validar(String nombre) =>
        PaymentInputs.customerNameInput(value: nombre).validateError().inputError;

    test('acepta nombres con tildes, eñe, apóstrofe, punto y guion', () {
      expect(validar("María-José O'Neil Jr."), isNull);
    });

    test('vacío o solo espacios es requerido', () {
      expect(validar(''), InputError.required);
      expect(validar('   '), InputError.required);
    });

    test('una sola letra no alcanza', () {
      expect(validar(' a '), InputError.min);
    });

    test('tiene que empezar con una letra', () {
      expect(validar('-Ana'), InputError.invalid);
      expect(validar("'Ana"), InputError.invalid);
    });

    test('el filtro de caracteres deja letras y deja fuera números y emojis', () {
      final permitido = PaymentInputs.customerNameCharacters;
      expect(permitido.hasMatch('ñ'), isTrue);
      expect(permitido.hasMatch('Á'), isTrue);
      expect(permitido.hasMatch('5'), isFalse);
      expect(permitido.hasMatch('😀'), isFalse);
    });

    test('los apóstrofes tipográficos y el espacio duro no se pierden', () {
      expect(PaymentInputs.normalizeCustomerName('O’Brien'), "O'Brien");
      expect(PaymentInputs.normalizeCustomerName('Jos´'), 'Jos´',
          reason: 'la tecla muerta del acento no se toca mientras compone');
      expect(PaymentInputs.normalizeCustomerName('Ana\u00A0María'), 'Ana María');
    });

    test('más de 30 caracteres no pasa aunque el teclado se haya adelantado', () {
      expect(validar('a' * 30), isNull);
      expect(validar('a' * 31), InputError.max);
    });

    test('lo que acepta la validación también lo acepta el backend', () {
      expect(PaymentInputs.customerNamePattern.pattern,
          r"^[a-zA-ZÀ-ÖØ-öø-ÿ][a-zA-ZÀ-ÖØ-öø-ÿ' .-]*$");
      expect(PaymentInputs.customerNameMaxLength, 30);
    });
  });

  group('razón social', () {
    InputError? validar(String razon) =>
        PaymentInputs.businessNameInput(value: razon).validateError().inputError;

    test('solo espacios es requerido', () {
      expect(validar('   '), InputError.required);
    });

    test('un carácter no alcanza, igual que en el backend', () {
      expect(validar('a'), InputError.min);
      expect(validar('Bello SRL'), isNull);
    });

    test('restos invisibles de un emoji no cuentan como razón social', () {
      expect(validar('\u200D\u200D'), InputError.min);
      expect(PaymentInputs.invisibleCharacters.hasMatch('\u200D'), isTrue);
    });

    test('el largo se cuenta igual que en el backend', () {
      expect(validar('a' * 150), isNull);
      expect(validar('a' * 151), InputError.max);
    });

    test('el filtro deja fuera emojis y conserva signos de empresa', () {
      expect(PaymentInputs.outsideBasicPlane.hasMatch('😀'), isTrue);
      expect(PaymentInputs.outsideBasicPlane.hasMatch('Bello & Cía. S.R.L.'), isFalse);
    });
  });

  group('correo', () {
    InputError? validar(String correo) =>
        PaymentInputs.emailInput(value: correo).validateError().inputError;

    test('vacío es válido porque es opcional', () {
      expect(validar(''), isNull);
    });

    test('acepta correos comunes', () {
      expect(validar('juan.perez@gmail.com'), isNull);
      expect(validar('ventas+kiosco@empresa.com.bo'), isNull);
    });

    test('no pasa de 100 caracteres, el largo de la columna en facturas', () {
      expect(validar('${'a' * 90}@gmail.com'), isNull);
      expect(validar('${'a' * 91}@gmail.com'), InputError.max);
    });

    test('acepta correos largos de empresa que antes se recortaban', () {
      expect(validar('facturacion.electronica.2024@empresa.com.bo'), isNull);
      expect(validar('recepcion.facturas@constructorabolivar.com.co'), isNull);
    });

    test('el campo no recorta: un correo demasiado largo se marca como error', () {
      expect(PaymentInputs.emailInputMaxLength, greaterThan(PaymentInputs.emailMaxLength));
    });

    test('rechaza lo que el backend rechazaría en el cobro', () {
      for (final correo in [
        'josé@gmail.com',
        '"ab"@x.co',
        'a@[1.2.3.4]',
        'a@-b.co',
        'a@b-.co',
        'juan@gmail',
      ]) {
        expect(validar(correo), InputError.invalid, reason: correo);
      }
    });
  });

  group('tope para el teclado numérico propio', () {
    test('recorta lo que pasa del máximo', () {
      expect(PaymentInputs.limit('1234567890123456789', PaymentInputs.phoneMaxLength),
          '123456789012345');
    });

    test('no toca lo que está dentro del máximo', () {
      expect(PaymentInputs.limit('70000000', PaymentInputs.phoneMaxLength), '70000000');
    });
  });
}
