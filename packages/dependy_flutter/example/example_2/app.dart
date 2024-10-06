// In this example, we will demonstrate how to use [ScopedDependyProvider] widget.

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
      title: 'Example 2 (ScopedDependyProvider)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

/// No [ScopedDependyModuleMixin] is applied and [MyHomePage] is a [StatelessWidget]
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    /// From previous example, we learned how we can use [ScopedDependyModuleMixin]
    ///
    /// This is an alternative way how we can Scope [dependy] modules.
    ///
    /// [ScopedDependyProvider] does accept:
    /// - [builder] function which is used to build the UI and it does provide back
    /// the [BuildContext] and a [scope] object which let's us
    /// access the methods [dependy/watchDependy] as seen on the `example 1`
    ///
    /// - [moduleBuilder] functions which provides to us a [parentModule] and expects
    /// back an instance of [DependyModule] scoped to this [Widget]
    ///
    return ScopedDependyProvider(
      builder: (context, scope) {
        /// Here are are retrieving an instance of [Example2State] but also
        /// watching it for changes.
        ///
        /// Any change emitted by it will trigger a rebuild.
        final state = scope.watchDependy<Example2State>();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Example 2 (ScopedDependyProvider)'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '${state.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              state.incrementCounter();
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        );
      },

      /// This function must be implemented to return a module
      /// that is scoped to the lifespan of the [_MyHomePageState].
      ///
      /// Note: Do not return a singleton module here, as that module will be disposed of
      /// once the [Widget] is removed from the tree.
      /// For example:
      /// ```dart
      ///   return example2ServicesModule; // Do not do this!
      /// ```
      ///
      /// If you are not overriding or providing any extra modules or providers specifically for
      /// this [Widget], you may not need to use the [ScopedDependyModuleMixin].
      moduleBuilder: (_) {
        /// The module scoped to the lifespan of [_MyHomePageState].
        ///
        /// Note: [example2ServicesModule/submodules] won't dispose.
        return DependyModule(
          providers: {
            DependyProvider<Example2State>(
              (dependy) {
                // Here we resolve the logger service from [example2ServicesModule].
                final logger = dependy<LoggerService>();

                // We finally return the instance to be used in [_MyHomePageState].
                return Example2State(logger);
              },
              dependsOn: {
                LoggerService,
                // Our [Example2State] depends on [LoggerService].
              },
            ),
          },
          modules: {
            example2ServicesModule,
          },
        );
      },
    );
  }
}
