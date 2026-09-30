import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// What the browser says about this page when the app starts.
Map<String, Object?> platformStartInfo() {
  final info = <String, Object?>{};
  void read(String key, Object? Function() value) {
    try {
      info[key] = value();
    } catch (_) {}
  }

  read('userAgent', () => web.window.navigator.userAgent);
  read('origin', () => web.window.location.origin);
  read('visibility', () => web.document.visibilityState);
  read('online', () => web.window.navigator.onLine);
  read('cores', () => web.window.navigator.hardwareConcurrency);
  read('screen', () => '${web.window.screen.width}x${web.window.screen.height}');
  // Chrome discards a background tab to save memory and reloads it when shown
  // again: that is a restart nobody asked for.
  read('wasDiscarded',
      () => (web.document as JSObject).getProperty<JSAny?>('wasDiscarded'.toJS)?.dartify());
  read('deviceMemoryGb',
      () => (web.window.navigator as JSObject).getProperty<JSAny?>('deviceMemory'.toJS)?.dartify());
  return info;
}

/// Reports what can silently stop the kiosk's timers and requests: the tab
/// hidden (Chrome throttles its timers), frozen or back from a freeze, and
/// the browser going offline.
void listenPlatformSignals(
    void Function(String type, Map<String, Object?> data) emit) {
  try {
    web.document.addEventListener(
        'visibilitychange',
        ((web.Event _) =>
                emit('web.visibility', {'state': web.document.visibilityState}))
            .toJS);
    web.document.addEventListener(
        'freeze', ((web.Event _) => emit('web.freeze', const {})).toJS);
    web.document.addEventListener(
        'resume', ((web.Event _) => emit('web.resume', const {})).toJS);
    web.window.addEventListener(
        'online', ((web.Event _) => emit('web.online', const {})).toJS);
    web.window.addEventListener(
        'offline', ((web.Event _) => emit('web.offline', const {})).toJS);
    web.window.addEventListener(
        'pagehide', ((web.Event _) => emit('web.pagehide', const {})).toJS);
  } catch (_) {}
}

String? currentVisibility() {
  try {
    return web.document.visibilityState;
  } catch (_) {
    return null;
  }
}

bool? currentOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return null;
  }
}

/// Tells why a request to the terminal failed, which the browser hides: a
/// CORS refusal and a refused connection both reach Dart as the same
/// "XMLHttpRequest error".
///
/// Asks [url] again in `no-cors` mode, where the browser does not need the
/// terminal's permission to complete the request:
/// - `answered`: the terminal is up and answered; the earlier failure was the
///   browser refusing to hand over the answer (CORS).
/// - `failed`: the request itself failed; [ms] tells a refused connection
///   (a few ms) from a network that gave up.
/// - `no_answer`: nothing came back before [timeout].
Future<({String result, int ms})> probeReachability(Uri url,
    {Duration timeout = const Duration(seconds: 3)}) async {
  final watch = Stopwatch()..start();
  final controller = web.AbortController();
  final timer = Timer(timeout, () => controller.abort());
  try {
    await web.window
        .fetch(
            url.toString().toJS,
            web.RequestInit(
                mode: 'no-cors', cache: 'no-store', signal: controller.signal))
        .toDart;
    return (result: 'answered', ms: watch.elapsedMilliseconds);
  } catch (_) {
    return (
      result: watch.elapsed >= timeout ? 'no_answer' : 'failed',
      ms: watch.elapsedMilliseconds,
    );
  } finally {
    timer.cancel();
  }
}
