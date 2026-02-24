# Changelog

## 1.6.0

### Features

* **Debug graph**: Added `debugGraph()` method to `DependyModule` and `EagerDependyModule`. Returns a
  formatted ASCII tree of the entire dependency graph showing provider types, tags, keys, lifecycle
  (singleton/transient), resolution status (pending/cached/always new), disposed state, and nested
  submodules. Useful during development for inspecting what's registered and resolved.

---

## 1.5.0

### Features

* **Overrides for testing**: Added `overrideWith` method to `DependyModule`. Create a new module with
  specific providers replaced by (Type, tag) match — perfect for swapping real services with mocks in
  tests. The original module is not modified, making it safe for parallel tests. Full verification
  runs on the new module so misconfigurations are caught early.

---

## 1.4.0

### Features

* **Tagged instances**: Added optional `tag` parameter to `DependyProvider` for registering multiple
  instances of the same type. Resolve with `module<T>(tag: 'name')`. Tags work with singletons,
  transients, submodules, eager modules, and all verification checks (duplicates, circular
  dependencies, captive dependencies).

---

## 1.3.0

### Features

* **Transient providers**: Added `transient` parameter to `DependyProvider`. When `true`, a fresh
  instance is created on every resolution instead of caching a singleton.
* **Captive dependency detection**: `DependyModule` now throws `DependyCaptiveDependencyException`
  at construction time if a singleton provider depends on a transient provider, preventing the
  silent capture of transient instances.

### Infrastructure

* Migrated to Dart pub workspace (monorepo) structure.

---

## 1.2.0

### Features

* **EagerDependyModule**:
    - Introduced the `EagerDependyModule` class for eager resolution of dependencies.
    - Users can convert a `DependyModule` into an `EagerDependyModule`

### New Extension Method

* **`asEager()`**:
    - Added an extension method on `DependyModule` that creates an instance of `EagerDependyModule`.

### Code Example

```dart

final dependyModule = DependyModule(providers: { /* providers here */
});

// Eagerly resolve all providers
final eagerModule = awaitdependyModule.asEager();

// Now you can call services directly
final myService = eagerModule<MyService>();
```

---

## 1.1.0

### Features

* Asynchronous factories: Added support for resolving dependencies asynchronously.

---

## 1.0.2

### Fixes

* Resolved Dart analyzer issues.
* Corrected typos in `README.md`.

---

## 1.0.1

### Improvements

* Added examples on `pub.dev`.
* Provided detailed documentation for exceptions.

---

## 1.0.0

### Initial Release

* Launch of the Dependy module system with basic functionality.
