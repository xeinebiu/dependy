# Debug Graph

Use `debugGraph()` to inspect the module tree during development. It returns a formatted ASCII string showing every provider and submodule with its type, tag, lifecycle, resolution status, and decorator count.

## Example

```dart
import 'package:dependy/dependy.dart';

class LoggerService {}
class DatabaseService {
  final LoggerService logger;
  DatabaseService(this.logger);
}
class HttpRequest {}

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
      },
    ),
  },
);

void main() async {
  // Before resolution
  print(module.debugGraph());
  // DependyModule (key: app)
  // +-- LoggerService [singleton] - pending
  // +-- DatabaseService [singleton] - pending
  // |    dependsOn: {LoggerService}
  // +-- HttpRequest [transient] - always new
  // \-- [module] DependyModule (key: http_module)
  //     \-- HttpClient #api [singleton] - pending

  // After resolving DatabaseService
  await module<DatabaseService>();
  print(module.debugGraph());
  // +-- LoggerService [singleton] - cached
  // +-- DatabaseService [singleton] - cached

  // After disposal
  module.dispose();
  print(module.debugGraph());
  // DependyModule (key: app) [DISPOSED]
}
```

`EagerDependyModule` also supports `debugGraph()`.
