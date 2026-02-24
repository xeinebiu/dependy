# Debug Graph

Inspect the module tree with `debugGraph()`.

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
);

void main() async {
  // Before resolution. All singletons are pending.
  print(module.debugGraph());
  // DependyModule (key: app)
  // +-- LoggerService [singleton] - pending
  // +-- DatabaseService [singleton] - pending
  // |    dependsOn: {LoggerService}
  // +-- HttpRequest [transient] - always new

  // Resolve DatabaseService (also resolves LoggerService)
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

## What It Shows

- Provider type, tag, and lifecycle (singleton/transient)
- Resolution status (pending, cached, always new)
- `dependsOn` declarations
- Decorator counts
- Nested submodules
- Disposed state
