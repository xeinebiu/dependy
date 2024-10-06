import 'package:dependy/dependy.dart';

// region Logger
abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print('[Logger]: $message');
  }
}
// endregion

// region Database
abstract class DatabaseService {
  void connect();

  void close();
}

class SqlDatabaseService extends DatabaseService {
  final LoggerService _logger;

  SqlDatabaseService(this._logger);

  @override
  void connect() {
    _logger.log('Connected to Sql Database');
  }

  @override
  void close() {
    _logger.log('Closed Sql Database');
  }
}

class SqliteDatabaseService extends DatabaseService {
  final LoggerService _logger;

  SqliteDatabaseService(this._logger);

  @override
  void connect() {
    _logger.log('Connected to Sqlite Database');
  }

  @override
  void close() {
    _logger.log('Closed Sqlite Database');
  }
}
// endregion

// region Api
abstract class ApiService {
  void fetchData();

  void dispose();
}

class ApiServiceImpl extends ApiService {
  final DatabaseService _db;
  final LoggerService _logger;

  ApiServiceImpl(this._db, this._logger);

  @override
  void fetchData() {
    _logger.log('Fetching data from API...');
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log('Disposing $this');
  }
}

class MockApiService extends ApiService {
  final DatabaseService _db;
  final LoggerService _logger;

  MockApiService(this._db, this._logger);

  @override
  void fetchData() {
    _logger.log('Mocking API data...');
    _db.connect();
  }

  @override
  void dispose() {
    _logger.log('Disposing $this');
  }
}
// endregion

// Singleton module: provides services that live across the application
final singletonModule = DependyModule(
  key: 'singleton_module',
  providers: {
    DependyProvider<LoggerService>(
      (resolve) => ConsoleLoggerService(),
      key: 'singleton_logger_service',
    ),
    DependyProvider<DatabaseService>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return SqlDatabaseService(logger);
      },
      key: 'singleton_database_service',
      dependsOn: {
        LoggerService,
      },
    ),
    DependyProvider<ApiService>(
      (dependy) async {
        final databaseService = await dependy<DatabaseService>();
        final logger = await dependy<LoggerService>();
        return ApiServiceImpl(databaseService, logger);
      },
      key: 'singleton_api_service',
      dependsOn: {
        DatabaseService,
        LoggerService,
      },
    ),
  },
);

// Scoped module: provides services that live temporarily and are disposed when done
final scopedModule = DependyModule(
  key: 'scoped_module',
  providers: {
    // Here we declare a different implementation of DatabaseService [SqliteDatabaseService]
    // for scoped usage. Scoped services are designed to be used in a temporary context.
    DependyProvider<DatabaseService>(
      (dependy) async {
        final logger = await dependy<LoggerService>();
        return SqliteDatabaseService(logger);
      },
      key: 'scoped_database_service',
      dependsOn: {
        LoggerService,
      },
      dispose: (database) {
        // Close the database connections when the [DependyProvider] is disposed.
        database?.close();
      },
    ),
    // A different implementation of ApiService (MockApiService) is provided.
    DependyProvider<ApiService>(
      (dependy) async {
        // will resolve to [SqliteDatabaseService]
        final database = await dependy<DatabaseService>();

        // will resolve from [singletonModule]
        final logger = await dependy<LoggerService>();

        return MockApiService(database, logger);
      },
      dependsOn: {
        DatabaseService,
        LoggerService,
      },
      dispose: (api) {
        // Dispose the api service when the [DependyProvider] is disposed.
        api?.dispose();
      },
    ),
  },
  modules: {
    singletonModule,
    // Makes available all of its providers to the [scopedModule]
  },
);

void main() async {
  print('=== Scoped Module Usage ===');
  final scopedApiService = await scopedModule<ApiService>();
  scopedApiService.fetchData();
  scopedModule.dispose(); // Disposes all services in the [scopedModule]

  // Result:
  // [Logger]: Mocking API data...
  // [Logger]: Connected to Sqlite Database
  // [Logger]: Closed Sqlite Database
  // [Logger]: Disposing Instance of 'MockApiService'

  // Demonstrating the singleton behavior (persistent services)
  print('\n=== Singleton Module Usage After Scoped Module Disposed ===');
  final singletonApiService = await singletonModule<ApiService>();
  singletonApiService.fetchData();

  // Result:
  // [Logger]: Fetching data from API...
  // [Logger]: Connected to Sql Database
}
