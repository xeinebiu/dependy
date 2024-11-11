---
sidebar_position: 4
---

# API

This guide provides an overview of the key components of the Dependy Flutter API. With these tools, you can manage dependencies, create and share scopes, and dynamically watch and react to changes in the widget tree.

---

## Overview of Key Classes and Functions

### 1. `ScopedDependy`

The `ScopedDependy` class provides two main functions for accessing dependencies:

- `dependy<T>`: Retrieves a dependency of type `T` from the dependency graph.
- `watchDependy<T>`: Retrieves a `ChangeNotifier` of type `T` and listens for changes in that notifier. Rebuilds the UI when changes occur.

#### Usage:
```dart
ScopedDependyProvider(
  builder: (context, scope) {
    return FutureBuilder(
        /// Here are are retrieving an instance of [Example2State] but also
        /// watching it for changes.
        ///
        /// Any change emitted by it will trigger a rebuild.
        future: scope.watchDependy<Example2State>(),
        ...
      );
    },
);
```

### 2. `getDependyScope`

This function retrieves the nearest `ScopedDependy` instance from the widget tree, throwing an exception if no provider is found.

```dart
final scopedDependy = getDependyScope(context);
final example2State = scope.watchDependy<Example2State>();
```

> **Note**: When using `getDependyScope` to watch a service, the rebuild can occur on the widget that originally provided the scope. To avoid unwanted rebuilds of the entire scoped widget, use `ScopedDependyConsumer`. `ScopedDependyConsumer` limits the rebuild to just the consumer widget.

---

## Widgets and Mixins

### 3. `ScopedDependyMixin`

A mixin that provides scoped dependencies to a specific `StatefulWidget`. This mixin manages dependency creation, disposal, and watches for changes when necessary.

#### Methods:
- `dependy<T>`: Retrieves a dependency of type `T` from the dependency graph.
- `watchDependy<T>`: Retrieves a `ChangeNotifier` dependency of type `T`, listening for changes to trigger rebuilds.
- `parentModule()`: Retrieves a `DependyModule` from the nearest graph, allowing access to parent dependencies.
- `shareDependyScope`: Allows the widget to share its scope with descendant widgets.
- `moduleBuilder()`: Returns a `DependyModule` instance scoped to this widget’s tree. 
  - Note: Do not return a singleton module from here as that module will be disposed once the [Widget] is removed from the tree. If you are not overriding or providing any extra module or providers specifically for this [Widget], then you might not need to use the [ScopedDependyMixin].

#### Example Usage:
```dart
class _MyHomePageState extends State<MyHomePage> with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    return shareDependyScope(
      child: MyWidget(), // MyWidget will inherit this widget's scope
    );
  }
}
```

### 5. `ScopedDependyProvider`

A widget that provides scoped dependency modules within the widget tree. Useful when you need to scope a dependency to a particular widget and control sharing.

#### Parameters:
- `builder`: Builds the widget with access to `ScopedDependy`.
- `shareScope`: When `true`, shares the provider’s scope with all descendant widgets.
- `moduleBuilder()`: Returns a `DependyModule` instance scoped to this widget’s tree.
    - Note: Do not return a singleton module from here as that module will be disposed once the [Widget] is removed from the tree. If you are not overriding or providing any extra module or providers specifically for this [Widget], then you might not need to use the [ScopedDependyMixin].

#### Example Usage:
```dart
ScopedDependyProvider(
  moduleBuilder: (parentModule) => DependyModule(providers: ..., modules: ...),
  shareScope: true,
  builder: (context, scope) => MyWidget(),
);
```

### 6. `ScopedDependyConsumer`

A widget for consuming dependencies in the nearest scope. Useful for watching specific services or retrieving modules from the nearest dependency graph.

#### Parameters:
- `builder`: Builds the widget with access to `ScopedDependy`.
- `module`: (Optional) Specifies the module to use; otherwise, it will use the nearest dependency graph.

#### Example Usage:
```dart
ScopedDependyConsumer(
  builder: (context, scope) => MyWidget(),
);
```

---
