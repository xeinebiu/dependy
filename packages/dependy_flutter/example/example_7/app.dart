import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
import 'package:flutter/material.dart';

import 'services/counter_service.dart';
import 'services/logger_service.dart';

/// Here we use [EagerDependyModule] instead of [DependyModule]
///
/// [EagerDependyModule] should allow to retrieve services synchronously
///
/// Note: Services are still resolved asynchronous, that is why we have to await for creation of [EagerDependyModule[
late final EagerDependyModule dependy;

Future<void> _initDependy() async {
  dependy = await DependyModule(
    providers: {
      DependyProvider<LoggerService>(
        (_) => ConsoleLoggerService(),
      ),
      DependyProvider<CounterService>(
        (dependy) async {
          final loggerService = await dependy<LoggerService>();

          return CounterServiceImpl(5, loggerService);
        },
        dependsOn: {
          LoggerService,
        },
      ),
    },
  ).asEager(); // Use asEager to eagerly initialize dependencies and allow synchronous access
}

Future<void> main() async {
  // Initialize the global [dependy] and make it synchronous
  await _initDependy();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example 7 (EagerDependyModule)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Example 7 (EagerDependyModule)',
        ),
      ),
      body: const Center(
        child: CounterView(),
      ),
      floatingActionButton: const CounterButton(),
    );
  }
}

/// [CounterButton] is responsible for incrementing the counter value.
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Access LoggerService synchronously
        final loggerService = dependy<LoggerService>();
        loggerService.log('CounterButton onPressed');

        // Access CounterService synchronously
        final counterService = dependy<CounterService>();
        counterService.increment();
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

/// [CounterView] is responsible for displaying the current counter value.
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    // Access CounterService synchronously
    final counterService = dependy<CounterService>();

    /// Since we do not use "watchDependy", we will use here [DependyNotifierListener]
    ///
    /// `watchDependy` is available only on scopes, since here we use a singleton module, `watchDependy` is not available.
    return DependyNotifierListener(
      notifier: counterService, // Listen for updates from CounterService
      builder: (context, notifier) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${counterService.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        );
      },
    );
  }
}
