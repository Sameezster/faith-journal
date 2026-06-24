/// Build-time flavor configuration (dev / staging / prod).
/// Selects the FastAPI base URL and Firebase project per environment.
enum Flavor { dev, staging, prod }

class AppConfig {
  const AppConfig({required this.flavor, required this.apiBaseUrl});

  final Flavor flavor;
  final String apiBaseUrl;

  static const AppConfig dev = AppConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://10.0.2.2:8080/api/v1', // Android emulator -> localhost
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
