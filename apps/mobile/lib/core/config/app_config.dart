/// Build-time flavor configuration (dev / staging / prod).
/// Selects the FastAPI base URL and Firebase project per environment.
enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  /// LAN IP of the developer's Mac. Update this to match
  /// `ipconfig getifaddr en0` on the host machine. Used as the dev API host
  /// from physical phones on the same WiFi.
  static const String devLanIp = '192.168.31.155';

  /// Build a dev config for the given host. `main()` picks the right host
  /// at startup based on whether the app is running on a real device or
  /// inside an emulator/simulator.
  factory AppConfig.dev({required String host}) => AppConfig(
        flavor: Flavor.dev,
        apiBaseUrl: 'http://$host:8080/api/v1',
      );

  /// Static fallback used in tests / when the runtime resolver can't run.
  static const AppConfig devFallback = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://$devLanIp:8080/api/v1',
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
