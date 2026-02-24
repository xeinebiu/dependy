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

/// Decorator: adds retry logic
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
  String toString() => 'RetryApiClient(maxRetries: $maxRetries, inner: $_inner)';
}

class LoggerService {
  void log(String message) => print('[LOG] $message');
}

/// Decorator: adds logging
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

void main() async {
  final module = DependyModule(
    key: 'app',
    providers: {
      DependyProvider<LoggerService>((_) => LoggerService()),
      DependyProvider<ApiClient>(
        (_) => HttpApiClient(),
        decorators: [
          // First decorator: wrap with retry
          (client, _) => RetryApiClient(client, maxRetries: 3),
          // Second decorator: wrap with logging (resolves LoggerService)
          (client, resolve) async {
            final logger = await resolve<LoggerService>();
            return LoggingApiClient(client, logger);
          },
        ],
      ),
    },
  );

  // Resolve the decorated client
  final client = await module.call<ApiClient>();

  // Shows: LoggingApiClient(inner: RetryApiClient(maxRetries: 3, inner: HttpApiClient))
  print('Resolved: $client');

  // Use it
  final response = await client.get('/users');
  print('Got: $response');

  // Debug graph shows decorator count
  print('\n${module.debugGraph()}');
}
