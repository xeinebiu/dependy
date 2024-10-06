/// This exception is thrown when a provider tries to resolve a dependency
/// that has not been declared in its `dependsOn` set.
///
/// This verifies that all dependencies are explicitly defined,
/// promoting better design and avoiding runtime errors.
///
/// **Example**:
///
/// If **Provider D** requires **Provider E**, but **Provider E** is not listed
/// in the `dependsOn` set of **Provider D**,
/// a `DependyProviderMissingDependsOnException` will occur.
class DependyProviderMissingDependsOnException implements Exception {
  final dynamic message;

  DependyProviderMissingDependsOnException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return 'DependyProviderMissingDependsOnException';
    return 'DependyProviderMissingDependsOnException: $message';
  }
}
