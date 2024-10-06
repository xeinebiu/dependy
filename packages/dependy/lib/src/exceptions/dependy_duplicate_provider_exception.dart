/// This exception is thrown when there is more than one provider of the
/// same type registered within a single module.
///
/// **Example**:
///
/// ```dart
/// final databaseModule = DependyModule(
///   providers: {
///     DependyProvider<DatabaseService>(
///           (_) => SqlDatabaseService(),
///     ),
///     DependyProvider<DatabaseService>(
///           (_) => SqliteDatabaseService(),
///       dependsOn: {},
///     ),
///   },
/// );
/// ```
class DependyDuplicateProviderException implements Exception {
  final dynamic message;

  DependyDuplicateProviderException(this.message);

  @override
  String toString() {
    final message = this.message;
    if (message == null) return 'DependyDuplicateProviderException';
    return 'DependyDuplicateProviderException: $message';
  }
}
