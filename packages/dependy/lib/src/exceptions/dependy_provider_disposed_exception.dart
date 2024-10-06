/// This exception is thrown when you try to use a provider that has already
/// been disposed.
///
/// Once a provider is disposed, it cannot be used anymore.
///
/// **Example**:
///
/// If you call `<module><T>()` on a disposed provider,
/// a `DependyProviderDisposedException` will be raised.
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
