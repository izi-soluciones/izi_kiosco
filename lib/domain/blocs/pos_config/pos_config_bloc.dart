import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

part 'pos_config_state.dart';

class PosConfigBloc extends Cubit<PosConfigState> {
  final AuthBloc authBloc;
  nsd.Discovery? _discovery;
  Timer? _healthTimer;

  PosConfigBloc(this.authBloc) : super(PosConfigState.init()) {
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    // Optionally load last paired IP and check health immediately
    // For now, start empty if not saved differently
  }

  Future<void> beginDiscovery() async {
    emit(
      state.copyWith(
        status: PosConfigStatus.discovering,
        discoveredDevices: [],
      ),
    );
    List<PosDevice> devices = [];

    // 1. Check Localhost (Mock POS) fallback
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8081/health'))
          .timeout(const Duration(seconds: 1));
      if (res.statusCode == 200) {
        devices.add(
          const PosDevice(name: "Local Mock POS", ip: "127.0.0.1", port: 8081),
        );
      }
    } catch (_) {}

    // 2. Start mDNS Discovery
    try {
      final discovery = await nsd.startDiscovery('_http._tcp');
      _discovery = discovery;
      _discovery?.addListener(() {
        final currentServices = _discovery?.services ?? [];
        final newDevices = List<PosDevice>.from(devices);

        for (var service in currentServices) {
          if (service.name != null && service.name!.startsWith("izify-POS-")) {
            final ip = service.host;
            final port = service.port;
            if (ip != null && port != null) {
              final exists = newDevices.any(
                (d) => d.ip == ip && d.port == port,
              );
              if (!exists) {
                newDevices.add(
                  PosDevice(name: service.name!, ip: ip, port: port),
                );
              }
            }
          }
        }

        if (!isClosed) {
          emit(state.copyWith(discoveredDevices: newDevices));
        }
      });
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PosConfigStatus.error,
            errorMessage: "Error starting mDNS: $e",
          ),
        );
      }
    }
  }

  Future<void> endDiscovery() async {
    if (_discovery != null) {
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (state.status == PosConfigStatus.discovering) {
      emit(state.copyWith(status: PosConfigStatus.idle));
    }
  }

  Future<void> pairDevice(PosDevice device) async {
    emit(state.copyWith(status: PosConfigStatus.pairing));

    final kioskId = authBloc.state.currentDevice?.nombre ?? 'KIOSK-001';

    try {
      final res = await http
          .post(
            Uri.parse('http://${device.ip}:${device.port}/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"kioskId": kioskId}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['token'] != null) {
          await TokenUtils.saveTokenCard(
            data['token'],
          ); // Reusing tokenCard for Izify POS token
          emit(
            state.copyWith(
              status: PosConfigStatus.paired,
              pairedDevice: device,
              isHealthy: true,
            ),
          );
          _startHealthPolling(device);
        } else {
          emit(
            state.copyWith(
              status: PosConfigStatus.error,
              errorMessage: "Invalid pairing response",
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: PosConfigStatus.error,
            errorMessage: "Failed to pair: ${res.statusCode}",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PosConfigStatus.error,
          errorMessage: "Pairing network error: $e",
        ),
      );
    }
  }

  void _startHealthPolling(PosDevice device) {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final res = await http
            .get(Uri.parse('http://${device.ip}:${device.port}/health'))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          if (!isClosed) emit(state.copyWith(isHealthy: true));
        } else {
          if (!isClosed) emit(state.copyWith(isHealthy: false));
        }
      } catch (e) {
        if (!isClosed) emit(state.copyWith(isHealthy: false));
      }
    });
  }

  Future<void> unpair() async {
    if (state.pairedDevice != null) {
      final token = await TokenUtils.getTokenCard();
      try {
        await http
            .post(
              Uri.parse(
                'http://${state.pairedDevice!.ip}:${state.pairedDevice!.port}/unpair',
              ),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    _healthTimer?.cancel();
    await TokenUtils.deleteTokenCard();
    emit(
      state.copyWith(
        status: PosConfigStatus.idle,
        pairedDevice: null,
        isHealthy: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _healthTimer?.cancel();
    if (_discovery != null) {
      nsd.stopDiscovery(_discovery!);
    }
    return super.close();
  }
}

class PosDevice extends Equatable {
  final String name;
  final String ip;
  final int port;

  const PosDevice({required this.name, required this.ip, required this.port});

  @override
  List<Object?> get props => [name, ip, port];
}
