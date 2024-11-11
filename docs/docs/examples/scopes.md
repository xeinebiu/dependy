---
sidebar_position: 5
---

# Scopes

This example demonstrates how to use `Dependy` to manage scoped services alongside singleton services in a Dart application.

## Overview

- **Scoped Services**: These services are created and disposed of within a specific scope. They are useful when you need a temporary service that should not persist beyond the context of a particular operation or request.

- **Singleton Services**: These services are created once and live for the duration of the application. They are shared across the app and remain active until the application ends.

In this example, we have:

1. A **LoggerService** that logs messages.
2. A **DatabaseService** with two implementations: `SqlDatabaseService` and `SqliteDatabaseService`.
3. An **ApiService** that fetches data, with two implementations: `ApiServiceImpl` (real API service) and `MockApiService` (mocked service for testing).

The example demonstrates how to configure these services with `Dependy` and use them within both a **singleton** and **scoped** module.

---

## Services

### LoggerService
The `LoggerService` is an abstract class used for logging messages.

#### Implementation

```dart
class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print('[Logger]: $message');
  }
}
```

### DatabaseService
The `DatabaseService` is an abstract class for managing database connections. There are two implementations:

- `SqlDatabaseService`: Simulates a connection to an SQL database.
- `SqliteDatabaseService`: Simulates a connection to a SQLite database.

#### Implementation

```dart
class SqlDatabaseService extends DatabaseService {
  SqlDatabaseService(this._logger);

  final LoggerService _logger;

  @override
  void connect() {
    _logger.log('Connected to Sql Database');
  }

  @override
  void close() {
    _logger.log('Closed Sql Database');
  }
}
```

```dart
class SqliteDatabaseService extends DatabaseService {
  SqliteDatabaseService(this._logger);

  final LoggerService _logger;

  @override
  void connect() {
    _logger.log('Connected to Sqlite Database');
  }

  @override
  void close() {
    _logger.log('Closed Sqlite Database');
  }
}
```

### ApiService
The `ApiService` abstract class defines methods for fetching data and disposing of resources.

There are two implementations:

- `ApiServiceImpl`: A real API service.
- `MockApiService`: A mock API service for testing.

#### Implementation

```dart
class ApiServiceImpl extends ApiService {
  ApiServiceImpl(this._db, this._logger);

  final DatabaseService _db;
  final LoggerService _logger;

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
```

```dart
class MockApiService extends ApiService {
  MockApiService(this._db, this._logger);

  final DatabaseService _db;
  final LoggerService _logger;

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
```

---

## Modules

### Singleton Module

The `singletonModule` defines services that are created once and shared throughout the application. These services are available globally.

```dart
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
      dependsOn: {LoggerService},
    ),
    DependyProvider<ApiService>(
      (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        final logger = await dependy<LoggerService>();
        return ApiServiceImpl(databaseService, logger);
      },
      key: 'singleton_api_service',
      dependsOn: {DatabaseService, LoggerService},
    ),
  },
);
```

### Scoped Module

The `scopedModule` defines services that are scoped to a specific context or operation. These services are disposed of once the scope ends.

```dart
final scopedModule = DependyModule(
  key: 'scoped_module',
  providers: {
    // override the DatabaseService from singletonModule
    DependyProvider<DatabaseService>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return SqliteDatabaseService(logger);
      },
      key: 'scoped_database_service',
      dependsOn: {LoggerService},
      
      // called when the scopedModule is disposed
      dispose: (database) {
        database?.close();
      },
    ),
    
    // override the ApiService from singletonModule
    DependyProvider<ApiService>(
      (dependy) async {
        final database = await dependy<DatabaseService>();
        final logger = await dependy<LoggerService>();
        return MockApiService(database, logger);
      },
      dependsOn: {DatabaseService, LoggerService},

      // called when the scopedModule is disposed
      dispose: (api) {
        api?.dispose();
      },
    ),
  },
  modules: {singletonModule},
);
```

---

## Usage Example

### Scoped Module Usage

The following code demonstrates how to use the `scopedModule` to fetch data from a mock API. After the task is done, the scoped services are disposed of.

```dart
void main() async {
  print('=== Scoped Module Usage ===');
  final scopedApiService = await scopedModule<ApiService>();
  scopedApiService.fetchData();
  scopedModule.dispose(); // Disposes all services in the scoped module

  // Output:
  // [Logger]: Mocking API data...
  // [Logger]: Connected to Sqlite Database
  // [Logger]: Closed Sqlite Database
  // [Logger]: Disposing Instance of 'MockApiService'
}
```

### Singleton Module Usage

After the `scopedModule` is disposed of, we can use the singleton services to fetch data from a real API.

```dart
  // Singleton Module Usage
  print('\n=== Singleton Module Usage After Scoped Module Disposed ===');
  final singletonApiService = await singletonModule<ApiService>();
  singletonApiService.fetchData();

  // Output:
  // [Logger]: Fetching data from API...
  // [Logger]: Connected to Sql Database
}
```

---

## Key Concepts

- **Scoped Services**: Temporary services that are disposed of when they are no longer needed. Ideal for situations like request-based services.
- **Singleton Services**: Persistent services that are created once and shared across the entire application.

