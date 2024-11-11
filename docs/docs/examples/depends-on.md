---
sidebar_position: 3
---

# Depends on

In this example, we demonstrate how Dependy handles services with dependencies on other services, using a configuration service (`ConfigService`), a logging service (`LoggerService`), and a calculator service (`CalculatorService`).

### Code Example

```dart
import 'package:dependy/dependy.dart';

class ConfigService {
  final String appName = 'DependyExample';
}

class LoggerService {
  final ConfigService _config;

  LoggerService(this._config);

  void log(String message) {
    print('${_config.appName}: $message');
  }
}

class CalculatorService {
  final LoggerService _logger;

  CalculatorService(this._logger);

  int multiply(int a, int b) {
    _logger.log('Multiplying $a and $b');
    return a * b;
  }
}

// Define the Dependy module with dependencies
final dependy = DependyModule(
  providers: {
    // Register ConfigService as a provider, without dependencies
    DependyProvider<ConfigService>(
          (_) => ConfigService(),
    ),

    // Register LoggerService as a provider with ConfigService as its dependency
    DependyProvider<LoggerService>(
      // The 'dependy' parameter here allows us to access other providers in this module
          (dependy) async {
        // Retrieve the ConfigService dependency using 'dependy<ConfigService>()'
        final configService = await dependy<ConfigService>();

        // Now create and return the LoggerService instance, injecting ConfigService into it
        return LoggerService(configService);
      },
      dependsOn: {ConfigService}, // Specifies ConfigService as a dependency
    ),

    // Register CalculatorService as a provider with LoggerService as its dependency
    DependyProvider<CalculatorService>(
          (dependy) async {
        // Retrieve LoggerService using 'dependy<LoggerService>()' before creating CalculatorService
        final loggerService = await dependy<LoggerService>();

        // Create and return CalculatorService with LoggerService injected
        return CalculatorService(loggerService);
      },
      dependsOn: {LoggerService}, // Specifies LoggerService as a dependency
    ),
  },
);


void main() async {
  final calculatorService = await dependy<CalculatorService>();

  print('Result: ${calculatorService.multiply(3, 5)}');
}
```

---

### Explanation of the Code

#### Service Classes:
- **ConfigService**: Holds a simple configuration value, `appName`, used by `LoggerService` for logging.
- **LoggerService**: Depends on `ConfigService` to prefix log messages with the application name. This dependency is injected through the constructor.
- **CalculatorService**: Depends on `LoggerService` and uses it to log each calculation before returning the result. This dependency is also injected through the constructor.

#### Setting Up the Dependy Module:
- The `dependy` module contains providers for each service, registered independently of their order. Dependy automatically manages dependencies, so you don’t have to worry about the order of declaration.
- **ConfigService**: Registered as a provider without any dependencies.
- **LoggerService**: Registered with an asynchronous factory function that retrieves `ConfigService` before creating the `LoggerService` instance.
- **CalculatorService**: Registered similarly, with a dependency on `LoggerService`.

#### Using the Services:
- In `main`, we retrieve `CalculatorService` from `DependyModule` and use it to call `multiply`. This action triggers `LoggerService` to log the operation, showcasing Dependy’s dependency injection in action.
