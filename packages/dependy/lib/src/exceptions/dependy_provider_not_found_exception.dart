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
