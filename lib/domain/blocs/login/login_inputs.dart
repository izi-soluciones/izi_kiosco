part of 'login_bloc.dart';

class LoginInputs{

  static InputObj userInput({String value =""}){
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

  static InputObj passwordInput({String value =""}){
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