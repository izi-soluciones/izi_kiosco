import 'package:flutter/material.dart';

class AppConstants{
  static num paginationSize = 15;
  static int timerTimeSeconds=30;
  static int timerTimeSecondsInvoiced=90;
  static int timerMessage=12;
  static int regenerateQrTime=30;
  static int remainingQrTime=30;
  static String defaultCurrency="Bs";
  static int defaultCurrencyId=150;
  static String restaurantEnv="restaurante";
  static int codeCI =1;

  static List<String> ciList=["lp", "cb", "sc", "or", "pt", "ch", "tj", "be", "pd"];

  static const idPaymentMethodCash=1;
  static const idPaymentMethodCard=2;
  static const idPaymentMethodQR=3;
  static const idPaymentMethodTransfer=5;
  static const idPaymentMethodGiftCard=6;
  static const idPaymentMethodOthers=8;
  static const idPaymentMethodPOS=0;



  static const categoryIcons=[
    CategoryIcons(["postre","alfajores"], Icons.bakery_dining_outlined),
    CategoryIcons(["sandwich","sándwich"], Icons.fastfood_outlined),
    CategoryIcons(["hamburguesa",'burguer'], Icons.fastfood_outlined),
    CategoryIcons(["combo","pastas"], Icons.restaurant_menu),
    CategoryIcons(["desayuno"], Icons.free_breakfast_outlined),
    CategoryIcons(["extras"], Icons.plus_one),
    CategoryIcons(["jugo","bebidas","gaseosas"], Icons.local_drink_outlined),
    CategoryIcons(["car"], Icons.directions_car),
    CategoryIcons(["niños"], Icons.child_care_outlined),
    CategoryIcons(["otras"], Icons.restaurant),
    CategoryIcons(["bbq ribs"], Icons.restaurant)
  ];
}
class CategoryIcons{
  final List<String> name;
  final IconData icon;
  final String? image;
  const CategoryIcons(this.name,this.icon,{this.image});
}