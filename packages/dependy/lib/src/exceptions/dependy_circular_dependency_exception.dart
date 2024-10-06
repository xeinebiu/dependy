class DependyCircularDependencyException implements Exception {
  final dynamic message;

  DependyCircularDependencyException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyCircularDependencyException";
    return "DependyCircularDependencyException: $message";
  }
}
