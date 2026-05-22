import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';
import 'package:izi_kiosco/domain/utils/calc_utils.dart';

class TaxesStrategyBo implements TaxesStrategy{
  @override
 num getTotalItem(ParametrosFacturacionItem parametrosFacturacionItem, num cantidad, num precio){
    return Calc.mul(cantidad, precio);
  }

  @override
  PaymentStatus? verifyParameters(Contribuyente? contribuyente, Sucursal? sucursal, Device? currentDevice, String? economicActivity) {

    if (economicActivity==null) {
      return PaymentStatus.errorActivity;
    }
    return null;
  }
  
  @override
  int decimals= 2;
  
  @override
  bool showQR = true;

  @override
  bool showBreB = false;
  
  @override
  String brandName = "iZi";

  @override
  String labelProcessingInvoice = LocaleKeys.payment_messages_processingInvoice;

  @override
  String? countryCode = "BO";
}