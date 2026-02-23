/// This exception is thrown when a singleton provider depends on a transient
/// provider, which would silently "capture" the transient instance and defeat
/// its purpose.
///
/// **To fix this**, either:
/// - Make the consuming provider transient as well, or
/// - Make the dependency a singleton if sharing is acceptable.
class DependyCaptiveDependencyException implements Exception {
  final dynamic message;

  DependyCaptiveDependencyException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return 'DependyCaptiveDependencyException';
    return 'DependyCaptiveDependencyException: $message';
  }
}
