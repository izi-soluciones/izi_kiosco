import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';

class SocketRepositoryOffline extends SocketRepository{
  @override
  closeInvoicesListening() {
    return;
  }

  @override
  closeQrListening() {
    return;
  }

  @override
  Stream<Invoice> listenInvoices({required int contribuyenteId, required int sucursalId}) {
    return const Stream.empty();
  }

  @override
  Stream listenPayment({required Charge charge}) {
    return const Stream.empty();
  }

}