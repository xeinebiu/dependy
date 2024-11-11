---
sidebar_position: 3
---

# Core Concepts

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
lifecycle and resolution of dependencies. A module can also contain other modules, allowing us to organize your
services hierarchically.

Modules help us:

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

#### Use Cases

- **Single Service**: A module can manage a single service that can be used throughout the application (e.g.,
  `LoggerService`).
- **Multiple Services**: A module can manage several unrelated services, allowing us to inject them where necessary (
  e.g., `LoggerService` and `ApiService`).
- **Services with Dependencies**: Providers can depend on each other (e.g., `ApiService` depends on
  `LoggerService`, and `LoggerService` depends on `ConfigService`).
- **Hierarchical Modules**: Large applications can be structured into multiple modules that handle different domains (
  e.g., database services, API services, etc.).

---

### Disposing Providers and Modules

You can dispose of all the providers in a **`DependyModule`** by calling the `dispose` method. This method will invoke
the `dispose` function on each **`DependyProvider`** within the module.

#### Disposing Submodules

If you want to also dispose of all submodules along with their providers, you can use the `dispose` method with the
named argument `disposeSubmodules` set to `true`.
> Default disposeSubmodules:false

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

Keys provide a way to identify specific providers and modules during development. When an exception occurs or when we
log information, the key associated with a provider or module can help us trace back to the source of the issue. This
makes it easier to pinpoint where things went wrong.

#### Example Usage

When creating a provider, you can specify a key like this:

```dart
DependyProvider<MyService>(
    (_) => MyService(),
    key: 'my_service_key',
);
```

---

### Scopes

A **scope** defines the lifetime of a service or object. Scopes determine how long a service stays in memory and when it
should be disposed of. Services can either be short-lived or long-lived, depending on the scope they are placed in.
Here's a breakdown:

1. **Singleton Scope**:
    - Services in this scope live as long as the application is running.
    - They are created once and shared across the entire app.
    - Perfect for services that need to persist throughout the app's lifecycle, such as logging, authentication, or
      configuration services.

2. **Scoped Scope**:
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