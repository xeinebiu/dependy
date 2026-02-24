// In this example, we demonstrate [ScopedDependyAsyncBuilder].
//
// [ScopedDependyAsyncBuilder] resolves an async dependency and provides a
// sealed [AsyncDependySnapshot] to a single builder — replacing the common
// pattern of nesting [ScopedDependyConsumer] with [FutureBuilder].
//
// Compare with example_3, which uses the verbose approach:
//
//   ScopedDependyConsumer(
//     builder: (context, scope) {
//       return FutureBuilder(
//         future: scope.watchDependy<CounterService>(),
//         builder: (context, snapshot) {
//           final counterService = snapshot.data;
//           return Text('${counterService?.counter}');
//         },
//       );
//     },
//   )
//
// With [ScopedDependyAsyncBuilder], the same result is achieved in one widget
// using exhaustive pattern matching:
//
//   ScopedDependyAsyncBuilder<CounterService>(
//     builder: (context, snapshot) => switch (snapshot) {
//       AsyncDependyData(:final value) => Text('${value.counter}'),
//       AsyncDependyError(:final error) => Text('$error'),
//       AsyncDependyLoading() => const CircularProgressIndicator(),
//     },
//   )

import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
import 'package:flutter/material.dart';

import 'services/counter_service.dart';
import 'services/module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example 9 (ScopedDependyAsyncBuilder)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
    return ScopedDependyProvider(
      shareScope: true,
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Example 9 (ScopedDependyAsyncBuilder)'),
          ),
          body: const Center(
            child: CounterView(),
          ),
          floatingActionButton: const CounterButton(),
        );
      },
      moduleBuilder: (_) {
        return DependyModule(
          providers: {},
          modules: {
            example9ServicesModule,
          },
        );
      },
    );
  }
}

/// [CounterButton] resolves [CounterService] on press and calls [increment()].
///
/// No need for [ScopedDependyAsyncBuilder] here — the button doesn't display
/// async data. It simply triggers an action using the shared scope.
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = getDependyScope(context);

    return FloatingActionButton(
      onPressed: () async {
        final counterService = await scope.dependy<CounterService>();
        counterService.increment();
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

/// [CounterView] uses [ScopedDependyAsyncBuilder] to resolve and watch
/// [CounterService], handling all three states with exhaustive pattern matching.
///
/// This replaces the [ScopedDependyConsumer] + [FutureBuilder] nesting
/// shown in example_3.
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyAsyncBuilder<CounterService>(
      /// The sealed [AsyncDependySnapshot] enables exhaustive switch expressions.
      builder: (context, snapshot) => switch (snapshot) {
        AsyncDependyData(:final value) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '${value.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        AsyncDependyError(:final error) => Text('Failed to load: $error'),
        AsyncDependyLoading() => const CircularProgressIndicator(),
      },
    );
  }
}
