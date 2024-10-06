import 'dart:async';

/// Used as part of [DependyFactory] to resolve `dependsOn` dependencies
///
/// **Example**
///
/// ````dart
///     DependyProvider<CalculatorService>(
///       (dependy) => CalculatorService(dependy<LoggerService>()),
///       ...
///     ),
/// ````
typedef DependyResolve = FutureOr<T> Function<T extends Object>();

/// Used on [DependyProvider] to notify about disposal of it.
///
/// While notifying the listeners, if the [DependyProvider] has been resolved, an
/// instance of resolved [T] will be provided.
///
/// **Example**
///
/// ````dart
///     DependyProvider<DatabaseService>(
///       ...
///       dispose: (database) {
///         database?.close();
///       },
///     ),
///
/// ````
typedef DependyDispose<T> = void Function(T);

/// Used on [DependyProvider] to create an instance of given [T].
///
/// It provides a [DependyResolve] to resolve `dependsOn` dependencies.
///
/// **Example**
///
/// ````dart
///    DependyProvider<CalculatorService>(
///       (dependy) => CalculatorService(dependy<LoggerService>()),
///       ...
///     )
/// ````
typedef DependyFactory<T extends Object> = FutureOr<T> Function(
  DependyResolve dependencies,
);
