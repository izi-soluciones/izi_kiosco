part of 'pos_configuration_bloc.dart';

enum PosConfigurationStatus { waitingActivate, successActivate, init, errorActivate, successChangeEnvironment,errorChangeEnvironment,waitingChangeEnvironment}

class PosConfigurationState extends Equatable {
  final PosConfigurationStatus status;

  final bool isTest;

  const PosConfigurationState({required this.status, required this.isTest});

  factory PosConfigurationState.init(bool isTest) => PosConfigurationState(
      status: PosConfigurationStatus.init, isTest: isTest);

  copyWith({PosConfigurationStatus? status, bool? isTest}) {
    return PosConfigurationState(
        status: status ?? this.status, isTest: isTest ?? this.isTest);
  }

  @override
  List<Object?> get props => [status, isTest];
}
