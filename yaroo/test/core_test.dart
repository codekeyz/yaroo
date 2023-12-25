import 'package:spookie/spookie.dart';
import 'package:yaroo/http/http.dart';
import 'package:yaroo/http/kernel.dart';
import 'package:yaroo/src/config/app.dart';
import 'package:yaroo/src/core.dart';

import 'core_test.reflectable.dart';

final appConfig = AppConfig(
    name: 'Test App',
    environment: 'production',
    isDebug: false,
    url: 'http://localhost',
    port: 3000,
    key: 'askdfjal;ksdjkajl;j');

class TestMiddleware extends Middleware {
  @override
  handle(Request req, Response res, NextFunction next) {}
}

class FoobarMiddleware extends Middleware {
  @override
  handle(Request req, Response res, NextFunction next) {}
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

class TestApp extends ApplicationFactory {
  TestApp(Kernel kernel) : super(kernel, appConfig);
}

void main() {
  initializeReflectable();

  group('Core', () {
    group('Kernel', () {
      setUpAll(() {
        TestApp(TestAppKernel([TestMiddleware]));
      });

      test('should resolve global middleware', () {
        final globalMiddleware = ApplicationFactory.globalMiddleware;
        expect(globalMiddleware, isA<HandlerFunc>());
      });

      test('should throw if type is not subtype of Middleware', () {
        final middlewares = ApplicationFactory.resolveMiddlewareForGroup('api');
        expect(middlewares, isA<Iterable<HandlerFunc>>());

        expect(middlewares.length, 1);

        expect(() => ApplicationFactory.resolveMiddlewareForGroup('web'), throwsA(isA<UnsupportedError>()));
      });
    });
  });
}
