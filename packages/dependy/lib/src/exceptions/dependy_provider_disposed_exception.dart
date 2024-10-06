class DependyProviderDisposedException implements Exception {
  final dynamic message;

  DependyProviderDisposedException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyProviderDisposedException";
    return "DependyProviderDisposedException: $message";
  }
}
