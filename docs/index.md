---
layout: home

hero:
  name: Dependy
  text: Dependency Injection for Dart & Flutter
  tagline: Lightweight, modular dependency injection. Define providers, compose modules, and let Dependy wire it all together.
  actions:
    - theme: brand
      text: Get Started
      link: /introduction/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/xeinebiu/dependy

features:
  - icon: 🔧
    title: Easy to Use
    details: Lightweight and straightforward API. Define providers, create modules, and resolve dependencies in just a few lines of code.
  - icon: 📦
    title: Modular by Design
    details: Compose independent modules, nest scopes, and combine them freely. Keep your architecture clean as your app grows.
  - icon: ⚡
    title: Powered by Dart
    details: Built with Dart's type system and async features. Full type safety, no code generation, and no reflection required.
  - icon: 📱
    title: Flutter Ready
    details: First-class Flutter support with scoped providers, widget mixins, and reactive rebuilds out of the box.
---

## Simple by Design

- Provider-based DI with lazy resolution
- Composable modules and nested scopes
- Singleton, transient, and scoped lifetimes
- Tagged instances, decorators, and reset
- Override providers for testing
- Debug graph for inspecting the dependency tree
- First-class Flutter integration

```dart
import 'package:dependy/dependy.dart';

final module = DependyModule(
  providers: {
    DependyProvider<CounterService>(
      (_) => CounterService(),
    ),
  },
);

final counter = await module<CounterService>();
counter.increment();
print(counter.count); // 1
```
