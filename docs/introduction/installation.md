# Installation

## Add Dependy to Your Project

::: code-group

```bash [Dart]
dart pub add dependy
```

```bash [Flutter]
flutter pub add dependy
flutter pub add dependy_flutter
```

:::

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  dependy: ^1.8.0
```

Then fetch the package:

```bash
dart pub get
```

:::info Latest version
Check [pub.dev/packages/dependy](https://pub.dev/packages/dependy) for the latest version number.
:::

## Import

```dart
import 'package:dependy/dependy.dart';
```

## Quick Example

```dart
import 'package:dependy/dependy.dart';

class CounterService {
  int _count = 0;
  int get count => _count;
  int increment() => ++_count;
}

final module = DependyModule(
  providers: {
    DependyProvider<CounterService>(
      (_) => CounterService(),
    ),
  },
);

void main() async {
  final counter = await module<CounterService>();

  print(counter.increment()); // 1
  print(counter.increment()); // 2
}
```

Providers are resolved lazily. `CounterService` is created only when first requested.

## Next Steps

- [Core Concepts](./core-concepts): Providers, modules, scopes, and disposal
- [Examples](/examples/counter-service): More practical examples
- [Flutter Integration](/flutter/getting-started): Using Dependy with Flutter
