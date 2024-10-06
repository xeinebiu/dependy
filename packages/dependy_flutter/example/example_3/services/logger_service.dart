abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print("ConsoleLogger: $message");
  }
}
