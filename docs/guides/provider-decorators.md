# Provider Decorators

Use `decorators` to wrap a resolved instance with composable transformations such as logging, caching, retry logic, and auth headers, without baking them into the factory.

Decorators are applied in list order after the factory runs, inside singleton caching.

## Example

```dart
import 'package:dependy/dependy.dart';

abstract class ApiClient {
  Future<String> get(String path);
}

class HttpApiClient implements ApiClient {
  @override
  Future<String> get(String path) async => 'response from $path';
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
}

class LoggerService {
  void log(String msg) => print('[LOG] $msg');
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
}

final module = DependyModule(
  providers: {
    DependyProvider<LoggerService>((_) => LoggerService()),
    DependyProvider<ApiClient>(
      (_) => HttpApiClient(),
      decorators: [
        // First: wrap with retry
        (client, _) => RetryApiClient(client, maxRetries: 3),
        // Second: wrap with logging (can resolve other providers)
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
  // Resolved: LoggingApiClient -> RetryApiClient -> HttpApiClient

  await client.get('/users');
  // [LOG] GET /users
  // [LOG] Response: response from /users
}
```

## How It Works

- **Singletons** are decorated once and cached.
- **Transients** are decorated on every resolution.
- **Order matters**: first decorator wraps the raw instance, second wraps the first's output, and so on.
- **Decorators can resolve dependencies**: the `resolve` parameter gives access to the full module, not limited by `dependsOn`.
- **`overrideWith`** replaces the whole provider including its decorators.
