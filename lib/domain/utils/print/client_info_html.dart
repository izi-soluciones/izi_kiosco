// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? obtenerUserAgent() {
  try {
    return html.window.navigator.userAgent;
  } catch (_) {
    return null;
  }
}
