import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('Log: $message');
  }
}

class MathService {
  int square(int number) => number * number;
}

final module = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => LoggerService(),
    ),
    DependyProvider<MathService>(
      (_) => MathService(),
    )
  },
);

void main() async {
  final loggerService = module<LoggerService>();
  final mathService = module<MathService>();

  loggerService.log('Calculating square of 4: ${mathService.square(4)}');
}
