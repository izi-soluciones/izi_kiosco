import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

class AppConstants{
  static num paginationSize = 15;
  static int timerTimeSeconds=30;
  static int timerTimeSecondsInvoiced=90;
  static int regenerateQrTime=30;
  static int remainingQrTime=30;
  static String defaultCurrency="Bs";
  static int defaultCurrencyId=150;
  static String restaurantEnv="restaurante";
  static String posUrlEnv="POS_URL";
  static int codeCI =1;

  static List<String> ciList=["lp", "cb", "sc", "or", "pt", "ch", "tj", "be", "pd"];

  static const idPaymentMethodCash=1;
  static const idPaymentMethodCard=2;
  static const idPaymentMethodQR=3;
  static const idPaymentMethodTransfer=5;
  static const idPaymentMethodGiftCard=6;
  static const idPaymentMethodOthers=8;



  static const categoryIcons=[
    CategoryIcons("postre", IziIcons.cake),
    CategoryIcons("sandwich", IziIcons.sandwich),
    CategoryIcons("sándwich", IziIcons.sandwich),
    CategoryIcons("jugo", IziIcons.juices)
  ];
}
class CategoryIcons{
  final String name;
  final IconData icon;
  const CategoryIcons(this.name,this.icon);
}