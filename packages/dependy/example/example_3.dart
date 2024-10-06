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

final module = DependyModule(
  providers: {
    DependyProvider<ConfigService>(
      (_) => ConfigService(),
    ),
    DependyProvider<LoggerService>(
      (dependy) => LoggerService(dependy<ConfigService>()),
      dependsOn: {
        ConfigService,
      },
    ),
    DependyProvider<CalculatorService>(
      (dependy) => CalculatorService(dependy<LoggerService>()),
      dependsOn: {
        LoggerService,
      },
    ),
  },
);

void main() async {
  final calculatorService = module<CalculatorService>();

  print('Result: ${calculatorService.multiply(3, 5)}');
}
