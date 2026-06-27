/// Build-time flavor configuration (dev / staging / prod).
/// Selects the FastAPI base URL and Firebase project per environment.
enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  /// Dev config talks to the FastAPI service running on the developer's Mac.
  /// - On an Android emulator, `10.0.2.2` aliases the host machine.
  /// - On a physical phone, replace with the Mac's LAN IP (run
  ///   `ipconfig getifaddr en0` on the Mac and update the value below).
  /// Both the phone and the Mac must be on the same WiFi network.
  static const AppConfig dev = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://192.168.31.155:8080/api/v1',
  );
  static const AppConfig staging = AppConfig(
    flavor: Flavor.staging,
    apiBaseUrl: 'https://staging-api.faithjournal.app/api/v1',
  );
  static const AppConfig prod = AppConfig(
    flavor: Flavor.prod,
    apiBaseUrl: 'https://api.faithjournal.app/api/v1',
  );
}
