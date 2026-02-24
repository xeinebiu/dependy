import 'package:dependy/dependy.dart';

// A simple HttpClient that connects to a specific base URL.
class HttpClient {
  final String baseUrl;

  HttpClient(this.baseUrl);

  String get(String path) => 'GET $baseUrl$path';
}

// A service that uses the API-specific HttpClient.
class UserService {
  final HttpClient _client;

  UserService(this._client);

  String fetchUser(int id) => _client.get('/users/$id');
}

// A service that uses the CDN-specific HttpClient.
class CacheService {
  final HttpClient _client;

  CacheService(this._client);

  String fetchAsset(String name) => _client.get('/assets/$name');
}

void main() async {
  final module = DependyModule(
    providers: {
      // Two HttpClient providers distinguished by tag
      DependyProvider<HttpClient>(
        (_) => HttpClient('https://api.example.com'),
        tag: 'api',
      ),
      DependyProvider<HttpClient>(
        (_) => HttpClient('https://cdn.example.com'),
        tag: 'cdn',
      ),

      // UserService depends on the 'api' HttpClient
      DependyProvider<UserService>(
        (resolve) async {
          final client = await resolve<HttpClient>(tag: 'api');
          return UserService(client);
        },
        dependsOn: {HttpClient},
      ),

      // CacheService depends on the 'cdn' HttpClient
      DependyProvider<CacheService>(
        (resolve) async {
          final client = await resolve<HttpClient>(tag: 'cdn');
          return CacheService(client);
        },
        dependsOn: {HttpClient},
      ),
    },
  );

  // Resolve tagged instances directly
  final apiClient = await module<HttpClient>(tag: 'api');
  final cdnClient = await module<HttpClient>(tag: 'cdn');

  print(apiClient.get('/health')); // GET https://api.example.com/health
  print(cdnClient.get('/logo.png')); // GET https://cdn.example.com/logo.png

  // Resolve services that internally use tagged dependencies
  final userService = await module<UserService>();
  final cacheService = await module<CacheService>();

  print(userService.fetchUser(42)); // GET https://api.example.com/users/42
  print(cacheService
      .fetchAsset('style.css')); // GET https://cdn.example.com/assets/style.css
}
