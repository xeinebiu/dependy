class DependyDuplicateProviderException implements Exception {
  final dynamic message;

  DependyDuplicateProviderException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyDuplicateProviderException";
    return "DependyDuplicateProviderException: $message";
  }
}
