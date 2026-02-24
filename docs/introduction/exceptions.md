# Exceptions

Dependy throws specific exceptions to help you catch configuration and runtime errors early.

## `DependyCircularDependencyException`

:::danger
Thrown when providers form a cycle in the dependency graph. For example, A depends on B, B depends on C, and C depends on A. Dependy detects this and fails fast instead of entering an infinite loop.
:::

## `DependyModuleDisposedException`

:::danger
Thrown when you try to resolve from a module that has already been disposed. Once `module.dispose()` is called, the module is no longer usable.
:::

## `DependyProviderNotFoundException`

:::danger
Thrown when no provider is registered for the requested type in the module or any of its submodules.
:::

## `DependyProviderMissingDependsOnException`

:::danger
Thrown when a provider's factory resolves a type that is not declared in its `dependsOn` set. This enforces explicit dependency declarations.
:::

## `DependyProviderDisposedException`

:::danger
Thrown when you try to resolve from a provider that has already been disposed.
:::

## `DependyCaptiveDependencyException`

:::danger
Thrown at module construction when a singleton provider declares a dependency on a transient provider. This would silently "capture" the transient instance, defeating its purpose. Either make the consumer transient too, or make the dependency a singleton.
:::

## `DependyDuplicateProviderException`

:::danger
Thrown when two providers of the same type (and same tag) are registered in a single module.

```dart
// This throws DependyDuplicateProviderException:
final module = DependyModule(
  providers: {
    DependyProvider<DatabaseService>((_) => SqlDatabaseService()),
    DependyProvider<DatabaseService>((_) => SqliteDatabaseService()),
  },
);
```

Use `tag` to register multiple providers of the same type, or split them into separate modules.
:::
