/// The app build that enrolls: `app` in the monitoring contracts.
class MonitoringApp {
  /// The longest `app.*` value izi-ms-monitoreo accepts.
  static const int maxFieldLength = 64;

  /// `2.3.1+45`: version and build number.
  final String? version;

  /// The `FLAVOR` the app was built with (`izify`, `prod`, `local`...).
  final String flavor;

  /// `web` or `android`.
  final String platform;

  const MonitoringApp(
      {required this.version, required this.flavor, required this.platform});

  Map<String, dynamic> toJson() {
    final version = MonitoringEnrollmentDto.fitText(this.version, maxFieldLength);
    final flavor = MonitoringEnrollmentDto.fitText(this.flavor, maxFieldLength);
    final platform = MonitoringEnrollmentDto.fitText(this.platform, maxFieldLength);
    return {
      if (version != null) "version": version,
      if (flavor != null) "flavor": flavor,
      if (platform != null) "platform": platform,
    };
  }
}

/// Body of `POST /monitoreo/kiosco/enrolamiento` (contracts §3.1).
///
/// Contribuyente, sucursal and device are not sent as ids: the gateway
/// takes them from the kiosk token. The names only make the support console
/// readable, so each is optional, and each is cut to what the service
/// accepts: a long name must never keep the kiosk from enrolling.
class MonitoringEnrollmentDto {
  static const int schema = 1;
  static const String kind = "kiosk";

  /// The longest `deviceName` izi-ms-monitoreo accepts.
  static const int maxDeviceNameLength = 100;

  /// The longest `business.*` value izi-ms-monitoreo accepts.
  static const int maxBusinessFieldLength = 200;

  final String installationId;
  final MonitoringApp app;
  final String? deviceName;
  final String? contribuyenteNombre;
  final String? sucursalNombre;
  final String? pais;

  const MonitoringEnrollmentDto(
      {required this.installationId,
      required this.app,
      this.deviceName,
      this.contribuyenteNombre,
      this.sucursalNombre,
      this.pais});

  Map<String, dynamic> toJson() {
    final deviceName = fitText(this.deviceName, maxDeviceNameLength);
    final contribuyenteNombre = fitText(this.contribuyenteNombre, maxBusinessFieldLength);
    final sucursalNombre = fitText(this.sucursalNombre, maxBusinessFieldLength);
    final pais = fitText(this.pais, maxBusinessFieldLength);
    final business = {
      if (contribuyenteNombre != null) "contribuyenteNombre": contribuyenteNombre,
      if (sucursalNombre != null) "sucursalNombre": sucursalNombre,
      if (pais != null) "pais": pais,
    };
    return {
      "schema": schema,
      "installationId": installationId,
      "kind": kind,
      "app": app.toJson(),
      if (deviceName != null) "deviceName": deviceName,
      if (business.isNotEmpty) "business": business,
    };
  }

  /// [value] trimmed and cut to at most [max] UTF-16 code units (how the
  /// service counts), never splitting an emoji or other surrogate pair. Null
  /// when nothing is left.
  static String? fitText(String? value, int max) {
    if (value == null) return null;
    var text = value.trim();
    if (text.length > max) {
      var end = max;
      // A high surrogate at the cut would be left without its pair.
      if (end > 0 && _isHighSurrogate(text.codeUnitAt(end - 1))) end--;
      text = text.substring(0, end).trimRight();
    }
    return text.isEmpty ? null : text;
  }

  static bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}
