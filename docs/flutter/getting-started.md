# Getting Started with Flutter

## Overview

Dependy Flutter extends the core Dependy library with scoping features for the Flutter widget tree. It lets you:

- Scope services to widget lifetimes, automatically disposed when widgets are removed
- Share dependency scopes across the widget tree without prop drilling
- Reactively rebuild widgets when `ChangeNotifier` dependencies update
- Resolve async dependencies with a clean builder pattern

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  dependy: ^1.8.0
  dependy_flutter: ^1.8.0
```

Then fetch:

```bash
flutter pub get
```

## Import

```dart
import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
```

## Next Steps

- [Scoping](./scoping): Why and when to scope dependencies in Flutter
- [API Reference](./api): All widgets, mixins, and functions
- [Flutter Examples](./examples/scoped-dependy-mixin): Step-by-step Flutter examples
