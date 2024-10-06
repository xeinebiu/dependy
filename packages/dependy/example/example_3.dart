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

final dependy = DependyModule(
  providers: {
    DependyProvider<ConfigService>(
      (_) => ConfigService(),
    ),
    DependyProvider<LoggerService>(
      (dependy) async {
        final configService = await dependy<ConfigService>();
        return LoggerService(configService);
      },
      dependsOn: {
        ConfigService,
      },
    ),
    DependyProvider<CalculatorService>(
      (dependy) async {
        final loggerService = await dependy<LoggerService>();
        return CalculatorService(loggerService);
      },
      dependsOn: {
        LoggerService,
      },
    ),
  },
);

void main() async {
  final calculatorService = await dependy<CalculatorService>();

  print('Result: ${calculatorService.multiply(3, 5)}');
}
