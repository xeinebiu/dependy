# ScopedDependyAsyncBuilder

`ScopedDependyAsyncBuilder<T>` resolves an async dependency and provides a sealed `AsyncDependySnapshot<T>`, replacing the common pattern of nesting `ScopedDependyConsumer` with `FutureBuilder`.

When the resolved type is a `ChangeNotifier`, it automatically listens for changes and rebuilds.

## Setup

Define a `CounterService` and a services module:

```dart
abstract class CounterService {
  int get counter;
  void increment();
}

class SimpleCounterService extends ChangeNotifier implements CounterService {
  int _counter = 0;

  @override
  int get counter => _counter;

  @override
  void increment() {
    _counter++;
    notifyListeners();
  }
}

final servicesModule = DependyModule(
  providers: {
    DependyProvider<CounterService>(
      (_) => SimpleCounterService(),
    ),
  },
);
```

## Main App with Shared Scope

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyProvider(
      shareScope: true,
      builder: (context, scope) {
        return Scaffold(
          appBar: AppBar(title: const Text('ScopedDependyAsyncBuilder')),
          body: const Center(child: CounterView()),
          floatingActionButton: const CounterButton(),
        );
      },
      moduleBuilder: (_) {
        return DependyModule(
          providers: {},
          modules: {servicesModule},
        );
      },
    );
  }
}
```

## CounterView with AsyncBuilder

The builder receives a sealed `AsyncDependySnapshot`. Use exhaustive pattern matching to handle all states:

```dart
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScopedDependyAsyncBuilder<CounterService>(
      builder: (context, snapshot) => switch (snapshot) {
        AsyncDependyData(:final value) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              Text(
                '${value.counter}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        AsyncDependyError(:final error) => Text('Failed to load: $error'),
        AsyncDependyLoading() => const CircularProgressIndicator(),
      },
    );
  }
}
```

## CounterButton

The button resolves the service directly from the shared scope. No `AsyncBuilder` is needed since it does not display async data.

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

## Optional Parameters

```dart
ScopedDependyAsyncBuilder<MyService>(
  module: myModule,  // resolve from a specific module
  tag: 'special',    // resolve a tagged provider
  watch: false,      // disable automatic ChangeNotifier watching
  builder: (context, snapshot) => switch (snapshot) {
    AsyncDependyData(:final value) => Text('$value'),
    AsyncDependyError(:final error) => Text('Error: $error'),
    AsyncDependyLoading() => const CircularProgressIndicator(),
  },
);
```

## Key Concepts

- **Sealed snapshots**: `AsyncDependyLoading`, `AsyncDependyData`, and `AsyncDependyError` enable exhaustive pattern matching. No unhandled states.
- **Automatic watching**: When `T` is a `ChangeNotifier` and `watch` is `true` (default), the widget rebuilds on every notification.
- **Replaces nested boilerplate**: One widget instead of `ScopedDependyConsumer` + `FutureBuilder`.
