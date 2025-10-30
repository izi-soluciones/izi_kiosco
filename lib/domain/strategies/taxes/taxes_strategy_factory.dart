

import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_bo.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_co.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_default.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';

class TaxesStrategyFactory{
  static TaxesStrategy taxes(Contribuyente? contribuyente){
    if(contribuyente?.usaSiat==true || (contribuyente?.habilitadoFacturacion ==true && contribuyente?.config?["paisId"]=="BO")){
      return TaxesStrategyBo();
    }
    if(contribuyente?.habilitadoFacturacion == true && contribuyente?.config is Map && contribuyente?.config?["paisId"]=="CO"){
      return TaxesStrategyCo();
    }
    return TaxesStrategyDefault();
  }
}