# Overrides for Testing

Swap specific providers with `overrideWith()` without modifying the original module.

```dart
import 'package:dependy/dependy.dart';

class HttpClient {
  final String baseUrl;
  HttpClient(this.baseUrl);
  String get(String path) => 'GET $baseUrl$path';
}

class MockHttpClient extends HttpClient {
  MockHttpClient() : super('https://mock.test');
  @override
  String get(String path) => 'MOCK $baseUrl$path';
}

class UserService {
  final HttpClient _client;
  UserService(this._client);
  String fetchUser(int id) => _client.get('/users/$id');
}

final productionModule = DependyModule(
  providers: {
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://api.example.com'),
    ),
    DependyProvider<UserService>(
      (resolve) async => UserService(await resolve<HttpClient>()),
      dependsOn: {HttpClient},
    ),
  },
);

void main() async {
  // Swap HttpClient with a mock and keep everything else
  final testModule = productionModule.overrideWith(
    providers: {
      DependyProvider<HttpClient>((_) => MockHttpClient()),
    },
  );

  final userService = await testModule<UserService>();
  print(userService.fetchUser(42));
  // MOCK https://mock.test/users/42
}
```

## Key Points

- The original module is never modified. Safe for parallel tests.
- Tagged providers are matched by type and tag during override.
- Only the specified providers are swapped; everything else resolves normally.
