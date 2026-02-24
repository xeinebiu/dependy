# Getting Started

## Welcome to Dependy

A lightweight, flexible dependency injection library for Dart.

## Why Dependy?

Managing dependencies in growing codebases gets complex fast. Services depend on other services, lifetimes need managing, and testing requires swapping implementations. Many DI libraries add too much overhead or ceremony.

Dependy keeps it simple: define providers, compose modules, resolve dependencies.

## Key Features

- **Provider-based DI**: Define how each service is created and declare its dependencies.
- **Modular architecture**: Group providers into modules. Nest modules for hierarchical organization.
- **Circular dependency detection**: Dependy tracks the resolution graph and fails fast on cycles.
- **Transient providers**: Create a fresh instance on every resolution with `transient: true`.
- **Tagged instances**: Register multiple providers of the same type using `tag`.
- **Provider decorators**: Wrap resolved instances with composable transformations (logging, caching, retry).
- **Provider reset**: Clear cached singletons and cascade to dependents. Ideal for logout flows.
- **Override for testing**: Swap providers with `overrideWith()` without rebuilding the module tree.
- **Debug graph**: Inspect the entire dependency tree with `debugGraph()`.
- **Async & eager initialization**: Load services lazily or prepare them all eagerly with `asEager()`.
- **Flutter integration**: First-class support with scoped providers, widget mixins, and reactive rebuilds.

:::tip Ready to install?
Head over to the [Installation guide](./installation) to add Dependy to your project in seconds.
:::

## Next Steps

- [Installation](./installation): Add Dependy to your Dart or Flutter project
- [Core Concepts](./core-concepts): Learn about providers, modules, and scopes
- [Examples](/examples/counter-service): See Dependy in action
