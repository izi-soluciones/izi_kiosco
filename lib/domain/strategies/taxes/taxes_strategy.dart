import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/item.dart';

abstract class TaxesStrategy{
  num getTotalItem(ParametrosFacturacionItem parametrosFacturacionItem, num cantidad, num precio);  
  PaymentStatus? verifyParameters(Contribuyente? contribuyente, Sucursal? sucursal, Device? device, String? economicActivity);  
}