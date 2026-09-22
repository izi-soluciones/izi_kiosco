part of 'pos_config_bloc.dart';

enum PosConfigStatus { idle, discovering, pairing, paired, pairedLoaded, error }

class PosConfigState extends Equatable {
  final PosConfigStatus status;
  final List<PosDevice> discoveredDevices;
  final PosDevice? pairedDevice;
  final bool? isHealthy;
  final Map<String, dynamic>? healthData;
  final String? errorMessage;

  /// Last readiness report from the paired terminal.
  final IzifyPosHealth? health;

  /// Why the paired terminal cannot charge right now (Spanish), or null.
  final String? notReadyReason;

  const PosConfigState({
    required this.status,
    required this.discoveredDevices,
    this.pairedDevice,
    this.isHealthy,
    this.healthData,
    this.errorMessage,
    this.health,
    this.notReadyReason,
  });

  factory PosConfigState.init() {
    return const PosConfigState(
      status: PosConfigStatus.idle,
      discoveredDevices: [],
      pairedDevice: null,
      isHealthy: null,
      healthData: null,
      errorMessage: null,
    );
  }

  PosConfigState copyWith({
    PosConfigStatus? status,
    List<PosDevice>? discoveredDevices,
    PosDevice? pairedDevice,
    bool clearPairedDevice = false,
    bool? isHealthy,
    Map<String, dynamic>? healthData,
    String? errorMessage,
    IzifyPosHealth? Function()? health,
    String? Function()? notReadyReason,
  }) {
    return PosConfigState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      pairedDevice: clearPairedDevice ? null : (pairedDevice ?? this.pairedDevice),
      isHealthy: clearPairedDevice ? null : (isHealthy ?? this.isHealthy),
      healthData: clearPairedDevice ? null : (healthData ?? this.healthData),
      errorMessage: errorMessage ?? this.errorMessage,
      health: clearPairedDevice ? null : (health != null ? health() : this.health),
      notReadyReason: clearPairedDevice
          ? null
          : (notReadyReason != null ? notReadyReason() : this.notReadyReason),
    );
  }

  @override
  List<Object?> get props => [
    status,
    discoveredDevices,
    pairedDevice,
    isHealthy,
    healthData,
    errorMessage,
    health,
    notReadyReason,
  ];
}
