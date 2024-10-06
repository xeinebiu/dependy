/// This exception is thrown when you attempt to resolve a provider from
/// a **`DependyModule`** that has already been disposed.
///
/// Once a module is disposed, it can no longer provide instances of its services.
///
/// **Example**:
///
/// If you call `module<SomeService>()` after calling `module.dispose()`,
/// a `DependyModuleDisposedException` will be raised.
class DependyModuleDisposedException implements Exception {
  final dynamic message;

  DependyModuleDisposedException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyModuleDisposedException";
    return "DependyModuleDisposedException: $message";
  }
}
