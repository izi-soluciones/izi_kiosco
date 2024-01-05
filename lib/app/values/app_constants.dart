class AppConstants{
  static num paginationSize = 15;
  static int timerTimeSeconds=30000;
  static int timerTimeSecondsInvoiced=600000;
  static int regenerateQrTime=30;
  static int remainingQrTime=30;
  static String defaultCurrency="Bs";
  static int defaultCurrencyId=150;
  static String restaurantEnv="restaurante";
  static String posUrlEnv="POS_URL";

  static const idPaymentMethodCash=1;
  static const idPaymentMethodCard=2;
  static const idPaymentMethodQR=3;
  static const idPaymentMethodTransfer=5;
  static const idPaymentMethodGiftCard=6;
  static const idPaymentMethodOthers=8;
}