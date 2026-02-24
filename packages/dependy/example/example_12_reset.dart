import 'package:dependy/dependy.dart';

class AuthService {
  final String? currentUser;

  AuthService({this.currentUser});

  bool get isLoggedIn => currentUser != null;

  @override
  String toString() => 'AuthService(user: $currentUser)';
}

class UserRepository {
  final AuthService auth;

  UserRepository(this.auth);

  @override
  String toString() => 'UserRepository(auth: $auth)';
}

void main() async {
  final module = DependyModule(
    key: 'app',
    providers: {
      DependyProvider<AuthService>(
        (_) => AuthService(currentUser: 'alice@example.com'),
        dispose: (auth) {
          if (auth != null) {
            print('  Cleaning up session for ${auth.currentUser}');
          }
        },
      ),
      DependyProvider<UserRepository>(
        (resolve) async => UserRepository(await resolve<AuthService>()),
        dependsOn: {AuthService},
      ),
    },
  );

  // --- 1. Initial resolution ---
  final auth = await module.call<AuthService>();
  final repo = await module.call<UserRepository>();
  print('=== Before reset ===');
  print('auth: $auth');
  print('repo: $repo');
  print('repo.auth is same as auth? ${identical(repo.auth, auth)}'); // true
  print(module.debugGraph());

  // --- 2. Reset AuthService — cascades to UserRepository automatically ---
  print('\n=== Resetting AuthService (logout) ===');
  module.reset<AuthService>();
  // Prints: Cleaning up session for alice@example.com

  print(module.debugGraph());
  // Both AuthService and UserRepository are now pending

  // --- 3. Re-resolve — everything is fresh and re-wired ---
  final freshAuth = await module.call<AuthService>();
  final freshRepo = await module.call<UserRepository>();

  print('Same auth? ${identical(auth, freshAuth)}'); // false
  print('Same repo? ${identical(repo, freshRepo)}'); // false
  print(
    'repo got fresh auth? ${identical(freshRepo.auth, freshAuth)}',
  ); // true
}
