---
sidebar_position: 1
---

# ScopedDependyMixin

This example demonstrates how to use the `ScopedDependyMixin` to manage scoped dependencies in a Flutter app, such
as a `LoggerService` & `Example1State`, with a simple counter app. The goal is to show how to inject and use
dependencies in a scoped manner with `ScopedDependyMixin`.

### Step 1: Define the `LoggerService`

First, define an abstract class for the logger service:

```dart
abstract class LoggerService {
  void log(String message);
}
```

Then, create an implementation of the logger service:

```dart
class ConsoleLoggerService extends LoggerService {
  @override
  void log(String message) {
    print('ConsoleLogger: $message');
  }
}
```

### Step 2: Create the Dependy Module

Next, create a module to provide the `LoggerService`. This module will be used to register the `ConsoleLoggerService` as
the implementation for `LoggerService`.

> Note: This module we assume it as a singleton module that does live across the app process lifespan

```dart

final example1ServicesModule = DependyModule(
  providers: {
    DependyProvider<LoggerService>(
          (_) => ConsoleLoggerService(),
    ),
  },
);
```

### Step 3: Define the State Class with a `ChangeNotifier`

Now, create a `ChangeNotifier` class to manage the app's state, which includes the counter. This class will also use the
`LoggerService` to log actions like incrementing or decrementing the counter.

```dart
class Example1State with ChangeNotifier {
  Example1State(this.loggerService);

  final LoggerService loggerService;

  int _counter = 0;

  int get counter => _counter;

  void incrementCounter() {
    _counter++;
    notifyListeners();
    loggerService.log('incrementCounter $counter');
  }

  void decrementCounter() {
    _counter--;
    notifyListeners();
    loggerService.log('decrementCounter $counter');
  }
}
```

### Step 4: Create the Main Flutter Application

Set up the main `MyApp` widget and the `MyHomePage` widget. This is where the `ScopedDependyMixin` is applied,
allowing us to scope dependencies like `Example1State` within this widget's lifecycle.

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example 1 (Using ScopedDependyMixin)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
```

### Step 5: Apply `ScopedDependyMixin` to the `State` Class

Now, apply `ScopedDependyMixin` to your `State` class (`_MyHomePageState`). This mixin gives you scoped dependency
management for your `StatefulWidget`. Here’s where you will handle the state (with a counter) and inject the
dependencies (like `Example1State`).

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// This class applies the [ScopedDependyMixin] to manage dependencies.
class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(

      /// [watchDependy] triggers a rebuild when the watched dependency changes.
      future: watchDependy<Example1State>(),
      builder: (context, snapshot) {
        final state = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .inversePrimary,
            title: const Text('Example 1 (Using ScopedDependyMixin)'),
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
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              /// Call the increment function directly.
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

  /// This method returns the module scoped to the widget's lifecycle.
  @override
  DependyModule moduleBuilder() {
    return DependyModule(
      providers: {
        DependyProvider<Example1State>(
              (dependy) async {
            // Resolve LoggerService dependency
            final logger = await dependy<LoggerService>();

            // Return the Example1State with the resolved logger
            return Example1State(logger);
          },
          dependsOn: {
            LoggerService,
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

### Key Concepts

1. ``ScopedDependyMixin``: This mixin is added to the `State` class to manage dependencies. It helps with
   dependency scoping, ensures dependencies are created, and handles rebuilding the widget when the state changes.

2. ``watchDependy<Example1State>()``: This function retrieves the `Example1State` from the dependency graph and rebuilds
   the widget when any changes occur in the state (like incrementing or decrementing the counter).

3. ``dependy<Example1State>()``: This function is used to retrieve the dependency (`Example1State`) without setting up a
   listener. It's useful for direct calls like incrementing the counter, where you don’t need to watch the state.

4. ``moduleBuilder()``: This method is responsible for returning the scoped module that contains the providers and
   dependencies needed by the widget. It ensures that the dependencies are scoped to the widget’s lifecycle and will be
   disposed when the widget is removed from the tree.

## Example Code

You can view the complete example code for this project on GitHub: [example_1/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_1/app.dart)
