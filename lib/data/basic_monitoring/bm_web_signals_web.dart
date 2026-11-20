import 'dart:html' as html;

bool? bmOnline() {
  try {
    return html.window.navigator.onLine;
  } catch (_) {
    return null;
  }
}

String? bmVisibility() {
  try {
    final state = html.document.visibilityState;
    return state == 'hidden' ? 'hidden' : 'visible';
  } catch (_) {
    return null;
  }
}
