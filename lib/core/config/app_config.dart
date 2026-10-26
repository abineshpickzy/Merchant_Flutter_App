enum Environment { dev, qa, prod }

class AppConfig {
  final Environment environment;
  final String serverUrl;
  final String appName;
  final int paymentEnvironment;

  const AppConfig({
    required this.environment,
    required this.serverUrl,
    required this.appName,
    required this.paymentEnvironment,
  });

  static late final AppConfig instance;

  static void init({
    required Environment environment,
    required String serverUrl,
    required String appName,
    required int paymentEnvironment,
  }) {
    instance = AppConfig(
      environment: environment,
      serverUrl: serverUrl,
      appName: appName,
      paymentEnvironment: paymentEnvironment,
    );
  }

  bool get isDev => environment == Environment.dev;
  bool get isQa => environment == Environment.qa;
  bool get isProd => environment == Environment.prod;
}
