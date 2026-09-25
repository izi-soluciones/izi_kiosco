import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Sirve el logo congelado en el fixture a cualquier GET que hagan los
/// templates, para que el harness no dependa de la red ni del servidor.
class FixtureHttpOverrides extends HttpOverrides {
  FixtureHttpOverrides(this.bytes);

  final Uint8List bytes;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FixtureHttpClient(bytes);
}

class _FixtureHttpClient implements HttpClient {
  _FixtureHttpClient(this.bytes);

  final Uint8List bytes;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FixtureHttpClientRequest(bytes, url, method);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FixtureHttpClientRequest implements HttpClientRequest {
  _FixtureHttpClientRequest(this.bytes, this.uri, this.method);

  final Uint8List bytes;

  @override
  final Uri uri;

  @override
  final String method;

  @override
  final HttpHeaders headers = _FixtureHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FixtureHttpClientResponse(bytes);

  @override
  Future<HttpClientResponse> get done => close();

  @override
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FixtureHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FixtureHttpClientResponse(this.bytes);

  final Uint8List bytes;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([bytes]).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => bytes.length;

  @override
  HttpHeaders get headers => _FixtureHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FixtureHttpHeaders implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
