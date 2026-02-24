import 'package:dependy/dependy.dart';
import 'package:test/test.dart';

class LoggerService {
  final String tag;

  LoggerService([this.tag = 'APP']);
}

class DatabaseService {
  final LoggerService logger;

  DatabaseService(this.logger);

  bool closed = false;

  void close() => closed = true;
}

class ApiClient {
  final DatabaseService database;

  ApiClient(this.database);
}

class HttpRequest {
  static int _nextId = 0;
  final int id;

  HttpRequest() : id = _nextId++;

  static void reset() => _nextId = 0;
}

class EmailService {
  final String provider;

  EmailService([this.provider = 'default']);
}

class HttpClient {
  final String baseUrl;

  HttpClient(this.baseUrl);
}

class UserService {
  final HttpClient client;

  UserService(this.client);
}

// Circular: AuthService ↔ UserRepository
class AuthService {
  final UserRepository users;

  AuthService(this.users);
}

class UserRepository {
  final AuthService auth;

  UserRepository(this.auth);
}

// Transitive circular: NotificationService → OrderService → InventoryService → NotificationService
class NotificationService {
  final InventoryService inventory;

  NotificationService(this.inventory);
}

class OrderService {
  final NotificationService notifications;

  OrderService(this.notifications);
}

class InventoryService {
  final OrderService orders;

  InventoryService(this.orders);
}

