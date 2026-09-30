/// Spanish UI strings used by the E2E finders, mirrored VERBATIM from
/// assets/translations/es.json (the app ships a single 'es' locale, so text
/// finders are deterministic). Each constant is annotated with its JSON key —
/// if a test fails on a missing string, re-check that key in es.json.
abstract class S {
  // home.body.clickToInit
  static const homeClickToInit = 'Toca aquí para hacer tu pedido';

  // login (hardcoded in lib/ui/pages/login_page/widgets/login_form.dart)
  static const loginQrTitle = 'Iniciar Sesión con QR';

  // makeOrder.body.selectWhere (rendered with a trailing ':')
  static const selectWhere = 'Selecciona dónde comerás hoy';
  // makeOrder.body.eatHere
  static const eatHere = 'Para comer aquí';
  // makeOrder.body.takeAway
  static const takeAway = 'Para llevar';
  // makeOrder.body.items = 'Items ({})'
  static const itemsPrefix = 'Items (';

  // payment.titles.paymentMethods
  static const paymentMethods = 'Métodos de pago';
  // payment.titles.invoiceData
  static const invoiceData = 'Datos de facturación';
  // payment.inputs.phoneNumber.placeholder — the TextField HINT (the label is
  // "Ingresa tu número de celular"). Required by some contribuyentes.
  static const phonePlaceholder = 'Ingresa tu número de teléfono';
  // payment.buttons.qr
  static const qrButton = 'QR';
  // payment.buttons.checkout
  static const checkoutButton = 'Pagar en caja';
  // payment.buttons.proceedPayment (invoice page AND demo page — demo page is
  // targeted via Key('demo_proceed_btn') instead of this text)
  static const proceedPayment = 'Proceder al pago';
  // payment.subtitles.successPayment
  static const successPayment = '¡Pago exitoso!';
  // payment.subtitles.successOrder
  static const successOrder = '¡Orden creada!';
  // payment.buttons.makeAnotherPurchase
  static const makeAnotherPurchase = 'Realizar otra compra';

  // makeOrderRetail.scan.waitingScan
  static const retailWaitingScan =
      'Acerca los códigos de barras de tus productos al lector para poder escanearlos';
  // makeOrderRetail.scan.productsScanned
  static const productsScanned = 'Productos escaneados';
  // makeOrderRetail.scan.initAgain
  static const retailInitAgain = 'Empezar de nuevo';
  // makeOrderRetail.areYouSureInitAgain
  static const retailInitAgainWarning =
      '¿Esta seguro de borrar los items registrados?';

  // passwordModal.buttons.confirm
  static const pinConfirm = 'Confirmar';
  // passwordModal.errors.wrongPin
  static const wrongPin = 'El pin no es correcto';

  // errorPayments.columns.status / .action
  static const errorColStatus = 'Estado';
  static const errorColAction = 'Acción';

  // general.body.thisScreenClose (first line; full string has a countdown arg)
  static const inactivityTitle = '¿NECESITAS MÁS TIEMPO?';
}
