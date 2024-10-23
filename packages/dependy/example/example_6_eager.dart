import 'package:dependy/dependy.dart';

class ConfigService {
  ConfigService(this.apiUrl);

  final String apiUrl;
}

class LoggerService {
  void log(String message) {
    print("LOG: $message");
  }
}

class DatabaseService {
  DatabaseService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void connect() {
    logger.log("Connecting to database at ${config.apiUrl}");
  }
}

class ApiService {
  ApiService(this.config, this.logger);

  final ConfigService config;
  final LoggerService logger;

  void fetchData() {
    logger.log("Fetching data from API at ${config.apiUrl}");
  }
}

void main() async {
  final eagerModule = await DependyModule(
    providers: {
      DependyProvider<ConfigService>(
        (resolve) async => ConfigService("https://api.example.com"),
      ),
      DependyProvider<LoggerService>(
        (resolve) async => LoggerService(),
      ),
      DependyProvider<DatabaseService>(
        (resolve) async => DatabaseService(
          await resolve<ConfigService>(),
          await resolve<LoggerService>(),
        ),
        dependsOn: {ConfigService, LoggerService},
      ),
      DependyProvider<ApiService>(
        (resolve) async => ApiService(
          await resolve<ConfigService>(),
          await resolve<LoggerService>(),
        ),
        dependsOn: {ConfigService, LoggerService},
      ),
    },
  ).asEager(); // Convert to an EagerDependyModule using asEager extension

  // Now, retrieve the services synchronously
  final dbService = eagerModule<DatabaseService>();
  dbService.connect();

  final apiService = eagerModule<ApiService>();
  apiService.fetchData();
}
