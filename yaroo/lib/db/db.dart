import 'package:collection/collection.dart';
import 'package:yaroo/src/_config/config.dart';
import 'package:yaroorm/yaroorm.dart';

export 'package:yaroorm/src/database/entity.dart';

class UseDatabaseConnection {
  final String name;
  late final DatabaseDriver _driver;

  UseDatabaseConnection(this.name) : _driver = DB.driver(name);

  Query query(String table) => Query.query(table, _driver);
}

class DB {
  static final List<DatabaseConnection> _connections = [];
  static final Map<String, DatabaseDriver> _driverInstances = {};

  static late final UseDatabaseConnection defaultConnection;
  static late final List<Migration> migrations;
  static final String _defaultDatabaseValue = 'default';

  DB._();

  static DatabaseDriver get defaultDriver => defaultConnection._driver;

  static Query query(String table) => defaultConnection.query(table);

  static UseDatabaseConnection connection(String connName) => UseDatabaseConnection(connName);

  static DatabaseDriver driver(String connName) {
    if (connName == _defaultDatabaseValue) return defaultDriver;
    final cached = _driverInstances[connName];
    if (cached != null) return cached;
    final connInfo = _connections.firstWhereOrNull((e) => e.name == connName);
    if (connInfo == null) {
      throw Exception('No Database connection found with name: $connName');
    }
    return _driverInstances[connName] = DatabaseDriver.init(connInfo);
  }

  static void init(ConfigResolver dbConfig) {
    final configuration = dbConfig.call();
    final defaultConn = configuration.getValue<String>(_defaultDatabaseValue);
    if (defaultConn == null) {
      throw ArgumentError.notNull('Default database connection');
    }
    final connInfos = configuration.getValue<Map<String, dynamic>>('connections');
    if (connInfos == null || connInfos.isEmpty) {
      throw ArgumentError('Database connection infos not provided');
    }
    final connections = connInfos.entries.map((e) => DatabaseConnection.from(e.key, e.value));
    final defaultConnection = connections.firstWhereOrNull((e) => e.name == defaultConn);
    if (defaultConnection == null) {
      throw ArgumentError('Database connection info not found for $defaultConn');
    }

    DB._connections
      ..clear()
      ..addAll(connections);

    DB.defaultConnection = UseDatabaseConnection(defaultConn);
    DB._driverInstances[defaultConn] = DatabaseDriver.init(defaultConnection);
  }
}
