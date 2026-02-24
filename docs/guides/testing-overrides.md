# Testing with Overrides

Use `overrideWith()` to swap specific providers for tests or mocking, without rebuilding the module tree. The original module is not modified.

## Example

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
  // Swap HttpClient with a mock. Everything else stays the same.
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

## Overriding Tagged Providers

Tags are matched during override, so only the provider with the same type and tag is replaced:

```dart
final testTagged = taggedModule.overrideWith(
  providers: {
    DependyProvider<HttpClient>(
      (_) => MockHttpClient(),
      tag: 'api',
    ),
  },
);
```

:::info
The original module is never modified. `overrideWith` returns a new module, making it safe for parallel tests.
:::
