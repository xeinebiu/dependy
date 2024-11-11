---
sidebar_position: 2
---

# Multiple Services

In this example, we’ll demonstrate how to use Dependy to manage multiple services within a module and retrieve them when needed. We'll create two simple services, `LoggerService` and `MathService`, register them in a `DependyModule`, and then access and use them in our main function.

```dart
import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('Log: $message');
  }
}

class MathService {
  int square(int number) => number * number;
}

// Define the Dependy module with LoggerService and MathService as providers
final dependy = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => LoggerService(),
    ),
    DependyProvider<MathService>(
      (_) => MathService(),
    ),
  },
);

void main() async {
  // Retrieve instances of LoggerService and MathService from the module
  final loggerService = await dependy<LoggerService>();
  final mathService = await dependy<MathService>();

  // Use the services
  loggerService.log('Calculating square of 4: ${mathService.square(4)}');
}
```

### Explanation of the Code

1. **Creating Services**:
    - **LoggerService**: This service contains a `log` method, which prints a message to the console. It's designed for logging information.
    - **MathService**: This service provides a `square` method, which returns the square of a given integer. It serves as a simple mathematical utility.

2. **Setting up the Dependy Module**:
    - We define a `DependyModule` called `dependy` to organize and manage these services.
    - We add `LoggerService` and `MathService` as providers in the `DependyModule` using `DependyProvider`.
    - Each provider specifies how to create an instance of the respective service. Dependy will create each service only when it’s first requested, as it resolves providers lazily by default.

3. **Retrieving and Using Services**:
    - In the `main` function, we retrieve `LoggerService` and `MathService` by calling `await dependy<LoggerService>()` and `await dependy<MathService>()`.
    - We then use `LoggerService` to log a message, which includes the result of `mathService.square(4)`.

### Key Points on Lazy Resolution
Dependy’s lazy resolution means that neither `LoggerService` nor `MathService` is created until we actually request them in the `main` function. This helps optimize resource usage by avoiding unnecessary service initialization.
