// In this example, we will demonstrate how to use [ScopedDependyModuleMixin].
//
// [ScopedDependyModuleMixin] can only be applied to a [StatefulWidget].
//
// It provides scoping functionality to the applied [Widget].
//
// Jump to [_MyHomePageState] to continue reading...

import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
import 'package:flutter/material.dart';

import 'services/logger_service.dart';
import 'services/module.dart';
import 'state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example 1 (Using ScopedDependyModuleMixin)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// We apply the [ScopedDependyModuleMixin] to provide scoping.
/// This scoping manages the lifespan of the [Example1State] service.
///
/// [Example1State] will exist as long as [_MyHomePageState] does.
class _MyHomePageState extends State<MyHomePage> with ScopedDependyModuleMixin {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      /// watchDependy is a function from [ScopedDependyModuleMixin].
      /// It accepts only a [ChangeNotifier] and triggers a rebuild each
      /// time a change is notified.
      future: watchDependy<Example1State>(),
      builder: (context, snapshot) {
        final state = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Example 1 (Using ScopedDependyModuleMixin)'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '${state?.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              /// Here we can use the state.incrementCounter() directly.
              ///
              /// But for demonstration purposes, when we do not need to watch a service,
              /// we can use the function `dependy` from [ScopedDependyModuleMixin]
              /// to read the service without watching it.
              final state = await dependy<Example1State>();
              state.incrementCounter();
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  /// This function must be implemented to return a module
  /// that is scoped to the lifespan of the [_MyHomePageState].
  ///
  /// Note: Do not return a singleton module here, as that module will be disposed of
  /// once the [Widget] is removed from the tree.
  /// For example:
  /// ```dart
  ///   return example1ServicesModule; // Do not do this!
  /// ```
  ///
  /// If you are not overriding or providing any extra modules or providers specifically for
  /// this [Widget], you may not need to use the [ScopedDependyModuleMixin].
  @override
  DependyModule moduleBuilder() {
    /// The module scoped to the lifespan of [_MyHomePageState].
    ///
    /// Note: [example1ServicesModule/submodules] won't dispose.
    return DependyModule(
      providers: {
        DependyProvider<Example1State>(
          (dependy) async {
            // Here we resolve the logger service from [example1ServicesModule].
            final logger = await dependy<LoggerService>();

            // We finally return the instance to be used in [_MyHomePageState].
            return Example1State(logger);
          },
          dependsOn: {
            LoggerService, // Our [Example1State] depends on [LoggerService].
          },
        ),
      },
      modules: {
        example1ServicesModule,
      },
    );
  }
}
