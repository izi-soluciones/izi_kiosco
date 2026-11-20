import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';

const _bmIdleStatuses = {
  PaymentStatus.successInvoice,
  PaymentStatus.waitingGet,
  PaymentStatus.errorActivity,
  PaymentStatus.errorCashRegisters,
  PaymentStatus.errorGet,
};

bool bmIsCharging(PaymentState s) => !_bmIdleStatuses.contains(s.status);
