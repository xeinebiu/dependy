import 'exceptions/dependy_circular_dependency_exception.dart';
import 'exceptions/dependy_duplicate_provider_exception.dart';
import 'exceptions/dependy_module_disposed_exception.dart';
import 'exceptions/dependy_provider_disposed_exception.dart';
import 'exceptions/dependy_provider_missing_depends_on_exception.dart';
import 'exceptions/dependy_provider_not_found_exception.dart';
import 'types.dart';

/// A provider responsible for creating instances of type [T] using a specified [factory].
///
/// A key may be provided for debugging purposes.
///
/// Dependencies of [T] must be declared in [dependsOn]; otherwise, a [DependyProviderMissingDependsOnException] is thrown.
///
/// Use [dispose] for any necessary cleanup when the provider is no longer needed.
final class DependyProvider<T extends Object> {
  DependyProvider(
    DependyFactory<T> factory, {
    String? key,
    Set<Type>? dependsOn,
    DependyDispose<T?>? dispose,
  })  : _factory = factory,
        _key = key,
        _dependsOn = dependsOn,
        _type = T,
        _dispose = dispose {}

  final DependyFactory<T> _factory;

  final Set<Type>? _dependsOn;
  late final DependyDispose<T?>? _dispose;
  final String? _key;
  final Type _type;

  T? _instance;

  bool _disposed = false;

  bool get disposed => _disposed;

  /// Disposes of the current provider and performs any cleanup defined in the [dispose] callback.
  void dispose() {
    _dispose?.call(_instance);

    _instance = null;
    _disposed = true;
  }

  /// Checks if the type of the provider matches the given type [other].
  ///
  /// Returns `true` if the types are the same, otherwise `false`.
  bool _isSameType(Type other) {
    return _type == other;
  }

  /// Creates an instance of type [T].
  ///
  /// Uses the provided [resolve] function to handle dependencies.
  ///
  /// Throws [DependyProviderDisposedException] if the provider has been disposed.
  T _create(DependyResolve resolve) {
    if (_disposed) throw DependyProviderDisposedException((this, _key));

    return _instance ??= _factory(_resolveDependsOn(resolve));
  }

  /// Returns a function that can resolve dependencies of type [K].
  ///
  /// Throws [DependyProviderMissingDependsOnException] if a non-declared dependency is requested.
  DependyResolve _resolveDependsOn(DependyResolve resolve) {
    return <K extends Object>() {
      if (_dependsOn case final dependsOn?) {
        for (final dependency in dependsOn) {
          if (K == dependency) {
            return resolve<K>();
          }
        }
      }

      throw DependyProviderMissingDependsOnException((K, _key));
    };
  }
}

/// A module that manages the creation and disposal of providers.
///
/// It verifies that the provider graph is free of circular dependencies and missing providers.
class DependyModule {
  /// The [providers] set contains the [DependyProvider] instances to be managed.
  /// The optional [key] aids in debugging.
  DependyModule({
    required Set<DependyProvider<Object>> providers,
    Set<DependyModule>? modules,
    String? key,
  })  : _providers = providers,
        _modules = modules ?? {},
        _key = key {
    _verify();
  }

  final Set<DependyModule> _modules;
  final Set<DependyProvider<Object>> _providers;
  final String? _key;

  bool _disposed = false;

  /// Disposes all providers in this module.
  /// If [disposeSubmodules] is true, disposes submodules as well.
  void dispose({bool disposeSubmodules = false}) {
    if (_disposed) {
      return;
    }
    _disposed = true;

    for (final provider in _providers) {
      provider.dispose();
    }

    if (disposeSubmodules) {
      for (final module in _modules) {
        module.dispose(disposeSubmodules: true);
      }
    }
  }

  /// Calls the provider for the requested type [T].
  ///
  /// Returns an instance of type [T].
  ///
  /// Throws [DependyProviderNotFoundException] if no provider for [T] is found.
  T call<T extends Object>() {
    if (_disposed) {
      throw DependyModuleDisposedException((this, _key));
    }

    final visited = <DependyModule>{};
    return _callWithModules<T>(this, visited);
  }

  T _callWithModules<T extends Object>(
    DependyModule module,
    Set<DependyModule> visited,
  ) {
    // First check in current module
    for (final provider in module._providers) {
      if (provider._isSameType(T)) {
        return provider._create(module.call) as T;
      }
    }

    visited.add(module);

    // Check in other modules
    for (final module in module._modules) {
      if (!visited.contains(module)) {
        try {
          return module._callWithModules<T>(module, visited);
        } catch (e) {
          // Continue searching, do not throw if not found
          if (e is! DependyProviderNotFoundException) {
            rethrow;
          }
        }
      }
    }

    throw DependyProviderNotFoundException((T, _key));
  }

  void _verify() {
    _verifyMissingProviders();
    _verifyDuplicateProviders();
    _verifyCircularDependency();
  }

  void _verifyCircularDependency() {
    final visited = <Type>{};
    final inProgress = <Type>{};

    for (final provider in _providers) {
      _checkCircularDependency(provider, visited, inProgress);
    }
  }

  void _checkCircularDependency(
    DependyProvider<Object> provider,
    Set<Type> visited,
    Set<Type> inProgress,
  ) {
    if (visited.contains(provider._type)) return;

    if (inProgress.contains(provider._type)) {
      throw DependyCircularDependencyException(
        (
          provider,
          provider._key,
          inProgress.last,
        ),
      );
    }

    inProgress.add(provider._type);

    final dependencies = provider._dependsOn;
    if (dependencies != null) {
      for (final dependency in dependencies) {
        final dependentProvider = _providers.firstWhere(
          (f) => f._isSameType(dependency),
          orElse: () {
            for (final module in _modules) {
              if (module._providers.any((p) => p._isSameType(dependency))) {
                return module._providers.firstWhere(
                  (p) => p._isSameType(dependency),
                );
              }
            }

            throw DependyProviderNotFoundException(
              (
                provider,
                provider._key,
                dependency,
              ),
            );
          },
        );
        _checkCircularDependency(dependentProvider, visited, inProgress);
      }
    }

    inProgress.remove(provider._type);
    visited.add(provider._type);
  }

  void _verifyMissingProviders() {
    for (final provider in _providers) {
      if (provider._dependsOn case final dependencies?) {
        for (final dependency in dependencies) {
          final exists = _providers.any((p) => p._isSameType(dependency)) ||
              _checkDependencyInModules(
                dependency,
                _modules,
              );

          if (!exists) {
            throw DependyProviderNotFoundException(
              (
                provider,
                provider._key,
                dependency,
              ),
            );
          }
        }
      }
    }
  }

  bool _checkDependencyInModules(
    Type dependency,
    Set<DependyModule> modules,
  ) {
    for (final module in modules) {
      // Check if the module itself has the dependency
      if (module._providers.any((p) => p._isSameType(dependency))) {
        return true;
      }

      // Recursively check the sub-modules
      if (_checkDependencyInModules(
        dependency,
        module._modules,
      )) {
        return true;
      }
    }
    return false;
  }

  void _verifyDuplicateProviders() {
    for (final provider in _providers) {
      for (final otherProvider in _providers) {
        if (provider != otherProvider &&
            provider._isSameType(otherProvider._type)) {
          throw DependyDuplicateProviderException((
            this,
            _key,
            provider,
            otherProvider,
          ));
        }
      }
    }
  }
}
