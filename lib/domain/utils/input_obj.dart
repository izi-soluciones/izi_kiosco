import 'package:equatable/equatable.dart';

enum InputError {
  required,
  invalid,
  min,
  max,
  other
}

class InputObj extends Equatable{
  final String value;
  final InputError? inputError;
  final InputError? Function(String) validator;
  final bool loading;

  const InputObj({
    this.value = "",
    required this.validator,
    this.inputError,
    this.loading = false
});

  InputObj changeValue(String value){
    return InputObj(inputError: inputError,value: value,validator: validator);
  }

  InputObj changeLoading(bool? loading){
    return InputObj(inputError: inputError,value: value,validator: validator,loading: loading ?? this.loading);
  }

  InputObj validateError({String? valueRequired}){
    InputError? error;
    error = valueRequired!=null && valueRequired.isEmpty?null:validator(value);
    return InputObj(inputError: error,value: value,validator: validator);
  }
  copyWith({String? value, InputError? Function()? inputError, InputError? Function(String)? validator, bool? loading}){
    return InputObj(
      value: value ?? this.value,
      inputError: inputError !=null? inputError(): this.inputError,
      validator: validator ?? this.validator,
      loading: loading ?? this.loading
    );
  }



  @override
  List<Object?> get props => [value,inputError,loading];


}