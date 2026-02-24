# Installation

## Add Packages

::: code-group

```bash [CLI]
flutter pub add dependy
flutter pub add dependy_flutter
```

```yaml [pubspec.yaml]
dependencies:
  dependy: ^1.8.0
  dependy_flutter: ^1.8.0
```

:::

Then run:

```bash
flutter pub get
```

:::info Latest version
Check [pub.dev/packages/dependy](https://pub.dev/packages/dependy) and [pub.dev/packages/dependy_flutter](https://pub.dev/packages/dependy_flutter) for the latest versions.
:::

## Import

```dart
import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
```

## Quick Example

```dart
class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: watchDependy<CounterState>(),
      builder: (context, snapshot) {
        final state = snapshot.data;
        return Text('${state?.counter}');
      },
    );
  }

  @override
  DependyModule moduleBuilder() {
    return DependyModule(
      providers: {
        DependyProvider<CounterState>((_) => CounterState()),
      },
    );
  }
}
```

The module is scoped to the widget. It is automatically disposed when the widget is removed from the tree.
