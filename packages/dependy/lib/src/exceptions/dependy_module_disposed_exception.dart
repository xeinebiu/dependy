class DependyModuleDisposedException implements Exception {
  final dynamic message;

  DependyModuleDisposedException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return "DependyModuleDisposedException";
    return "DependyModuleDisposedException: $message";
  }
}
