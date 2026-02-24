# Provider Reset

Clear a cached singleton and let it re-create on next access.

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
          if (auth != null) print('Cleaning up: ${auth.currentUser}');
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

  // Reset. Cascades to UserRepository automatically.
  module.reset<AuthService>();
  // Prints: Cleaning up: alice@example.com

  // Re-resolve. Everything is fresh and re-wired.
  final freshAuth = await module<AuthService>();
  final freshRepo = await module<UserRepository>();
  print(identical(auth, freshAuth));             // false
  print(identical(freshRepo.auth, freshAuth));   // true
}
```

## Key Points

- `reset()` calls the dispose callback on the old instance before clearing.
- **Cascades automatically**: providers whose `dependsOn` includes the reset type are also reset.
- No-op for transient providers and disposed providers.
- `EagerDependyModule` does not support `reset()`.
