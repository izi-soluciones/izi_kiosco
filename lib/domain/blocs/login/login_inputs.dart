part of 'login_bloc.dart';

class LoginInputs{

  static InputObj userInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        if(val.isEmpty){
          return InputError.required;
        }
        String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
        RegExp regExp = RegExp(pattern);
        if(!regExp.hasMatch(val)){
          return InputError.invalid;
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
        return null;
      },
    );
  }
}