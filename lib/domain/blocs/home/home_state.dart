part of 'home_bloc.dart';


class HomeState extends Equatable{

  final bool statusServer;
  final bool statusServerPos;


  const HomeState(
      {
        required this.statusServer,
        required this.statusServerPos
    });


  factory HomeState.init()=>
  const HomeState(statusServer: true, statusServerPos: true);


  HomeState copyWith({
    bool? statusServer,
    bool? statusServerPos,}){
    return HomeState(
        statusServer: statusServer?? this.statusServer,
        statusServerPos: statusServerPos??this.statusServerPos
    );
  }

  @override
  List<Object?> get props => [
    statusServerPos,
    statusServer
  ];
}
