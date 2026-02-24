# Dependy - A Simple Dependency Injection Library for Dart

[![Pub](https://img.shields.io/pub/v/dependy.svg)](https://pub.dev/packages/dependy)

### Docs
[Dependy Website](https://dependy.xeinebiu.com/)

### Contents

1. [About](#about)
2. [Installation](#installation)
3. [Core Concepts](#core-concepts)
    - [DependyProvider](#dependyprovider)
    - [DependyModule](#dependymodule)
    - [Use Cases](#use-cases)
4. [Disposing Providers and Modules](#disposing-providers-and-modules)
5. [Purpose of Keys](#purpose-of-keys)
6. [Scopes](#scopes)
7. [Exceptions](#exceptions)
8. [Examples](#examples)
   - [Simple Counter Service](#simple-counter-service)
   - [Two Independent Services](#two-independent-services)
   - [Services with Dependencies](#services-with-dependencies)
   - [Multiple Modules with Dependencies](#multiple-modules-with-dependencies)
   - [Eager initialization](#eager-initialization)
   - [Transient Providers](#transient-providers)
   - [Tagged Instances](#tagged-instances)
   - [Overrides for Testing](#overrides-for-testing)
   - [Debug Graph](#debug-graph)
   - [Provider Decorators](#provider-decorators)
9. [MIT License](#mit-license)

---

## About

**Dependy** is a lightweight and flexible dependency injection (DI) library for Dart. It simplifies managing services and their dependencies, making our code more modular, maintainable, and testable.
Dependy supports hierarchical modules, dependency tracking, and circular dependency detection.
It also supports eager or lazy/asynchronous initialization, allowing services to be loaded efficiently when needed.

### Key Features:

- **Provider-based DI**: Define how each service (provider) is created and manage dependencies between them.
- **Support for modules**: Structure your providers into modules to improve separation of concerns.
- **Circular dependency detection**: Avoid infinite loops by tracking dependencies.
- **Tagged instances**: Register multiple providers of the same type using `tag`, resolve with `module<T>(tag: 'name')`.
- **Transient providers**: Create a fresh instance on every resolution with `transient: true`.
- **Captive dependency detection**: Fail fast when a singleton depends on a transient provider.
- **Overrides for testing**: Swap providers in a module for tests/mocking with `overrideWith`, without rebuilding the entire module tree.
- **Provider decorators**: Wrap resolved instances with composable transformations (logging, caching, retry, auth) applied after the factory, inside singleton caching. Decorators receive full module resolve and are applied in list order.
- **Debug graph**: Inspect the entire dependency tree with `debugGraph()` — shows types, tags, lifecycle, resolution status, decorator counts, and nested modules as a formatted ASCII tree.
- **Async initialization**: Initialize services asynchronously.
- **Eager initialization**: Initialize and prepare all services eagerly.

## Installation

Add `dependy` to your `pubspec.yaml`:

```yaml
dependencies:
  dependy: ^1.7.0
```

Then, run:

```bash
dart pub get
```

Import `dependy` in your Dart files:

```dart
import 'package:dependy/dependy.dart';
```

---

## Core Concepts

### DependyProvider

A **`DependyProvider`** is responsible for providing instances of a specific service. It manages how a service or object
is created, its dependencies, and optionally how it is disposed when no longer needed.

Each provider:

- Requires a **factory** function that defines how the instance of an object is created.
- Optionally takes a set of dependencies (other services that it relies on).
- Handles cleanup when the provider is disposed using a **dispose** method.

Example of a provider for a `LoggerService`:

```dart
DependyProvider<LoggerService>((_) => LoggerService());
```

You can use providers to manage services, singletons, and objects that require dependencies. For example, if a service
`A` requires service `B`, you can specify this dependency through `dependsOn` in `DependyProvider`.

### DependyModule

A **`DependyModule`** is a collection of `DependyProvider` instances. It serves as a container for managing the
lifecycle and resolution of dependencies. A module can also contain other modules, allowing you to organize your
services hierarchically.

Modules help you:

- Group related services (e.g., authentication services, database services).
- Avoid tight coupling between components by abstracting how services are resolved.
- Handle complex applications with multiple modules, each responsible for different functionality.


Example of a simple module:

```dart

final loggingService = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
        (_) => LoggerService(),
    ),
  },
);

```

### Use Cases

- **Single Service**: A module can manage a single service that can be used throughout the application (e.g.,
  `LoggerService`).
- **Multiple Services**: A module can manage several unrelated services, allowing you to inject them where necessary (
  e.g., `LoggerService` and `ApiService`).
- **Services with Dependencies**: Providers can depend on each other (e.g., `ApiService` depends on
  `LoggerService`, and `LoggerService` depends on `ConfigService`).
- **Hierarchical Modules**: Large applications can be structured into multiple modules that handle different domains (
  e.g., database services, API services, etc.).

---

### Disposing Providers and Modules

You can dispose of all the providers in a **`DependyModule`** by calling the `dispose` method. This method will invoke the `dispose` function on each **`DependyProvider`** within the module.

#### Disposing Submodules

If you want to also dispose of all submodules along with their providers, you can use the `dispose` method with the named argument `disposeSubmodules` set to `true`.

#### Example

Here’s how to use the `dispose` method in a module:

```dart

final loggingModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
        (_) => LoggerService(),
    ),
  },
);


// When you are done with the module, dispose of its providers
// provide disposeSubmodules: true o also dispose of submodules (default: false)
loggingModule.dispose(disposeSubmodules: true);
```

---

### Purpose of Keys

Keys provide a way to identify specific providers and modules during development. When an exception occurs or when you log information, the key associated with a provider or module can help you trace back to the source of the issue. This makes it easier to pinpoint where things went wrong.

### Example Usage

When creating a provider, you can specify a key like this:

```dart
DependyProvider<MyService>(
  (_) => MyService(),
  key: 'my_service_key',
);
```
---

### Scopes

A **scope** defines the lifetime of a service or object. Scopes determine how long a service stays in memory and when it should be disposed of. Services can either be short-lived or long-lived, depending on the scope they are placed in. Here's a breakdown:

1. **Singleton Scope**:
    - Services in this scope live as long as the application is running.
    - They are created once and shared across the entire app.
    - Perfect for services that need to persist throughout the app's lifecycle, such as logging, authentication, or configuration services.

2. **Transient Scope**:
    - A new instance is created on every resolution — nothing is cached.
    - Enable by setting `transient: true` on a `DependyProvider`.
    - Ideal for short-lived objects like HTTP requests, form validators, or command handlers.
    - A singleton provider **cannot** depend on a transient provider. Dependy detects this at module construction and throws a `DependyCaptiveDependencyException`.

3. **Tagged Instances**:
    - Register multiple providers of the same type by assigning a unique `tag` to each.
    - Resolve with `module<T>(tag: 'name')`. An untagged provider is resolved with `module<T>()`.
    - Inside factories, forward the tag: `resolve<T>(tag: 'name')`.
    - `dependsOn` remains `Set<Type>` — tags are a routing detail inside factories, not a dependency declaration.

4. **Scoped Scope**:
    - Services in this scope are temporary and exist only for a short time.
    - These services are disposed of when they are no longer needed.
    - Useful for services that are tied to a specific part of your app, like a screen, a form, or a session.


#### Example
````dart
// region Logger
abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print('[Logger]: $message');
  }
}
// endregion

// region Database
abstract class DatabaseService {
  void connect();

  void close();
}

class SqlDatabaseService extends DatabaseService {
  final LoggerService _logger;

  SqlDatabaseService(this._logger);

  @override
  void connect() {
    _logger.log('Connected to Sql Database');
  }

  @override
  void close() {
    _logger.log('Closed Sql Database');
  }
}

class SqliteDatabaseService extends DatabaseService {
  final LoggerService _logger;

  SqliteDatabaseService(this._logger);

  @override
  void connect() {
    _logger.log('Connected to Sqlite Database');
  }

  @override
  void close() {
    _logger.log('Closed Sqlite Database');
  }
}
// endregion

// region Api
abstract class ApiService {
  void fetchData();

  void dispose();
}

class ApiServiceImpl extends ApiService {
  final DatabaseService _db;
  final LoggerService _logger;

  ApiServiceImpl(this._db, this._logger);

  @override
  void fetchData() {
    _logger.log('Fetching data from API...');
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log('Disposing $this');
  }
}

class MockApiService extends ApiService {
  final DatabaseService _db;
  final LoggerService _logger;

  MockApiService(this._db, this._logger);

  @override
  void fetchData() {
    _logger.log('Mocking API data...');
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log('Disposing $this');
  }
}
// endregion

// Singleton module: provides services that live across the application
final singletonModule = DependyModule(
  key: 'singleton_module',
  providers: {
    DependyProvider<LoggerService>(
          (resolve) => ConsoleLoggerService(),
      key: 'singleton_logger_service',
    ),
    DependyProvider<DatabaseService>(
          (dependy) async {
        final logger = await dependy<LoggerService>();
        return SqlDatabaseService(logger);
      },
      key: 'singleton_database_service',
      dependsOn: {
        LoggerService,
      },
    ),
    DependyProvider<ApiService>(
          (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        final logger = await dependy<LoggerService>();
        return ApiServiceImpl(databaseService, logger);
      },
      key: 'singleton_api_service',
      dependsOn: {
        DatabaseService,
        LoggerService,
      },
    ),
  },
);

// Scoped module: provides services that live temporarily and are disposed when done
final scopedModule = DependyModule(
  key: 'scoped_module',
  providers: {
    // Here we declare a different implementation of DatabaseService [SqliteDatabaseService]
    // for scoped usage. Scoped services are designed to be used in a temporary context.
    DependyProvider<DatabaseService>(
          (dependy) async {
        final logger = await dependy<LoggerService>();
        return SqliteDatabaseService(logger);
      },
      key: 'scoped_database_service',
      dependsOn: {
        LoggerService,
      },
      dispose: (database) {
        // Close the database connections when the [DependyProvider] is disposed.
        database?.close();
      },
    ),
    // A different implementation of ApiService (MockApiService) is provided.
    DependyProvider<ApiService>(
          (dependy) async {
        // will resolve to [SqliteDatabaseService]
        final database = await dependy<DatabaseService>();

        // will resolve from [singletonModule]
        final logger = await dependy<LoggerService>();

        return MockApiService(database, logger);
      },
      dependsOn: {
        DatabaseService,
        LoggerService,
      },
      dispose: (api) {
        // Dispose the api service when the [DependyProvider] is disposed.
        api?.dispose();
      },
    ),
  },
  modules: {
    singletonModule,
    // Makes available all of its providers to the [scopedModule]
  },
);

void main() async {
  print('=== Scoped Module Usage ===');
  final scopedApiService = await scopedModule<ApiService>();
  scopedApiService.fetchData();
  scopedModule.dispose(); // Disposes all services in the [scopedModule]

  // Result:
  // [Logger]: Mocking API data...
  // [Logger]: Connected to Sqlite Database
  // [Logger]: Closed Sqlite Database
  // [Logger]: Disposing Instance of 'MockApiService'

  // Demonstrating the singleton behavior (persistent services)
  print('\n=== Singleton Module Usage After Scoped Module Disposed ===');
  final singletonApiService = await singletonModule<ApiService>();
  singletonApiService.fetchData();

  // Result:
  // [Logger]: Fetching data from API...
  // [Logger]: Connected to Sql Database
}
````

---

## Exceptions

**Dependy** can throw several exceptions during its operation. Understanding when these exceptions occur will help you handle errors gracefully in your application.

### `DependyCircularDependencyException`

This exception is thrown when there is a circular dependency in the provider graph. A circular dependency occurs when two or more providers depend on each other directly or indirectly, leading to an infinite loop during resolution.

**Example**: If **Service-A** depends on **Service-B**, **Service-B** depends on **Service-C**, and **Service-C** depends on **Service-A**. This indirect chain of dependencies leads to an infinite loop during resolution.

### `DependyModuleDisposedException`

This exception is thrown when you attempt to resolve a provider from a **`DependyModule`** that has already been disposed. Once a module is disposed, it can no longer provide instances of its services.

**Example**: If you call `module<SomeService>()` after calling `module.dispose()`, a `DependyModuleDisposedException` will be raised.

### `DependyProviderNotFoundException`

This exception occurs when you try to resolve a provider for a specific type, but no provider is registered for that type within the module or its submodules.

**Example**: If you attempt to get an instance of **Provider C** but it has not been defined in the current module or any of its submodules, a `DependyProviderNotFoundException` will be thrown.

### `DependyProviderMissingDependsOnException`

This exception is thrown when a provider tries to resolve a dependency that has not been declared in its `dependsOn` set. This verifies that all dependencies are explicitly defined, promoting better design and avoiding runtime errors.

**Example**: If **Provider D** requires **Provider E**, but **Provider E** is not listed in the `dependsOn` set of **Provider D**, a `DependyProviderMissingDependsOnException` will occur.

### `DependyProviderDisposedException`

This exception is thrown when you try to use a provider that has already been disposed. Once a provider is disposed, it cannot be used anymore.

**Example**: If you call `<module><T>()` on a disposed provider, a `DependyProviderDisposedException` will be raised.

### `DependyCaptiveDependencyException`

This exception is thrown when a singleton provider depends on a transient provider. This would silently "capture" the transient instance, defeating its purpose. Either make the consuming provider transient as well, or make the dependency a singleton.

**Example**: If a singleton `AuthService` declares `dependsOn: {SessionToken}` and `SessionToken` is registered with `transient: true`, a `DependyCaptiveDependencyException` will be thrown at module construction.

### `DependyDuplicateProviderException`

This exception is thrown when there is more than one provider of the same type registered within a single module.

**Example**:

```dart
final databaseModule = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
          (_) => SqlDatabaseService(),
    ),
    DependyProvider<DatabaseService>(
          (_) => SqliteDatabaseService(),
      dependsOn: {},
    ),
  },
);
```

In this example, both `SqlDatabaseService` and `SqliteDatabaseService` are registered as providers for the `DatabaseService` type within the same module.

---

## Examples

### Simple Counter Service

In this example, we use a single service called `CounterService`, which provides a simple counter that increments on
each call.

```dart
class CounterService {
  int _count = 0;

  int increment() => ++_count;
}

final dependy = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (_) => CounterService(),
    ),
  },
);

void main() async {
  final counterService = await dependy<CounterService>();

  print('Initial Count: ${counterService.increment()}');
  print('After Increment: ${counterService.increment()}');
}
```

### Two Independent Services

In this example, we have two independent services: `LoggerService` for logging and `MathService` for performing a
mathematical operation.

```dart
class LoggerService {
  void log(String message) {
    print('Log: $message');
  }
}

class MathService {
  int square(int number) => number * number;
}

final dependy = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
          (_) => LoggerService(),
    ),
    DependyProvider<MathService>(
          (_) => MathService(),
    ),
  },
);

void main() async {
  final loggerService = await dependy<LoggerService>();
  final mathService = await dependy<MathService>();

  loggerService.log('Calculating square of 4: ${mathService.square(4)}');
}
```

### Services with Dependencies

Here, the `CalculatorService` depends on `LoggerService`, and `LoggerService` depends on `ConfigService`. Each
dependency is resolved in the correct order.

```dart
import 'package:dependy/dependy.dart';

class ConfigService {
  final String appName = 'DependyExample';
}

class LoggerService {
  final ConfigService _config;

  LoggerService(this._config);

  void log(String message) {
    print('${_config.appName}: $message');
  }
}

class CalculatorService {
  final LoggerService _logger;

  CalculatorService(this._logger);

  int multiply(int a, int b) {
    _logger.log('Multiplying $a and $b');
    return a * b;
  }
}

final dependy = DependyModule(
  providers: {
    DependyProvider<ConfigService>(
          (_) => ConfigService(),
    ),
    DependyProvider<LoggerService>(
          (dependy) async {
        final configService = await dependy<ConfigService>();
        return LoggerService(configService);
      },
      dependsOn: {
        ConfigService,
      },
    ),
    DependyProvider<CalculatorService>(
          (dependy) async {
        final loggerService = await dependy<LoggerService>();
        return CalculatorService(loggerService);
      },
      dependsOn: {
        LoggerService,
      },
    ),
  },
);

void main() async {
  final calculatorService = await dependy<CalculatorService>();

  print('Result: ${calculatorService.multiply(3, 5)}');
}
```

### Multiple Modules with Dependencies

In this example, we organize services into two modules: one for database and API services, and another for
authentication and payment services. Each module manages its own set of dependencies.

```dart
class DatabaseService {
  void connect() => print('Connected to Database');
}

class ApiService {
  final DatabaseService _db;

  ApiService(this._db);

  void fetchData() {
    print('Fetching data from API...');
    _db.connect();
  }
}

class AuthService {
  void authenticate() => print('User authenticated');
}

class PaymentService {
  final AuthService _auth;

  PaymentService(this._auth);

  void processPayment() {
    _auth.authenticate();
    print('Payment processed');
  }
}

final module1 = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
          (_) => DatabaseService(),
    ),
    DependyProvider<ApiService>(
          (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        return ApiService(databaseService);
      },
      dependsOn: {
        DatabaseService,
      },
    ),
  },
);

final module2 = DependyModule(
  providers: {
    DependyProvider<AuthService>(
          (_) => AuthService(),
    ),
    DependyProvider<PaymentService>(
          (dependy) async {
        final authService = await dependy<AuthService>();
        return PaymentService(authService);
      },
      dependsOn: {
        AuthService,
      },
    ),
  },
);

final module3 = DependyModule(
  providers: {
    DependyProvider<AuthService>(
          (_) => AuthService(),
    ),
    DependyProvider<PaymentService>(
          (dependy) async {
        final authService = await dependy<AuthService>();
        return PaymentService(authService);
      },
      dependsOn: {
        AuthService,
      },
    ),
  },
);

final mainModule = DependyModule(
  providers: {},
  modules: {
    module1,
    module2,
  },
);

void main() async {
  final apiService = await mainModule<ApiService>();
  final paymentService = await mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}
```

### Eager initialization
```dart

class ConfigService {
  ConfigService(this.apiUrl);

  final String apiUrl;
}

class LoggerService {
  void log(String message) {
    print("LOG: $message");
  }
}

class DatabaseService {
  DatabaseService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void connect() {
    logger.log("Connecting to database at ${config.apiUrl}");
  }
}

class ApiService {
  ApiService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void fetchData() {
    logger.log("Fetching data from API at ${config.apiUrl}");
  }
}

void main() async {
  final eagerModule = await DependyModule(
    providers: {
      DependyProvider<ConfigService>(
        (resolve) async => ConfigService("https://api.example.com"),
      ),
      DependyProvider<LoggerService>(
        (resolve) async => LoggerService(),
      ),
      DependyProvider<DatabaseService>(
        (resolve) async => DatabaseService(
          await resolve<ConfigService>(),
          await resolve<LoggerService>(),
        ),
        dependsOn: {ConfigService, LoggerService},
      ),
      DependyProvider<ApiService>(
        (resolve) async => ApiService(
          await resolve<ConfigService>(),
          await resolve<LoggerService>(),
        ),
        dependsOn: {ConfigService, LoggerService},
      ),
    },
  ).asEager(); // Convert to an EagerDependyModule using asEager extension

  // Now, retrieve the services synchronously
  final dbService = eagerModule<DatabaseService>();
  dbService.connect();

  final apiService = eagerModule<ApiService>();
  apiService.fetchData();
}


```

### Transient Providers

In this example, `FormValidator` is transient — each resolution returns a fresh instance with its own state. `LoggerService` and `AuthService` remain singletons, shared across the app.

```dart
import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('[Logger]: $message');
  }
}

class AuthService {
  final LoggerService _logger;

  AuthService(this._logger);

  void authenticate(String user) {
    _logger.log('Authenticating $user');
  }
}

class FormValidator {
  final LoggerService _logger;
  final List<String> _errors = [];

  FormValidator(this._logger);

  void validate(String field, String value) {
    if (value.isEmpty) {
      _errors.add('$field is required');
    }
    _logger.log('Validated $field');
  }

  bool get isValid => _errors.isEmpty;

  List<String> get errors => List.unmodifiable(_errors);
}

// LoggerService and AuthService are singletons — shared across the app.
// FormValidator is transient — a fresh instance for every form submission.
//
// Note: a singleton cannot depend on a transient provider.
// Dependy enforces this at module creation to prevent the "captive dependency"
// anti-pattern. A transient can safely depend on singletons.
final dependy = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => LoggerService(),
    ),
    DependyProvider<AuthService>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return AuthService(logger);
      },
      dependsOn: {LoggerService},
    ),
    DependyProvider<FormValidator>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return FormValidator(logger);
      },
      dependsOn: {LoggerService},
      transient: true,
    ),
  },
);

void main() async {
  // Each call returns a fresh FormValidator with its own error state
  final loginForm = await dependy<FormValidator>();
  loginForm.validate('email', 'user@example.com');
  loginForm.validate('password', '');
  print('Login valid: ${loginForm.isValid}'); // false
  print('Errors: ${loginForm.errors}'); // [password is required]

  final signupForm = await dependy<FormValidator>();
  signupForm.validate('email', 'new@example.com');
  signupForm.validate('password', 'secret123');
  print('Signup valid: ${signupForm.isValid}'); // true

  // AuthService is a singleton — same instance everywhere
  final auth = await dependy<AuthService>();
  auth.authenticate('user@example.com');
}
```

### Tagged Instances

Use `tag` to register multiple providers of the same type. Each tagged provider is resolved independently by its tag.

```dart
import 'package:dependy/dependy.dart';

class HttpClient {
  final String baseUrl;

  HttpClient(this.baseUrl);

  String get(String path) => 'GET $baseUrl$path';
}

class UserService {
  final HttpClient _client;

  UserService(this._client);

  String fetchUser(int id) => _client.get('/users/$id');
}

class CacheService {
  final HttpClient _client;

  CacheService(this._client);

  String fetchAsset(String name) => _client.get('/assets/$name');
}

final module = DependyModule(
  providers: {
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://api.example.com'),
      tag: 'api',
    ),
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://cdn.example.com'),
      tag: 'cdn',
    ),
    DependyProvider<UserService>(
      (resolve) async {
        final client = await resolve<HttpClient>(tag: 'api');
        return UserService(client);
      },
      dependsOn: {HttpClient},
    ),
    DependyProvider<CacheService>(
      (resolve) async {
        final client = await resolve<HttpClient>(tag: 'cdn');
        return CacheService(client);
      },
      dependsOn: {HttpClient},
    ),
  },
);

void main() async {
  final apiClient = await module<HttpClient>(tag: 'api');
  final cdnClient = await module<HttpClient>(tag: 'cdn');

  print(apiClient.get('/health'));   // GET https://api.example.com/health
  print(cdnClient.get('/logo.png')); // GET https://cdn.example.com/logo.png

  final userService = await module<UserService>();
  print(userService.fetchUser(42));  // GET https://api.example.com/users/42
}
```

### Overrides for Testing

Use `overrideWith` to swap specific providers in a module for tests or mocking — without rebuilding the entire module tree. The original module is not modified, making it safe for parallel tests.

```dart
import 'package:dependy/dependy.dart';

class HttpClient {
  final String baseUrl;
  HttpClient(this.baseUrl);
  String get(String path) => 'GET $baseUrl$path';
}

class MockHttpClient extends HttpClient {
  MockHttpClient() : super('https://mock.test');
  @override
  String get(String path) => 'MOCK $baseUrl$path';
}

class UserService {
  final HttpClient _client;
  UserService(this._client);
  String fetchUser(int id) => _client.get('/users/$id');
}

final productionModule = DependyModule(
  providers: {
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://api.example.com'),
    ),
    DependyProvider<UserService>(
      (resolve) async => UserService(await resolve<HttpClient>()),
      dependsOn: {HttpClient},
    ),
  },
);

void main() async {
  // Test — swap HttpClient with a mock, keep everything else
  final testModule = productionModule.overrideWith(
    providers: {
      DependyProvider<HttpClient>((_) => MockHttpClient()),
    },
  );

  final userService = await testModule<UserService>();
  print(userService.fetchUser(42));
  // MOCK https://mock.test/users/42

  // Override tagged providers
  final taggedModule = DependyModule(
    providers: {
      DependyProvider<HttpClient>(
        (_) => HttpClient('https://api.real.com'),
        tag: 'api',
      ),
    },
  );

  final testTagged = taggedModule.overrideWith(
    providers: {
      DependyProvider<HttpClient>(
        (_) => MockHttpClient(),
        tag: 'api',
      ),
    },
  );

  final client = await testTagged<HttpClient>(tag: 'api');
  print(client.get('/health'));
  // MOCK https://mock.test/health
}
```

### Debug Graph

Use `debugGraph()` to inspect the module tree at any point during development. It returns a formatted ASCII string showing every provider and submodule with its type, tag, lifecycle, resolution status, and disposed state.

```dart
import 'package:dependy/dependy.dart';

class LoggerService {}

class DatabaseService {
  final LoggerService logger;
  DatabaseService(this.logger);
}

class HttpRequest {}

class HttpClient {
  final String baseUrl;
  HttpClient(this.baseUrl);
}

Future<void> main() async {
  final module = DependyModule(
    key: 'app',
    providers: {
      DependyProvider<LoggerService>((_) => LoggerService()),
      DependyProvider<DatabaseService>(
        (resolve) async => DatabaseService(await resolve<LoggerService>()),
        dependsOn: {LoggerService},
      ),
      DependyProvider<HttpRequest>((_) => HttpRequest(), transient: true),
    },
    modules: {
      DependyModule(
        key: 'http_module',
        providers: {
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://api.example.com'),
            tag: 'api',
          ),
          DependyProvider<HttpClient>(
            (_) => HttpClient('https://cdn.example.com'),
            tag: 'cdn',
          ),
        },
      ),
    },
  );

  // Before resolution — all singletons are pending
  print(module.debugGraph());
  // DependyModule (key: app)
  // +-- LoggerService [singleton] - pending
  // +-- DatabaseService [singleton] - pending
  // |    dependsOn: {LoggerService}
  // +-- HttpRequest [transient] - always new
  // \-- [module] DependyModule (key: http_module)
  //     +-- HttpClient #api [singleton] - pending
  //     \-- HttpClient #cdn [singleton] - pending

  // After resolving DatabaseService
  await module.call<DatabaseService>();
  print(module.debugGraph());
  // DependyModule (key: app)
  // +-- LoggerService [singleton] - cached
  // +-- DatabaseService [singleton] - cached
  // |    dependsOn: {LoggerService}
  // +-- HttpRequest [transient] - always new
  // \-- [module] DependyModule (key: http_module)
  //     +-- HttpClient #api [singleton] - pending
  //     \-- HttpClient #cdn [singleton] - pending

  // After disposal
  module.dispose();
  print(module.debugGraph());
  // DependyModule (key: app) [DISPOSED]
  // +-- LoggerService [singleton] [DISPOSED]
  // +-- DatabaseService [singleton] [DISPOSED]
  // |    dependsOn: {LoggerService}
  // +-- HttpRequest [transient] [DISPOSED]
  // \-- [module] DependyModule (key: http_module)
  //     +-- HttpClient #api [singleton] - pending
  //     \-- HttpClient #cdn [singleton] - pending
}
```

`EagerDependyModule` also supports `debugGraph()`, showing `resolved` status for eagerly initialized providers.

### Provider Decorators

Use `decorators` to wrap a resolved instance with composable transformations — logging, caching, retry logic, auth, etc. — without baking them into the factory. Decorators are applied in list order after the factory creates the base instance, inside the provider's singleton caching.

Each decorator receives the current instance and a `resolve` function for resolving additional dependencies from the module (not restricted by `dependsOn`).

```dart
import 'package:dependy/dependy.dart';

abstract class ApiClient {
  Future<String> get(String path);
}

class HttpApiClient implements ApiClient {
  @override
  Future<String> get(String path) async => 'response from $path';

  @override
  String toString() => 'HttpApiClient';
}

class RetryApiClient implements ApiClient {
  final ApiClient _inner;
  final int maxRetries;

  RetryApiClient(this._inner, {this.maxRetries = 3});

  @override
  Future<String> get(String path) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await _inner.get(path);
      } catch (_) {
        if (i == maxRetries - 1) rethrow;
      }
    }
    throw StateError('unreachable');
  }

  @override
  String toString() => 'RetryApiClient(inner: $_inner)';
}

class LoggerService {
  void log(String message) => print('[LOG] $message');
}

class LoggingApiClient implements ApiClient {
  final ApiClient _inner;
  final LoggerService _logger;

  LoggingApiClient(this._inner, this._logger);

  @override
  Future<String> get(String path) async {
    _logger.log('GET $path');
    final result = await _inner.get(path);
    _logger.log('Response: $result');
    return result;
  }

  @override
  String toString() => 'LoggingApiClient(inner: $_inner)';
}

final module = DependyModule(
  key: 'app',
  providers: {
    DependyProvider<LoggerService>((_) => LoggerService()),
    DependyProvider<ApiClient>(
      (_) => HttpApiClient(),
      decorators: [
        // First decorator wraps the raw instance
        (client, _) => RetryApiClient(client, maxRetries: 3),
        // Second decorator wraps the first's output, resolves LoggerService
        (client, resolve) async {
          final logger = await resolve<LoggerService>();
          return LoggingApiClient(client, logger);
        },
      ],
    ),
  },
);

void main() async {
  final client = await module<ApiClient>();

  // Resolved: LoggingApiClient(inner: RetryApiClient(inner: HttpApiClient))
  print('Resolved: $client');

  final response = await client.get('/users');
  // [LOG] GET /users
  // [LOG] Response: response from /users
  print('Got: $response');

  // debugGraph() shows decorator count
  print(module.debugGraph());
  // DependyModule (key: app)
  // +-- LoggerService [singleton] - cached
  // \-- ApiClient [singleton] - cached
  //      decorators: 2
}
```

**Key points:**
- **Singletons** are decorated once and cached — subsequent calls return the same decorated instance.
- **Transients** are decorated on every call, wrapping each fresh instance.
- **Order matters** — decorators are applied in list order. First decorator wraps the raw instance, second wraps the first's output, etc.
- **Decorators receive full module resolve** — they can resolve any type available in the module hierarchy, not just types listed in `dependsOn`.
- **`overrideWith`** replaces the whole provider including its decorators. The override's own decorators (if any) are used; the original's decorators are not inherited.

---

## MIT License

```
MIT License

Copyright (c) [2024] [xeinebiu/dependy]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
