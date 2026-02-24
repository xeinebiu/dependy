# Core Concepts

## DependyProvider

A `DependyProvider<T>` defines how to create an instance of type `T`. Each provider has:

- A **factory** function that creates the instance.
- An optional `dependsOn` set declaring which types it needs.
- An optional `dispose` callback for cleanup.
- An optional `tag` for registering multiple providers of the same type.
- An optional `transient: true` flag for creating a fresh instance on every resolution.
- An optional `decorators` list for wrapping the resolved instance.

```dart
DependyProvider<LoggerService>(
  (_) => ConsoleLoggerService(),
);
```

A provider with dependencies:

```dart
DependyProvider<ApiService>(
  (resolve) async {
    final logger = await resolve<LoggerService>();
    return ApiService(logger);
  },
  dependsOn: {LoggerService},
);
```

## DependyModule

A `DependyModule` is a container for providers. Modules can nest other modules, letting you organize services hierarchically.

```dart
final appModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>((_) => ConsoleLoggerService()),
    DependyProvider<ApiService>(
      (resolve) async => ApiService(await resolve<LoggerService>()),
      dependsOn: {LoggerService},
    ),
  },
);
```

### Combining Modules

Group related services into separate modules and compose them:

```dart
final dbModule = DependyModule(
  providers: {
    DependyProvider<DatabaseService>((_) => DatabaseService()),
  },
);

final appModule = DependyModule(
  providers: {
    DependyProvider<ApiService>(
      (resolve) async => ApiService(await resolve<DatabaseService>()),
      dependsOn: {DatabaseService},
    ),
  },
  modules: {dbModule},
);
```

Providers in `appModule` can resolve types from `dbModule`.

## Scopes and Lifetimes

### Singleton (default)

Created once, cached, shared across all resolutions:

```dart
DependyProvider<LoggerService>((_) => LoggerService());
```

### Transient

A new instance on every resolution. Nothing is cached:

```dart
DependyProvider<FormValidator>(
  (_) => FormValidator(),
  transient: true,
);
```

:::warning Captive dependency
A singleton provider **cannot** depend on a transient provider. Dependy detects this at module construction and throws `DependyCaptiveDependencyException`.
:::

### Scoped

Services tied to a specific module's lifetime. When the module is disposed, its scoped services are disposed too. This is especially useful in Flutter with `ScopedDependyMixin` and `ScopedDependyProvider`.

## Tagged Instances

Register multiple providers of the same type using `tag`:

```dart
DependyProvider<HttpClient>(
  (_) => HttpClient('https://api.example.com'),
  tag: 'api',
),
DependyProvider<HttpClient>(
  (_) => HttpClient('https://cdn.example.com'),
  tag: 'cdn',
),
```

Resolve by tag:

```dart
final apiClient = await module<HttpClient>(tag: 'api');
final cdnClient = await module<HttpClient>(tag: 'cdn');
```

## Disposing

Dispose all providers in a module:

```dart
module.dispose();
```

To also dispose submodules:

```dart
module.dispose(disposeSubmodules: true);
```

:::warning Using a disposed module
Resolving from a disposed module throws `DependyModuleDisposedException`. Always check a module is still active before resolving.
:::

## Keys

Keys identify providers and modules in error messages and debug output:

```dart
DependyProvider<MyService>(
  (_) => MyService(),
  key: 'my_service',
);
```

## Next Steps

- [Exceptions](./exceptions): Errors Dependy can throw
- [Guides](/guides/transient-providers): Transient providers, tagged instances, decorators, and more
- [Examples](/examples/counter-service): See these concepts in practice
