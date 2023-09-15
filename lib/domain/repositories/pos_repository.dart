import 'package:izi_kiosco/domain/models/pos.dart';

abstract class PosRepository{
  Future<Pos?> getPos({required int contribuyente,required int sucursal});
  Future<Pos> activatePos({required int contribuyente,required int sucursal,required bool isTest});
  Future<Pos> updateEnvironment({required int posId,required bool isTest});
}