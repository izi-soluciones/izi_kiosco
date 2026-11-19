import 'package:web/web.dart' as web;

/// Reloads the kiosk page, as F5 would: the app starts over from the
/// server's files. True once asked.
bool reloadPage() {
  web.window.location.reload();
  return true;
}
