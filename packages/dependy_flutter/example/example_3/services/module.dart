import 'package:dependy/dependy.dart';

import 'counter_service.dart';
import 'logger_service.dart';

final example3ServicesModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
      (_) => ConsoleLoggerService(),
    ),
    DependyProvider<CounterService>(
      (dependy) async {
        final loggerService = await dependy<LoggerService>();
        return CounterServiceImpl(1, loggerService);
      },
      dependsOn: {
        LoggerService,
      },
    ),
  },
);
