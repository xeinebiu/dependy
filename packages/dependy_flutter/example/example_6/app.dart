// Same usecase as on `example-5` but using [ScopedDependyProvider]

import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
import 'package:flutter/material.dart';

import 'services/counter_service.dart';
import 'services/logger_service.dart';

void main() {
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
    return ScopedDependyProvider(
      builder: (context, scope) {
        return MaterialApp(
          title:
              'Example 6 (Share Multiple Scopes using ScopedDependyProvider)',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(),
        );
      },
      moduleBuilder: (_) {
        return DependyModule(
          providers: {
            // Provide the Logger service on the widget scope
            DependyProvider<LoggerService>(
              (_) => ConsoleLoggerService(),
            ),
          },
          modules: {},
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return ScopedDependyProvider(
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text(
              'Example 6 (Share Multiple Scopes using ScopedDependyProvider)',
            ),
          ),
          body: const Center(
            child: CounterView(),
          ),
          floatingActionButton: const CounterButton(),
        );
      },
      moduleBuilder: (parentModule) {
        return DependyModule(
          providers: {
            // Provide the [CounterService] on the widget scope
            DependyProvider<CounterService>(
              (dependy) {
                final loggerService = dependy<LoggerService>();

                // increment step of 5
                return CounterServiceImpl(5, loggerService);
              },
              dependsOn: {
                LoggerService,
              },
            ),
          },
          modules: {
            // We are importing the parent module
            parentModule(),
          },
        );
      },
    );
  }
}

/// [CounterButton] is responsible for incrementing the counter value.
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyConsumer(
      builder: (context, scope) {
        return FloatingActionButton(
          onPressed: () {
            // [LoggerService] lives two scopes on this example higher.
            scope.dependy<LoggerService>().log("CounterButton onPressed");

            /// When the button is pressed, we call [increment()] to update the counter.
            scope.dependy<CounterService>().increment();
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        );
      },
    );
  }
}

/// [CounterView] is responsible for displaying the current counter value.
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyConsumer(
      builder: (context, scope) {
        /// Here we are watching [CounterService] and rebuilding the latest counter value.
        final counterService = scope.watchDependy<CounterService>();

        // [LoggerService] lives two scopes on this example higher.
        scope.dependy<LoggerService>().log("CounterView build");

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
