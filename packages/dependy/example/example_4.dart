import 'package:dependy/dependy.dart';

class DatabaseService {
  void connect() => print("Connected to Database");
}

class ApiService {
  final DatabaseService _db;

  ApiService(this._db);

  void fetchData() {
    print("Fetching data from API...");
    _db.connect();
  }
}

class AuthService {
  void authenticate() => print("User authenticated");
}

class PaymentService {
  final AuthService _auth;

  PaymentService(this._auth);

  void processPayment() {
    _auth.authenticate();
    print("Payment processed");
  }
}

final module1 = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
      (_) => DatabaseService(),
    ),
    DependyProvider<ApiService>(
      (dependy) => ApiService(dependy<DatabaseService>()),
      dependsOn: {
        DatabaseService,
      },
    ),
  },
);

final module2 = DependyModule(
  providers: {
    DependyProvider<AuthService>(
      (_) => AuthService(),
    ),
    DependyProvider<PaymentService>(
      (dependy) => PaymentService(dependy<AuthService>()),
      dependsOn: {
        AuthService,
      },
    ),
  },
);

final module3 = DependyModule(
  providers: {
    DependyProvider<AuthService>(
      (_) => AuthService(),
    ),
    DependyProvider<PaymentService>(
      (resolve) => PaymentService(resolve<AuthService>()),
      dependsOn: {
        AuthService,
      },
    ),
  },
);

final mainModule = DependyModule(
  providers: {},
  modules: {module1, module2},
);

void main() async {
  final apiService = mainModule<ApiService>();
  final paymentService = mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}