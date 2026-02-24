# Scoping

Dependy provides **scoping** to manage the lifespan of dependencies within the widget tree. Scoped services are created and disposed alongside the widgets they belong to.

## Why Scope?

- **Automatic cleanup**: Services are disposed when the widget is removed from the tree. No manual lifecycle management.
- **Context-specific instances**: Different screens can have different implementations of the same service type.
- **No prop drilling**: Share scopes with descendants so child widgets can resolve dependencies directly.
- **Memory efficiency**: Services only exist while they are needed.

## Use Cases

- **Screen-specific ViewModels**: A ViewModel that only exists while a screen is mounted.
- **Route-based services**: Create on navigation push, dispose on pop.
- **Feature-specific overrides**: Override a shared service with a specialized version for a specific part of the app.
- **Nested scopes**: An app-level scope provides `LoggerService`, a page-level scope adds `CounterService` that depends on the logger.

## Overriding Dependencies

With scoping, you can override a service and make it available to descendants. A child scope can provide a different implementation while still accessing the parent scope's services via `parentModule()`.

:::info Avoid returning singletons from moduleBuilder()
Do not return a singleton module from `moduleBuilder()`. That module will be disposed when the widget is removed from the tree. Instead, include singleton modules as submodules so they are not disposed with the scoped module.
:::

## Choosing an Approach

| Approach | Widget type | Share scope | Use when |
|----------|-------------|-------------|----------|
| `ScopedDependyMixin` | `StatefulWidget` | `shareDependyScope()` | You need `State` lifecycle hooks |
| `ScopedDependyProvider` | Any widget | `shareScope: true` | Declarative, no mixin needed |
| `ScopedDependyAsyncBuilder` | Any widget | Inherits parent scope | Resolving a single async dependency with loading/error states |
