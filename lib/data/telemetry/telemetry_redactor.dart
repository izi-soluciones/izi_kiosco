/// Keeps secrets out of everything the kiosk records: no card number, PIN,
/// EcoPay credential or token may reach the device log or Sentry.
///
/// Two layers, because a secret can hide in a key or inside a message:
/// - a key naming a secret drops its value whatever it holds;
/// - every string is scrubbed of card-like digit runs, bearer tokens and URL
///   query strings (the `/payment-updates` URL carries `?token=`).
class TelemetryRedactor {
  static const String mask = '[redactado]';
  static const int maxStringLength = 300;
  static const int _maxDepth = 4;

  /// Words that make a key secret, matched against the words of the key
  /// (`mqttPassword` → mqtt, password), so `company` never matches `pan`.
  static const Set<String> _secretWords = {
    'token', 'password', 'pass', 'pwd', 'pin', 'secret', 'mqtt',
    'auth', 'authorization', 'pan', 'cvv', 'cvc', 'signature', 'cookie',
    'credential', 'credentials',
  };

  /// Whole keys that are secret without a secret word in them.
  static const Set<String> _secretKeys = {
    'cardnumber', 'cardmasked', 'commerceid', 'cajaid', 'apikey',
    'captchakey', 'xpublictoken',
  };

  static bool isSecretKey(String key) {
    final flat = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (_secretKeys.contains(flat)) return true;
    final words = key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'));
    return words.any(_secretWords.contains);
  }

  /// 12 to 19 digits, optionally grouped by spaces or dashes: a card number.
  /// Not when glued to a letter, digit or dash, so a `KOS-<millis>-…`
  /// reference survives.
  static final RegExp _cardLike = RegExp(r'(?<![\w-])(?:\d[ -]?){11,18}\d(?![\w-])');
  static final RegExp _bearer = RegExp(r'Bearer\s+\S+', caseSensitive: false);
  static final RegExp _urlQuery =
      RegExp(r'\b((?:https?|wss?)://[^\s?#]+)\?[^\s#]*', caseSensitive: false);
  static final RegExp _secretParam = RegExp(
      r'\b(token|password|pass|pin|secret|signature)=([^&\s]+)',
      caseSensitive: false);

  static String scrub(String value) {
    var out = value
        .replaceAll(_bearer, 'Bearer $mask')
        .replaceAllMapped(_urlQuery, (m) => '${m[1]}?$mask')
        .replaceAllMapped(_secretParam, (m) => '${m[1]}=$mask')
        .replaceAll(_cardLike, mask);
    if (out.length > maxStringLength) {
      out = '${out.substring(0, maxStringLength)}…';
    }
    return out;
  }

  /// A copy of [data] safe to keep and send. Values become JSON-friendly:
  /// strings, numbers, booleans, null, lists and maps.
  static Map<String, Object?> redact(Map<String, Object?> data) =>
      _map(data, 0);

  static Map<String, Object?> _map(Map data, int depth) => {
        for (final e in data.entries)
          e.key.toString(): isSecretKey(e.key.toString())
              ? mask
              : _value(e.value, depth + 1),
      };

  static Object? _value(Object? value, int depth) {
    if (value == null || value is num || value is bool) return value;
    if (value is String) return scrub(value);
    if (depth > _maxDepth) return '…';
    if (value is Map) return _map(value, depth);
    if (value is Iterable) {
      return value.take(20).map((v) => _value(v, depth + 1)).toList();
    }
    if (value is Duration) return value.inMilliseconds;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.name;
    return scrub(value.toString());
  }
}
