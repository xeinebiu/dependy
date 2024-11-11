---
sidebar_position: 3
---

# Scoping

Dependy provides **scoping** to manage the lifespan of dependencies within the widget tree. This feature helps optimize
resource usage and create services with lifespans suited to specific parts of the app, while also enabling flexible
control over dependency overrides for certain areas of the app.

### Why Use Scoping?

- **Temporary Lifespan**: Scoping allows certain services to have a limited lifespan, ensuring they’re only active when
  needed. Services can be disposed of when they’re no longer in use.
- **Context-Specific Services**: Ideal for dependencies tied to particular screens, routes, or contexts. This allows us
  to create different instances of a service based on specific areas of the app.
- **Efficient Resource Management**: Scoping prevents unnecessary memory usage by disposing of services that aren’t
  needed, keeping the app lightweight and responsive.

### Scoping Use Cases

- **Screen-Specific Services**: For example, ViewModels or other dependencies that are only used on certain screens.
  Scoping ensures these services are created and disposed of alongside the screen.
- **Route-Based Scoping**: Scoped services can be created when a route is loaded and disposed of when the route is
  removed, which is useful for dependencies that shouldn’t last beyond a particular route.
- **Performance Optimization**: By scoping services to specific areas of the app, we avoid leaving unused instances in
  memory, freeing up resources and improving app performance.

### Overriding Dependencies within Scope

With scoping, you can **override a dependency or service and make it available to descendants**. This is particularly
useful in cases where different parts of the app may require slightly modified services or ViewModels. For example, a
screen can override a shared ViewModel or service with a specialized version that fits its unique needs, while still
maintaining access to other shared dependencies from the parent scope.

Dependy supports **sharing the scope with descendants** so every descendant can access the same scoped services or
ViewModels. This makes it easy to manage shared data and functionality across a specific part of the widget tree without
the need for redundant instances or complex state management.

### When to Use Scoping

Use scoping in these situations:

- **Single-Screen Services**: For dependencies that are only relevant to one screen, like a ViewModel or page-specific
  state.
- **Transient Services**: Services that only need to exist temporarily, such as network fetchers or state managers for
  pop-up dialogs or overlays.
- **Route-Dependent Dependencies**: If a service only makes sense within a single route or navigation path, scoping it
  to that route makes sure it’s disposed of as soon as the route changes.
- **Dependency Overrides**: For cases where certain screens need customized instances of shared services, scoping allows
  overrides that stay contained within specific parts of the app.
