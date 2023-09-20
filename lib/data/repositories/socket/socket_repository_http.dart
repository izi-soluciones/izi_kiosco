import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer' as developer;

class SocketRepositoryHttp extends SocketRepository{

  io.Socket? _socketInvoices;
  @override
  Stream<Invoice> listenInvoices({required int contribuyenteId,required int sucursalId}) async*{
    StreamController<Invoice> streamController = StreamController();
    String path = "/facturas";
    _socketInvoices = io.io("${dotenv.env[EnvKeys.apiUrlNotifications]}$path",
        io.OptionBuilder().setTransports(['websocket','polling']).build() );

    _socketInvoices?.onError((data) => developer.log(data.toString()));
    _socketInvoices?.onConnecting((data) => developer.log("Connecting"));
    _socketInvoices?.onConnectError((data) => developer.log("Connecting error $data"));
    _socketInvoices?.on('connect',(_) {
      developer.log("Socket notifications connect $contribuyenteId - $sucursalId");
    });
    _socketInvoices?.onDisconnect((data) {
      developer.log("Socket notifications disconnect $contribuyenteId - $sucursalId");
    });
    _socketInvoices?.on("imprimirFactura-$contribuyenteId-$sucursalId", (data)
    {
      streamController.add(Invoice.fromJson(data));
    }
    );

    yield* streamController.stream;


  }

  @override
  closeInvoicesListening(){
    _socketInvoices?.close();
  }

  io.Socket? _socketQr;
  @override
  Stream<dynamic> listenQr({required Charge charge}) async*{
    StreamController<dynamic> streamController = StreamController();
    String path = "/payment_notification";
    _socketQr = io.io("${dotenv.env[EnvKeys.apiUrlNotifications]}$path",
        io.OptionBuilder().setTransports(['websocket','polling']).build() );

    _socketQr?.onError((data) => developer.log(data.toString()));
    _socketQr?.onConnecting((data) => developer.log("Connecting"));
    _socketQr?.onConnectError((data) => developer.log("Connecting error $data"));
    _socketQr?.on('connect',(_) {
      developer.log("Socket qr connect");
    });
    _socketQr?.onDisconnect((data) {
      developer.log("Socket qr disconnect");
    });
    _socketQr?.on('payment-notification', (data)
    {
      if(data?["status"]=="success" && data?["uuid"] == charge.uuid){
        streamController.add(data);
      }
    }
    );

    yield* streamController.stream;


  }

  @override
  closeQrListening(){
    _socketQr?.disconnect();
    _socketQr?.close();
  }
  
}