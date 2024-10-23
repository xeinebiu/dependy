# Dependy Flutter

### Contents
- [About](#about)
- [Installation](#installation)
- [Import](#import)
- [Why Scoping is Important](#why-scoping-is-important)
  - [When to Use Scoping](#when-to-use-scoping)
- [Usage](#usage)
  - [ScopedDependyModuleMixin](#scopeddependymodulemixin)
  - [ScopedDependyProvider](#scopeddependyprovider)
  - [Share scope using ScopedDependyProvider](#share-scope-using-scopeddependyprovider)
  - [Share scope using ScopedDependyModuleMixin](#share-scope-using-scopeddependymodulemixin)
  - [Share multiple scopes using ScopedDependyModuleMixin](#share-multiple-scopes-using-scopeddependymodulemixin)

## About

Dependy Flutter is built on top of Dependy. It adds scoping features to help us manage dependencies within the widget
tree of our Flutter applications.

## Installation

To add Dependy Flutter to our project, we need to update `pubspec.yaml` file:

```yaml
dependencies:
  dependy: ^1.2.0
  dependy_flutter: ^1.2.0
```

Next, we run this command to install the dependencies:

```bash
flutter pub get
```

## Import

To use Dependy Flutter in our project, we need to import the necessary libraries:

```dart
import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
```

## Why Scoping is Important

- **Temporary Lifespan**: Some services should only last a short time. Scoping allows us to create services that we can
  dispose of when they’re no longer needed.

- **Specific Use Cases**: Scoping works well for services tied to specific contexts, like ViewModels or state on
  particular screens or routes in our application. This means we can have different instances of a service for different
  parts of our app.

- **Resource Management**: By limiting how long certain services last, we can make sure resources are freed up when
  they’re no longer required.

### When to Use Scoping

- **Screen-Specific Services**: If we have ViewModels or services that are only relevant to a specific screen, scoping
  helps us manage their lifecycle without affecting other parts of our app.

- **Route-Based Scoping**: When we navigate between different routes, we can create and dispose of scoped dependencies
  with the route. This is useful for services that shouldn’t last beyond the current route.

- **Performance Optimization**: By scoping services, we can avoid unnecessary instances lingering in memory, which leads
  to better use of system resources.

## Usage

### ScopedDependyModuleMixin

```dart
// In this example, we will demonstrate how to use [ScopedDependyModuleMixin].
//
// [ScopedDependyModuleMixin] can only be applied to a [StatefulWidget].
//
// It provides scoping functionality to the applied [Widget].
//

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


```

### ScopedDependyProvider

```dart
// In this example, we will demonstrate how to use [ScopedDependyProvider] widget.

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
        return FutureBuilder(
          /// Here are are retrieving an instance of [Example2State] but also
          /// watching it for changes.
          ///
          /// Any change emitted by it will trigger a rebuild.
          future: scope.watchDependy<Example2State>(),
          builder: (context, snapshot) {
            final state = snapshot.data;

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
                      '${state?.counter}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  state?.incrementCounter();
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
            );
          },
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
                      (dependy) async {
                // Here we resolve the logger service from [example2ServicesModule].
                final logger = await dependy<LoggerService>();

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
```

### Share scope using ScopedDependyProvider

````dart
// From the `example-1` and `example-2` we learned about [ScopedDependyModuleMixin]
// and [ScopedDependyProvider]
//
// On a more complex application, sometimes it is important to share the scope with other
// widgets to avoid props-drilling.
//
// Dependy does allow sharing scope using a [StatefulWidget] that applies [ScopedDependyModuleMixin] or
// [ScopedDependyProvider]
//
// On this example, we will use [ScopedDependyProvider] for demonstration.

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
        return FloatingActionButton(
          onPressed: () async {
            /// When the button is pressed, we call [increment()] to update the counter.
            final counterService = await scope.dependy<CounterService>();
            counterService.increment();
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
````

### Share scope using ScopedDependyModuleMixin

```dart
// From the `example-3` we learned about sharing scope using [ScopedDependyProvider]
//
// On this example, we are about to use [ScopedDependyModuleMixin]
//
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ScopedDependyModuleMixin {
  @override
  Widget build(BuildContext context) {
    /// While on [ScopedDependyProvider] we could set shareScope: true, using
    /// [ScopedDependyModuleMixin] we can invoke [shareDependyScope] which
    /// does achieve the exact same thing.
    return shareDependyScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Example 4 (Share Scope ScopedDependyModuleMixin)'),
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
        return FloatingActionButton(
          onPressed: () async {
            /// When the button is pressed, we call [increment()] to update the counter.
            final counterService = await scope.dependy<CounterService>();
            counterService.increment();
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
```

### Share multiple scopes using ScopedDependyModuleMixin

````dart
// From the previous example we learned about sharing scopes.
//
// On this example, we are about to demonstrate how multiple scoping works when shared using [ScopedDependyModuleMixin]
//
// App
//    -- LoggerService
//    MyHomePage
//        -- CounterService
//        CounterButton
//            -- Access LoggerService
//            -- Access CounterService
//        CounterView
//            -- Access LoggerService
//            -- Access CounterService

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ScopedDependyModuleMixin {
  @override
  Widget build(BuildContext context) {
    /// Share dependy scope with the descendants
    ///
    /// In this case, on entire App Level
    return shareDependyScope(
      child: MaterialApp(
        title:
        'Example 5 (Share Multiple Scopes using ScopedDependyModuleMixin)',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }

  @override
  DependyModule moduleBuilder() {
    return DependyModule(
      providers: {
        // Provide the Logger service on the widget scope
        DependyProvider<LoggerService>(
                  (_) => ConsoleLoggerService(),
        ),
      },
      modules: {},
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ScopedDependyModuleMixin {
  @override
  Widget build(BuildContext context) {
    return shareDependyScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text(
            'Example 5 (Share Multiple Scopes using ScopedDependyModuleMixin)',
          ),
        ),
        body: const Center(
          child: CounterView(),
        ),
        floatingActionButton: const CounterButton(),
      ),
    );
  }

  @override
  DependyModule moduleBuilder() {
    return DependyModule(
      providers: {
        // Provide the [CounterService] on the widget scope
        DependyProvider<CounterService>(
                  (dependy) async {
            final loggerService = await dependy<LoggerService>();

            // increment step of 5
            return CounterServiceImpl(5, loggerService);
          },
          dependsOn: {
            LoggerService,
          },
        ),
      },
      modules: {
        // This function comes from [ScopedDependyModuleMixin]
        // Import it if its services are needed on this scope.
        parentModule(),
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
          onPressed: () async {
            // [LoggerService] lives two scopes on this example higher.
            final loggerService = await scope.dependy<LoggerService>();
            loggerService.log('CounterButton onPressed');

            /// When the button is pressed, we call [increment()] to update the counter.
            final counterService = await scope.dependy<CounterService>();
            counterService.increment();
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
        return FutureBuilder(
          /// Here we are watching [CounterService] and rebuilding the latest counter value.
          future: scope.watchDependy<CounterService>(),
          builder: (context, snapshot) {
            final counterService = snapshot.data;

            // [LoggerService] lives two scopes on this example higher.
            scope.dependy<LoggerService>().then(
                      (value) => value.log("CounterView build"),
            );

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

````

### Share multiple scopes using ScopedDependyModuleMixin

```dart
// Same use-case as on `example-5` but using [ScopedDependyProvider]

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyProvider(
      shareScope: true,
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
                      (dependy) async {
                final loggerService = await dependy<LoggerService>();

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
          onPressed: () async {
            // [LoggerService] lives two scopes on this example higher.
            final loggerService = await scope.dependy<LoggerService>();
            loggerService.log('CounterButton onPressed');

            /// When the button is pressed, we call [increment()] to update the counter.
            final counterService = await scope.dependy<CounterService>();
            counterService.increment();
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
        return FutureBuilder(
          /// Here we are watching [CounterService] and rebuilding the latest counter value.
          future: scope.watchDependy<CounterService>(),
          builder: (context, snapshot) {
            final counterService = snapshot.data;

            // [LoggerService] lives two scopes on this example higher.
            scope.dependy<LoggerService>().then(
                      (value) => value.log("CounterView build"),
            );

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

```

### EagerDependyModule

This type of Dependy Module does provide us the possibility to convert an Asynchronous DependyModule to
a synchronous one.

```dart
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

```
