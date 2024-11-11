---
sidebar_position: 4
---

# Exceptions

**Dependy** can throw several exceptions during its operation. Understanding when these exceptions occur will help us handle errors gracefully in our application.

### `DependyCircularDependencyException`

This exception is thrown when there is a circular dependency in the provider graph. A circular dependency occurs when two or more providers depend on each other directly or indirectly, leading to an infinite loop during resolution.

**Example**: If **Service-A** depends on **Service-B**, **Service-B** depends on **Service-C**, and **Service-C** depends on **Service-A**. This indirect chain of dependencies leads to an infinite loop during resolution.

### `DependyModuleDisposedException`

This exception is thrown when we attempt to resolve a provider from a **`DependyModule`** that has already been disposed. Once a module is disposed, it can no longer provide instances of its services.

**Example**: If we call `module<SomeService>()` after calling `module.dispose()`, a `DependyModuleDisposedException` will be raised.

### `DependyProviderNotFoundException`

This exception occurs when we try to resolve a provider for a specific type, but no provider is registered for that type within the module or its submodules.

**Example**: If we attempt to get an instance of **Provider C** but it has not been defined in the current module or any of its submodules, a `DependyProviderNotFoundException` will be thrown.

### `DependyProviderMissingDependsOnException`

This exception is thrown when a provider tries to resolve a dependency that has not been declared in its `dependsOn` set. This verifies that all dependencies are explicitly defined, promoting better design and avoiding runtime errors.

**Example**: If **Provider D** requires **Provider E**, but **Provider E** is not listed in the `dependsOn` set of **Provider D**, a `DependyProviderMissingDependsOnException` will occur.

### `DependyProviderDisposedException`

This exception is thrown when we try to use a provider that has already been disposed. Once a provider is disposed, it cannot be used anymore.

**Example**: If we call `<module><T>()` on a disposed provider, a `DependyProviderDisposedException` will be raised.

### `DependyDuplicateProviderException`

This exception is thrown when there is more than one provider of the same type registered within a single module.

**Example**:

```dart
final databaseModule = DependyModule(
  providers: {
    DependyProvider<DatabaseService>(
          (_) => SqlDatabaseService(),
    ),
    DependyProvider<DatabaseService>(
          (_) => SqliteDatabaseService(),
    ),
  },
);
```

In this example, both `SqlDatabaseService` and `SqliteDatabaseService` are registered as providers for the `DatabaseService` type within the same module.

---