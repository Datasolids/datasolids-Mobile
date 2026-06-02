// Development entry. Run with:
//   flutter run --flavor development --target lib/main_development.dart
// or via the Makefile: `make dev`.

import 'package:datasolids_mobile/bootstrap.dart';
import 'package:datasolids_mobile/core/config/flavor.dart';

Future<void> main() async {
  await bootstrap(flavor: Flavor.development);
}
