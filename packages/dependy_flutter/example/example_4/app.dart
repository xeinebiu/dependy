// From the `example-3` we learned about sharing scope using [ScopedDependyProvider]
//
// On this example, we are about to use [ScopedDependyMixin]
//
// Jump to [_MyHomePageState] to continue reading...

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
      title: 'Example 4 (Share Scope ScopedDependyMixin)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    /// While on [ScopedDependyProvider] we could set shareScope: true, using
    /// [ScopedDependyMixin] we can invoke [shareDependyScope] which
    /// does achieve the exact same thing.
    return shareDependyScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Example 4 (Share Scope ScopedDependyMixin)'),
        ),
        body: const Center(
          /// Notice that we are not passing any state directly to [CounterView].
          /// Instead, it will access the shared scope and retrieve the state it needs.
          child: CounterView(),
        ),

        /// Similarly, [CounterButton] will also use the shared scope to
        /// access the [CounterService] and modify its state.
        floatingActionButton: const CounterButton(),
      ),
    );
  }

  @override
  DependyModule moduleBuilder() {
    /// Notice that something is different from previous example.
    ///
    /// Since [CounterService] lives inside [example4ServicesModule], we are not providing it.
    ///
    /// If we need to override it, we can provide one in `providers`.
    ///
    /// Note: As we learned in previous example, we should not return [example4ServicesModule] directly
    /// from this function because when the Widget is removed from the tree, it will be disposed of. (Submodules won't be.)
    return DependyModule(
      providers: {},
      modules: {
        example4ServicesModule,
      },
    );
  }
}

/// [CounterButton] is responsible for incrementing the counter value.
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = getDependyScope(context);
    return FloatingActionButton(
      onPressed: () async {
        /// When the button is pressed, we call [increment()] to update the counter.
        final counterService = await scope.dependy<CounterService>();
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
    /// We are using the [ScopedDependyConsumer] to isolate the rebuilds inside this widget.
    ///
    /// We can also do something similar to
    /// ```dart
    ///   final scope = getDependyScope(context);
    ///   final counterService = scope.watchDependy<CounterService>();
    /// ```
    ///
    /// But that will register the listener on the [ScopedDependyProvider] level, causing it to rebuild.
    return ScopedDependyConsumer(
      builder: (context, scope) {
        return FutureBuilder(
          /// Here we are watching [CounterService] and rebuilding the latest counter value.
          future: scope.watchDependy<CounterService>(),
          builder: (context, snapshot) {
            final counterService = snapshot.data;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '${counterService?.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
