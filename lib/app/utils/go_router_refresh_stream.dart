import 'dart:async';
import 'package:flutter/material.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class GoRouterRefreshStream extends ChangeNotifier {

  AuthState stateGlobal;

  GoRouterRefreshStream(Stream<AuthState> stream,this.stateGlobal) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (state){
            if(state.status != stateGlobal.status){
              stateGlobal = state;
              return notifyListeners();
            }
          },
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
