part of 'pos_config_bloc.dart';

enum PosConfigStatus { idle, discovering, pairing, paired, error }

class PosConfigState extends Equatable {
  final PosConfigStatus status;
  final List<PosDevice> discoveredDevices;
  final PosDevice? pairedDevice;
  final bool isHealthy;
  final String? errorMessage;

  const PosConfigState({
    required this.status,
    required this.discoveredDevices,
    this.pairedDevice,
    required this.isHealthy,
    this.errorMessage,
  });

  factory PosConfigState.init() {
    return const PosConfigState(
      status: PosConfigStatus.idle,
      discoveredDevices: [],
      isHealthy: false,
    );
  }

  PosConfigState copyWith({
    PosConfigStatus? status,
    List<PosDevice>? discoveredDevices,
    PosDevice? pairedDevice,
    bool? isHealthy,
    String? errorMessage,
  }) {
    return PosConfigState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      pairedDevice: pairedDevice ?? this.pairedDevice,
      isHealthy: isHealthy ?? this.isHealthy,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    discoveredDevices,
    pairedDevice,
    isHealthy,
    errorMessage,
  ];
}
