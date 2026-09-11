import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/customer.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';

class _FakeComandaRepository implements ComandaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  List<Customer> clientes = [];
  final Map<String, Completer<List<Customer>>> pendientes = {};

  @override
  Future<List<Customer>> queryBusinessSearch(
      {required String query, required String? pais}) {
    final pendiente = pendientes[query];
    return pendiente != null ? pendiente.future : Future.value(clientes);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSocketRepository implements SocketRepository {
  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late PaymentBloc bloc;
  late _FakeBusinessRepository negocios;

  setUp(() {
    negocios = _FakeBusinessRepository();
    bloc = PaymentBloc(_FakeComandaRepository(), negocios,
        _FakeSocketRepository());
  });

  tearDown(() => bloc.close());

  test('el pago arranca sin factura', () {
    expect(bloc.state.wantsInvoice, isFalse);
  });

  test('el nombre vacio no pasa la validacion', () {
    bloc.validateInput(customerName: true);
    expect(bloc.state.customerName.inputError, InputError.required);

    bloc.changeInputs(customerName: 'Camila');
    bloc.validateInput(customerName: true);
    expect(bloc.state.customerName.inputError, isNull);
  });

  test('sin factura el telefono vacio es un error', () {
    bloc.validateInput(phoneNumber: true);
    expect(bloc.state.phoneNumber.inputError, InputError.required);
  });

  test('con factura el telefono vacio es un error', () {
    bloc.changeWantsInvoice(true);
    bloc.validateInput(phoneNumber: true);
    expect(bloc.state.phoneNumber.inputError, InputError.required);
  });

  test('sin factura el correo no se exige', () {
    bloc.validateInput(email: true);
    expect(bloc.state.email.inputError, isNull);
  });

  test('con factura el correo sigue siendo opcional', () {
    bloc.changeWantsInvoice(true);
    bloc.validateInput(email: true);
    expect(bloc.state.email.inputError, isNull);
  });

  test('con factura un correo mal escrito es un error', () {
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(email: 'camila@');
    bloc.validateInput(email: true);
    expect(bloc.state.email.inputError, InputError.invalid);
  });

  test('pedir factura copia el nombre a la razon social', () {
    bloc.changeInputs(customerName: 'Camila');
    bloc.changeWantsInvoice(true);
    expect(bloc.state.businessName.value, 'Camila');
  });

  test('pedir factura respeta una razon social ya escrita', () {
    bloc.changeInputs(customerName: 'Camila', businessName: 'Bello SRL');
    bloc.changeWantsInvoice(true);
    expect(bloc.state.businessName.value, 'Bello SRL');
  });

  test('un NIT sin coincidencia no borra la razón social precargada', () async {
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Camila Rojas');
  });

  test('un NIT con coincidencia trae su razón social', () async {
    negocios.clientes = [Customer(nit: '1234567', razonSocial: 'Bello SRL')];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Bello SRL');
  });

  test('cambiar a un NIT sin coincidencia deshace solo lo autocompletado', () async {
    negocios.clientes = [Customer(nit: '1234567', razonSocial: 'Bello SRL')];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(documentNumber: '7654321');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Camila Rojas');
  });

  test('volver a consultar el mismo NIT no pisa la corrección del cliente', () async {
    negocios.clientes = [Customer(nit: '1234567', razonSocial: 'X')];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(businessName: 'Xavier SRL');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Xavier SRL');
  });

  test('otro NIT que coincide trae su razón social aunque la anterior se haya editado', () async {
    negocios.clientes = [
      Customer(nit: '1234567', razonSocial: 'Bello SRL'),
      Customer(nit: '7654321', razonSocial: 'Cielo SAS'),
    ];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(businessName: 'Bello S.R.L.');
    bloc.changeInputs(documentNumber: '7654321');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Cielo SAS');
  });

  test('una pausa en un NIT a medio escribir no hace que el nuevo NIT herede la razón editada', () async {
    negocios.clientes = [
      Customer(nit: '1234567', razonSocial: 'Bello SRL'),
      Customer(nit: '7654321', razonSocial: 'Cielo SAS'),
    ];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(businessName: 'Bello S.R.L.');
    bloc.changeInputs(documentNumber: '765');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(documentNumber: '7654321');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Cielo SAS');
  });

  test('la respuesta tardía de un NIT viejo no deshace la del NIT actual', () async {
    final lenta = Completer<List<Customer>>();
    negocios.pendientes['123456'] = lenta;
    negocios.clientes = [Customer(nit: '1234567', razonSocial: 'Bello SRL')];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '123456');
    final consultaVieja = bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Bello SRL');
    lenta.complete([]);
    await consultaVieja;
    expect(bloc.state.businessName.value, 'Bello SRL');
  });

  test('acortar el NIT apaga el indicador de carga de una consulta en vuelo', () async {
    final lenta = Completer<List<Customer>>();
    negocios.pendientes['123456'] = lenta;
    bloc.changeInputs(documentNumber: '123456');
    final consulta = bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.documentNumber.loading, isTrue);
    bloc.changeInputs(documentNumber: '12');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.documentNumber.loading, isFalse);
    lenta.complete([]);
    await consulta;
    expect(bloc.state.documentNumber.loading, isFalse);
  });

  test('el error de una consulta vieja no apaga el indicador de la consulta en curso', () async {
    final vieja = Completer<List<Customer>>();
    final nueva = Completer<List<Customer>>();
    negocios.pendientes['123456'] = vieja;
    negocios.pendientes['1234567'] = nueva;
    bloc.changeInputs(documentNumber: '123456');
    final consultaVieja = bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(documentNumber: '1234567');
    final consultaNueva = bloc.queryBusiness(authState: AuthState.init());
    vieja.completeError(Exception('red'));
    await consultaVieja;
    expect(bloc.state.documentNumber.loading, isTrue);
    nueva.complete([]);
    await consultaNueva;
    expect(bloc.state.documentNumber.loading, isFalse);
  });

  test('acortar el NIT deshace lo autocompletado', () async {
    negocios.clientes = [Customer(nit: '1234567', razonSocial: 'Bello SRL')];
    bloc.changeInputs(customerName: 'Camila Rojas');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(documentNumber: '1234567');
    await bloc.queryBusiness(authState: AuthState.init());
    bloc.changeInputs(documentNumber: '12');
    await bloc.queryBusiness(authState: AuthState.init());
    expect(bloc.state.businessName.value, 'Camila Rojas');
  });

  test('desistir de la factura limpia los datos fiscales y conserva el nombre',
      () {
    bloc.changeInputs(customerName: 'Camila');
    bloc.changeWantsInvoice(true);
    bloc.changeInputs(
        documentNumber: '1234567',
        businessName: 'Bello SRL',
        email: 'bello@ejemplo.com');

    bloc.changeWantsInvoice(false);

    expect(bloc.state.wantsInvoice, isFalse);
    expect(bloc.state.documentNumber.value, isEmpty);
    expect(bloc.state.businessName.value, isEmpty);
    expect(bloc.state.email.value, isEmpty);
    expect(bloc.state.customerName.value, 'Camila');
  });
}
