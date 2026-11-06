/// Outside the browser there is no page to watch: nothing to report.
Map<String, Object?> platformStartInfo() => const {};

void listenPlatformSignals(
    void Function(String type, Map<String, Object?> data) emit) {}

String? currentVisibility() => null;

bool? currentOnline() => null;

/// See the web implementation. Native builds read the socket error instead.
Future<({String result, int ms})> probeReachability(Uri url,
        {Duration timeout = const Duration(seconds: 3)}) async =>
    (result: 'unsupported', ms: 0);
