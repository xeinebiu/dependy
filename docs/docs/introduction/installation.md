---
sidebar_position: 2
---

# Installation

### Step 1: Add Dependy to Your Project

#### With Dart

To add Dependy to your Dart project, open your terminal and run:

```bash
dart pub add dependy
```

#### With Flutter

If you are using Flutter, run:

```bash
flutter pub add dependy
```

Both commands will update your `pubspec.yaml` file automatically and fetch the package.

Alternatively, you can manually edit your `pubspec.yaml` file to include Dependy:

```yaml
dependencies:
  dependy: ^1.2.0
```

After editing, run the following command to get the package:

```bash
dart pub get
```

### Step 2: Import Dependy in Your Code

In any Dart file where you want to use Dependy, add the following import statement:

```dart
import 'package:dependy/dependy.dart';
```

### Step 3: Example Usage

Here’s a simple example to illustrate how to use Dependy for dependency injection:

```dart
import 'package:dependy/dependy.dart';

/// Check other examples on the source

class CounterService {
  int _count = 0;

  int increment() => ++_count;
}

final dependy = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (_) => CounterService(),
    ),
  },
);

void main() async {
  final counterService = await dependy<CounterService>();

  print('Initial Count: ${counterService.increment()}');
  print('After Increment: ${counterService.increment()}');
}
```

