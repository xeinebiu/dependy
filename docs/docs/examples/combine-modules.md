---
sidebar_position: 4
---

# Combine Modules

In this example, we demonstrate how to use Dependy to manage services with dependencies on each other in a modular system. The code demonstrates how to structure and use different modules to create services like `DatabaseService`, `ApiService`, `AuthService`, and `PaymentService`.

### Code Example

```dart
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
          DatabaseService,    // dependsOn DatabaseService which is declared on databaseModule
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
      databaseModule,           // makes the databaseModule providers are accessible from mainModule
    }
);

void main() async {
  final apiService = await mainModule<ApiService>();
  final paymentService = await mainModule<PaymentService>();

  apiService.fetchData();
  paymentService.processPayment();
}

```

---

### Explanation of the Code

#### Service Classes:
- **DatabaseService**: This service is simulating a database connection. The `connect` method prints a message indicating a successful connection.

- **ApiService**: This service depends on `DatabaseService` to cache the data retrieved by api. The `fetchData` method prints a message and then calls `DatabaseService` to simulate a database connection.

- **AuthService**: This service handles user authentication. The `authenticate` method prints a message to simulate user authentication.

- **PaymentService**: This service depends on `AuthService` to authenticate users before processing payments. The `processPayment` method authenticates the user and then prints a message to indicate payment processing.

#### Modules:
- **databaseModule**: Contains the `DatabaseService`.

- **mainModule**: Contains the `ApiService`, `AuthService` and `PaymentService`. `PaymentService` depends on `AuthService` for user authentication, and this is specified within the module.

#### Running the Application:
When you run the application, you should see the following output:
```
Fetching data from API...
Connected to Database
User authenticated
Payment processed
```

This output confirms that the dependencies are resolved correctly, and the services interact as expected.
