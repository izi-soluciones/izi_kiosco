import 'dart:collection';

class BmActivity {
  BmActivity();

  static final BmActivity instance = BmActivity();

  final HashSet<Object> _charging = HashSet<Object>.identity();
  final Expando<bool> _closed = Expando<bool>('bmActivityClosed');
  String? _screen;

  void paymentChanged(Object owner, bool charging) {
    try {
      // Un emit tardío de un bloc ya cerrado no puede dejar «paying» pegado.
      if (_closed[owner] == true) return;
      if (charging) {
        _charging.add(owner);
      } else {
        _charging.remove(owner);
      }
    } catch (_) {}
  }

  void paymentClosed(Object owner) {
    try {
      _closed[owner] = true;
    } catch (_) {}
    _charging.remove(owner);
  }

  void screenChanged(String? screen) {
    _screen = screen;
  }

  String? get screen => _screen;

  bool get charging => _charging.isNotEmpty;

  String get mode {
    if (charging) return 'paying';
    if (_screen == 'makeOrder' || _screen == 'makeOrderRetail') return 'ordering';
    return 'idle';
  }
}
