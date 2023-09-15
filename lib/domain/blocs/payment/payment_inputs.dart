part of 'payment_bloc.dart';

class PaymentInputs{



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

  static InputObj businessNameInput({String value =""}){
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
  static InputObj emailInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
        RegExp regExp = RegExp(pattern);
        if(!regExp.hasMatch(val) && val.isNotEmpty){
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