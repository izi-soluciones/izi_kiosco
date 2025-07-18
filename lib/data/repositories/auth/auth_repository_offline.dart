import 'package:dio/dio.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';

class AuthRepositoryOffline extends AuthRepository{
  final DioClient _dioClient = DioClient();

  @override
  Future<List<Contribuyente>> getContribuyentes() async{

    return [Contribuyente(
        actividadesEconomicas: [],
        autorizadosAPI: [],
        id: 39942,
      nombre: "Burger King",
      razonSocial: "Burger King"
    )];
  }
  @override
  Future<Contribuyente> getCurrentContribuyenteById(int idContribuyente) async{
    return Contribuyente(
        actividadesEconomicas: [],
        autorizadosAPI: [],
        config: {"beta": true, "simphony": {"orgName": "BFS", "clientId": "QkZTLjY4Y2JjYjYyLTgwZGItNDA4Mi1hYjMxLTcwNTJkYzdkZjlhMA", "userName": "BKKIOSKOAPIV4"}, "numeracion": {"porSucursal": true, "numeracionDia": true}, "dispositivos": true, "aERestaurante": {"codigoCaeb": "561110", "descripcion": "RESTAURANTES", "tipoActividad": "P"}, "monedaImpuesto": 150, "monedaInventario": 150},
        id: 39942,
        nombre: "Burger King",
      razonSocial: "Burger King"
    );
  }
  @override
  Future<LoginResponse> login(LoginRequest loginRequest) async{
    return LoginResponse(user: User(nombres: "kiosko", apellidos: "Kiosko", id: ""), token: "", refreshToken: "");
  }

  @override
  Future<User> getCurrentUserById(String idUser)async {
    return User(nombres: "kiosko", apellidos: "Kiosko", id: "");

  }

  @override
  Future<List<Device>> getDevicesByContribuyente(int idContribuyente) async {
    return [
      Device(
          id: 1,
          config: ConfigDevice(demo: false,isRetail: false, actividadEconomica: '', almacen: '',video: "https://izi-bol-temp.s3.amazonaws.com/videos-disp/eceead87-a064-40a5-b53f-a3f6a59b9f31.mp4"),
          sucursal: 3,
          nombre: '', caja: 3, enUso: false, activo: true)
    ];
  }

  @override
  Future<void> disableDevice(int idDevice) async {
    return;
  }

  @override
  Future<void> enableDevice(int idDevice)async {
    return;
  }

  @override
  Future<void> addDevice(AddKioskDto addKioskDto) async{
    return;
    try{
      String path="/dispositivos";
      var response=await _dioClient.post(
          uri: path,
          body: addKioskDto.toJson(),
          options: Options(responseType: ResponseType.json)
      );
      if(response.statusCode!=200)
      {
        throw response.data;
      }
    }
    catch(e){
      throw(e.toString());
    }
  }

  @override
  Future<List<Sucursal>> getSucursales(int idContribuyente) async{
    return [
      Sucursal(
        id: 1,
        nombre: "",
        direccion: "Av. Cristo Redentor, esq. Sta. Gema  (Entre 7mo. y 8vo. Anillo)",
        config: {"siat": {"sucursal": "38", "puntoVenta": 0, "estadoContingencia": {}, "eventoSignificativoActivo": {}}, "simphony": {"locRef": "bkno", "rvcRef": 110, "tenderId": 13, "crearCaja": true, "priceSequence": 1, "tenderIdPayment": 2004, "checkEmployeeRef": 14, "orderTypeRefAqui": 9, "tenderIdPaymentQr": 2006, "definitionSequence": 1, "orderTypeRefLlevar": 10, "tenderIdPaymentCard": 2005, "orderTypeRefAquiCaja": 1, "orderTypeRefLlevarCaja": 2}, "pasosConfig": {"pasoDatos": true, "pasoActividades": false, "pasoDosificacion": false}, "usuarioWifi": "bknorte", "almacenVenta": "6863f38e3bf718d5d2d77bf9", "passwordWifi": "bk491575", "usaLogoRollo": false, "usaInventario": true, "configPrefactura": "descuenta", "nombrePreFactura": "Pre-Factura", "tipoFacturaVentas": "compacto", "permiteSobreventas": true, "restaurantPagoAdelantado": true}
      )
    ];
    String path="/contribuyentes/$idContribuyente/sucursales-permitidas";
    var response=await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json)
    );
    if(response.statusCode==200)
    {
      return List.from(response.data).map((e) => Sucursal.fromJson(e)).toList();
    }
    else{
      throw response.data;
    }
  }

}