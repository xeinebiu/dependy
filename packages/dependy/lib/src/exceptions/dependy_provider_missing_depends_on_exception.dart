class DependyProviderMissingDependsOnException implements Exception {
  final dynamic message;

  DependyProviderMissingDependsOnException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyProviderMissingDependsOnException";
    return "DependyProviderMissingDependsOnException: $message";
  }
}
