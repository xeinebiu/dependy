import 'exceptions/dependy_captive_dependency_exception.dart';
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
    String? tag,
    Set<Type>? dependsOn,
    DependyDispose<T?>? dispose,
    bool transient = false,
  })  : _factory = factory,
        _key = key,
        _tag = tag,
        _dependsOn = dependsOn,
        _type = T,
        _dispose = dispose,
        _transient = transient;

  final DependyFactory<T> _factory;

  final Set<Type>? _dependsOn;
  late final DependyDispose<T?>? _dispose;
  final String? _key;
  final String? _tag;
  final Type _type;
  final bool _transient;

  T? _instance;

  bool _disposed = false;

  bool get disposed => _disposed;

  /// Disposes of the current provider and performs any cleanup defined in the [dispose] callback.
  void dispose() {
    _dispose?.call(_instance);

    _instance = null;
    _disposed = true;
  }

  /// Checks if the provider matches the given [type] and [tag].
  ///
  /// Returns `true` if both the type and tag match, otherwise `false`.
  bool _matches(Type type, String? tag) {
    return _type == type && _tag == tag;
  }

  /// Creates an instance of type [T].
  ///
  /// Uses the provided [resolve] function to handle dependencies.
  ///
  /// Throws [DependyProviderDisposedException] if the provider has been disposed.
  Future<T> _create(DependyResolve resolve) async {
    if (_disposed) throw DependyProviderDisposedException((this, _key));

    if (_transient) {
      return await _factory(_resolveDependsOn(resolve));
    }
    return _instance ??= await _factory(_resolveDependsOn(resolve));
  }

  /// Returns a function that can resolve dependencies of type [K].
  ///
  /// Throws [DependyProviderMissingDependsOnException] if a non-declared dependency is requested.
  DependyResolve _resolveDependsOn(DependyResolve resolve) {
    return <K extends Object>({String? tag}) async {
      if (_dependsOn case final dependsOn?) {
        for (final dependency in dependsOn) {
          if (K == dependency) {
            return resolve<K>(tag: tag);
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
  bool get disposed => _disposed;

  /// Disposes all providers in this module.
  ///
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
  /// Optionally specify a [tag] to resolve a specific tagged instance.
  ///
  /// Throws [DependyProviderNotFoundException] if no provider for [T] is found.
  Future<T> call<T extends Object>({String? tag}) async {
    if (_disposed) {
      throw DependyModuleDisposedException((this, _key));
    }

    final visited = <DependyModule>{};
    return _callWithModules<T>(this, visited, tag: tag);
  }

  Future<T> _callWithModules<T extends Object>(
    DependyModule module,
    Set<DependyModule> visited, {
    String? tag,
  }) async {
    // First check in current module
    for (final provider in module._providers) {
      if (provider._matches(T, tag)) {
        return await provider._create(
          <K extends Object>({String? tag}) => module.call<K>(tag: tag),
        ) as T;
      }
    }

    visited.add(module);

    // Check in other modules
    for (final module in module._modules) {
      if (!visited.contains(module)) {
        try {
          return await module._callWithModules<T>(module, visited, tag: tag);
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
    _verifyCaptiveDependencies();
  }

  void _verifyCircularDependency() {
    final visited = <(Type, String?)>{};
    final inProgress = <(Type, String?)>{};

    for (final provider in _providers) {
      _checkCircularDependency(provider, visited, inProgress);
    }
  }

  void _checkCircularDependency(
    DependyProvider<Object> provider,
    Set<(Type, String?)> visited,
    Set<(Type, String?)> inProgress,
  ) {
    final key = (provider._type, provider._tag);

    if (visited.contains(key)) return;

    if (inProgress.contains(key)) {
      throw DependyCircularDependencyException(
        (
          provider,
          provider._key,
          inProgress.last.$1,
        ),
      );
    }

    inProgress.add(key);

    final dependencies = provider._dependsOn;
    if (dependencies != null) {
      for (final dependency in dependencies) {
        final dependentProviders = _findAllProviders(dependency);

        if (dependentProviders.isEmpty) {
          throw DependyProviderNotFoundException(
            (
              provider,
              provider._key,
              dependency,
            ),
          );
        }

        for (final dependentProvider in dependentProviders) {
          _checkCircularDependency(dependentProvider, visited, inProgress);
        }
      }
    }

    inProgress.remove(key);
    visited.add(key);
  }

  /// Finds all providers of the given [type] across this module and submodules.
  List<DependyProvider<Object>> _findAllProviders(Type type) {
    final result = <DependyProvider<Object>>[];
    _collectProviders(type, this, result, <DependyModule>{});
    return result;
  }

  static void _collectProviders(
    Type type,
    DependyModule module,
    List<DependyProvider<Object>> result,
    Set<DependyModule> visited,
  ) {
    if (visited.contains(module)) return;
    visited.add(module);

    for (final provider in module._providers) {
      if (provider._type == type) {
        result.add(provider);
      }
    }

    for (final submodule in module._modules) {
      _collectProviders(type, submodule, result, visited);
    }
  }

  void _verifyMissingProviders() {
    for (final provider in _providers) {
      if (provider._dependsOn case final dependencies?) {
        for (final dependency in dependencies) {
          final exists =
              _providers.any((p) => p._type == dependency) ||
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
      if (module._providers.any((p) => p._type == dependency)) {
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
            provider._matches(otherProvider._type, otherProvider._tag)) {
          throw DependyDuplicateProviderException(
            (
              this,
              _key,
              provider,
              otherProvider,
            ),
          );
        }
      }
    }
  }

  void _verifyCaptiveDependencies() {
    for (final provider in _providers) {
      if (provider._transient) continue;

      if (provider._dependsOn case final dependencies?) {
        for (final dependency in dependencies) {
          final depProviders = _findAllProviders(dependency);
          for (final depProvider in depProviders) {
            if (depProvider._transient) {
              throw DependyCaptiveDependencyException(
                (
                  provider,
                  provider._key,
                  depProvider,
                  depProvider._key,
                ),
              );
            }
          }
        }
      }
    }
  }
}

class EagerDependyModule {
  EagerDependyModule._(this._module);

  final Map<(Type, String?), Object> _resolvedProviders = {};
  final DependyModule _module;

  bool get disposed => _module.disposed;

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Initializes all providers asynchronously. This should be called before any `call<T>()` is made.
  Future<void> _init() async {
    final visited = <DependyModule>{};
    await _resolveAllProviders(_module, visited);

    _initialized = true;
  }

  Future<void> _resolveAllProviders(
    DependyModule module,
    Set<DependyModule> visited,
  ) async {
    for (final provider in module._providers) {
      final key = (provider._type, provider._tag);
      if (!_resolvedProviders.containsKey(key)) {
        _resolvedProviders[key] = await provider._create(
          <K extends Object>({String? tag}) => module.call<K>(tag: tag),
        );
      }
    }

    visited.add(module);

    for (final submodule in module._modules) {
      if (!visited.contains(submodule)) {
        await _resolveAllProviders(submodule, visited);
      }
    }
  }

  T call<T extends Object>({String? tag}) {
    if (disposed) {
      throw DependyModuleDisposedException((this, _module._key));
    }

    if (!initialized) {}

    final provider = _resolvedProviders[(T, tag)];
    if (provider == null) {
      throw DependyProviderNotFoundException((T, _module._key));
    }
    return provider as T;
  }

  /// Disposes all providers in this module.
  ///
  /// If [disposeSubmodules] is true, disposes submodules as well.
  void dispose({bool disposeSubmodules = false}) {
    if (disposed) {
      return;
    }

    _resolvedProviders.clear();

    _module.dispose(disposeSubmodules: disposeSubmodules);
  }
}

extension DependyModuleExt on DependyModule {
  Future<EagerDependyModule> asEager() async {
    final eagerModule = EagerDependyModule._(this);
    await eagerModule._init();
    return eagerModule;
  }
}
