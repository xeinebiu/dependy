
/// This exception occurs when you try to resolve a provider for a specific type,
/// but no provider is registered for that type within the module or its submodules.
///
/// **Example**: If you attempt to get an instance of **Provider C** but it
/// has not been defined in the current module or any of its submodules,
/// a `DependyProviderNotFoundException` will be thrown.
class DependyProviderNotFoundException implements Exception {
  final dynamic message;

  DependyProviderNotFoundException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyProviderNotFoundException";
    return "DependyProviderNotFoundException: $message";
  }
}
