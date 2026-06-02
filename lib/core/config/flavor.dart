/// Build flavors keep the same code targeting different backends
/// and crash-reporting projects. Always pass the flavor explicitly —
/// `Flavor.production` is never inferred.

enum Flavor {
  development,
  staging,
  production;

  String get envFileName {
    switch (this) {
      case Flavor.development:
        return '.env.development';
      case Flavor.staging:
        return '.env.staging';
      case Flavor.production:
        return '.env.production';
    }
  }

  String get displayName {
    switch (this) {
      case Flavor.development:
        return 'Datasolids (Dev)';
      case Flavor.staging:
        return 'Datasolids (Staging)';
      case Flavor.production:
        return 'Datasolids';
    }
  }

  bool get isProduction => this == Flavor.production;
}
