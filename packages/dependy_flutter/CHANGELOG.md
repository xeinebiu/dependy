## 1.2.0

### Features:
* **EagerDependyModule**: Added support for `EagerDependyModule`, enabling synchronous access to dependencies after asynchronous initialization.
    - Users can convert a `DependyModule` to an `EagerDependyModule` using the `asEager()` extension method.
    - Dependencies are resolved eagerly, meaning services are accessible synchronously once the module is initialized.

* **DependyNotifierListener**: Introduced the `DependyNotifierListener` widget to listen to services that extend `ChangeNotifier` and automatically rebuild the UI when the state changes.

### Code Example:

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
        dependsOn: { LoggerService },
      ),
    },
  ).asEager(); // Initialize dependy eagerly
}

Future<void> main() async {
  await _initDependy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example (EagerDependyModule)',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EagerDependyModule Example')),
      body: const Center(child: CounterView()),
      floatingActionButton: const CounterButton(),
    );
  }
}

class CounterButton extends StatelessWidget {
  const CounterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        final loggerService = dependy<LoggerService>();
        loggerService.log('Increment button pressed');

        final counterService = dependy<CounterService>();
        counterService.increment();
      },
      child: const Icon(Icons.add),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final counterService = dependy<CounterService>();

    return DependyNotifierListener(
      notifier: counterService,
      builder: (context, notifier) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text('${counterService.counter}',
                style: Theme.of(context).textTheme.headlineMedium),
          ],
        );
      },
    );
  }
}
```

---

## 1.1.0

* Updated to **dependy** version 1.1.0.
* Added support for asynchronous service initialization.

## 1.0.2

* Updated to **dependy** version 1.0.2.

## 1.0.1

* Added example on pub.dev.
* Updated to **dependy** version 1.0.1.

## 1.0.0

* Initial release.
