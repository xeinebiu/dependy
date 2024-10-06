/// This exception is thrown when there is a circular dependency in the provider graph.
///
/// A circular dependency occurs when two or more providers depend on each other directly
/// or indirectly, leading to an infinite loop during resolution.
///
/// **Example**:
///
/// If **Service-A** depends on **Service-B**, **Service-B** depends on **Service-C**,
/// and **Service-C** depends on **Service-A**. This indirect chain of dependencies
/// leads to an infinite loop during resolution.
class DependyCircularDependencyException implements Exception {
  final dynamic message;

  DependyCircularDependencyException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return 'DependyCircularDependencyException';
    return 'DependyCircularDependencyException: $message';
  }
}
