import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/kernel.dart';
import 'package:yaroo/yaroo.dart';

import 'core_test.reflectable.dart';

const appConfig = AppConfig(
  name: 'Test App',
  environment: 'production',
  isDebug: false,
  url: 'http://localhost',
  port: 3000,
  key: 'askdfjal;ksdjkajl;j',
);

class TestMiddleware extends Middleware {}

class FoobarMiddleware extends Middleware {
  @override
  HandlerFunc get handler => (req, res, next) => next();
}

class TestAppKernel extends Kernel {
  final List<Type> middlewares;

  TestAppKernel(this.middlewares);

  @override
  List<Type> get middleware => middlewares;

  @override
  Map<String, List<Type>> get middlewareGroups => {
        'api': [FoobarMiddleware],
        'web': [String]
      };
}

class TestKidsApp extends ApplicationFactory {
  final List<Type> serviceProvs;
  final AppConfig? config;

  TestKidsApp(
    Kernel kernel,
    this.serviceProvs, {
    this.config,
  }) : super(kernel, config ?? appConfig);

  @override
  List<Type> get providers => serviceProvs;
}

void main() {
  initializeReflectable();

  group('Core', () {
    final testApp = TestKidsApp(TestAppKernel([TestMiddleware]), []);

    group('Kernel', () {
      test('should resolve global middleware', () {
        expect(ApplicationFactory.globalMiddleware, isA<HandlerFunc>());
      });

      group('when middleware group', () {
        test('should resolve', () {
          final group = Route.middleware('api').group('Users', [
            Route.route(HTTPMethod.GET, '/', (req, res) => null),
          ]);

          expect(group.paths, ['[ALL]: /users', '[GET]: /users/']);
        });

        test('should error when not exist', () {
          expect(
            () => Route.middleware('foo').group('Users', [
              Route.route(HTTPMethod.GET, '/', (req, res) => null),
            ]),
            throwsA(
              isA<ArgumentError>().having((p0) => p0.message, 'message', 'Middleware group `foo` does not exist'),
            ),
          );
        });
      });

      test('should throw if type is not subtype of Middleware', () {
        final middlewares = ApplicationFactory.resolveMiddlewareForGroup('api');
        expect(middlewares, isA<Iterable<HandlerFunc>>());

        expect(middlewares.length, 1);

        expect(() => ApplicationFactory.resolveMiddlewareForGroup('web'), throwsA(isA<UnsupportedError>()));
      });
    });

    test('should return tester', () async {
      await testApp.bootstrap(listen: false);

      expect(await testApp.tester, isA<Spookie>());
    });
  });
}
