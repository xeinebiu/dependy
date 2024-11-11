---
sidebar_position: 3
---

# Share Scope (ScopedDependyProvider)

In this example, we demonstrate how to use `ScopedDependyProvider` to share a dependency scope across multiple widgets,
specifically for managing the `CounterService` without passing it through props. This approach helps avoid prop-drilling
in complex applications.

By using `ScopedDependyProvider` with `shareScope` set to `true`, we allow child widgets to access shared dependencies
directly, rather than through intermediate widgets.

### Step 1: Define the `CounterService`

This service manages the counter value and provides functions to increment and retrieve it.

```dart
abstract class CounterService {
  int get counter;

  void increment();
}

class SimpleCounterService implements CounterService {
  int _counter = 0;

  @override
  int get counter => _counter;

  @override
  void increment() {
    _counter++;
  }
}
```

### Step 2: Create the Dependy Module

Define a module that includes `SimpleCounterService` as the implementation for `CounterService`.

```dart

final example3ServicesModule = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (_) => SimpleCounterService(),
    ),
  },
);
```

### Step 3: Set Up the Main Application

Set up the main `MyApp` widget and the `MyHomePage` widget.

```dart
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
```

### Step 4: Apply `ScopedDependyProvider` in `MyHomePage`

In the `MyHomePage` widget, apply `ScopedDependyProvider` to create a shared dependency scope. Setting `shareScope` to
`true` allows all descendant widgets to access this scope.

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
            title: const Text('Example 3 (Share Scope ScopedDependyProvider)'),
          ),
          body: const Center(
            child: CounterView(),
          ),
          floatingActionButton: const CounterButton(),
        );
      },
      moduleBuilder: (_) {
        // Only provide additional dependencies if needed. Here, `example3ServicesModule` is directly included in the modules set.
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
```

### Step 5: Define the `CounterButton` Widget

The `CounterButton` widget increments the counter value by interacting with the shared `CounterService` scope.

#### Important Note:

Here, we use `scope.dependy<CounterService>()` instead of `watchDependy`. This retrieves the dependency instance without
setting up a listener or causing a rebuild on state changes. This is efficient because `CounterButton` only calls the
`increment` method without needing to observe state changes.

```dart
class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = getDependyScope(context);

    return FloatingActionButton(
      onPressed: () async {
        final counterService = await scope.dependy<CounterService>();
        counterService.increment();
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
```

### Step 6: Define the `CounterView` Widget

The `CounterView` widget displays the current counter value by accessing the shared `CounterService` instance and
watching it for changes.

#### Important Note:

In this widget, we use `scope.watchDependy<CounterService>()` to observe changes in `CounterService`. This sets up a
listener, causing `CounterView` to rebuild whenever the counter value updates. This is necessary to display real-time
updates to the UI.

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

### Key Concepts

1. **`ScopedDependyProvider`**: Provides a shared scope of dependencies within the widget tree. Setting `shareScope` to
   `true` allows descendant widgets to access dependencies without explicitly passing them as props.

2. **`ScopedDependyConsumer`**: Retrieves a dependency and rebuilds the widget when the dependency changes. This is
   useful for widgets like `CounterButton` and `CounterView` that interact with or display the current state.

3. **Why use `.dependy` in `CounterButton` and `watchDependy` in `CounterView`?**

    - `dependy<CounterService>()`: Retrieves the dependency without listening for changes, which is ideal for
      non-observing tasks like calling `increment` in `CounterButton`.
    - `watchDependy<CounterService>()`: Sets up a listener for changes in the dependency, causing the widget to rebuild
      when the state changes. This is used in `CounterView` to watch for updates in the counter value.

4. **Isolating Rebuilds**:

   Using `ScopedDependyConsumer` in `CounterButton` and `CounterView` isolates rebuilds to these widgets only. While
   it’s possible to directly access dependencies with `getDependyScope(context)` and
   `scope.watchDependy<CounterService>()`, this would register the listener at the `ScopedDependyProvider` level,
   causing unnecessary rebuilds for the entire provider. Instead, `ScopedDependyConsumer` manages rebuilds at the level
   of each child widget.

5. **`DependyModule` with `example3ServicesModule`**: Defines the services and dependencies used in the application.
   Since `CounterService` is inside `example3ServicesModule`, it's accessible in the shared scope without needing to
   redefine it in the module.

---

## Example Code

The complete code for this example is available on
GitHub: [example_3/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_3/app.dart)