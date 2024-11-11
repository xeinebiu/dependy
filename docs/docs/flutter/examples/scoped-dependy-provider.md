---
sidebar_position: 2
---

# ScopedDependyProvider

This example demonstrates how to use the `ScopedDependyProvider` widget to manage scoped dependencies,
such as a `LoggerService` and `Example2State`, in a simple counter app. The goal is to show how to inject and use
dependencies in a more declarative way by using `ScopedDependyProvider`.

This approach offers an alternative to `ScopedDependyMixin`.

### Setting Up Dependencies

First, define a logging service and a simple counter state similar to the previous example.

#### `LoggerService` and `ConsoleLoggerService`

```dart
abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print('ConsoleLogger: $message');
  }
}
```

#### `Example2State`

Define `Example2State`, a `ChangeNotifier` that uses `LoggerService` and contains simple counter logic:

```dart
class Example2State with ChangeNotifier {
  Example2State(this.loggerService);

  final LoggerService loggerService;

  int _counter = 0;

  int get counter => _counter;

  void incrementCounter() {
    _counter++;
    notifyListeners();
    loggerService.log('incrementCounter $_counter');
  }
}
```

#### `DependyModule` for Services

We create a `DependyModule` to provide instances of services like `LoggerService`.

```dart

final example2ServicesModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
          (_) => ConsoleLoggerService(),
    ),
  },
);
```

### Main App Setup

The main entry point remains similar as on previous example:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
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
```

### Setting Up `ScopedDependyProvider`

In this example, we use the `ScopedDependyProvider` widget instead of `ScopedDependyMixin` to provide dependencies
within `MyHomePage`, which is a `StatelessWidget`.

Unlike `ScopedDependyMixin`, `ScopedDependyProvider` does not require a `StatefulWidget` and can be applied to a
`StatelessWidget` as well.

#### `MyHomePage`

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .inversePrimary,
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
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium,
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
      /// this [Widget], you may not need to use the [ScopedDependyMixin].
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

### Key Concepts

#### `ScopedDependyProvider`

- `ScopedDependyProvider` is used here to define a scope for `Example2State` and other dependencies within `MyHomePage`.
  Got it, let's clarify the `moduleBuilder` section more accurately.
- `moduleBuilder` function must be implemented to return a `DependyModule` that is scoped to the lifespan of the
  `MyHomePage` widget.
  > **Important**:Do not return a singleton module here, as this module will be disposed of once the widget is removed
  from the tree. For instance, avoid directly returning `example2ServicesModule` as this could lead to unexpected
  disposal behavior:
  > ```
  > return example2ServicesModule; // Avoid this!
  >  ```
  > If you aren’t overriding or adding any extra modules or providers specifically for this widget, you may not need
  to
  use `ScopedDependyMixin`.

#### Watching the Dependency with `watchDependy`

In the `FutureBuilder`, we use `scope.watchDependy<Example2State>()` to get an instance of `Example2State` and listen
for any changes. This allows for automatic rebuilds when `Example2State` updates, making the component reactive.

## Example Code

You can view the complete example code for this project on
GitHub: [example_1/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_2/app.dart)