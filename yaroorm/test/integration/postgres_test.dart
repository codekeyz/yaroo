@Tags(['integration'])
import 'package:test/test.dart';
import 'package:yaroorm/src/database/driver/driver.dart';

import '../unit/helpers/drivers.dart';
import 'base/integration_base.dart';

final driver = DatabaseDriver.init(postGresConnection);

void main() {
  group('PostGres SQL', () {
    test('driver should connect', () async {
      await driver.connect(secure: false);

      expect(driver.isOpen, isTrue);
    });

    runIntegrationTest(driver);
  });
}
