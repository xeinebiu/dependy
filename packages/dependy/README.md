# Dependy - A Simple Dependency Injection Library for Dart

[![Pub](https://img.shields.io/pub/v/dependy.svg)](https://pub.dev/packages/dependy)

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
9. [MIT License](#mit-license)

---

## About

**Dependy** is a lightweight and flexible dependency injection (DI) library for Dart. It simplifies the management of
services and their dependencies, making your code more modular, maintainable, and testable. Dependy also supports
hierarchical modules, dependency tracking, and circular dependency detection.

### Key Features:

- **Provider-based DI**: Define how each service (provider) is created and manage dependencies between them.
- **Support for modules**: Structure your providers into modules to improve separation of concerns.
- **Circular dependency detection**: Avoid infinite loops by tracking dependencies.

---

## Installation

Add `dependy` to your `pubspec.yaml`:

```yaml
dependencies:
  dependy: ^1.0.0
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
loggingModule.dispose(disposeSubmodules: true); // Disposes only the providers
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

2. **Scoped Scope**:
    - Services in this scope are temporary and exist only for a short time.
    - These services are disposed of when they are no longer needed.
    - Useful for services that are tied to a specific part of your app, like a screen, a form, or a session.


#### Example
````dart
import 'package:dependy/dependy.dart';

// region Logger
abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print("[Logger]: $message");
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
    _logger.log("Connected to Sql Database");
  }

  @override
  void close() {
    _logger.log("Closed Sql Database");
  }
}

class SqliteDatabaseService extends DatabaseService {
  final LoggerService _logger;

  SqliteDatabaseService(this._logger);

  @override
  void connect() {
    _logger.log("Connected to Sqlite Database");
  }

  @override
  void close() {
    _logger.log("Closed Sqlite Database");
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
    _logger.log("Fetching data from API...");
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log("Disposing $this");
  }
}

class MockApiService extends ApiService {
  final DatabaseService _db;
  final LoggerService _logger;

  MockApiService(this._db, this._logger);

  @override
  void fetchData() {
    _logger.log("Mocking API data...");
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log("Disposing $this");
  }
}
// endregion

// Singleton module: provides services that live across the application
final singletonModule = DependyModule(
  key: "singleton_module",
  providers: {
    DependyProvider<LoggerService>(
          (resolve) => ConsoleLoggerService(),
      key: "singleton_logger_service",
    ),
    DependyProvider<DatabaseService>(
          (dependy) {
        final logger = dependy<LoggerService>();
        return SqlDatabaseService(logger);
      },
      key: "singleton_database_service",
      dependsOn: {LoggerService},
    ),
    DependyProvider<ApiService>(
          (dependy) {
        final databaseService = dependy<DatabaseService>();
        final logger = dependy<LoggerService>();
        return ApiServiceImpl(databaseService, logger);
      },
      key: "singleton_api_service",
      dependsOn: {DatabaseService, LoggerService},
    ),
  },
);

// Scoped module: provides services that live temporarily and are disposed when done
final scopedModule = DependyModule(
  key: "scoped_module",
  providers: {
    // Here we declare a different implementation of DatabaseService [SqliteDatabaseService]
    // for scoped usage. Scoped services are designed to be used in a temporary context.
    DependyProvider<DatabaseService>(
          (dependy) {
        final logger = dependy<LoggerService>();
        return SqliteDatabaseService(logger);
      },
      key: "scoped_database_service",
      dependsOn: {LoggerService},
      dispose: (database) {
        // Close the database connections when the [DependyProvider] is disposed.
        database?.close();
      },
    ),
    // A different implementation of ApiService (MockApiService) is provided.
    DependyProvider<ApiService>(
          (dependy) {
        // will resolve to [SqliteDatabaseService]
        final database = dependy<DatabaseService>();

        // will resolve from [singletonModule]
        final logger = dependy<LoggerService>();

        return MockApiService(database, logger);
      },
      dependsOn: {DatabaseService, LoggerService},
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

void main() {
  print("=== Scoped Module Usage ===");
  final scopedApiService = scopedModule<ApiService>();
  scopedApiService.fetchData();
  scopedModule.dispose(); // Disposes all services in the [scopedModule]

  // Result:
  // [Logger]: Mocking API data...
  // [Logger]: Connected to Sqlite Database
  // [Logger]: Closed Sqlite Database
  // [Logger]: Disposing Instance of 'MockApiService'

  // Demonstrating the singleton behavior (persistent services)
  print("\n=== Singleton Module Usage After Scoped Module Disposed ===");
  final singletonApiService = singletonModule<ApiService>();
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
import 'package:dependy/dependy.dart';

class CounterService {
  int _count = 0;

  int increment() => ++_count;
}

final module = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (resolve) => CounterService(),
    ),
  },
);

void main() {
  final counterService = module<CounterService>();

  print('Initial Count: ${counterService.increment()}');
  print('After Increment: ${counterService.increment()}');
}

```

### Two Independent Services

In this example, we have two independent services: `LoggerService` for logging and `MathService` for performing a
mathematical operation.

```dart
import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('Log: $message');
  }
}

class MathService {
  int square(int number) => number * number;
}

final module = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
          (resolve) => LoggerService(),
    ),
    DependyProvider<MathService>(
          (resolve) => MathService(),
    )
  },
);

void main() {
  final loggerService = module<LoggerService>();
  final mathService = module<MathService>();

  loggerService.log('Calculating square of 4: ${mathService.square(4)}');
}

```

### Services with Dependencies

Here, the `CalculatorService` depends on `LoggerService`, and `LoggerService` depends on `ConfigService`. Each
dependency is resolved in the correct order.

```dart

import 'package:dependy/dependy.dart';

class ConfigService {
  final String appName = "DependyExample";
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

final module = DependyModule(
  providers: {
    DependyProvider<ConfigService>(
      (resolve) => ConfigService(),
    ),
    DependyProvider<LoggerService>(
      (dependy) => LoggerService(dependy<ConfigService>()),
      dependsOn: {
        ConfigService,
      },
    ),
    DependyProvider<CalculatorService>(
      (resolve) => CalculatorService(dependy<LoggerService>()),
      dependsOn: {
        LoggerService,
      },
    ),
  },
);

void main() {
  final calculatorService = module<CalculatorService>();

  print('Result: ${calculatorService.multiply(3, 5)}');
}

```

### Multiple Modules with Dependencies

In this example, we organize services into two modules: one for database and API services, and another for
authentication and payment services. Each module manages its own set of dependencies.

```dart
import 'package:dependy/dependy.dart';

class DatabaseService {
  void connect() => print("Connected to Database");
}

class ApiService {
  final DatabaseService _db;

  ApiService(this._db);

  void fetchData() {
    print("Fetching data from API...");
    _db.connect();
  }
}

class AuthService {
  void authenticate() => print("User authenticated");
}

class PaymentService {
  final AuthService _auth;

  PaymentService(this._auth);

  void processPayment() {
    _auth.authenticate();
    print("Payment processed");
  }
}

final module1 = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
      (_) => DatabaseService(),
    ),
    DependyProvider<ApiService>(
      (dependy) => ApiService(dependy<DatabaseService>()),
      dependsOn: {DatabaseService},
    ),
  },
);

final module2 = DependyModule(
  providers: {
    DependyProvider<AuthService>(
      (_) => AuthService(),
    ),
    DependyProvider<PaymentService>(
      (dependy) => PaymentService(dependy<AuthService>()),
      dependsOn: {AuthService},
    ),
  },
);

final mainModule = DependyModule(
  providers: {},
  modules: {module1, module2},
);

void main() {
  final apiService = mainModule<ApiService>();
  final paymentService = mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}

```

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
