---
sidebar_position: 6
---

# Eager Module

This example demonstrates how to use the `Dependy` library to create an eager-loaded module where all dependencies are resolved synchronously. The `asEager()` extension allows you to eagerly resolve and instantiate services immediately when the module is created, rather than lazily resolving them on demand.

## Overview

In this example, we define several services and use the `DependyModule` to manage their dependencies:

1. **ConfigService**: Provides configuration information, like the API URL.
2. **LoggerService**: Logs messages.
3. **DatabaseService**: Represents a database connection, which depends on `ConfigService` and `LoggerService`.
4. **ApiService**: Represents an API service, also depending on `ConfigService` and `LoggerService`.

We will use the `asEager()` extension to make all services available immediately when the module is created.

---

## Services

### ConfigService

This service holds the configuration, such as the API URL.

```dart
class ConfigService {
  ConfigService(this.apiUrl);

  final String apiUrl;
}
```

### LoggerService

This service is responsible for logging messages.

```dart
class LoggerService {
  void log(String message) {
    print("LOG: $message");
  }
}
```

### DatabaseService

The `DatabaseService` simulates a connection to a database. It depends on both `ConfigService` and `LoggerService` to log the connection details.

```dart
class DatabaseService {
  DatabaseService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void connect() {
    logger.log("Connecting to database at ${config.apiUrl}");
  }
}
```

### ApiService

The `ApiService` fetches data from an API, also requiring the `ConfigService` for the API URL and `LoggerService` for logging.

```dart
class ApiService {
  ApiService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void fetchData() {
    logger.log("Fetching data from API at ${config.apiUrl}");
  }
}
```

---

## Eager Module Setup

In the `main` function, we create an eager module that resolves all services synchronously using the `asEager()` extension. This means all dependencies will be resolved and the services will be instantiated as soon as the module is created.

```dart
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

  // Retrieve the services synchronously
  final dbService = eagerModule<DatabaseService>();
  dbService.connect();

  final apiService = eagerModule<ApiService>();
  apiService.fetchData();
}
```

### Key Points

1. **Eager Loading**: The `asEager()` extension eagerly resolves all dependencies and makes them available immediately after module creation.
2. **Service Retrieval**: Services can be retrieved synchronously after the module is created, making it simpler to use the services without waiting for async resolution.

---

## Expected Output

When the application runs, the following output will be printed to the console:

```
LOG: Connecting to database at https://api.example.com
LOG: Fetching data from API at https://api.example.com
```

---
