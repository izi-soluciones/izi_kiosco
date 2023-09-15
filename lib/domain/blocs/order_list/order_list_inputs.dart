part of 'order_list_bloc.dart';

class OrderListInputs{

  static InputObj searchInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }

  static InputObj statusInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }
  static InputObj dateStartInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }
  static InputObj dateEndInput({String value =""}){
    return InputObj(
      value: value,
      validator: (val) {
        return null;
      },
    );
  }
}