import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/payment_attempt_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/customer.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/identification_type.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/iva_responsability.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/models/person_type.dart';
import 'package:izi_kiosco/domain/models/tax_responsability.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/utils/crash_report.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'dart:io';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
part 'payment_state.dart';
part 'payment_inputs.dart';

class PaymentConfig {
  Future Function(Contribuyente, Sucursal) setParams;
  Function(PaymentDtoVentaData) setParamsOrderPayment;
  Function(PaymentAttemptDto) setParamsPayment;
  Function(Customer customer) setParamsCustomer;
  PaymentConfig({
    required this.setParams,
    required this.setParamsOrderPayment,
    required this.setParamsPayment,
    required this.setParamsCustomer,
  });
}

class PaymentBloc extends Cubit<PaymentState> {
  final ComandaRepository _comandaRepository;
  StreamSubscription? qrStream;
  final BusinessRepository _businessRepository;
  final SocketRepository _socketRepository;
  PaymentConfig? countryConfig;
  CancelToken cancelToken = CancelToken();

  PaymentBloc(
    this._comandaRepository,
    this._businessRepository,
    this._socketRepository,
  ) : super(PaymentState.init());

  initOrder({
    required PaymentObj paymentObj,
    required AuthState authState,
  }) async {
    try {
      PaymentCountryTaxes? countryTaxes = _setCountryConfig(
        authState.currentContribuyente!,
      );

      List<CashRegister> cashRegisters = await _businessRepository
          .getCashRegisters(
            contribuyenteId: authState.currentContribuyente?.id ?? 0,
            sucursalId: authState.currentSucursal?.id ?? 0,
          );

      cashRegisters.removeWhere((element) => !element.abierta);

      if (cashRegisters.isEmpty) {
        emit(state.copyWith(status: PaymentStatus.errorCashRegisters));
        emit(state.copyWith(status: PaymentStatus.waitingGet));
        return;
      }
      int indexCashRegister = cashRegisters.indexWhere(
        (element) => element.id == authState.currentDevice?.caja,
      );
      CashRegister? currentCashRegister;
      if (indexCashRegister != -1) {
        currentCashRegister = cashRegisters.elementAtOrNull(indexCashRegister);
      } else {
        currentCashRegister = cashRegisters.firstOrNull;
        // emit(state.copyWith(status: PaymentStatus.errorCashRegisters));
        // emit(state.copyWith(status: PaymentStatus.waitingGet));
        // return;
      }

      int indexCurrency = authState.currencies.indexWhere(
        (element) =>
            element.id ==
            authState.currentContribuyente?.config["monedaInventario"],
      );
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }
      String? economicActivity;
      if (authState.currentDevice?.config.isRetail == true) {
        economicActivity = authState.currentDevice?.config.actividadEconomica;
      } else {
        if (authState.currentContribuyente?.config?["aERestaurante"] != null) {
          if (authState.currentContribuyente?.config?["aERestaurante"] is num) {
            economicActivity = authState
                .currentContribuyente
                ?.config?["aERestaurante"]
                ?.toString();
          } else if (authState.currentContribuyente?.config?["aERestaurante"]
              is String) {
            economicActivity =
                authState.currentContribuyente?.config?["aERestaurante"];
          } else if (authState.currentContribuyente?.config?["aERestaurante"]
                  is Map &&
              authState
                      .currentContribuyente
                      ?.config?["aERestaurante"]?["codigoCaeb"] !=
                  null) {
            economicActivity = authState
                .currentContribuyente
                ?.config?["aERestaurante"]?["codigoCaeb"];
          }
        }
      }

      if (authState.currentContribuyente?.tieneFacturacion == true) {
        PaymentStatus? statusVerification = authState.taxesStrategy
            .verifyParameters(
              authState.currentContribuyente,
              authState.currentSucursal,
              authState.currentDevice,
              economicActivity,
            );
        if (statusVerification != null) {
          return emit(state.copyWith(status: statusVerification));
        }
      }

      await countryConfig?.setParams(
        authState.currentContribuyente!,
        authState.currentSucursal!,
      );
      String? savedIzifyPosIp = await TokenUtils.getPosIp();
      if (savedIzifyPosIp == null) {
        final ecopayIp = authState.currentDevice?.config.ipEcopay;
        if (ecopayIp != null) {
          savedIzifyPosIp = ecopayIp.contains(':')
              ? ecopayIp
              : '$ecopayIp:8081';
        }
      }
      emit(
        state.copyWith(
          status: PaymentStatus.successGet,
          step: 1,
          economicActivity: economicActivity,
          currentCurrency: currentCurrency,
          paymentObj: paymentObj,
          izifyPosIp: savedIzifyPosIp,
          countryTaxes: countryTaxes,
          cashRegisters: cashRegisters,
          currentCashRegister: currentCashRegister,
        ),
      );
    } catch (error) {
      log(error.toString());
      emit(
        state.copyWith(
          status: PaymentStatus.errorGet,
          errorDescription: error.toString(),
        ),
      );
      emit(state.copyWith(status: PaymentStatus.waitingGet));
    }
  }

  InputObj _validatePhone() {
    if (state.phoneNumber.value.isEmpty)
      return state.phoneNumber.copyWith(inputError: () => InputError.required);

    try {
      final fullNumber = "${state.phonePrefix}${state.phoneNumber.value}";

      final phone = PhoneNumber.parse(fullNumber);

      if (!phone.isValid()) {
        return state.phoneNumber.copyWith(inputError: () => InputError.invalid);
      }

      return state.phoneNumber.copyWith(inputError: () => null);
    } catch (_) {
      return state.phoneNumber.copyWith(inputError: () => InputError.invalid);
    }
  }

  validateInput({
    bool documentNumber = false,
    bool businessName = false,
    bool invoiceNumber = false,
    bool authorization = false,
    bool email = false,
    bool firstDigits = false,
    bool lastDigits = false,
    bool phoneNumber = false,
  }) {
    if (phoneNumber) {
      emit(state.copyWith(phoneNumber: _validatePhone()));
      return _validatePhone().inputError == null;
    }

    if (documentNumber) {
      emit(
        state.copyWith(
          documentNumber: state.documentNumber.validateError(
            valueRequired: state.businessName.value,
          ),
        ),
      );
    }
    if (businessName) {
      emit(
        state.copyWith(
          businessName: state.businessName.validateError(
            valueRequired: state.documentNumber.value,
          ),
        ),
      );
    }
    if (email) {
      emit(
        state.copyWith(
          email: state.email.validateError(valueRequired: state.email.value),
        ),
      );
    }
  }

  resetInputs() {
    emit(
      state.copyWith(
        status: PaymentStatus.setInputs,
        businessName: state.businessName.changeValue(""),
        phoneNumber: state.phoneNumber.changeValue(""),
        documentNumber: state.documentNumber.changeValue(""),
      ),
    );
    emit(state.copyWith(status: PaymentStatus.successGet));
  }

  changeInputs({
    int? cashRegister,
    bool? withException,
    bool? isManual,
    String? documentNumber,
    String? complement,
    String? businessName,
    String? authorization,
    String? invoiceNumber,
    String? phonePrefix,
    String? email,
    String? firstDigits,
    String? lastDigits,
    String? phoneNumber,
  }) {
    if (phoneNumber != null) {
      emit(
        state.copyWith(phoneNumber: state.phoneNumber.changeValue(phoneNumber)),
      );
    }
    if (isManual != null) {
      emit(state.copyWith(isManual: isManual));
    }

    if (withException != null) {
      emit(state.copyWith(withException: withException));
    }

    if (documentNumber != null) {
      emit(
        state.copyWith(
          documentNumber: state.documentNumber.changeValue(documentNumber),
        ),
      );
    }
    if (complement != null) {
      emit(
        state.copyWith(complement: state.complement.changeValue(complement)),
      );
    }
    if (businessName != null) {
      emit(
        state.copyWith(
          businessName: state.businessName.changeValue(businessName),
        ),
      );
    }
    if (email != null) {
      emit(state.copyWith(email: state.email.changeValue(email)));
    }
    if (phonePrefix != null) {
      emit(state.copyWith(phonePrefix: phonePrefix));
    }
  }

  changeCashAmount(num cash) {
    emit(state.copyWith(cashAmount: cash));
  }

  changeStep(int step) {
    emit(state.copyWith(step: step));
  }

  backReset() {
    _socketRepository.closeQrListening();
    qrStream?.cancel();
    qrStream = null;
    emit(
      state.copyWith(
        step: 0,
        paymentType: PaymentType.others,
        cashAmount: 0,
        qrCharge: () => null,
        qrAmount: 0,
        qrPaymentKey: -1,
      ),
    );
  }

  selectPayment(PaymentType paymentType, AuthState authState) async {
    try {
      if (paymentType == PaymentType.cashRegister) {
        emit(state.copyWith(status: PaymentStatus.processingOrder));
        Comanda comanda = await _comandaRepository.markAsCreated(
          state.paymentObj?.uuid ?? "",
        );
        if (comanda.numero is int) {
          _printRolloOrder(
            authState,
            orderNumber: (comanda.numero as int),
            customOrderNumber:
                comanda.custom is Map && comanda.custom["numeroCustom"] is int
                ? comanda.custom["numeroCustom"]
                : null,
          );
        }
        emit(
          state.copyWith(
            step: 5,
            status: PaymentStatus.paymentProcessed,
            paymentType: paymentType,
          ),
        );
        timerSuccess = Timer(const Duration(seconds: 10), () async {
          emit(state.copyWith(status: PaymentStatus.successInvoice));
        });
        return;
      }
      if (authState.currentContribuyente?.tieneFacturacion == true ||
          authState.currentDevice?.config.isRetail != true) {
        emit(
          state.copyWith(
            paymentType: paymentType,
            step: 2,
            qrWait: false,
            qrLoading: false,
            qrCharge: () => null,
          ),
        );
      }
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: PaymentStatus.markCreateError));
      emit(state.copyWith(status: PaymentStatus.successGet));
    }
  }

  markPaidQr() {
    emit(state.copyWith(step: 3, paymentType: PaymentType.qr));
  }

  bool _validateInputs() {
    emit(
      state.copyWith(
        email: state.email.validateError(valueRequired: state.email.value),
        documentNumber: state.documentNumber.validateError(
          valueRequired: state.businessName.value,
        ),
        businessName: state.businessName.validateError(
          valueRequired: state.documentNumber.value,
        ),
        phoneNumber: _validatePhone(),
      ),
    );

    if (state.documentNumber.inputError != null) {
      return false;
    }
    if (state.businessName.inputError != null) {
      return false;
    }
    if (state.phoneNumber.inputError != null) {
      return false;
    }
    if (state.email.inputError != null) {
      return false;
    }

    return true;
  }

  @override
  Future<void> close() async {
    if (state.status != PaymentStatus.successInvoice &&
        state.status != PaymentStatus.successPayment &&
        state.status != PaymentStatus.paymentProcessed &&
        state.paymentObj != null &&
        (state.paymentObj?.uuid ?? "").isNotEmpty) {
      // Intentamos cancelar genéricamente cualquier cobro que haya quedado pendiente
      try {
        await _comandaRepository.cancelPaymentAttempt(
          uuid: state.paymentObj!.uuid!,
        );
      } catch (e) {
        log("Error al cancelar el intento de pago: $e");
      }
    }
    _socketRepository.closeQrListening();
    qrStream?.cancel();
    qrStream = null;
    timerSuccess?.cancel();
    return super.close();
  }

  Future<bool> _verifyIzifySocket(String token) async {
    try {
      final posIpRaw = state.izifyPosIp;
      if (posIpRaw == null) return false;
      final posIp = posIpRaw.split(':')[0];

      // The POS now authenticates the WebSocket via a token query parameter.
      final channel = WebSocketChannel.connect(
        Uri.parse(
          'ws://$posIp:8081/payment-updates?token=${Uri.encodeQueryComponent(token)}',
        ),
      );
      await channel.ready.timeout(const Duration(seconds: 4));
      await channel.sink.close();
      return true;
    } catch (e) {
      log('WebSocket verification failed: $e');
      return false;
    }
  }

  /// Waits for the final Izify POS payment result. Listens on the
  /// `/payment-updates` WebSocket (best-effort) and, in parallel, polls
  /// `GET /payment-status/{reference}` as a fallback in case the socket was
  /// reconnecting when the event was emitted. Whichever channel first yields a
  /// terminal result wins. The result includes the new PENDING outcome, which
  /// the caller must NOT auto-retry.
  Future<PosPaymentResult> _waitForIzifyPaymentStatus(
    AuthState authState, {
    required String token,
    String? reference,
  }) async {
    final posIpRaw = state.izifyPosIp;
    if (posIpRaw == null) {
      return const PosPaymentResult(status: PosPaymentStatus.unknown);
    }
    final posIp = posIpRaw.split(':')[0];

    const overallTimeout = Duration(seconds: 60);
    final completer = Completer<PosPaymentResult>();

    WebSocketChannel? channel;
    StreamSubscription? wsSub;
    Timer? pollTimer;
    Timer? timeoutTimer;

    void finish(PosPaymentResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
    }

    // WebSocket listener (token now required as a query param).
    try {
      channel = WebSocketChannel.connect(
        Uri.parse(
          'ws://$posIp:8081/payment-updates?token=${Uri.encodeQueryComponent(token)}',
        ),
      );
      wsSub = channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map) {
              final result = PosPaymentResult.fromJson(data);
              if (result.isTerminal) {
                finish(result);
              }
            }
          } catch (_) {}
        },
        onError: (e) => log('Izify WS error: $e'),
        cancelOnError: false,
      );
    } catch (e) {
      log('Izify WS connect failed: $e');
    }

    // Polling fallback: only if we have a reference to poll for.
    if (reference != null && reference.isNotEmpty) {
      final creds = await _getIzifyIpAndToken(authState);
      final ipPort = creds?['ipPort'] ?? '$posIp:8081';
      pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (completer.isCompleted) return;
        final result = await _comandaRepository.pollIzifyPaymentStatus(
          ipPort: ipPort,
          token: token,
          reference: reference,
        );
        if (result != null && result.isTerminal) {
          finish(result);
        }
      });
    }

    timeoutTimer = Timer(overallTimeout, () {
      finish(const PosPaymentResult(status: PosPaymentStatus.unknown));
    });

    try {
      return await completer.future;
    } finally {
      pollTimer?.cancel();
      timeoutTimer.cancel();
      await wsSub?.cancel();
      try {
        await channel?.sink.close();
      } catch (_) {}
    }
  }

  Future<Map<String, String>?> _getIzifyIpAndToken(AuthState authState) async {
    final ipPort = await TokenUtils.getPosIp();
    final posToken = await TokenUtils.getPosToken();
    if (ipPort != null && posToken != null) {
      return {'ipPort': ipPort, 'token': posToken};
    }

    final ipEcopay = authState.currentDevice?.config.ipEcopay;
    final tokenEcopay = authState.currentDevice?.config.token;
    if (ipEcopay != null && tokenEcopay != null) {
      final ipWithPort = ipEcopay.contains(':') ? ipEcopay : '$ipEcopay:8081';
      return {'ipPort': ipWithPort, 'token': tokenEcopay};
    }

    return null;
  }

  Future<CardPayment> _callCardProvider(
    AuthState authState, {
    required bool izify,
    required bool linkser,
    required bool contactless,
    required String cardType,
    required int quotas,
  }) async {
    if (izify) {
      final creds = await _getIzifyIpAndToken(authState);
      if (creds == null) {
        throw Exception("No se encontraron credenciales del POS");
      }
      // The POS now authenticates the WebSocket, so the token is required to
      // verify the socket is alive.
      final isSocketAlive = await _verifyIzifySocket(creds['token']!);
      if (!isSocketAlive) {
        throw Exception("Terminal POS sin conexión al socket");
      }
      const currencyIso = "COP";
      return _comandaRepository.callCardPaymentIzify(
        ipPort: creds['ipPort']!,
        token: creds['token']!,
        currency: currencyIso,
        cardType: cardType,
        quotas: quotas,
        amount: (state.paymentObj?.amount ?? 0).toStringAsFixed(2),
      );
    }
    if (linkser) {
      return _comandaRepository.callCardPayment(
        amount: _getIntFromDecimal(
          _roundToNDecimals(state.paymentObj?.amount ?? 0, 2),
        ),
        ip: authState.currentDevice!.config.ipLinkser!,
      );
    }
    return _comandaRepository.callCardPaymentATC(
      amount: (state.paymentObj?.amount ?? 0).moneyFormat(
        digitsTaxes: authState.taxesStrategy.decimals,
      ),
      ip: authState.currentDevice!.config.ipAtc!,
      cancelToken: cancelToken,
      contactless: contactless,
    );
  }

  Future<(bool, Object?)> _retryMarkPayment(
    String uuid,
    int? internalId,
  ) async {
    Object? lastError;
    for (var i = 0; i < 10; i++) {
      try {
        await _comandaRepository.markPaymentATC(uuid, internalId);
        return (true, null);
      } catch (e) {
        lastError = e;
        await Future.delayed(Duration(seconds: 1 * (i + 1)));
        log(e.toString());
      }
    }
    return (false, lastError);
  }

  Future<void> _saveCardError(
    CardPayment cp,
    String response,
    String reportMsg,
  ) async {
    cp.response = response;
    CrashReport.report(reportMsg, cp.toJson().toString());
    await LocalStorageCardErrors.saveCardErrors(jsonEncode(cp.toJson()));
  }

  void _emitCardError(AuthState authState) {
    if (authState.currentContribuyente?.habilitadoFacturacion == true) {
      emit(state.copyWith(status: PaymentStatus.cardError, step: 2));
    } else {
      emit(state.copyWith(status: PaymentStatus.cardError, step: 1));
    }
    emit(state.copyWith(status: PaymentStatus.successGet));
  }

  /// PENDING means the outcome is UNKNOWN - the card may or may not have been
  /// charged. It must NOT be auto-retried; surface it to the operator to
  /// verify/reconcile before any retry.
  void _emitCardPending(AuthState authState, {String? message}) {
    if (authState.currentContribuyente?.habilitadoFacturacion == true) {
      emit(state.copyWith(
          status: PaymentStatus.cardPending,
          step: 2,
          errorDescription: message));
    } else {
      emit(state.copyWith(
          status: PaymentStatus.cardPending,
          step: 1,
          errorDescription: message));
    }
    emit(state.copyWith(status: PaymentStatus.successGet));
  }

  /// Waits for the Izify POS result (WebSocket + polling fallback) and maps it
  /// to whether the kiosk should proceed to mark the payment as paid.
  /// Returns `true` only on a confirmed SUCCESS. On ERROR/CANCELLED emits a
  /// card error; on PENDING emits the distinct pending state (no auto-retry).
  Future<bool> _awaitIzifyResult(
      AuthState authState, CardPayment cardPayment) async {
    final creds = await _getIzifyIpAndToken(authState);
    final token = creds?['token'];
    if (token == null) {
      // The /pay request already fired, so we cannot know whether the card was
      // charged. Mark as UNKNOWN so a retry warns the operator first.
      cardPayment.status = 'UNKNOWN';
      await _saveCardError(cardPayment, "Sin confirmar - sin credenciales",
          "Izify sin credenciales para verificar el pago");
      _emitCardPending(authState);
      return false;
    }

    final result = await _waitForIzifyPaymentStatus(
      authState,
      token: token,
      reference: cardPayment.reference,
    );

    // Persist the transactionId if the POS reported one so the transactions
    // screen can display it.
    if (result.transactionId != null) {
      cardPayment.transactionId = result.transactionId;
    }

    switch (result.status) {
      case PosPaymentStatus.success:
        return true;
      case PosPaymentStatus.pending:
        cardPayment.status = 'PENDING';
        await _saveCardError(
            cardPayment,
            "Pendiente - ${result.errorMessage ?? 'sin confirmar'}",
            "Izify payment PENDING (unconfirmed - verify before retry)");
        _emitCardPending(authState, message: result.errorMessage);
        return false;
      case PosPaymentStatus.error:
      case PosPaymentStatus.cancelled:
      case PosPaymentStatus.unknown:
        // UNKNOWN here means no terminal result arrived within the timeout.
        // Treat it like PENDING (do not auto-retry) to stay safe against a
        // possible silent charge.
        if (result.status == PosPaymentStatus.unknown) {
          cardPayment.status = 'UNKNOWN';
          await _saveCardError(cardPayment, "Sin confirmar (timeout)",
              "Izify no confirmed result within timeout");
          _emitCardPending(authState);
          return false;
        }
        cardPayment.status =
            result.status == PosPaymentStatus.cancelled ? 'CANCELLED' : 'ERROR';
        await _saveCardError(cardPayment,
            "Rechazada - ${result.errorMessage ?? ''}".trim(),
            "Izify terminal rejected payment");
        _emitCardError(authState);
        return false;
    }
  }

  void _emitMarkFailedFallback() {
    emit(state.copyWith(step: 6, status: PaymentStatus.paymentProcessed));
    timerSuccess = Timer(const Duration(seconds: 30), () async {
      emit(state.copyWith(status: PaymentStatus.successInvoice));
    });
  }

  /// Retries a previously-failed POS card transaction from the transactions
  /// screen. Re-initiates a payment through the SAME path as the normal card
  /// flow: `/pay` (HMAC-signed) + WebSocket/`pollIzifyPaymentStatus` result
  /// handling via [_awaitIzifyResult].
  ///
  /// A NEW `reference` is generated for the retry (inside
  /// `callCardPaymentIzify`, which mints a fresh one on every call) so the new
  /// attempt is tracked independently of the original. A retry that comes back
  /// PENDING is again surfaced as `cardPending` and never auto-retried.
  ///
  /// Callers MUST NOT invoke this for a confirmed-success transaction, and must
  /// warn the operator first when the original was pending/unknown (the card
  /// may already have been charged).
  Future<bool> retryCardPayment(
    AuthState authState,
    CardPayment original, {
    String cardType = "DEBITO",
    int quotas = 0,
  }) async {
    // Guard: never retry a confirmed success (would risk double-charging).
    if (!original.canRetry) {
      return false;
    }

    final amount = original.amount;
    final currency = original.currency ?? "COP";
    final parsedAmount = double.tryParse(amount ?? "");
    if (parsedAmount == null || parsedAmount <= 0) {
      emit(state.copyWith(
          status: PaymentStatus.cardError,
          errorDescription: "Monto inválido para reintentar"));
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }

    emit(state.copyWith(status: PaymentStatus.cardProcessing));
    try {
      final creds = await _getIzifyIpAndToken(authState);
      if (creds == null) {
        throw Exception("No se encontraron credenciales del POS");
      }
      final isSocketAlive = await _verifyIzifySocket(creds['token']!);
      if (!isSocketAlive) {
        throw Exception("Terminal POS sin conexión al socket");
      }

      // Fires /pay with a brand-new reference and HMAC signature.
      final cardPayment = await _comandaRepository.callCardPaymentIzify(
        ipPort: creds['ipPort']!,
        token: creds['token']!,
        currency: currency,
        cardType: cardType,
        quotas: quotas,
        amount: amount!,
      );

      // Same result flow as a normal payment (PENDING -> cardPending, etc.).
      return await _awaitIzifyResult(authState, cardPayment);
    } catch (e) {
      log(e.toString());
      _emitCardError(authState);
      return false;
    }
  }

  Future<bool> _makeCardRetailPayment(
    AuthState authState, {
    bool atc = false,
    bool linkser = false,
    bool izify = false,
    bool contactless = true,
    String cardType = "DEBITO",
    int quotas = 0,
  }) async {
    try {
      emit(state.copyWith(step: 4));

      PaymentAttemptDto newPayment = PaymentAttemptDto(
        uuid: state.paymentObj?.uuid ?? "",
        metodoPago: AppConstants.idPaymentMethodPOS,
        nit: state.documentNumber.value.isEmpty
            ? "0"
            : state.documentNumber.value,
        complemento:
            AppConstants.ciList.contains(
                  state.complement.value.toLowerCase(),
                ) ||
                state.documentNumber.value.isEmpty
            ? null
            : state.complement.value,
        razonSocial: state.businessName.value.isEmpty
            ? "S/N"
            : state.businessName.value,
        telefonoComprador: state.phoneNumber.value.isNotEmpty
            ? "${state.phonePrefix}${state.phoneNumber.value}"
            : null,
        correoElectronico: state.email.value.isNotEmpty
            ? state.email.value
            : null,
      );

      countryConfig?.setParamsPayment(newPayment);

      Charge charge = await _comandaRepository.generatePaymentAttempt(
        newPayment,
      );
      await _listenPaymentRetail(authState, charge);
      if (authState.currentDevice?.config.demo == true) {
        emit(
          state.copyWith(
            step: 8,
            status: PaymentStatus.demoPayment,
            qrCharge: () => charge,
          ),
        );
        return true;
      }

      final cardPayment = await _callCardProvider(
        authState,
        izify: izify,
        linkser: linkser,
        contactless: contactless,
        cardType: cardType,
        quotas: quotas,
      );

      if (izify) {
        final approved = await _awaitIzifyResult(authState, cardPayment);
        if (!approved) {
          // Error / cancelled / pending states are already emitted inside
          // _awaitIzifyResult (PENDING is surfaced distinctly, not retried).
          return false;
        }
      }

      emit(state.copyWith(status: PaymentStatus.processingOrder));

      final (marked, lastError) = await _retryMarkPayment(
        state.paymentObj?.uuid ?? "",
        charge.intentoPago,
      );
      if (marked) return true;

      await _saveCardError(
        cardPayment,
        "Aprobada - Error sync server: ${lastError ?? 'desconocido'}",
        "Error complete payment POS",
      );
      _emitMarkFailedFallback();
      return false;
    } catch (e) {
      log(e.toString());
      if (authState.currentContribuyente?.tieneFacturacion == true) {
        emit(state.copyWith(status: PaymentStatus.cardError, step: 2));
      } else {
        emit(state.copyWith(status: PaymentStatus.cardError, step: 1));
      }
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> _makeCardOrderPayment(
    AuthState authState, {
    bool atc = false,
    bool linkser = false,
    bool izify = false,
    bool contactless = true,
    String cardType = "DEBITO",
    int quotas = 0,
  }) async {
    try {
      emit(state.copyWith(step: 4));

      PaymentDto newPayment = _buildPaymentDto(AppConstants.idPaymentMethodPOS);

      Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0,
        payment: newPayment,
      );
      await _saveAndListenPaymentOrder(authState, charge);
      if (authState.currentDevice?.config.demo == true) {
        emit(
          state.copyWith(
            step: 8,
            status: PaymentStatus.demoPayment,
            qrCharge: () => charge,
          ),
        );
        return true;
      }

      final cardPayment = await _callCardProvider(
        authState,
        izify: izify,
        linkser: linkser,
        contactless: contactless,
        cardType: cardType,
        quotas: quotas,
      );

      if (izify) {
        final approved = await _awaitIzifyResult(authState, cardPayment);
        if (!approved) {
          // Error / cancelled / pending states are already emitted inside
          // _awaitIzifyResult (PENDING is surfaced distinctly, not retried).
          return false;
        }
      }

      emit(state.copyWith(status: PaymentStatus.processingOrder));

      final (marked, lastError) = await _retryMarkPayment(charge.uuid, null);
      if (marked) return true;

      await _saveCardError(
        cardPayment,
        "Aprobada - Error sync server: ${lastError ?? 'desconocido'}",
        "Error complete payment POS",
      );
      _emitMarkFailedFallback();
      return false;
    } catch (e) {
      log(e.toString());
      if (authState.currentContribuyente?.tieneFacturacion == true) {
        emit(state.copyWith(status: PaymentStatus.cardError, step: 2));
      } else {
        emit(state.copyWith(status: PaymentStatus.cardError, step: 1));
      }
      emit(state.copyWith(status: PaymentStatus.successGet));
      return false;
    }
  }

  Future<bool> makeCardPayment(
    AuthState authState, {
    bool atc = false,
    bool linkser = false,
    bool izify = false,
    bool contactless = true,
    String cardType = "DEBITO",
    int quotas = 0,
  }) async {
    if ((authState.currentContribuyente?.tieneFacturacion != true ||
            (_validateInputs() && (atc || linkser || izify))) &&
        state.paymentObj?.isComanda == true) {
      return await _makeCardOrderPayment(
        authState,
        atc: atc,
        contactless: contactless,
        linkser: linkser,
        izify: izify,
        cardType: cardType,
        quotas: quotas,
      );
    } else if (((authState.currentContribuyente?.tieneFacturacion != true) ||
            (_validateInputs() && (atc || linkser || izify))) &&
        state.paymentObj?.isComanda == false) {
      return await _makeCardRetailPayment(
        authState,
        atc: atc,
        contactless: contactless,
        linkser: linkser,
        izify: izify,
        cardType: cardType,
        quotas: quotas,
      );
    }
    return false;
  }

  Future<bool> _generateRetailQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {
      PaymentAttemptDto newPayment = PaymentAttemptDto(
        uuid: state.paymentObj?.uuid ?? "",
        metodoPago: AppConstants.idPaymentMethodQR,
        nit: state.documentNumber.value.isEmpty
            ? "0"
            : state.documentNumber.value,
        complemento:
            AppConstants.ciList.contains(
                  state.complement.value.toLowerCase(),
                ) ||
                state.documentNumber.value.isEmpty
            ? null
            : state.complement.value,
        razonSocial: state.businessName.value.isEmpty
            ? "S/N"
            : state.businessName.value,
        telefonoComprador: state.phoneNumber.value.isNotEmpty
            ? "${state.phonePrefix}${state.phoneNumber.value}"
            : null,
        correoElectronico: state.email.value.isNotEmpty
            ? state.email.value
            : null,
      );
      countryConfig?.setParamsPayment(newPayment);

      Charge charge = await _comandaRepository.generatePaymentAttempt(
        newPayment,
      );
      await _listenPaymentRetail(authState, charge);
      emit(
        state.copyWith(
          step: 8,
          status: PaymentStatus.demoPayment,
          qrCharge: () => charge,
        ),
      );
      return true;
    }

    emit(state.copyWith(qrLoading: true));
    PaymentAttemptDto newPayment = PaymentAttemptDto(
      uuid: state.paymentObj?.uuid ?? "",
      metodoPago: AppConstants.idPaymentMethodQR,
      nit: state.documentNumber.value.isEmpty
          ? "0"
          : state.documentNumber.value,
      complemento:
          AppConstants.ciList.contains(state.complement.value.toLowerCase()) ||
              state.documentNumber.value.isEmpty
          ? null
          : state.complement.value,
      razonSocial: state.businessName.value.isEmpty
          ? "S/N"
          : state.businessName.value,
      telefonoComprador: state.phoneNumber.value.isNotEmpty
          ? "${state.phonePrefix}${state.phoneNumber.value}"
          : null,
      correoElectronico: state.email.value.isNotEmpty
          ? state.email.value
          : null,
    );
    countryConfig?.setParamsPayment(newPayment);

    Charge charge = await _comandaRepository.generatePaymentAttempt(newPayment);
    await _listenPaymentRetail(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Future<bool> _generateOrderQR(AuthState authState) async {
    if (authState.currentDevice?.config.demo == true) {
      PaymentDto newPayment = _buildPaymentDto(AppConstants.idPaymentMethodQR);
      Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0,
        payment: newPayment,
      );
      await _saveAndListenPaymentOrder(authState, charge);
      emit(
        state.copyWith(
          step: 8,
          status: PaymentStatus.demoPayment,
          qrCharge: () => charge,
        ),
      );
      return true;
    }

    emit(state.copyWith(qrLoading: true));

    PaymentDto qr = _buildPaymentDto(AppConstants.idPaymentMethodQR);

    Charge charge = await _comandaRepository.generatePayment(
      contribuyenteId: authState.currentContribuyente?.id ?? 0,
      payment: qr,
    );
    await _saveAndListenPaymentOrder(authState, charge);
    emit(state.copyWith(qrCharge: () => charge, qrLoading: false));
    return true;
  }

  Timer? timerSuccess;
  Future<bool> generateQR(AuthState authState) async {
    try {
      if (_validateInputs() ||
          authState.currentContribuyente?.tieneFacturacion != true) {
        emit(state.copyWith(step: 3));
        if (state.paymentObj?.isComanda == true) {
          return await _generateOrderQR(authState);
        } else {
          return await _generateRetailQR(authState);
        }
      }
      return false;
    } catch (e) {
      log(e.toString());
      emit(
        state.copyWith(
          qrLoading: false,
          qrCharge: () => null,
          status: PaymentStatus.qrError,
        ),
      );
      if (authState.currentContribuyente?.tieneFacturacion == true) {
        emit(state.copyWith(step: 2, status: PaymentStatus.successGet));
      } else {
        emit(state.copyWith(step: 1, status: PaymentStatus.successGet));
      }
      return false;
    }
  }

  Future<bool> _generateRetailBREB(AuthState authState) async {
    emit(
      state.copyWith(
        status: PaymentStatus.brebLoading,
        brebLoading: true,
        brebCharge: null,
        step: 7,
        paymentType: PaymentType.breb,
      ),
    );
    if (authState.currentDevice?.config.demo == true) {
      PaymentAttemptDto newPayment = PaymentAttemptDto(
        uuid: state.paymentObj?.uuid ?? "",
        metodoPago: AppConstants.idPaymentMethodBreB,
        nit: state.documentNumber.value.isEmpty
            ? "0"
            : state.documentNumber.value,
        complemento:
            AppConstants.ciList.contains(
                  state.complement.value.toLowerCase(),
                ) ||
                state.documentNumber.value.isEmpty
            ? null
            : state.complement.value,
        razonSocial: state.businessName.value.isEmpty
            ? "S/N"
            : state.businessName.value,
        telefonoComprador: state.phoneNumber.value,
        correoElectronico: state.email.value.isNotEmpty
            ? state.email.value
            : null,
      );
      countryConfig?.setParamsPayment(newPayment);

      Charge charge = await _comandaRepository.generatePaymentAttempt(
        newPayment,
      );
      await _listenPaymentRetail(authState, charge);
      emit(
        state.copyWith(
          step: 8,
          status: PaymentStatus.demoPayment,
          qrCharge: () => charge,
        ),
      );
      return true;
    }

    PaymentAttemptDto newPayment = PaymentAttemptDto(
      uuid: state.paymentObj?.uuid ?? "",
      metodoPago: AppConstants.idPaymentMethodBreB,
      nit: state.documentNumber.value.isEmpty
          ? "0"
          : state.documentNumber.value,
      complemento:
          AppConstants.ciList.contains(state.complement.value.toLowerCase()) ||
              state.documentNumber.value.isEmpty
          ? null
          : state.complement.value,
      razonSocial: state.businessName.value.isEmpty
          ? "S/N"
          : state.businessName.value,
      telefonoComprador: state.phoneNumber.value,
      correoElectronico: state.email.value.isNotEmpty
          ? state.email.value
          : null,
    );
    countryConfig?.setParamsPayment(newPayment);

    Charge charge = await _comandaRepository.generatePaymentAttempt(newPayment);
    await _listenPaymentRetail(authState, charge);

    emit(
      state.copyWith(
        brebCharge: charge,
        brebLoading: false,
        status: PaymentStatus.successGet,
      ),
    );
    return true;
  }

  Future<bool> _generateOrderBREB(AuthState authState) async {
    emit(
      state.copyWith(
        status: PaymentStatus.brebLoading,
        brebLoading: true,
        brebCharge: null,
        step: 7,
        paymentType: PaymentType.breb,
      ),
    );

    if (authState.currentDevice?.config.demo == true) {
      PaymentDto newPayment = _buildPaymentDto(
        AppConstants.idPaymentMethodBreB,
      );
      Charge charge = await _comandaRepository.generatePayment(
        contribuyenteId: authState.currentContribuyente?.id ?? 0,
        payment: newPayment,
      );
      await _saveAndListenPaymentOrder(authState, charge);
      emit(
        state.copyWith(
          step: 8,
          status: PaymentStatus.demoPayment,
          qrCharge: () => charge,
        ),
      );
      return true;
    }

    PaymentDto newPayment = _buildPaymentDto(AppConstants.idPaymentMethodBreB);

    Charge charge = await _comandaRepository.generatePayment(
      contribuyenteId: authState.currentContribuyente?.id ?? 0,
      payment: newPayment,
    );

    await _saveAndListenPaymentOrder(authState, charge);

    emit(
      state.copyWith(
        brebCharge: charge,
        brebLoading: false,
        status: PaymentStatus.successGet,
      ),
    );

    return true;
  }

  Future<bool> generateBREB(AuthState authState) async {
    try {
      if (_validateInputs() ||
          authState.currentContribuyente?.tieneFacturacion != true) {
        if (state.paymentObj?.isComanda == true) {
          return await _generateOrderBREB(authState);
        } else {
          return await _generateRetailBREB(authState);
        }
      }
      return false;
    } catch (e) {
      log(e.toString());
      emit(
        state.copyWith(
          brebLoading: false,
          status: PaymentStatus.brebError,
          errorDescription: e.toString(),
        ),
      );
      if (authState.currentContribuyente?.tieneFacturacion == true) {
        emit(state.copyWith(step: 2, status: PaymentStatus.successGet));
      } else {
        emit(state.copyWith(step: 1, status: PaymentStatus.successGet));
      }
      return false;
    }
  }

  _listenPaymentRetail(AuthState authState, Charge charge) async {
    if (isClosed) {
      return false;
    }
    if (qrStream != null) {
      _socketRepository.closeQrListening();
      qrStream?.cancel();
    }
    Timer? timer;

    Timer(const Duration(seconds: 15), () async {
      if (!isClosed) {
        emit(state.copyWith(qrWait: true));
      }
    });

    qrStream = _socketRepository.listenPayment(charge: charge).listen((
      event,
    ) async {
      if (event is Map && event["statusVenta"] == "success") {
        if (event["uuidFactura"] is String &&
            authState.currentDevice?.config.noPrintRollo != true) {
          await _printRollo(authState, idInvoice: event["uuidFactura"]);
        }
        if (timer != null) {
          timer!.cancel();
        }
        if (qrStream != null) {
          _socketRepository.closeQrListening();
          qrStream?.cancel();
        }
        emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
        timerSuccess = Timer(const Duration(seconds: 10), () async {
          emit(state.copyWith(status: PaymentStatus.successInvoice));
        });
      } else {
        timer = Timer(const Duration(seconds: 60), () async {
          emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
          timerSuccess = Timer(const Duration(seconds: 10), () async {
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          });
        });
        emit(
          state.copyWith(
            status: PaymentStatus.processingInvoice,
            qrCharge: () => null,
            qrLoading: false,
          ),
        );
      }
    });
  }

  Timer? timerManual;
  Timer? timerQR;

  bool isProcessing = false;
  bool activeProcessTimer = false;
  _saveAndListenPaymentOrder(AuthState authState, Charge charge) async {
    if (isClosed) {
      return false;
    }
    if (qrStream != null) {
      _socketRepository.closeQrListening();
      qrStream?.cancel();
    }

    Timer? timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!isProcessing && !isClosed) {
        isProcessing = true;
        _socketRepository.closeQrListening();
        qrStream?.cancel();
        timerManual?.cancel();
        timerQR?.cancel();
        emit(state.copyWith(step: 6, status: PaymentStatus.paymentProcessed));
        timerSuccess = Timer(
          const Duration(seconds: 10),
          () => emit(state.copyWith(status: PaymentStatus.successInvoice)),
        );
      }
    });
    timerQR = Timer(const Duration(seconds: 15), () async {
      if (!isClosed) {
        emit(state.copyWith(qrWait: true));
      }
    });

    timerManual?.cancel();
    timerManual = Timer(const Duration(seconds: 10), () async {
      if (!isClosed && state.paymentObj?.uuid != null && !activeProcessTimer) {
        activeProcessTimer = true;
        for (var i = 0; i < 60; i++) {
          if (isProcessing || isClosed) {
            break;
          }
          try {
            var comanda = await _comandaRepository.getComanda(
              orderUuid: state.paymentObj!.uuid!,
            );
            if (comanda.factura != null && !isProcessing) {
              isProcessing = true;
              if (qrStream != null) {
                _socketRepository.closeQrListening();
                qrStream?.cancel();
              }
              timerQR?.cancel();
              timeoutTimer.cancel();
              num? numero = comanda.numero;
              if (comanda.custom is Map &&
                  (comanda.custom["numeroCustom"] != null)) {
                numero = comanda.custom["numeroCustom"];
              }
              if (comanda.custom is Map &&
                  comanda.custom["facturaUuid"] is String) {
                await _printRollo(
                  authState,
                  idInvoice: comanda.custom["facturaUuid"],
                  orderNumber: comanda.numero?.toInt() ?? 0,
                  customOrderNumber: numero?.toInt(),
                );
              } else {
                await _printRolloOrder(
                  authState,
                  orderNumber: comanda.numero?.toInt() ?? 0,
                  customOrderNumber: numero?.toInt(),
                );
              }
              emit(
                state.copyWith(step: 5, status: PaymentStatus.paymentProcessed),
              );
              timerSuccess = Timer(const Duration(seconds: 10), () async {
                emit(state.copyWith(status: PaymentStatus.successInvoice));
              });
            }
          } catch (e) {
            log("error obteniendo comanda");
          }
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    });
    qrStream = _socketRepository.listenPayment(charge: charge).listen((
      event,
    ) async {
      if (event is Map && event["statusVenta"] == "success") {
        if (!isProcessing) {
          isProcessing = true;
          timerManual?.cancel();
          timerQR?.cancel();
          timeoutTimer.cancel();
          try {
            if (event["uuidFactura"] is String && event["numeroOrden"] is int) {
              await _printRollo(
                authState,
                idInvoice: event["uuidFactura"],
                orderNumber: event["numeroOrden"],
                customOrderNumber: event["numeroCustom"] is int
                    ? event["numeroCustom"]
                    : null,
              );
            } else if (event["numeroOrden"] is int) {
              await _printRolloOrder(
                authState,
                orderNumber: event["numeroOrden"],
                customOrderNumber: event["numeroCustom"] is int
                    ? event["numeroCustom"]
                    : null,
              );
            }
          } catch (_) {}
          if (qrStream != null) {
            _socketRepository.closeQrListening();
            qrStream?.cancel();
          }
          emit(state.copyWith(step: 5, status: PaymentStatus.paymentProcessed));
          timerSuccess = Timer(const Duration(seconds: 10), () async {
            emit(state.copyWith(status: PaymentStatus.successInvoice));
          });
        }
      } else {
        emit(
          state.copyWith(
            status: PaymentStatus.processingOrder,
            qrCharge: () => null,
            qrLoading: false,
          ),
        );
      }
    });
  }

  Future<void> queryBusiness({required AuthState authState}) async {
    try {
      if (state.documentNumber.value.length < 3) {
        return;
      }
      emit(
        state.copyWith(
          documentNumber: state.documentNumber.changeLoading(true),
        ),
      );
      List<Customer> businessList = await _businessRepository
          .queryBusinessSearch(
            query: state.documentNumber.value,
            pais: authState.taxesStrategy.countryCode,
          );
      Customer? find = businessList.firstWhereOrNull(
        (element) => element.nit == state.documentNumber.value,
      );
      if (find != null) {
        countryConfig?.setParamsCustomer(find);
      }
      emit(
        state.copyWith(
          businessName: state.businessName.changeValue(find?.razonSocial ?? ""),
          documentNumber: state.documentNumber.changeLoading(false),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          documentNumber: state.documentNumber.changeLoading(false),
        ),
      );
    }
  }

  cancelQR(AuthState authState) {
    if (authState.currentContribuyente?.tieneFacturacion == true) {
      emit(state.copyWith(step: 2, qrLoading: false, qrCharge: () => null));
    } else {
      emit(state.copyWith(step: 1, qrLoading: false, qrCharge: () => null));
    }
  }

  cancelBREB(AuthState authState) {
    emit(
      state.copyWith(
        step: authState.currentContribuyente?.tieneFacturacion == true ? 2 : 1,
        brebLoading: false,
        brebCharge: null,
      ),
    );
  }

  _printRolloOrder(
    AuthState authState, {
    required int orderNumber,
    int? customOrderNumber,
  }) async {
    log(
      "iZi Kiosco: [DEBUG] _printRolloOrder invoked for orderNumber: $orderNumber",
    );
    var tmp = await PrintTemplate.order80(
      orderNumber,
      customOrderNumber,
      authState.currentContribuyente!,
      authState.currentSucursal!,
      state.paymentObj,
      state.currentCurrency,
      taxesStrategy: authState.taxesStrategy,
    );
    var printUtils = PrintUtils();
    log(
      "iZi Kiosco: [DEBUG] _printRolloOrder dispatching ${tmp.length} PrintItems directly to printUtils...",
    );
    await printUtils.print(tmp, authState.currentDevice);
  }

  _printRollo(
    AuthState authState, {
    String? idInvoice,
    Invoice? invoice,
    int? orderNumber,
    int? customOrderNumber,
  }) async {
    try {
      log(
        "iZi Kiosco: [DEBUG] _printRollo invoked. idInvoice=$idInvoice, orderNumber=$orderNumber",
      );
      List<IziPrintItem> tmp = [];

      if (idInvoice == null && invoice == null && orderNumber == null) {
        log(
          "iZi Kiosco: [DEBUG] Aborting _printRollo, all tracking variables are null.",
        );
        return;
      }
      if (idInvoice != null) {
        invoice = await _comandaRepository.getInvoice(idInvoice);
        log(
          "iZi Kiosco: [DEBUG] Resolved explicit Invoice object from comanda repository? ${invoice != null}",
        );
      }
      if (orderNumber != null) {
        log("iZi Kiosco: [DEBUG] Formatting Order template natively...");
        tmp = await PrintTemplate.order80(
          orderNumber,
          customOrderNumber,
          authState.currentContribuyente!,
          authState.currentSucursal!,
          state.paymentObj,
          state.currentCurrency,
          taxesStrategy: authState.taxesStrategy,
        );
      }
      if (invoice == null) {
        log(
          "iZi Kiosco: [DEBUG] WARNING: invoice remained perfectly null, pushing purely order bytes (${tmp.length} items)...",
        );
        var printUtils = PrintUtils();
        await printUtils.print(tmp, authState.currentDevice);
        return;
      }

      final backendItems = invoice.customFactura["printItems"];
      final backendFormat = invoice.customFactura["printItemsFormat"];
      List<IziPrintItem>? backendTicket;
      if (backendItems is List && backendItems.isNotEmpty) {
        backendTicket = IziPrintItem.listFromJson(backendItems);
        if (backendTicket.isEmpty) backendTicket = null;
      }

      final backendCompacto =
          backendTicket != null && backendFormat == 'compacto';
      final useCompact = backendTicket != null
          ? backendCompacto
          : authState.currentDevice?.config.facturaCompacto == true;

      if (useCompact) {
        log(
          "iZi Kiosco: [DEBUG] Compact mode (backend=${backendTicket != null}): replacing tmp",
        );
        if (backendTicket != null) {
          tmp = backendTicket;
        } else {
          tmp = await PrintTemplate.printInvoiceCompact(
            authState.currentContribuyente!,
            authState.currentSucursal!,
            invoice,
            orderNumber: orderNumber,
            customOrderNumber: customOrderNumber,
            taxesStrategy: authState.taxesStrategy,
          );
        }
      } else {
        log(
          "iZi Kiosco: [DEBUG] Full mode: appending invoice payload after order",
        );
        tmp.add(IziPrintLineWrap(lines: 2));
        if (orderNumber != null) {
          tmp.add(IziPrintCut());
        }
        if (backendTicket != null) {
          tmp.addAll(backendTicket);
        } else if (authState.currentSucursal?.config is Map &&
            (authState.currentSucursal?.config as Map)["tipoFacturaVentas"] ==
                "compacto") {
          tmp.addAll(
            await PrintTemplate.printInvoiceCompact(
              authState.currentContribuyente!,
              authState.currentSucursal!,
              invoice,
              taxesStrategy: authState.taxesStrategy,
            ),
          );
        } else {
          tmp.addAll(
            await PrintTemplate.printInvoice(
              authState.currentContribuyente!,
              authState.currentSucursal!,
              invoice,
              taxesStrategy: authState.taxesStrategy,
            ),
          );
        }
      }

      var printUtils = PrintUtils();
      log(
        "iZi Kiosco: [DEBUG] Submitting FULL hybrid batch configuration to print core: ${tmp.length} items",
      );
      await printUtils.print(tmp, authState.currentDevice);
    } catch (e, stacktrace) {
      log(
        "iZi Kiosco: [DEBUG ERROR] _printRollo failure -> ${e.toString()} \nStacktrace: $stacktrace",
      );
    }
  }

  double _roundToNDecimals(num num, int n) {
    double multiplier = math.pow(10, n).toDouble();
    return (num * multiplier).round() / multiplier;
  }

  int _getIntFromDecimal(double num) {
    return (num * 100).toInt();
  }

  PaymentDto _buildPaymentDto(int metodoPago) {
    PaymentDtoVentaData ventaData = PaymentDtoVentaData(
      complemento:
          AppConstants.ciList.contains(state.complement.value.toLowerCase()) ||
              state.documentNumber.value.isEmpty
          ? null
          : state.complement.value,
      nit: state.documentNumber.value.isEmpty
          ? "0"
          : state.documentNumber.value,
      razonSocial: state.businessName.value.isEmpty
          ? "S/N"
          : state.businessName.value,
      telefonoComprador: state.phoneNumber.value.isNotEmpty
          ? "${state.phonePrefix}${state.phoneNumber.value}"
          : null,
      correoElectronico: state.email.value,
    );
    countryConfig?.setParamsOrderPayment(ventaData);
    PaymentDto newPayment = PaymentDto(
      ventaData: ventaData,
      orderId: state.paymentObj?.id ?? 0,
      metodoPago: metodoPago,
    );
    return newPayment;
  }

  Future<void> _setParamsCo(
    Contribuyente contribuyente,
    Sucursal sucursal,
  ) async {
    List<IdentificationType>? listIdentificationType;
    List<IvaResponsability>? listIvaResponsability;
    List<PersonType>? listPersonType;
    List<TaxResponsability>? listTaxResponsability;

    IdentificationType? identificationType;
    IvaResponsability? ivaResponsability;
    PersonType? personType;
    TaxResponsability? taxResponsability;

    final results = await Future.wait([
      _businessRepository.getIdentificationType(),
      _businessRepository.getIvaResponsability(),
      _businessRepository.getPersonType(),
      _businessRepository.getTaxResponsability(),
    ]);

    listIdentificationType = results[0] as List<IdentificationType>;
    listIvaResponsability = results[1] as List<IvaResponsability>;
    listPersonType = results[2] as List<PersonType>;
    listTaxResponsability = results[3] as List<TaxResponsability>;

    identificationType = listIdentificationType.firstOrNull;
    ivaResponsability = listIvaResponsability.lastOrNull;
    personType = listPersonType.lastOrNull;
    taxResponsability = listTaxResponsability.lastOrNull;
    emit(
      state.copyWith(
        paramsCo: ParamsCo(
          identificationType: identificationType?.codigo,
          ivaResponsability: ivaResponsability?.codigo,
          personType: personType?.codigo,
          listIdentificationType: listIdentificationType,
          listIvaResponsability: listIvaResponsability,
          listPersonType: listPersonType,
          listTaxResponsability: listTaxResponsability,
          taxResponsability: taxResponsability?.codigo,
        ),
      ),
    );
  }

  void _setParamsOrderPaymentCo(PaymentDtoVentaData paymentDtoVentaData) async {
    var identificationType = state.paramsCo?.identificationType;
    var ivaResponsability = state.paramsCo?.ivaResponsability;
    var personType = state.paramsCo?.personType;
    var taxResponsability = state.paramsCo?.taxResponsability;

    if (state.documentNumber.value.isEmpty) {
      paymentDtoVentaData.nit = AppConstants.defaultNitCo;
      paymentDtoVentaData.razonSocial = AppConstants.defaultRazonSocialCo;
      identificationType = AppConstants.tipoIdentificacionCo;
      ivaResponsability = AppConstants.responsabilidadIvaCo;
      personType = AppConstants.tipoPersonaCo;
      taxResponsability = AppConstants.responsabilidadFiscalCo;
    }

    if (identificationType == null ||
        ivaResponsability == null ||
        personType == null ||
        taxResponsability == null) {
      throw "Parametros incorrectos";
    }

    paymentDtoVentaData.co = PaymentDtoVentaDataCo(
      identificationType: identificationType,
      ivaResponsability: ivaResponsability,
      personType: personType,
      taxResponsability: taxResponsability,
    );
  }

  void _setParamsOrderPaymentBo(PaymentDtoVentaData paymentDtoVentaData) async {
    var documentType = state.paramsBo?.documentType;
    if (state.documentNumber.value.isEmpty) {
      documentType = state.paramsBo?.documentTypes.first;
    }
    paymentDtoVentaData.tipoDocumento = documentType;
  }

  void _setPaymentCo(PaymentAttemptDto paymentAttemptDto) async {
    var identificationType = state.paramsCo?.identificationType;
    var ivaResponsability = state.paramsCo?.ivaResponsability;
    var personType = state.paramsCo?.personType;
    var taxResponsability = state.paramsCo?.taxResponsability;

    if (state.documentNumber.value.isEmpty) {
      paymentAttemptDto.nit = AppConstants.defaultNitCo;
      paymentAttemptDto.razonSocial = AppConstants.defaultRazonSocialCo;
      identificationType = AppConstants.tipoIdentificacionCo;
      ivaResponsability = AppConstants.responsabilidadIvaCo;
      personType = AppConstants.tipoPersonaCo;
      taxResponsability = AppConstants.responsabilidadFiscalCo;
    }

    if (identificationType == null ||
        ivaResponsability == null ||
        personType == null ||
        taxResponsability == null) {
      throw "Parametros incorrectos";
    }

    paymentAttemptDto.co = PaymentDtoVentaDataCo(
      identificationType: identificationType,
      ivaResponsability: ivaResponsability,
      personType: personType,
      taxResponsability: taxResponsability,
    );
  }

  void _setParamsCustomerCo(Customer customer) async {
    emit(
      state.copyWith(
        status: PaymentStatus.setInputs,
        paramsCo: state.paramsCo?.copyWith(
          identificationType: customer.custom?.co?.tipoIdentificacion,
          taxResponsability: customer.custom?.co?.responsabilidadFiscal,
          ivaResponsability: customer.custom?.co?.responsabilidadIva,
          personType: customer.custom?.co?.tipoPersona,
        ),
      ),
    );
    emit(state.copyWith(status: PaymentStatus.successGet));
  }

  Future _setParamsBo(Contribuyente contribuyente, Sucursal sucursal) async {
    List<DocumentType>? documentTypes;
    DocumentType? documentType;
    documentTypes = await _businessRepository.getDocumentTypes();
    documentType = documentTypes.lastOrNull;
    emit(
      state.copyWith(
        paramsBo: ParamsBo(
          documentType: documentType,
          documentTypes: documentTypes ?? [],
        ),
      ),
    );
  }

  void _setPaymentBo(PaymentAttemptDto paymentAttemptDto) async {
    var documentType = state.paramsBo?.documentType;
    if (state.documentNumber.value.isEmpty) {
      documentType = state.paramsBo?.documentTypes.first;
    }
    paymentAttemptDto.tipoDocumento = documentType?.toJson();
  }

  void _setParamsCustomerBo(Customer customer) async {}

  PaymentCountryTaxes? _setCountryConfig(Contribuyente contribuyente) {
    if (contribuyente.tieneFacturacion == true) {
      if (contribuyente.usaSiat == true ||
          (contribuyente.config is Map &&
              contribuyente.config["paisId"] == "BO")) {
        countryConfig = PaymentConfig(
          setParams: _setParamsBo,
          setParamsCustomer: _setParamsCustomerBo,
          setParamsOrderPayment: _setParamsOrderPaymentBo,
          setParamsPayment: _setPaymentBo,
        );
        return PaymentCountryTaxes.bolivia;
      } else if (contribuyente.config is Map &&
          contribuyente.config["paisId"] == "CO") {
        countryConfig = PaymentConfig(
          setParams: _setParamsCo,
          setParamsCustomer: _setParamsCustomerCo,
          setParamsOrderPayment: _setParamsOrderPaymentCo,
          setParamsPayment: _setPaymentCo,
        );
        return PaymentCountryTaxes.colombia;
      }
    }
    return null;
  }

  changeInputsBo({int? documentType}) {
    if (documentType != null) {
      emit(
        state.copyWith(
          paramsBo: state.paramsBo?.copyWith(
            documentType: state.paramsBo?.documentTypes.firstWhere(
              (element) => element.codigoClasificador == documentType,
            ),
          ),
        ),
      );
    }
  }

  changeInputsCo({
    String? personType,
    String? taxResponsability,
    String? identificationType,
    String? ivaResponsability,
  }) {
    if (personType != null) {
      emit(
        state.copyWith(
          paramsCo: state.paramsCo?.copyWith(personType: personType),
        ),
      );
    }
    if (taxResponsability != null) {
      emit(
        state.copyWith(
          paramsCo: state.paramsCo?.copyWith(
            taxResponsability: taxResponsability,
          ),
        ),
      );
    }
    if (identificationType != null) {
      if (identificationType == AppConstants.idNitCo) {
        emit(
          state.copyWith(
            status: PaymentStatus.setInputs,
            paramsCo: state.paramsCo?.copyWith(
              identificationType: identificationType,
              ivaResponsability:
                  AppConstants.defaultDataNit["ivaResponsability"],
              personType: AppConstants.defaultDataNit["personType"],
              taxResponsability:
                  AppConstants.defaultDataNit["taxResponsability"],
            ),
          ),
        );
        emit(state.copyWith(status: PaymentStatus.successGet));
      } else {
        emit(
          state.copyWith(
            status: PaymentStatus.setInputs,
            paramsCo: state.paramsCo?.copyWith(
              identificationType: identificationType,
              ivaResponsability:
                  AppConstants.defaultDataOther["ivaResponsability"],
              personType: AppConstants.defaultDataOther["personType"],
              taxResponsability:
                  AppConstants.defaultDataOther["taxResponsability"],
            ),
          ),
        );
        emit(state.copyWith(status: PaymentStatus.successGet));
      }
    }
    if (ivaResponsability != null) {
      emit(
        state.copyWith(
          paramsCo: state.paramsCo?.copyWith(
            ivaResponsability: ivaResponsability,
          ),
        ),
      );
    }
  }

  cancelPaymentCard() {
    cancelToken.cancel();
    cancelToken = CancelToken();
  }

  Future<void> downloadQrCode() async {
    try {
      final qrUrl = state.qrCharge?.qrUrl;
      if (qrUrl == null) {
        return;
      }

      final dio = Dio();
      final response = await dio.get<List<int>>(
        qrUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

        if (kIsWeb) {
          final base64data = base64Encode(bytes);
          final a = html.AnchorElement(
            href: 'data:image/png;base64,$base64data',
          );
          a.setAttribute('download', fileName);
          a.click();
        } else {
          final status = await Permission.storage.request();
          if (status.isGranted) {
            final directory = await getApplicationDocumentsDirectory();
            final file = File('${directory.path}/$fileName');
            await file.writeAsBytes(bytes);
          } else {}
        }
      } else {}
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> confirmDemoPayment() async {
    try {
      if (state.paymentObj?.isComanda == true) {
        await _comandaRepository.confirmDemoPaymentOrder(
          id: state.qrCharge?.id ?? 0,
        );
      } else {
        await _comandaRepository.confirmDemoPaymentRetail(
          id: state.qrCharge?.id ?? 0,
        );
      }
    } catch (e) {
      log(e.toString());
      emit(
        state.copyWith(
          status: PaymentStatus.errorGet,
          errorDescription: e.toString(),
        ),
      );
      emit(state.copyWith(status: PaymentStatus.waitingGet));
    }
  }
}
