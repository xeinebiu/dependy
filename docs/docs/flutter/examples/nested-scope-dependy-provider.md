---
sidebar_position: 6
---

# Nested Scopes (ScopedDependyProvider)

In this example, we show how to manage nested dependency scopes using `ScopedDependyProvider`.

### App Overview

The app consists of multiple scopes:

- **App level**: Shares a `LoggerService` for logging messages across the entire application.
- **MyHomePage level**: Shares a `CounterService` that uses the `LoggerService` from the higher scope to log actions.
- **CounterButton**: Accesses both `LoggerService` and `CounterService` to log actions and update the counter.
- **CounterView**: Displays the counter value while accessing both `LoggerService` and `CounterService`.

---

### Step 1: Define the `LoggerService`

The `LoggerService` is used to log messages, and its implementation is provided at the `App` scope.

```dart
abstract class LoggerService {
  void log(String message);
}

class ConsoleLoggerService implements LoggerService {
  @override
  void log(String message) {
    print(message);
  }
}
```

---

### Step 2: Define the `CounterService`

The `CounterService` manages the counter state and interacts with `LoggerService` to log updates. Here, we use a simple
implementation of `CounterService` that increments the counter by a step of 5.

```dart
abstract class CounterService {
  int get counter;

  void increment();
}

class CounterServiceImpl implements CounterService {
  int _counter;
  final LoggerService loggerService;

  CounterServiceImpl(this._counter, this.loggerService);

  @override
  int get counter => _counter;

  @override
  void increment() {
    _counter += 5;
    loggerService.log('Counter incremented to $_counter');
  }
}
```

---

### Step 3: Set Up the `ScopedDependyProvider` for `MyApp`

The `ScopedDependyProvider` in `MyApp` provides the `LoggerService` for the entire app.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyProvider(
      shareScope: true,
      builder: (context, scope) {
        return MaterialApp(
          title: 'Example 6 (Share Multiple Scopes using ScopedDependyProvider)',
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
            // Provide LoggerService on the widget scope
            DependyProvider<LoggerService>(
                  (_) => ConsoleLoggerService(),
            ),
          },
        );
      },
    );
  }
}
```

---

### Step 4: Set Up the `ScopedDependyProvider` for `MyHomePage`

The `ScopedDependyProvider` in `MyHomePage` provides `CounterService` and depends on `LoggerService`.

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyProvider(
      shareScope: true,
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .inversePrimary,
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
            // Provide CounterService on the widget scope
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
          modules: {
            // Import the higher scope module
            // In this case it would be the scope of App which does contain the LoggerService
            parentModule(),
          },
        );
      },
    );
  }
}
```

---

### Step 5: Define the `CounterButton` Widget

The `CounterButton` widget interacts with both `LoggerService` and `CounterService`. It logs the action when the button
is pressed and increments the counter.

```dart
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = getDependyScope(context);

    return FloatingActionButton(
      onPressed: () async {
        final loggerService = await scope.dependy<LoggerService>();
        loggerService.log('CounterButton onPressed');

        final counterService = await scope.dependy<CounterService>();
        counterService.increment();
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
```

---

### Step 6: Define the `CounterView` Widget

The `CounterView` widget displays the current counter value and also logs each build. It listens to updates from
`CounterService` while accessing the `LoggerService`.

```dart
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyConsumer(
      builder: (context, scope) {
        return FutureBuilder(
          future: scope.watchDependy<CounterService>(),
          builder: (context, snapshot) {
            final counterService = snapshot.data;

            scope.dependy<LoggerService>().then(
                  (value) => value.log("CounterView build"),
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('You have pushed the button this many times:'),
                Text(
                  '${counterService?.counter}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium,
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

---

### Key Concepts

1. **Nested Scopes**: This example demonstrates how to share and manage multiple dependency scopes in the app using
   `ScopedDependyProvider`.
2. **ScopedDependyProvider**: This widget provides and manages dependencies within a specific scope. The scope can be
   shared across widgets, making dependency injection easier to manage.
3. **ScopedDependyConsumer**: This is used to listen for changes in a dependency and rebuild the widget. It allows
   `CounterView` to access the updated `CounterService` and also log actions with `LoggerService`.
4. **Inheritance of Modules**: The `parentModule()` function ensures that `LoggerService`, provided at the App level, is
   accessible to the `CounterService` in the child scope.
--- 

## Example Code

You can view the complete code for this example on
GitHub: [example_6/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_6/app.dart).