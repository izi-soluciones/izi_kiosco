/// The app build that enrolls: `app` in the monitoring contracts.
class MonitoringApp {
  /// `2.3.1+45`: version and build number.
  final String? version;

  /// The `FLAVOR` the app was built with (`izify`, `prod`, `local`...).
  final String flavor;

  /// `web` or `android`.
  final String platform;

  const MonitoringApp(
      {required this.version, required this.flavor, required this.platform});

  Map<String, dynamic> toJson() => {
        if (version != null) "version": version,
        "flavor": flavor,
        "platform": platform,
      };
}

/// Body of `POST /monitoreo/kiosco/enrolamiento` (contracts §3.1).
///
/// Contribuyente, sucursal and device are not sent as ids: the gateway
/// takes them from the kiosk token. The names only make the support console
/// readable, so each is optional.
class MonitoringEnrollmentDto {
  static const int schema = 1;
  static const String kind = "kiosk";

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
    final business = {
      if (_present(contribuyenteNombre)) "contribuyenteNombre": contribuyenteNombre,
      if (_present(sucursalNombre)) "sucursalNombre": sucursalNombre,
      if (_present(pais)) "pais": pais,
    };
    return {
      "schema": schema,
      "installationId": installationId,
      "kind": kind,
      "app": app.toJson(),
      if (_present(deviceName)) "deviceName": deviceName,
      if (business.isNotEmpty) "business": business,
    };
  }

  static bool _present(String? value) => value != null && value.trim().isNotEmpty;
}
