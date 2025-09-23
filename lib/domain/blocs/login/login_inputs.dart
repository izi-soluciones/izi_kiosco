part of 'login_bloc.dart';

class LoginInputs{

  static InputObj tokenInput({String value =""}){
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

  static InputObj tokenCardInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }

  static InputObj deviceInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        if(int.tryParse(val) == null){
          return InputError.invalid;
        }
        return null;
      },
    );
  }
}