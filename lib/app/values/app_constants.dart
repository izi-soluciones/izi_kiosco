import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

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
    CategoryIcons(["Comer"], IziIcons.bkComerAqui),
    CategoryIcons(["pollo"], IziIcons.bkComboPollo),
    CategoryIcons(["parrilla"], IziIcons.bkComboParrilla),
    CategoryIcons(["sueltas"], IziIcons.bkSueltas),
    CategoryIcons(["postres"], IziIcons.bkPostres),
    CategoryIcons(["ensaladas"], IziIcons.bkEnsaladas),
    CategoryIcons(["descuento"], IziIcons.bkCoreDescuento),
    CategoryIcons(["adicionales"], IziIcons.bkComplementos),
    CategoryIcons(["kids"], IziIcons.bkComplementos),
  ];
}
class CategoryIcons{
  final List<String> name;
  final IconData icon;
  const CategoryIcons(this.name,this.icon);
}