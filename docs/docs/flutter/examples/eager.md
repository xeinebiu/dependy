---
sidebar_position: 7
---

# Eager Module (Synchronous)

This example demonstrates how to use the `EagerDependyModule` to manage eagerly initialized services, like a
`LoggerService` and `CounterService`, in a simple counter app. The goal is to show how to set up and use services that
are available synchronously, even though their creation is asynchronous.

### Setting Up Dependencies

First, define the `LoggerService` and `CounterService` used in this example.

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

#### `CounterService` and `CounterServiceImpl`

```dart
abstract class CounterService {
  int get counter;

  void increment();
}

class CounterServiceImpl implements CounterService {
  CounterServiceImpl(this._counter, this.loggerService);

  final LoggerService loggerService;
  int _counter;

  @override
  int get counter => _counter;

  @override
  void increment() {
    _counter++;
    loggerService.log('Incremented counter to $_counter');
  }
}
```

### Creating the `EagerDependyModule`

We create an `EagerDependyModule` to initialize and provide instances of services like `LoggerService` and
`CounterService` synchronously.

```dart
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
```

### Main App Setup

In the main function, we initialize the `dependy` module synchronously and run the app.

```dart
Future<void> main() async {
  // Initialize the global [dependy] and make it synchronous
  await _initDependy();

  runApp(const MyApp());
}
```

### The `MyApp` Widget

The main app structure remains the same as in other examples.

```dart
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
```

### `MyHomePage` Widget

This is where the main UI resides. It includes a counter value displayed using `CounterView` and a button (
`CounterButton`) to increment the counter.

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
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
```

### `CounterButton` Widget

The `CounterButton` widget increments the counter when pressed. It synchronously accesses both the `LoggerService` and
`CounterService` to log actions and update the counter.

```dart
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
```

### `CounterView` Widget

The `CounterView` widget displays the current counter value. It listens for updates using `DependyNotifierListener`,
which listens for changes in the `CounterService`.

```dart
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final counterService = dependy<CounterService>();

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
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium,
            ),
          ],
        );
      },
    );
  }
}
```

### Key Concepts

#### `EagerDependyModule`

- `EagerDependyModule` is used to initialize services eagerly, making them immediately available for synchronous access
  throughout the app.
- The `asEager()` method is used to eagerly resolve and initialize dependencies, allowing them to be accessed
  synchronously via `dependy<>()`.

#### Synchronous Access to Dependencies

In this example, both the `LoggerService` and `CounterService` are resolved synchronously. This ensures that they are
immediately available when needed, without waiting for asynchronous resolution.

#### `DependyNotifierListener`

- `DependyNotifierListener` listens for changes in a dependency and rebuilds the widget whenever that dependency is
  updated.
- In this example, it listens for changes in the `CounterService` and updates the UI when the counter value changes.

## Example Code

You can view the complete example code for this project on
GitHub: [example_7/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_7/app.dart)