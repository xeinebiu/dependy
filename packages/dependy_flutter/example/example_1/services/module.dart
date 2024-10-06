import 'package:dependy/dependy.dart';

import 'logger_service.dart';

final example1ServicesModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => ConsoleLoggerService(),
    ),
  },
);
