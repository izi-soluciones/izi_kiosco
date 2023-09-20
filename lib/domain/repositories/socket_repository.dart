import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';

abstract class SocketRepository{

  Stream<Invoice> listenInvoices({required int contribuyenteId,required int sucursalId});
  closeInvoicesListening();
  Stream<dynamic> listenQr({required Charge charge});
  closeQrListening();
}