# Provider Reset

Use `reset<T>()` to clear a cached singleton and let it re-create on next access, without disposing the provider or rebuilding the module.

## When to Use

- Logout flows: reset auth and all dependent services
- Environment switches: swap config and cascade
- Test cleanup: reset state between test cases

## Example

```dart
import 'package:dependy/dependy.dart';

class AuthService {
  final String? currentUser;
  AuthService({this.currentUser});
  bool get isLoggedIn => currentUser != null;
}

class UserRepository {
  final AuthService auth;
  UserRepository(this.auth);
}

void main() async {
  final module = DependyModule(
    providers: {
      DependyProvider<AuthService>(
        (_) => AuthService(currentUser: 'alice@example.com'),
        dispose: (auth) {
          if (auth != null) print('Cleaning up session for ${auth.currentUser}');
        },
      ),
      DependyProvider<UserRepository>(
        (resolve) async => UserRepository(await resolve<AuthService>()),
        dependsOn: {AuthService},
      ),
    },
  );

  final auth = await module<AuthService>();
  final repo = await module<UserRepository>();
  print(identical(repo.auth, auth)); // true

  // Reset AuthService. Cascades to UserRepository automatically.
  module.reset<AuthService>();
  // Prints: Cleaning up session for alice@example.com

  // Re-resolve. Everything is fresh.
  final freshAuth = await module<AuthService>();
  final freshRepo = await module<UserRepository>();
  print(identical(auth, freshAuth)); // false
  print(identical(freshRepo.auth, freshAuth)); // true
}
```

## How It Works

- `reset()` calls the dispose callback on the old instance before clearing.
- The provider stays alive. The next `call()` re-runs the factory and decorators.
- **Cascades automatically**: any cached provider whose `dependsOn` includes the reset type is also reset, transitively.
- No-op for transient providers (nothing cached) and disposed providers.
- `EagerDependyModule` does **not** support `reset()`.
