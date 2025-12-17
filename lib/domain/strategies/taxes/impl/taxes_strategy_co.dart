import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';
import 'package:izi_kiosco/domain/utils/calc_utils.dart';

class TaxesStrategyCo implements TaxesStrategy{
  @override
  num getTotalItem(ParametrosFacturacionItem parametrosFacturacionItem, num cantidad, num precio){
        double totalImpuestos = 0;
        double precioItem = Calc.mul(cantidad, precio);
        if(parametrosFacturacionItem.co?.impuestos.isEmpty==true){
          return precioItem;
        }
        precioItem = Calc.roundConservador(precioItem);
        if (parametrosFacturacionItem.co?.impuestosIn==true) {
            double amount = 0;
            double rate = 0;
            for(ParametrosFacturacionCoImpuestosItem imp in parametrosFacturacionItem.co?.impuestos ?? []){
                    if (imp.monto != 0 && imp.isAmount) {
                        amount = Calc.add(amount, imp.monto);
                    }
                    else if (imp.rate !=0 && !imp.isAmount) {
                        rate = Calc.add(rate, imp.rate);
                    }
            }
            double unitarioIncluido = Calc.div(Calc.div(Calc.sub(precioItem, amount), Calc.add(1, Calc.div(rate, 100))), cantidad);
            unitarioIncluido = Calc.roundCeil(unitarioIncluido);
            precio = unitarioIncluido;

            precioItem = Calc.mul(cantidad, precio);
        }
        
        for(ParametrosFacturacionCoImpuestosItem element in parametrosFacturacionItem.co?.impuestos ?? []){
            if (element.isAmount) {
                totalImpuestos = Calc.add(totalImpuestos, element.monto);
            } else {
                double impuesto = Calc.roundConservador(
                    Calc.div(Calc.mul(precioItem, element.rate), 100)
                );
                totalImpuestos = Calc.add(totalImpuestos, impuesto);
            }

            totalImpuestos = Calc.roundConservador(totalImpuestos);
        }
        return Calc.add(precioItem, Calc.roundConservador(totalImpuestos));
  }

  @override
  PaymentStatus? verifyParameters(Contribuyente? contribuyente, Sucursal? sucursal, Device? device, String? economicActivity) {
    return null;
  }

  @override
  int decimals= 0;
  
  @override
  bool showQR = false;


  @override
  bool showBreB = true;

  @override
  String brandName = "IZIFY";
  @override
  String? countryCode = "CO";

}