# API Reference

## ScopedDependy

Provides two methods for accessing dependencies from a scope:

- **`dependy<T>()`**: Resolves a dependency of type `T`. Does not listen for changes.
- **`watchDependy<T>()`**: Resolves a `ChangeNotifier` of type `T` and listens for changes. Triggers a rebuild when the notifier updates.

## getDependyScope

Retrieves the nearest `ScopedDependy` from the widget tree:

```dart
final scope = getDependyScope(context);
final state = await scope.watchDependy<MyState>();
```

:::info Rebuild scope
When using `getDependyScope` with `watchDependy`, the rebuild happens at the widget that provided the scope. Use `ScopedDependyConsumer` to limit rebuilds to a smaller subtree.
:::

---

## Widgets and Mixins

### ScopedDependyMixin

A mixin for `StatefulWidget` that provides scoped dependencies.

**Methods:**
- `dependy<T>()`: Resolve without listening
- `watchDependy<T>()`: Resolve and listen for changes
- `parentModule()`: Access the parent scope's module
- `shareDependyScope()`: Share this scope with descendants
- `moduleBuilder()`: Override to return the scoped `DependyModule`

```dart
class _MyState extends State<MyWidget> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return shareDependyScope(
      child: MyChildWidget(),
    );
  }

  @override
  DependyModule moduleBuilder() {
    return DependyModule(
      providers: { /* ... */ },
      modules: {parentModule()},
    );
  }
}
```

:::warning
Do not return a singleton module from `moduleBuilder()`. That module will be disposed when the widget is removed from the tree. Include singletons as submodules instead.
:::

### ScopedDependyProvider

A widget that provides scoped dependencies. Works with both `StatelessWidget` and `StatefulWidget`.

**Parameters:**
- `builder`: Builds the widget with access to `ScopedDependy`
- `shareScope`: When `true`, descendants can access this scope
- `moduleBuilder`: Returns a scoped `DependyModule`

```dart
ScopedDependyProvider(
  shareScope: true,
  moduleBuilder: (parentModule) => DependyModule(
    providers: { /* ... */ },
    modules: {parentModule()},
  ),
  builder: (context, scope) => MyWidget(),
);
```

### ScopedDependyConsumer

Consumes dependencies from the nearest scope. Limits rebuilds to just this widget instead of the entire scope provider.

```dart
ScopedDependyConsumer(
  builder: (context, scope) {
    return FutureBuilder(
      future: scope.watchDependy<CounterService>(),
      builder: (context, snapshot) => Text('${snapshot.data?.counter}'),
    );
  },
);
```

### ScopedDependyAsyncBuilder

Resolves an async dependency and provides a sealed `AsyncDependySnapshot<T>`, replacing the common `ScopedDependyConsumer` + `FutureBuilder` nesting pattern.

When the resolved type is a `ChangeNotifier`, it automatically listens for changes (controlled via `watch`, which defaults to `true`).

**Snapshot types** (exhaustive pattern matching):
- `AsyncDependyLoading`: resolving in progress
- `AsyncDependyData`: resolved successfully
- `AsyncDependyError`: resolution failed

```dart
ScopedDependyAsyncBuilder<CounterService>(
  builder: (context, snapshot) => switch (snapshot) {
    AsyncDependyData(:final value) => Text('${value.counter}'),
    AsyncDependyError(:final error) => Text('Error: $error'),
    AsyncDependyLoading() => const CircularProgressIndicator(),
  },
);
```

**Optional parameters:**
- `module`: resolve from a specific module instead of the widget tree scope
- `tag`: resolve a tagged provider
- `watch`: disable automatic `ChangeNotifier` listening (default: `true`)

### DependyNotifierListener

Listens to a `ChangeNotifier` and rebuilds when it updates. Used with `EagerDependyModule` where scoped widgets are not needed.

```dart
final counterService = dependy<CounterService>();

DependyNotifierListener(
  notifier: counterService,
  builder: (context, notifier) => Text('${counterService.counter}'),
);
```
