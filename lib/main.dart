// Production entry. Build with:
//   flutter run --release \
//     --dart-define=FLAVOR=production \
//     --dart-define=API_BASE_URL=https://api.datasolids.com

import 'bootstrap.dart';
import 'core/config/flavor.dart';

Future<void> main() async {
  await bootstrap(flavor: Flavor.production);
}