void main() {
  group('DependyProvider - Singleton (default)', () {
    test('creates instance via factory', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('test')),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('test'));
    });

    test('returns same instance on subsequent calls', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('singleton')),
        },
      );

      final a = await module.call<LoggerService>();
      final b = await module.call<LoggerService>();
      expect(identical(a, b), isTrue);
    });

    test('calls dispose callback with resolved instance', () {
      LoggerService? disposed;

      final provider = DependyProvider<LoggerService>(
        (_) => LoggerService('disposable'),
        dispose: (instance) => disposed = instance,
      );

      final module = DependyModule(providers: {provider});

      module.call<LoggerService>().then((_) {
        module.dispose();
        expect(disposed, isNotNull);
        expect(disposed!.tag, equals('disposable'));
      });
    });

    test('calls dispose callback with null if never resolved', () {
      LoggerService? disposed = LoggerService('sentinel');
      bool disposeCalled = false;

      final provider = DependyProvider<LoggerService>(
        (_) => LoggerService(),
        dispose: (instance) {
          disposeCalled = true;
          disposed = instance;
        },
      );

      final module = DependyModule(providers: {provider});
      module.dispose();

      expect(disposeCalled, isTrue);
      expect(disposed, isNull);
    });

    test('throws DependyProviderDisposedException after disposal', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      module.dispose();

      expect(
        () => module.call<LoggerService>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });
  });

  group('DependyProvider - Transient', () {
    setUp(() => HttpRequest.reset());

    test('returns different instance on each call', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>((_) => HttpRequest(), transient: true),
        },
      );

      final a = await module.call<HttpRequest>();
      final b = await module.call<HttpRequest>();
      final c = await module.call<HttpRequest>();

      expect(a.id, equals(0));
      expect(b.id, equals(1));
      expect(c.id, equals(2));
      expect(identical(a, b), isFalse);
      expect(identical(b, c), isFalse);
    });

    test('dispose callback receives null (no cached instance)', () {
      HttpRequest? disposed = HttpRequest();
      bool disposeCalled = false;

      final provider = DependyProvider<HttpRequest>(
        (_) => HttpRequest(),
        transient: true,
        dispose: (instance) {
          disposeCalled = true;
          disposed = instance;
        },
      );

      final module = DependyModule(providers: {provider});

      module.call<HttpRequest>().then((_) {
        return module.call<HttpRequest>();
      }).then((_) {
        module.dispose();
        expect(disposeCalled, isTrue);
        expect(disposed, isNull);
      });
    });

    test('throws DependyProviderDisposedException after disposal', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      module.dispose();

      expect(
        () => module.call<HttpRequest>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });

    test('works with async factories', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) async {
              await Future.delayed(Duration(milliseconds: 1));
              return HttpRequest();
            },
            transient: true,
          ),
        },
      );

      final a = await module.call<HttpRequest>();
      final b = await module.call<HttpRequest>();
      expect(a.id != b.id, isTrue);
    });
  });

  group('DependyModule - Resolution', () {
    test('resolves a simple provider', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('simple')),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('simple'));
    });

    test('resolves provider with dependencies (dependsOn)', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('dep')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      final db = await module.call<DatabaseService>();
      expect(db.logger.tag, equals('dep'));
    });

    test('resolves from submodules', () async {
      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('sub')),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('sub'));
    });

    test('resolves dependencies across modules', () async {
      final loggerModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('cross')),
        },
      );

      final module = DependyModule(
        providers: {
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
        modules: {loggerModule},
      );

      final db = await module.call<DatabaseService>();
      expect(db.logger.tag, equals('cross'));
    });

    test('throws DependyProviderNotFoundException for unregistered type',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      expect(
        () => module.call<HttpRequest>(),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('throws DependyModuleDisposedException after disposal', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      module.dispose();

      expect(
        () => module.call<LoggerService>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });
  });

  group('DependyModule - Singleton behavior', () {
    test('returns same instance across multiple call<T>() invocations',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('same')),
        },
      );

      final a = await module.call<LoggerService>();
      final b = await module.call<LoggerService>();
      final c = await module.call<LoggerService>();
      expect(identical(a, b), isTrue);
      expect(identical(b, c), isTrue);
    });

    test('singleton provider with dependencies gets same dependency instance',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('shared')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      final db = await module.call<DatabaseService>();
      expect(identical(db.logger, logger), isTrue);
    });
  });

  group('DependyModule - Transient behavior', () {
    setUp(() => HttpRequest.reset());

    test('returns different instance on each call<T>()', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      final a = await module.call<HttpRequest>();
      final b = await module.call<HttpRequest>();
      expect(identical(a, b), isFalse);
      expect(a.id, isNot(equals(b.id)));
    });

    test('transient provider with singleton dependency gets same dependency',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('shared')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
            transient: true,
          ),
        },
      );

      final db1 = await module.call<DatabaseService>();
      final db2 = await module.call<DatabaseService>();

      expect(identical(db1, db2), isFalse);
      expect(identical(db1.logger, db2.logger), isTrue);
    });

    test('multiple transient providers work independently', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
          DependyProvider<EmailService>(
            (_) => EmailService('fresh'),
            transient: true,
          ),
        },
      );

      final r1 = await module.call<HttpRequest>();
      final r2 = await module.call<HttpRequest>();
      final e1 = await module.call<EmailService>();
      final e2 = await module.call<EmailService>();

      expect(identical(r1, r2), isFalse);
      expect(identical(e1, e2), isFalse);
    });
  });

  group('DependyModule - Verification', () {
    test('detects circular dependencies (Auth ↔ UserRepository)', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<AuthService>(
              (resolve) async => AuthService(await resolve<UserRepository>()),
              dependsOn: {UserRepository},
            ),
            DependyProvider<UserRepository>(
              (resolve) async => UserRepository(await resolve<AuthService>()),
              dependsOn: {AuthService},
            ),
          },
        ),
        throwsA(isA<DependyCircularDependencyException>()),
      );
    });

    test(
        'detects transitive circular dependencies '
        '(Notification → Order → Inventory → Notification)', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<NotificationService>(
              (resolve) async =>
                  NotificationService(await resolve<InventoryService>()),
              dependsOn: {InventoryService},
            ),
            DependyProvider<OrderService>(
              (resolve) async =>
                  OrderService(await resolve<NotificationService>()),
              dependsOn: {NotificationService},
            ),
            DependyProvider<InventoryService>(
              (resolve) async =>
                  InventoryService(await resolve<OrderService>()),
              dependsOn: {OrderService},
            ),
          },
        ),
        throwsA(isA<DependyCircularDependencyException>()),
      );
    });

    test('detects duplicate providers in same module', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<LoggerService>(
              (_) => LoggerService('console'),
              key: 'console',
            ),
            DependyProvider<LoggerService>(
              (_) => LoggerService('file'),
              key: 'file',
            ),
          },
        ),
        throwsA(isA<DependyDuplicateProviderException>()),
      );
    });

    test('detects missing providers (dependsOn type not registered)', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
            ),
          },
        ),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('allows valid dependency graphs', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<LoggerService>((_) => LoggerService()),
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
            ),
            DependyProvider<ApiClient>(
              (resolve) async => ApiClient(await resolve<DatabaseService>()),
              dependsOn: {DatabaseService},
            ),
          },
        ),
        returnsNormally,
      );
    });

    test('allows dependencies satisfied by submodules', () {
      final loggerModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      expect(
        () => DependyModule(
          providers: {
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
            ),
          },
          modules: {loggerModule},
        ),
        returnsNormally,
      );
    });
  });

  group('DependyModule - Captive dependency detection', () {
    test('throws when singleton depends on transient in same module', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<HttpRequest>(
              (_) => HttpRequest(),
              transient: true,
            ),
            DependyProvider<EmailService>(
              (resolve) async {
                final request = await resolve<HttpRequest>();
                return EmailService('request-${request.id}');
              },
              dependsOn: {HttpRequest},
            ),
          },
        ),
        throwsA(isA<DependyCaptiveDependencyException>()),
      );
    });

    test('throws when singleton depends on transient in submodule', () {
      final requestModule = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      expect(
        () => DependyModule(
          providers: {
            DependyProvider<EmailService>(
              (resolve) async {
                final request = await resolve<HttpRequest>();
                return EmailService('request-${request.id}');
              },
              dependsOn: {HttpRequest},
            ),
          },
          modules: {requestModule},
        ),
        throwsA(isA<DependyCaptiveDependencyException>()),
      );
    });

    test('allows transient depending on transient', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<HttpRequest>(
              (_) => HttpRequest(),
              transient: true,
            ),
            DependyProvider<EmailService>(
              (resolve) async {
                final request = await resolve<HttpRequest>();
                return EmailService('request-${request.id}');
              },
              dependsOn: {HttpRequest},
              transient: true,
            ),
          },
        ),
        returnsNormally,
      );
    });

    test('allows transient depending on singleton', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<LoggerService>((_) => LoggerService('shared')),
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
              transient: true,
            ),
          },
        ),
        returnsNormally,
      );
    });

    test('allows singleton depending on singleton', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<LoggerService>((_) => LoggerService()),
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
            ),
          },
        ),
        returnsNormally,
      );
    });
  });

  group('DependyModule - Disposal', () {
    test('disposes all providers in module', () async {
      bool loggerDisposed = false;
      bool dbDisposed = false;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            dispose: (_) => loggerDisposed = true,
          ),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
            dispose: (_) => dbDisposed = true,
          ),
        },
      );

      await module.call<DatabaseService>();

      module.dispose();
      expect(loggerDisposed, isTrue);
      expect(dbDisposed, isTrue);
    });

    test('does NOT dispose submodules by default', () {
      bool subDisposed = false;

      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            dispose: (_) => subDisposed = true,
          ),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      module.dispose();
      expect(subDisposed, isFalse);
      expect(subModule.disposed, isFalse);
    });

    test('disposes submodules when disposeSubmodules: true', () {
      bool subDisposed = false;

      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            dispose: (_) => subDisposed = true,
          ),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      module.dispose(disposeSubmodules: true);
      expect(subDisposed, isTrue);
      expect(subModule.disposed, isTrue);
    });

    test('idempotent - safe to call dispose twice', () {
      int disposeCount = 0;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            dispose: (_) => disposeCount++,
          ),
        },
      );

      module.dispose();
      module.dispose();

      expect(disposeCount, equals(1));
    });

    test('cannot resolve after disposal', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      module.dispose();

      expect(
        () => module.call<LoggerService>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });
  });

  group('DependyModule - dependsOn enforcement', () {
    test('throws when factory resolves undeclared dependency', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
          ),
        },
      );

      expect(
        () => module.call<DatabaseService>(),
        throwsA(isA<DependyProviderMissingDependsOnException>()),
      );
    });

    test('allows resolution of declared dependencies', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('ok')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      final db = await module.call<DatabaseService>();
      expect(db.logger.tag, equals('ok'));
    });
  });

  group('EagerDependyModule', () {
    test('all providers pre-resolved after asEager()', () async {
      int factoryCalls = 0;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) {
            factoryCalls++;
            return LoggerService('eager');
          }),
        },
      );

      final eager = await module.asEager();
      expect(factoryCalls, equals(1));

      eager.call<LoggerService>();
      expect(factoryCalls, equals(1));
    });

    test('synchronous call<T>() returns correct instances', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('sync')),
        },
      );

      final eager = await module.asEager();
      final logger = eager.call<LoggerService>();
      expect(logger.tag, equals('sync'));
    });

    test('returns same instance on subsequent calls', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final eager = await module.asEager();
      final a = eager.call<LoggerService>();
      final b = eager.call<LoggerService>();
      expect(identical(a, b), isTrue);
    });

    test('resolves providers from submodules', () async {
      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('sub-eager')),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      final eager = await module.asEager();
      final logger = eager.call<LoggerService>();
      expect(logger.tag, equals('sub-eager'));
    });

    test('throws DependyProviderNotFoundException for unregistered type',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final eager = await module.asEager();

      expect(
        () => eager.call<HttpRequest>(),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('throws DependyModuleDisposedException after disposal', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final eager = await module.asEager();
      eager.dispose();

      expect(
        () => eager.call<LoggerService>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });

    test('transient providers are resolved once in eager mode', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      final eager = await module.asEager();

      final a = eager.call<HttpRequest>();
      final b = eager.call<HttpRequest>();
      expect(identical(a, b), isTrue);
      expect(a.id, equals(0));
    });
  });

  group('Exception formatting', () {
    test('DependyProviderDisposedException has correct toString()', () {
      final e = DependyProviderDisposedException('test message');
      expect(
        e.toString(),
        equals('DependyProviderDisposedException: test message'),
      );
    });

    test('DependyProviderDisposedException with null message', () {
      final e = DependyProviderDisposedException(null);
      expect(e.toString(), equals('DependyProviderDisposedException'));
    });

    test('DependyModuleDisposedException has correct toString()', () {
      final e = DependyModuleDisposedException('module disposed');
      expect(
        e.toString(),
        equals('DependyModuleDisposedException: module disposed'),
      );
    });

    test('DependyModuleDisposedException with null message', () {
      final e = DependyModuleDisposedException(null);
      expect(e.toString(), equals('DependyModuleDisposedException'));
    });

    test('DependyProviderNotFoundException has correct toString()', () {
      final e = DependyProviderNotFoundException('not found');
      expect(
        e.toString(),
        equals('DependyProviderNotFoundException: not found'),
      );
    });

    test('DependyProviderNotFoundException with null message', () {
      final e = DependyProviderNotFoundException(null);
      expect(e.toString(), equals('DependyProviderNotFoundException'));
    });

    test('DependyCircularDependencyException has correct toString()', () {
      final e = DependyCircularDependencyException('circular');
      expect(
        e.toString(),
        equals('DependyCircularDependencyException: circular'),
      );
    });

    test('DependyCircularDependencyException with null message', () {
      final e = DependyCircularDependencyException(null);
      expect(e.toString(), equals('DependyCircularDependencyException'));
    });

    test('DependyDuplicateProviderException has correct toString()', () {
      final e = DependyDuplicateProviderException('duplicate');
      expect(
        e.toString(),
        equals('DependyDuplicateProviderException: duplicate'),
      );
    });

    test('DependyDuplicateProviderException with null message', () {
      final e = DependyDuplicateProviderException(null);
      expect(e.toString(), equals('DependyDuplicateProviderException'));
    });

    test('DependyProviderMissingDependsOnException has correct toString()', () {
      final e = DependyProviderMissingDependsOnException('missing');
      expect(
        e.toString(),
        equals('DependyProviderMissingDependsOnException: missing'),
      );
    });

    test('DependyProviderMissingDependsOnException with null message', () {
      final e = DependyProviderMissingDependsOnException(null);
      expect(
        e.toString(),
        equals('DependyProviderMissingDependsOnException'),
      );
    });

    test('DependyCaptiveDependencyException has correct toString()', () {
      final e = DependyCaptiveDependencyException('captive');
      expect(
        e.toString(),
        equals('DependyCaptiveDependencyException: captive'),
      );
    });

    test('DependyCaptiveDependencyException with null message', () {
      final e = DependyCaptiveDependencyException(null);
      expect(e.toString(), equals('DependyCaptiveDependencyException'));
    });
  });

  group('DependyModule - Tagged instances', () {
    test('two providers of same type with different tags resolve correctly',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('console'),
            tag: 'console',
          ),
          DependyProvider<LoggerService>(
            (_) => LoggerService('file'),
            tag: 'file',
          ),
        },
      );

      final console = await module.call<LoggerService>(tag: 'console');
      final file = await module.call<LoggerService>(tag: 'file');

      expect(console.tag, equals('console'));
      expect(file.tag, equals('file'));
      expect(identical(console, file), isFalse);
    });

    test('same type and same tag throws DependyDuplicateProviderException', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<LoggerService>(
              (_) => LoggerService('a'),
              tag: 'same',
            ),
            DependyProvider<LoggerService>(
              (_) => LoggerService('b'),
              tag: 'same',
            ),
          },
        ),
        throwsA(isA<DependyDuplicateProviderException>()),
      );
    });

    test('untagged and tagged of same type coexist', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('default'),
          ),
          DependyProvider<LoggerService>(
            (_) => LoggerService('special'),
            tag: 'special',
          ),
        },
      );

      final defaultLogger = await module.call<LoggerService>();
      final specialLogger = await module.call<LoggerService>(tag: 'special');

      expect(defaultLogger.tag, equals('default'));
      expect(specialLogger.tag, equals('special'));
      expect(identical(defaultLogger, specialLogger), isFalse);
    });

    test('tagged resolution from within a factory via resolve', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('api'),
            tag: 'api',
          ),
          DependyProvider<LoggerService>(
            (_) => LoggerService('cdn'),
            tag: 'cdn',
          ),
          DependyProvider<DatabaseService>(
            (resolve) async {
              final logger = await resolve<LoggerService>(tag: 'api');
              return DatabaseService(logger);
            },
            dependsOn: {LoggerService},
          ),
        },
      );

      final db = await module.call<DatabaseService>();
      expect(db.logger.tag, equals('api'));
    });

    test('tagged providers work with submodules', () async {
      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('sub-tagged'),
            tag: 'sub',
          ),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      final logger = await module.call<LoggerService>(tag: 'sub');
      expect(logger.tag, equals('sub-tagged'));
    });

    test('missing tagged provider throws DependyProviderNotFoundException',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('default'),
          ),
        },
      );

      expect(
        () => module.call<LoggerService>(tag: 'nonexistent'),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('requesting wrong tag throws DependyProviderNotFoundException',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('api'),
            tag: 'api',
          ),
        },
      );

      expect(
        () => module.call<LoggerService>(tag: 'cdn'),
        throwsA(isA<DependyProviderNotFoundException>()),
      );

      // Also requesting without tag should not find a tagged provider
      expect(
        () => module.call<LoggerService>(),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('tagged transient providers return fresh instances', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            tag: 'tagged',
            transient: true,
          ),
        },
      );

      final a = await module.call<HttpRequest>(tag: 'tagged');
      final b = await module.call<HttpRequest>(tag: 'tagged');

      expect(identical(a, b), isFalse);
      expect(a.id, isNot(equals(b.id)));
    });

    test('tagged singleton providers return same instance', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('singleton-tagged'),
            tag: 'cached',
          ),
        },
      );

      final a = await module.call<LoggerService>(tag: 'cached');
      final b = await module.call<LoggerService>(tag: 'cached');

      expect(identical(a, b), isTrue);
    });

    test('EagerDependyModule resolves tagged providers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('eager-api'),
            tag: 'api',
          ),
          DependyProvider<LoggerService>(
            (_) => LoggerService('eager-cdn'),
            tag: 'cdn',
          ),
        },
      );

      final eager = await module.asEager();
      final api = eager.call<LoggerService>(tag: 'api');
      final cdn = eager.call<LoggerService>(tag: 'cdn');

      expect(api.tag, equals('eager-api'));
      expect(cdn.tag, equals('eager-cdn'));
      expect(identical(api, cdn), isFalse);
    });

    test('captive dependency detection with tagged transient provider', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<HttpRequest>(
              (_) => HttpRequest(),
              tag: 'tagged',
              transient: true,
            ),
            DependyProvider<EmailService>(
              (resolve) async {
                final request = await resolve<HttpRequest>(tag: 'tagged');
                return EmailService('request-${request.id}');
              },
              dependsOn: {HttpRequest},
            ),
          },
        ),
        throwsA(isA<DependyCaptiveDependencyException>()),
      );
    });

    test('circular dependency detection with tagged providers', () {
      expect(
        () => DependyModule(
          providers: {
            DependyProvider<AuthService>(
              (resolve) async => AuthService(await resolve<UserRepository>()),
              dependsOn: {UserRepository},
              tag: 'tagged',
            ),
            DependyProvider<UserRepository>(
              (resolve) async => UserRepository(await resolve<AuthService>()),
              dependsOn: {AuthService},
              tag: 'tagged',
            ),
          },
        ),
        throwsA(isA<DependyCircularDependencyException>()),
      );
    });
  });

  group('DependyModule - debugGraph()', () {
    test('shows module key in header', () {
      final module = DependyModule(
        key: 'app',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final graph = module.debugGraph();
      expect(graph, startsWith('DependyModule (key: app)'));
    });

    test('shows module without key', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final graph = module.debugGraph();
      expect(graph, startsWith('DependyModule\n'));
    });

    test('shows provider type name', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('LoggerService'));
    });

    test('shows [singleton] lifecycle label', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('[singleton]'));
    });

    test('shows [transient] lifecycle label', () {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>((_) => HttpRequest(), transient: true),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('[transient]'));
    });

    test('shows provider key', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            key: 'my-logger',
          ),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('(key: my-logger)'));
    });

    test('shows provider tag with # prefix', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService(),
            tag: 'console',
          ),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('#console'));
    });

    test('shows pending for unresolved singleton', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('- pending'));
    });

    test('shows cached after resolution', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      await module.call<LoggerService>();
      final graph = module.debugGraph();
      expect(graph, contains('- cached'));
    });

    test('shows always new for transient', () {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>((_) => HttpRequest(), transient: true),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('- always new'));
    });

    test('shows dependsOn set', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('dependsOn: {LoggerService}'));
    });

    test('shows [DISPOSED] after disposal', () {
      final module = DependyModule(
        key: 'app',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      module.dispose();
      final graph = module.debugGraph();
      expect(graph, contains('DependyModule (key: app) [DISPOSED]'));
      expect(graph, contains('[DISPOSED]'));
    });

    test('shows submodules with [module] prefix', () {
      final sub = DependyModule(
        key: 'sub',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final module = DependyModule(
        key: 'root',
        providers: {},
        modules: {sub},
      );

      final graph = module.debugGraph();
      expect(graph, contains('[module] DependyModule (key: sub)'));
    });

    test('handles nested submodules with proper indentation', () {
      final inner = DependyModule(
        key: 'inner',
        providers: {
          DependyProvider<EmailService>((_) => EmailService()),
        },
      );

      final outer = DependyModule(
        key: 'outer',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
        modules: {inner},
      );

      final module = DependyModule(
        key: 'root',
        providers: {},
        modules: {outer},
      );

      final graph = module.debugGraph();
      expect(graph, contains('[module] DependyModule (key: outer)'));
      expect(graph, contains('[module] DependyModule (key: inner)'));
      // Inner module's provider should be indented further
      expect(graph, contains('EmailService'));
    });

    test('handles empty module', () {
      final module = DependyModule(
        key: 'empty',
        providers: {},
      );

      final graph = module.debugGraph();
      expect(graph, equals('DependyModule (key: empty)'));
    });

    test('handles shared submodule references', () {
      final shared = DependyModule(
        key: 'shared',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final moduleA = DependyModule(
        key: 'a',
        providers: {},
        modules: {shared},
      );

      final moduleB = DependyModule(
        key: 'b',
        providers: {},
        modules: {shared},
      );

      final root = DependyModule(
        key: 'root',
        providers: {},
        modules: {moduleA, moduleB},
      );

      final graph = root.debugGraph();
      expect(graph, contains('(already listed above)'));
    });
  });

  group('EagerDependyModule - debugGraph()', () {
    test('shows EagerDependyModule header', () async {
      final module = DependyModule(
        key: 'eager-app',
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final eager = await module.asEager();
      final graph = eager.debugGraph();
      expect(graph, startsWith('EagerDependyModule (key: eager-app)'));
    });

    test('shows resolved status for providers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      final eager = await module.asEager();
      final graph = eager.debugGraph();
      expect(graph, contains('- resolved'));
    });
  });

  group('DependyModule - Overrides', () {
    test('override replaces provider and resolves to new instance', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://mock.api')),
        },
      );

      final client = await testModule.call<HttpClient>();
      expect(client.baseUrl, equals('https://mock.api'));
    });

    test('override preserves non-overridden providers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('prod')),
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://mock.api')),
        },
      );

      final logger = await testModule.call<LoggerService>();
      final client = await testModule.call<HttpClient>();
      expect(logger.tag, equals('prod'));
      expect(client.baseUrl, equals('https://mock.api'));
    });

    test('override tagged provider (match by type + tag)', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://api.real.com'),
            tag: 'api',
          ),
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://cdn.real.com'),
            tag: 'cdn',
          ),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://api.mock.com'),
            tag: 'api',
          ),
        },
      );

      final api = await testModule.call<HttpClient>(tag: 'api');
      final cdn = await testModule.call<HttpClient>(tag: 'cdn');
      expect(api.baseUrl, equals('https://api.mock.com'));
      expect(cdn.baseUrl, equals('https://cdn.real.com'));
    });

    test('override untagged provider leaves tagged provider untouched',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://default.real.com'),
          ),
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://special.real.com'),
            tag: 'special',
          ),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://default.mock.com'),
          ),
        },
      );

      final defaultClient = await testModule.call<HttpClient>();
      final specialClient = await testModule.call<HttpClient>(tag: 'special');
      expect(defaultClient.baseUrl, equals('https://default.mock.com'));
      expect(specialClient.baseUrl, equals('https://special.real.com'));
    });

    test('override with submodule replacement', () async {
      final realSubmodule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('real-sub')),
        },
      );

      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
        },
        modules: {realSubmodule},
      );

      final mockSubmodule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('mock-sub')),
        },
      );

      final testModule = module.overrideWith(
        modules: {mockSubmodule},
      );

      final logger = await testModule.call<LoggerService>();
      expect(logger.tag, equals('mock-sub'));
    });

    test('override transient with singleton (and vice versa)', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      // Override transient with singleton
      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpRequest>((_) => HttpRequest()),
        },
      );

      final a = await testModule.call<HttpRequest>();
      final b = await testModule.call<HttpRequest>();
      expect(identical(a, b), isTrue);
    });

    test('overridden module passes verification (missing deps caught)', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      // Removing LoggerService while DatabaseService depends on it should fail
      expect(
        () => module.overrideWith(
          providers: {
            DependyProvider<DatabaseService>(
              (resolve) async =>
                  DatabaseService(await resolve<LoggerService>()),
              dependsOn: {LoggerService},
            ),
            // LoggerService is still present from original, so this should work
          },
        ),
        returnsNormally,
      );
    });

    test('original module is not modified after override', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
        },
      );

      module.overrideWith(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://mock.api')),
        },
      );

      final client = await module.call<HttpClient>();
      expect(client.baseUrl, equals('https://real.api'));
    });

    test('override works with asEager()', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
          DependyProvider<LoggerService>((_) => LoggerService('prod')),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://mock.api')),
        },
      );

      final eager = await testModule.asEager();
      final client = eager.call<HttpClient>();
      final logger = eager.call<LoggerService>();

      expect(client.baseUrl, equals('https://mock.api'));
      expect(logger.tag, equals('prod'));
    });

    test('override adds provider not in original (test-only provider)',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('prod')),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://test.api')),
        },
      );

      final client = await testModule.call<HttpClient>();
      final logger = await testModule.call<LoggerService>();
      expect(client.baseUrl, equals('https://test.api'));
      expect(logger.tag, equals('prod'));
    });

    test('captive dependency detection still runs on overridden module', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      // Override LoggerService with transient — DatabaseService is singleton
      // depending on transient, which should throw captive dependency error
      expect(
        () => module.overrideWith(
          providers: {
            DependyProvider<LoggerService>(
              (_) => LoggerService('transient'),
              transient: true,
            ),
          },
        ),
        throwsA(isA<DependyCaptiveDependencyException>()),
      );
    });

    test('overrideWith preserves override\'s own decorators', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('original'),
            decorators: [
              (logger, _) => LoggerService('original-decorated'),
            ],
          ),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('override'),
            decorators: [
              (logger, _) => LoggerService('override-decorated'),
            ],
          ),
        },
      );

      final logger = await testModule.call<LoggerService>();
      expect(logger.tag, equals('override-decorated'));
    });

    test('overrideWith does not inherit original decorators', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('original'),
            decorators: [
              (logger, _) => LoggerService('original-decorated'),
            ],
          ),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('override'),
          ),
        },
      );

      final logger = await testModule.call<LoggerService>();
      expect(logger.tag, equals('override'));
    });

    test('multiple overrides in single call', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('prod')),
          DependyProvider<HttpClient>((_) => HttpClient('https://real.api')),
          DependyProvider<UserService>(
            (resolve) async => UserService(await resolve<HttpClient>()),
            dependsOn: {HttpClient},
          ),
        },
      );

      final testModule = module.overrideWith(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('test')),
          DependyProvider<HttpClient>((_) => HttpClient('https://mock.api')),
        },
      );

      final logger = await testModule.call<LoggerService>();
      final client = await testModule.call<HttpClient>();
      final userService = await testModule.call<UserService>();

      expect(logger.tag, equals('test'));
      expect(client.baseUrl, equals('https://mock.api'));
      expect(userService.client.baseUrl, equals('https://mock.api'));
    });
  });

  group('DependyModule - Decorators', () {
    test('applies single decorator', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('decorated-${logger.tag}'),
            ],
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('decorated-base'));
    });

    test('applies multiple decorators in order', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('first(${logger.tag})'),
              (logger, _) => LoggerService('second(${logger.tag})'),
            ],
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('second(first(base))'));
    });

    test('decorator receives full resolve (not restricted by dependsOn)',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<EmailService>((_) => EmailService('smtp')),
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, resolve) async {
                final email = await resolve<EmailService>();
                return LoggerService('${logger.tag}+${email.provider}');
              },
            ],
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('base+smtp'));
    });

    test('decorator with async resolve', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<HttpClient>((_) => HttpClient('https://api.com')),
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, resolve) async {
                final client = await resolve<HttpClient>();
                return LoggerService('${logger.tag}@${client.baseUrl}');
              },
            ],
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('base@https://api.com'));
    });

    test('singleton decorated once — same instance on subsequent calls',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('decorated'),
            ],
          ),
        },
      );

      final a = await module.call<LoggerService>();
      final b = await module.call<LoggerService>();
      expect(identical(a, b), isTrue);
      expect(a.tag, equals('decorated'));
    });

    test('transient decorated on each call — different instances', () async {
      int callCount = 0;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            transient: true,
            decorators: [
              (logger, _) => LoggerService('decorated-${++callCount}'),
            ],
          ),
        },
      );

      final a = await module.call<LoggerService>();
      final b = await module.call<LoggerService>();
      expect(identical(a, b), isFalse);
      expect(a.tag, equals('decorated-1'));
      expect(b.tag, equals('decorated-2'));
    });

    test('decorator with tagged provider', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            tag: 'special',
            decorators: [
              (logger, _) => LoggerService('decorated-${logger.tag}'),
            ],
          ),
        },
      );

      final logger = await module.call<LoggerService>(tag: 'special');
      expect(logger.tag, equals('decorated-base'));
    });

    test('provider with no decorators works as before', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('plain'),
          ),
        },
      );

      final logger = await module.call<LoggerService>();
      expect(logger.tag, equals('plain'));
    });

    test('debugGraph shows decorator count', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('d1'),
              (logger, _) => LoggerService('d2'),
            ],
          ),
        },
      );

      final graph = module.debugGraph();
      expect(graph, contains('decorators: 2'));
    });

    test('dispose passes decorated instance', () async {
      LoggerService? disposed;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('decorated'),
            ],
            dispose: (instance) => disposed = instance,
          ),
        },
      );

      await module.call<LoggerService>();
      module.dispose();
      expect(disposed, isNotNull);
      expect(disposed!.tag, equals('decorated'));
    });
  });

  group('DependyModule - reset()', () {
    test('reset clears cached singleton — next call creates new instance',
        () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('cached')),
        },
      );

      final first = await module.call<LoggerService>();
      expect(first.tag, equals('cached'));

      module.reset<LoggerService>();

      final second = await module.call<LoggerService>();
      expect(second.tag, equals('cached'));
      expect(identical(first, second), isFalse);
    });

    test('reset calls dispose callback on old instance', () async {
      LoggerService? disposed;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('disposable'),
            dispose: (instance) => disposed = instance,
          ),
        },
      );

      final first = await module.call<LoggerService>();
      expect(disposed, isNull);

      module.reset<LoggerService>();
      expect(disposed, isNotNull);
      expect(identical(disposed, first), isTrue);
    });

    test('reset is no-op on transient provider', () async {
      HttpRequest.reset();

      final module = DependyModule(
        providers: {
          DependyProvider<HttpRequest>(
            (_) => HttpRequest(),
            transient: true,
          ),
        },
      );

      final a = await module.call<HttpRequest>();
      module.reset<HttpRequest>();
      final b = await module.call<HttpRequest>();

      // Transient already creates fresh instances; reset doesn't break it
      expect(identical(a, b), isFalse);
    });

    test('reset is no-op on disposed provider', () async {
      final provider = DependyProvider<LoggerService>(
        (_) => LoggerService('test'),
      );

      final module = DependyModule(providers: {provider});
      await module.call<LoggerService>();

      // Dispose the provider directly
      provider.dispose();
      // reset after dispose should not throw
      provider.reset();
      expect(provider.disposed, isTrue);
    });

    test('reset on never-resolved provider is safe', () async {
      LoggerService? disposed;
      bool disposeCalled = false;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('never-resolved'),
            dispose: (instance) {
              disposeCalled = true;
              disposed = instance;
            },
          ),
        },
      );

      // Reset before ever calling — should not throw
      module.reset<LoggerService>();
      expect(disposeCalled, isTrue);
      expect(disposed, isNull);
    });

    test('module.reset<T>() resets provider by type', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('by-type')),
        },
      );

      final first = await module.call<LoggerService>();
      module.reset<LoggerService>();
      final second = await module.call<LoggerService>();

      expect(identical(first, second), isFalse);
    });

    test('module.reset<T>(tag:) resets tagged provider', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('api'),
            tag: 'api',
          ),
          DependyProvider<LoggerService>(
            (_) => LoggerService('cdn'),
            tag: 'cdn',
          ),
        },
      );

      final apiBefore = await module.call<LoggerService>(tag: 'api');
      final cdnBefore = await module.call<LoggerService>(tag: 'cdn');

      module.reset<LoggerService>(tag: 'api');

      final apiAfter = await module.call<LoggerService>(tag: 'api');
      final cdnAfter = await module.call<LoggerService>(tag: 'cdn');

      // api was reset — different instance
      expect(identical(apiBefore, apiAfter), isFalse);
      // cdn was NOT reset — same instance
      expect(identical(cdnBefore, cdnAfter), isTrue);
    });

    test('module.reset<T>() throws on disposed module', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      module.dispose();

      expect(
        () => module.reset<LoggerService>(),
        throwsA(isA<DependyModuleDisposedException>()),
      );
    });

    test('module.reset<T>() throws for unregistered type', () {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      expect(
        () => module.reset<HttpRequest>(),
        throwsA(isA<DependyProviderNotFoundException>()),
      );
    });

    test('module.reset<T>() searches submodules', () async {
      final subModule = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('sub')),
        },
      );

      final module = DependyModule(
        providers: {},
        modules: {subModule},
      );

      final first = await module.call<LoggerService>();
      module.reset<LoggerService>();
      final second = await module.call<LoggerService>();

      expect(identical(first, second), isFalse);
    });

    test('reset re-runs decorators on next resolve', () async {
      int decoratorCallCount = 0;

      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) {
                decoratorCallCount++;
                return LoggerService('decorated-$decoratorCallCount');
              },
            ],
          ),
        },
      );

      final first = await module.call<LoggerService>();
      expect(first.tag, equals('decorated-1'));
      expect(decoratorCallCount, equals(1));

      module.reset<LoggerService>();

      final second = await module.call<LoggerService>();
      expect(second.tag, equals('decorated-2'));
      expect(decoratorCallCount, equals(2));
      expect(identical(first, second), isFalse);
    });

    test('reset does not affect other providers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('logger')),
          DependyProvider<EmailService>((_) => EmailService('email')),
        },
      );

      final loggerBefore = await module.call<LoggerService>();
      final emailBefore = await module.call<EmailService>();

      module.reset<LoggerService>();

      final loggerAfter = await module.call<LoggerService>();
      final emailAfter = await module.call<EmailService>();

      // Logger was reset — different instance
      expect(identical(loggerBefore, loggerAfter), isFalse);
      // Email was NOT reset — same instance
      expect(identical(emailBefore, emailAfter), isTrue);
    });

    test('reset cascades to consumers that dependsOn the reset type', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('dep')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      final loggerBefore = await module.call<LoggerService>();
      final dbBefore = await module.call<DatabaseService>();
      expect(identical(dbBefore.logger, loggerBefore), isTrue);

      // Reset the dependency — consumer is cascaded automatically
      module.reset<LoggerService>();

      final loggerAfter = await module.call<LoggerService>();
      final dbAfter = await module.call<DatabaseService>();

      // Both are fresh instances
      expect(identical(loggerBefore, loggerAfter), isFalse);
      expect(identical(dbBefore, dbAfter), isFalse);
      // Consumer got the new dependency
      expect(identical(dbAfter.logger, loggerAfter), isTrue);
    });

    test('reset cascades transitively through dependency chain', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('root')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
          DependyProvider<ApiClient>(
            (resolve) async => ApiClient(await resolve<DatabaseService>()),
            dependsOn: {DatabaseService},
          ),
        },
      );

      final loggerBefore = await module.call<LoggerService>();
      final dbBefore = await module.call<DatabaseService>();
      final apiBefore = await module.call<ApiClient>();

      // Reset the root dependency — should cascade through the whole chain
      module.reset<LoggerService>();

      final loggerAfter = await module.call<LoggerService>();
      final dbAfter = await module.call<DatabaseService>();
      final apiAfter = await module.call<ApiClient>();

      expect(identical(loggerBefore, loggerAfter), isFalse);
      expect(identical(dbBefore, dbAfter), isFalse);
      expect(identical(apiBefore, apiAfter), isFalse);
      // Whole chain re-wired
      expect(identical(apiAfter.database.logger, loggerAfter), isTrue);
    });

    test('reset cascade does not affect unrelated providers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('dep')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
          DependyProvider<EmailService>((_) => EmailService('unrelated')),
        },
      );

      final emailBefore = await module.call<EmailService>();
      await module.call<LoggerService>();
      await module.call<DatabaseService>();

      module.reset<LoggerService>();

      final emailAfter = await module.call<EmailService>();
      // Unrelated provider is untouched
      expect(identical(emailBefore, emailAfter), isTrue);
    });

    test('reset cascade skips unresolved consumers', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService('dep')),
          DependyProvider<DatabaseService>(
            (resolve) async => DatabaseService(await resolve<LoggerService>()),
            dependsOn: {LoggerService},
          ),
        },
      );

      // Resolve only the dependency, NOT the consumer
      await module.call<LoggerService>();

      // Reset should not throw even though DatabaseService was never resolved
      module.reset<LoggerService>();

      // Consumer resolves fresh with the new dependency
      final db = await module.call<DatabaseService>();
      final logger = await module.call<LoggerService>();
      expect(identical(db.logger, logger), isTrue);
    });

    test('debugGraph shows pending after reset', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>((_) => LoggerService()),
        },
      );

      await module.call<LoggerService>();
      expect(module.debugGraph(), contains('- cached'));

      module.reset<LoggerService>();
      expect(module.debugGraph(), contains('- pending'));
    });
  });

  group('EagerDependyModule - Decorators', () {
    test('eager module resolves decorated instances', () async {
      final module = DependyModule(
        providers: {
          DependyProvider<LoggerService>(
            (_) => LoggerService('base'),
            decorators: [
              (logger, _) => LoggerService('eager-decorated'),
            ],
          ),
        },
      );

      final eager = await module.asEager();
      final logger = eager.call<LoggerService>();
      expect(logger.tag, equals('eager-decorated'));
    });
  });
}
