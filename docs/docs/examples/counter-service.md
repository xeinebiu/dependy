---
sidebar_position: 1
---

# Counter Service

Here’s a quick example showing how to add a service to the Dependy module and retrieve it.

```dart
import 'package:dependy/dependy.dart';

class CounterService {
  int _count = 0;

  int increment() => ++_count;
}

// Define the Dependy module with providers
final dependy = DependyModule(
  providers: {
    DependyProvider<CounterService>(
          (_) => CounterService(),
    ),
  },
);

void main() async {
  // Retrieve the CounterService from the module
  final counterService = await dependy<CounterService>();

  print('Initial Count: ${counterService.increment()}');
  print('After Increment: ${counterService.increment()}');
}
```

In this example:

- We create a `CounterService` with a simple `increment()` method to keep track of a count.
- The `DependyModule` is defined with `CounterService` as a provider, making it accessible through Dependy's dependency
  injection system.
- In the `main` function, we retrieve and use `CounterService`, showing how Dependy handles service management.

By default, Dependy will resolve all providers lazily, meaning services are only created when they are first requested.
