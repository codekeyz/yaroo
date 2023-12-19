import 'package:yaroorm/src/database/driver/driver.dart';

import 'migrator.dart';

Future<bool> migrationsTableReady(DatabaseDriver driver, {String migrationsTable = 'migrations'}) async {
  final hasTable = await driver.hasTable(migrationsTable);
  if (hasTable) return true;

  final script = Migrator.migrationsSchema.toScript(driver.blueprint);
  await driver.execute(script);
  return true;
}
