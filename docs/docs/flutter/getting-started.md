---
sidebar_position: 1
---

# Getting Started

### Overview

Dependy Flutter builds on top of Dependy to provide additional scoping features tailored for Flutter applications. It
helps manage dependencies within the widget tree, ensuring that services can be scoped to specific parts of the UI and
lifecycle events of the Flutter app.

### Installation

To use Dependy Flutter in your project, you'll first need to update your `pubspec.yaml` file with the following
dependencies:

```yaml
dependencies:
  dependy: ^1.2.0
  dependy_flutter: ^1.2.0
```

After updating the `pubspec.yaml`, run the following command to fetch the dependencies:

```bash
flutter pub get
```

### Importing Dependy Flutter

To integrate Dependy Flutter into your project, import the necessary libraries into your Dart files:

```dart
import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
```

With Dependy Flutter, you can now easily manage your app’s dependencies and create scoped services that are linked to
specific parts of the widget tree, providing you with better control and modularity in your Flutter applications.