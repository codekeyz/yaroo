import 'package:cli_completion/cli_completion.dart';
import 'package:yaroo_cli/orm/commands/migrate_fresh_command.dart';
import 'package:yaroo_cli/src/utils.dart';
import 'package:yaroorm/yaroorm.dart';

import '../src/logger.dart';
import 'commands/command.dart';
import 'commands/migrate_command.dart';
import 'commands/migrate_reset_command.dart';
import 'commands/migrate_rollback_command.dart';

class MigrationData extends Entity<int, MigrationData> {
  final String migration;
  final int batch;

  MigrationData(this.migration, this.batch);
}

const executableName = 'yaroo orm';
const packageName = 'yaroo_cli';
const description = 'yaroorm command-line tool';

class OrmCLIRunner extends CompletionCommandRunner<int> {
  static Future<void> start(List<String> args, YaroormConfig config) async {
    return flushThenExit(await OrmCLIRunner._(config).run(args) ?? 0);
  }

  OrmCLIRunner._(YaroormConfig config) : super(executableName, description) {
    argParser.addOption(
      OrmCommand.connectionArg,
      abbr: 'c',
      help: 'specify database connection',
    );

    DB.init(config);

    addCommand(MigrateCommand());
    addCommand(MigrateFreshCommand());
    addCommand(MigrationRollbackCommand());
    addCommand(MigrationResetCommand());
  }

  @override
  void printUsage() => logger.info(usage);
}
