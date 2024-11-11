// From the `example-1` and `example-2` we learned about [ScopedDependyMixin]
// and [ScopedDependyProvider]
//
// On a more complex application, sometimes it is important to share the scope with other
// widgets to avoid props-drilling.
//
// Dependy does allow sharing scope using a [StatefulWidget] that applies [ScopedDependyMixin] or
// [ScopedDependyProvider]
//
// On this example, we will use [ScopedDependyProvider] for demonstration.
//

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
      title: 'Example 3 (Share Scope ScopedDependyProvider)',
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
    /// Here we are providing a scope at this widget level using [ScopedDependyProvider].
    /// We are setting [shareScope] to true, which lets this scope be accessible
    /// from all descendant in the widget tree.
    return ScopedDependyProvider(
      shareScope: true,
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Example 3 (Share Scope ScopedDependyProvider)'),
          ),
          body: const Center(
            /// Notice that we are not passing any state directly to [CounterView].
            /// Instead, it will access the shared scope and retrieve the state it needs.
            child: CounterView(),
          ),

          /// Similarly, [CounterButton] will also use the shared scope to
          /// access the [CounterService] and modify its state.
          floatingActionButton: const CounterButton(),
        );
      },
      moduleBuilder: (_) {
        /// Notice that something is different from previous example.
        ///
        /// Since [CounterService] lives inside [example3ServicesModule], we are not providing it.
        ///
        /// If we need to override it, we can provide one in `providers`.
        ///
        /// Note: As we learned in previous example, we should not return [example3ServicesModule] directly
        /// from this function because when the Widget is removed from the tree, it will be disposed of. (Submodules won't be.)
        return DependyModule(
          providers: {},
          modules: {
            example3ServicesModule,
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
