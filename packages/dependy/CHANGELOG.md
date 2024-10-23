# Changelog

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
final dependyModule = DependyModule(providers: { /* providers here */ });

// Eagerly resolve all providers
final eagerModule = await dependyModule.asEager();

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
