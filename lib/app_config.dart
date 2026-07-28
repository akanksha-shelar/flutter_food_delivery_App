enum Flavor { admin, client }

class AppConfig {
  final Flavor flavor;
  final String appTitle;

  static late AppConfig instance;

  AppConfig({required this.flavor, required this.appTitle}) {
    instance = this;
  }

  static bool get isAdmin => instance.flavor == Flavor.admin;
  static bool get isClient => instance.flavor == Flavor.client;
}
