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

    test('same type and same tag throws DependyDuplicateProviderException',
        () {
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
              (resolve) async =>
                  AuthService(await resolve<UserRepository>()),
              dependsOn: {UserRepository},
              tag: 'tagged',
            ),
            DependyProvider<UserRepository>(
              (resolve) async =>
                  UserRepository(await resolve<AuthService>()),
              dependsOn: {AuthService},
              tag: 'tagged',
            ),
          },
        ),
        throwsA(isA<DependyCircularDependencyException>()),
      );
    });
  });
}
