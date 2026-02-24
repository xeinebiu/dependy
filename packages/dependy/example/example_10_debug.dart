import 'package:dependy/dependy.dart';

class LoggerService {
  final String tag;

  LoggerService([this.tag = 'APP']);
}

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
  print('=== Before resolution ===');
  print(module.debugGraph());

  // Resolve DatabaseService (which also resolves LoggerService)
  await module.call<DatabaseService>();

  print('');
  print('=== After resolving DatabaseService ===');
  print(module.debugGraph());

  // Dispose the module
  module.dispose();

  print('');
  print('=== After disposal ===');
  print(module.debugGraph());
}
