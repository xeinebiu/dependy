import 'package:dependy/dependy.dart';

class DatabaseService {
  void connect() => print('Connected to Database');
}

class ApiService {
  final DatabaseService _db;

  ApiService(this._db);

  void fetchData() {
    print('Fetching data from API...');
    _db.connect();
  }
}

class AuthService {
  void authenticate() => print('User authenticated');
}

class PaymentService {
  final AuthService _auth;

  PaymentService(this._auth);

  void processPayment() {
    _auth.authenticate();
    print('Payment processed');
  }
}

final module1 = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
      (_) => DatabaseService(),
    ),
    DependyProvider<ApiService>(
      (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        return ApiService(databaseService);
      },
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
      (dependy) async {
        final authService = await dependy<AuthService>();
        return PaymentService(authService);
      },
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
      (dependy) async {
        final authService = await dependy<AuthService>();
        return PaymentService(authService);
      },
      dependsOn: {
        AuthService,
      },
    ),
  },
);

final mainModule = DependyModule(
  providers: {},
  modules: {
    module1,
    module2,
  },
);

void main() async {
  final apiService = await mainModule<ApiService>();
  final paymentService = await mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}
