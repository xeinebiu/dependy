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

final databaseModule = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
      (_) => DatabaseService(),
    ),
  },
);

final mainModule = DependyModule(
  providers: {
    DependyProvider<ApiService>(
          (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        return ApiService(databaseService);
      },
      dependsOn: {
        DatabaseService,
      },
    ),
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
  modules: {
    databaseModule,
  }
);

void main() async {
  final apiService = await mainModule<ApiService>();
  final paymentService = await mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}
