---
sidebar_position: 5
---

# Nested Scopes (ScopedDependyMixin)

In this example, we demonstrate how to share nested scopes across widgets using `ScopedDependyMixin`. The key
difference from previous examples is that we are managing different dependency scopes at different levels of the widget
tree, while ensuring that each widget has access to the necessary dependencies.

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

### Step 3: Create the `DependyModule` for `MyApp`

In the `MyApp` widget, we define the `DependyModule` that provides the `LoggerService` to the entire application.

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return shareDependyScope(
      child: MaterialApp(
        title: 'Example 5 (Share Multiple Scopes using ScopedDependyMixin)',
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
        // Provide LoggerService at the App level
        DependyProvider<LoggerService>(
              (_) => ConsoleLoggerService(),
        ),
      },
      modules: {},
    );
  }
}
```

---

### Step 4: Create the `DependyModule` for `MyHomePage`

In the `MyHomePage` widget, we define a separate `DependyModule` that provides `CounterService`. This service depends on
`LoggerService`, which is provided at a higher scope (the App level).

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return shareDependyScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: const Text(
            'Example 5 (Share Multiple Scopes using ScopedDependyMixin)',
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
        // Provide the CounterService at this widget scope
        DependyProvider<CounterService>(
              (dependy) async {
            final loggerService = await dependy<LoggerService>();

            // Create a CounterService with increment step of 5
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

            // Log every time the CounterView widget is built
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

1. **Nested Scopes**: This example demonstrates how to share multiple dependency scopes in the same app. The
   `LoggerService` is provided at the App level, while the `CounterService` is provided at a more localized level (in
   `MyHomePage`).

2. **ScopedDependyMixin**: By applying `ScopedDependyMixin` to both `MyApp` and `MyHomePage`, each widget can share and
   access dependencies within its scope, even if those dependencies exist at different levels in the widget tree.

3. **ScopedDependyConsumer**: Used to listen for changes in a dependency and rebuild the widget accordingly. This is
   used in `CounterButton` and `CounterView` to observe changes to `CounterService` while also accessing
   `LoggerService`.

4. **Inheritance of Modules**: The `parentModule()` function ensures that `LoggerService`, provided at the App level, is
   accessible to the `CounterService` in the child scope.

---

## Example Code

The complete code for this example can be found on
GitHub: [example_5/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_5/app.dart)