import 'package:test/test.dart';
import 'package:yaroorm/yaroorm.dart';

import 'fixtures/migrator.dart';
import 'fixtures/test_data.dart';

void runBasicE2ETest(String connectionName) {
  final driver = DB.driver(connectionName);

  return group('with ${driver.type.name} driver', () {
    test('driver should connect', () async {
      await driver.connect();

      expect(driver.isOpen, isTrue);
    });

    test('should have no tables', () async => expect(await driver.hasTable('users'), isFalse));

    test('should execute migration', () async {
      await runMigrator(connectionName, 'migrate');

      expect(await driver.hasTable('users'), isTrue);
    });

    test('should insert single user', () async {
      final result = await usersTestData.first.withDriver(driver).save();
      expect(result, isA<User>().having((p0) => p0.id, 'has primary key', 1));

      expect(await Query.table<User>().driver(driver).all(), hasLength(1));
    });

    test('should insert many users', () async {
      final remainingUsers = usersTestData.sublist(1).map((e) => e.to_db_data).toList();
      final userQuery = Query.table<User>().driver(driver);
      await userQuery.insertMany(remainingUsers);

      expect(await userQuery.all(), hasLength(usersTestData.length));
    });

    test('should update user', () async {
      final userQuery = Query.table<User>().driver(driver);

      final user = await userQuery.get();
      expect(user!.id!, 1);

      user
        ..firstname = 'Red Oil'
        ..age = 100;
      await user.save();

      final userFromDB = await userQuery.get(user.id!);
      expect(user, isNotNull);
      expect(userFromDB?.firstname, 'Red Oil');
      expect(userFromDB?.age, 100);
    });

    test('should update many users', () async {
      final userQuery = Query.table<User>().driver(driver);

      final age50Users = userQuery.whereEqual('age', 50);
      final usersWithAge50 = await age50Users.findMany();
      expect(usersWithAge50.length, 4);
      expect(usersWithAge50.every((e) => e.age == 50), isTrue);

      await userQuery
          .update(where: (query) => query.whereEqual('age', 50), values: {'home_address': 'Keta, Ghana'}).execute();

      final updatedResult = await age50Users.findMany();
      expect(updatedResult.length, 4);
      expect(updatedResult.every((e) => e.age == 50), isTrue);
      expect(updatedResult.every((e) => e.homeAddress == 'Keta, Ghana'), isTrue);
    });

    test('should fetch only users in Ghana', () async {
      final userQuery = Query.table<User>().driver(driver);

      final query = userQuery.whereLike('home_address', '%, Ghana').orderByDesc('age');
      final usersInGhana = await query.findMany();
      expect(usersInGhana.length, 10);
      expect(usersInGhana.every((e) => e.homeAddress.contains('Ghana')), isTrue);

      expect(await query.take(4), hasLength(4));
    });

    test('should get all users between age 35 and 50', () async {
      final userQuery = Query.table<User>().driver(driver);

      final age50Users = await userQuery.whereBetween('age', [35, 50]).orderByDesc('age').findMany();
      expect(age50Users.length, 19);
      expect(age50Users.first.age, 50);
      expect(age50Users.last.age, 35);
    });

    test('should get all users in somewhere in Nigeria', () async {
      final userQuery = Query.table<User>().driver(driver);

      final users = await userQuery.whereLike('home_address', '%, Nigeria').orderByAsc('home_address').findMany();

      expect(users.length, 18);
      expect(users.first.homeAddress, 'Abuja, Nigeria');
      expect(users.last.homeAddress, 'Owerri, Nigeria');
    });

    test('should get all users where age is 30 or 52', () async {
      final userQuery = Query.table<User>().driver(driver);

      final users = await userQuery.whereEqual('age', 30).orWhere('age', '=', 52).findMany();
      expect(users.every((e) => [30, 52].contains(e.age)), isTrue);
    });

    test('should delete user', () async {
      final userQuery = Query.table<User>().driver(driver);

      final userOne = await userQuery.get();
      expect(userOne, isNotNull);

      await userOne!.delete();

      final usersAfterDelete = await userQuery.all();
      expect(usersAfterDelete.any((e) => e.id == userOne.id), isFalse);
    });

    test('should delete many users', () async {
      final userQuery = Query.table<User>().driver(driver);

      final query = userQuery.whereLike('home_address', '%, Nigeria');
      expect(await query.findMany(), isNotEmpty);

      await query.delete();

      expect(await query.findMany(), isEmpty);
    });

    test('should drop tables', () async {
      await runMigrator(connectionName, 'migrate:reset');

      expect(await driver.hasTable('users'), isFalse);
    });

    test('should disconnect', () async {
      expect(driver.isOpen, isTrue);

      await driver.disconnect();

      expect(driver.isOpen, isFalse);
    });
  });
}