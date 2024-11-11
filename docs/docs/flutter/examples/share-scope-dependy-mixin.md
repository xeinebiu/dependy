---
sidebar_position: 4
---

# Share Scope (ScopedDependyMixin)

In this example, we demonstrate how to use `ScopedDependyMixin` in a `StatefulWidget` to share a dependency scope across
multiple widgets. Unlike `ScopedDependyProvider` (shown in the previous example), `ScopedDependyMixin` achieves the same
goal of sharing the scope by using `shareDependyScope()` inside a `StatefulWidget`.

This example provides a `CounterService` dependency that both `CounterButton` and `CounterView` widgets can access
directly from the shared scope.

### Step 1: Define the `CounterService`

This service manages the counter state and provides methods to increment and retrieve the counter value.

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

Set up a module that provides `SimpleCounterService` as the `CounterService` implementation.

```dart

final example4ServicesModule = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (_) => SimpleCounterService(),
    ),
  },
);
```

### Step 3: Set Up the Main Application

```dart
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
```

### Step 4: Use `ScopedDependyMixin` in `MyHomePage`

In the `MyHomePage` widget, which is a `StatefulWidget`, we apply `ScopedDependyMixin` and use `shareDependyScope()` to
make the dependency scope available to child widgets.

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    /// Using [shareDependyScope] here achieves the same result as `ScopedDependyProvider` with `shareScope: true`.
    return shareDependyScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: const Text('Example 4 (Share Scope ScopedDependyMixin)'),
        ),
        body: const Center(

          /// [CounterView] can access the shared scope directly, without needing props.
          child: CounterView(),
        ),

        /// [CounterButton] can also use the shared scope to access [CounterService].
        floatingActionButton: const CounterButton(),
      ),
    );
  }

  @override
  DependyModule moduleBuilder() {
    /// Only provide additional dependencies if necessary. Here, `example4ServicesModule`
    /// is added to the module list for this widget.
    return DependyModule(
      providers: {},
      modules: {
        example4ServicesModule,
      },
    );
  }
}
```

### Step 5: Define the `CounterButton` Widget

The `CounterButton` widget increments the counter by interacting with the shared `CounterService` dependency scope.

#### Important Note:

`CounterButton` uses `getDependyScope(context)` to access the dependency without setting up a listener. This is
efficient for non-observing tasks like calling the `increment` method.

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

The `CounterView` widget displays the current counter value by accessing and observing the `CounterService` dependency
for changes.

#### Important Note:

Here, `scope.watchDependy<CounterService>()` is used, setting up a listener to automatically update `CounterView` when
the counter value changes.

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

1. **`ScopedDependyMixin`**: Applied in a `StatefulWidget` to share a dependency scope. Using `shareDependyScope()`
   inside `build()` makes the scope accessible to all descendant widgets.

2. **`ScopedDependyConsumer`**: Used in both `CounterButton` and `CounterView` to manage dependency access and widget
   rebuilds. It allows each widget to interact with dependencies without causing unnecessary rebuilds of other parts of
   the widget tree.

3. **Why use `.dependy` in `CounterButton` and `watchDependy` in `CounterView`?**

    - `.dependy<CounterService>()`: Retrieves the dependency without observing changes. Ideal for `CounterButton` since
      it only needs to call `increment`.
    - `.watchDependy<CounterService>()`: Sets up a listener on `CounterService`, causing `CounterView` to rebuild
      whenever the counter updates. This approach is essential for displaying the latest counter value.

4. **Isolating Rebuilds**:

   Using `ScopedDependyConsumer` isolates rebuilds within each widget (`CounterButton` and `CounterView`). Although we
   could use `getDependyScope(context)` and call `scope.watchDependy<CounterService>()` directly, this would set up the
   listener at the top level, causing the entire provider to rebuild. By using `ScopedDependyConsumer`, we control
   rebuilds within each widget individually.

5. **`DependyModule` with `example4ServicesModule`**: Defines the services and dependencies for the application. The
   module includes `example4ServicesModule`, allowing `CounterService` to be accessible in the shared scope without
   redefinition.

---

## Example Code

The complete code for this example can be found on
GitHub: [example_4/app.dart](https://github.com/xeinebiu/dependy/blob/main/packages/dependy_flutter/example/example_4/app.dart)