part of 'payment_bloc.dart';

class PaymentInputs{

  static const int customerNameMaxLength = 30;
  static const int phoneMaxLength = 15;
  static const int documentNumberMaxLength = 20;
  static final RegExp customerNameCharacters = RegExp(r"[a-zA-ZÀ-ÖØ-öø-ÿ' .-]");
  static final RegExp customerNamePattern = RegExp(r"^[a-zA-ZÀ-ÖØ-öø-ÿ][a-zA-ZÀ-ÖØ-öø-ÿ' .-]*$");
  static final RegExp outsideBasicPlane = RegExp(r'[\u{10000}-\u{10FFFF}]', unicode: true);
  static final RegExp whitespace = RegExp(r'\s');
  static final RegExp invisibleCharacters = RegExp(r'[\u200B-\u200F\u2028-\u202E\u2060-\u206F\uFEFF]');
  static final RegExp alphanumeric = RegExp(r'[0-9a-zA-ZÀ-ÖØ-öø-ÿ]');
  static const int businessNameMaxLength = 150;
  // facturas.correoelectronicocomprador es VARCHAR(100): un correo más largo corta la factura después del cobro
  static const int emailMaxLength = 100;
  // El campo deja escribir más que el máximo a propósito: recortar convertía "…@empresa.com.bo" en
  // "…@empresa.com", un correo válido de otro dominio. Con margen, el cliente ve el error y no se pierde nada
  static const int emailInputMaxLength = 150;
  // Misma regex que el formato "fast" de AJV 6 en el backend, para no dejar pasar un correo que el cobro rechace
  static final RegExp emailBackend = RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*$", caseSensitive: false);
  static final RegExp emailTopLevelDomain = RegExp(r'\.[a-zA-Z]{2,}$');

  // iOS convierte ' en ’ y el filtro lo borraba. ´ y ` quedan fuera a propósito: en web son la tecla muerta del acento
  // y convertirlos mientras el teclado compone deja "Jos'é" en vez de "José"
  static String normalizeCustomerName(String value) =>
      value.replaceAll(RegExp(r"[’‘ʼ]"), "'").replaceAll('\u00A0', ' ');

  // El teclado numérico del design system escribe directo en el controller y se salta el maxLength del input
  static String limit(String value, int maxLength) =>
      value.length > maxLength ? value.substring(0, maxLength) : value;



  static InputObj documentNumberInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        return null;
      },
    );
  }

  static InputObj complementInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }

  static InputObj customerNameInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.trim().isEmpty){
          return InputError.required;
        }
        if(val.trim().length < 2){
          return InputError.min;
        }
        if(val.trim().runes.length > customerNameMaxLength){
          return InputError.max;
        }
        if(!customerNamePattern.hasMatch(val.trim())){
          return InputError.invalid;
        }
        return null;
      },
    );
  }

  static InputObj businessNameInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.trim().isEmpty){
          return InputError.required;
        }
        if(alphanumeric.allMatches(val).length < 2){
          return InputError.min;
        }
        if(val.runes.length > businessNameMaxLength){
          return InputError.max;
        }
        return null;
      },
    );
  }
  static InputObj emailInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return null;
        }
        if(val.length > emailMaxLength){
          return InputError.max;
        }
        if(val.length < 6 || !emailBackend.hasMatch(val) || !emailTopLevelDomain.hasMatch(val)){
          return InputError.invalid;
        }
        return null;
      },
    );
  }
  static InputObj firstDigitsInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        if(val.length!=4){
          return InputError.invalid;
        }

        if(num.tryParse(val)==null){
          return InputError.invalid;
        }
        return null;
      },
    );
  }
  static InputObj phoneNumberInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }
  static InputObj lastDigitsInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        if(val.length!=4){
          return InputError.invalid;
        }
        if(num.tryParse(val)==null){
          return InputError.invalid;
        }
        return null;
      },
    );
  }
  static InputObj invoiceNumber({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        return null;
      },
    );
  }
  static InputObj authorization({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        return null;
      },
    );
  }
}