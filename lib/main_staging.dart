// Staging entry. Run with:
//   flutter run --flavor staging --target lib/main_staging.dart
// or via the Makefile: `make staging`.

import 'package:datasolids_mobile/bootstrap.dart';
import 'package:datasolids_mobile/core/config/flavor.dart';

Future<void> main() async {
  await bootstrap(flavor: Flavor.staging);
}
