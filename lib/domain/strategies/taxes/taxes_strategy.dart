import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/item.dart';

abstract class TaxesStrategy{
  bool showQR;
  bool showBreB;
  String brandName;
  int decimals;

  TaxesStrategy({
    required this.showQR,
    required this.showBreB,
    required this.decimals,
    required this.brandName
  });
  
  num getTotalItem(ParametrosFacturacionItem parametrosFacturacionItem, num cantidad, num precio);  
  PaymentStatus? verifyParameters(Contribuyente? contribuyente, Sucursal? sucursal, Device? device, String? economicActivity);  
}