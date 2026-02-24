# Tagged Instances

Register multiple providers of the same type using `tag`. Resolve by tag.

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

class CacheService {
  final HttpClient _client;
  CacheService(this._client);
  String fetchAsset(String name) => _client.get('/assets/$name');
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
    DependyProvider<CacheService>(
      (resolve) async {
        final client = await resolve<HttpClient>(tag: 'cdn');
        return CacheService(client);
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

## Key Points

- Each tagged provider is resolved independently.
- Inside factories, forward the tag: `resolve<T>(tag: 'name')`.
- `dependsOn` remains `Set<Type>`. Tags are a routing detail, not a dependency declaration.
