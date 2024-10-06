import 'package:dependy/dependy.dart';

class LoggerService {
  void log(String message) {
    print('Log: $message');
  }
}

class MathService {
  int square(int number) => number * number;
}

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
  final loggerService = await dependy<LoggerService>();
  final mathService = await dependy<MathService>();

  loggerService.log('Calculating square of 4: ${mathService.square(4)}');
}
