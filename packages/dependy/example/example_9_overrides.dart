import 'package:dependy/dependy.dart';

// --- Production services ---

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

// --- Mock for testing ---

class MockHttpClient extends HttpClient {
  MockHttpClient() : super('https://mock.test');

  @override
  String get(String path) => 'MOCK $baseUrl$path';
}

// --- Module setup ---

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
  // Production usage
  final userService = await productionModule<UserService>();
  print(userService.fetchUser(42));
  // GET https://api.example.com/users/42

  // Test — swap HttpClient with a mock, keep everything else
  final testModule = productionModule.overrideWith(
    providers: {
      DependyProvider<HttpClient>((_) => MockHttpClient()),
    },
  );

  final testUserService = await testModule<UserService>();
  print(testUserService.fetchUser(42));
  // MOCK https://mock.test/users/42

  // Original module is untouched — safe for parallel tests
  final original = await productionModule<HttpClient>();
  print(original.baseUrl);
  // https://api.example.com
}
