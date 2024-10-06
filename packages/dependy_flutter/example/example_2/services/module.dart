import 'package:dependy/dependy.dart';

import 'logger_service.dart';

final example2ServicesModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (resolve) => ConsoleLoggerService(),
    ),
  },
);
