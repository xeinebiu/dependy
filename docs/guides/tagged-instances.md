# Tagged Instances

Use `tag` to register multiple providers of the same type within a single module.

## When to Use

- Multiple HTTP clients pointing to different base URLs
- Different database connections (read replica vs primary)
- Environment-specific configurations

## Example

```dart
import 'package:dependy/dependy.dart';

class HttpClient {
  final String baseUrl;
  HttpClient(this.baseUrl);
  String get(String path) => 'GET $baseUrl$path';
}

class UserService {
  final HttpClient _client;
  UserService(this._client);
  String fetchUser(int id) => _client.get('/users/$id');
}

final module = DependyModule(
  providers: {
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://api.example.com'),
      tag: 'api',
    ),
    DependyProvider<HttpClient>(
      (_) => HttpClient('https://cdn.example.com'),
      tag: 'cdn',
    ),
    DependyProvider<UserService>(
      (resolve) async {
        final client = await resolve<HttpClient>(tag: 'api');
        return UserService(client);
      },
      dependsOn: {HttpClient},
    ),
  },
);

void main() async {
  final apiClient = await module<HttpClient>(tag: 'api');
  final cdnClient = await module<HttpClient>(tag: 'cdn');

  print(apiClient.get('/health'));   // GET https://api.example.com/health
  print(cdnClient.get('/logo.png')); // GET https://cdn.example.com/logo.png

  final users = await module<UserService>();
  print(users.fetchUser(42)); // GET https://api.example.com/users/42
}
```

:::info
`dependsOn` remains `Set<Type>`. Tags are a routing detail inside factories, not a dependency declaration.
:::
