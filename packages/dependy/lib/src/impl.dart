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
    List<DependyDecorate<T>>? decorators,
  })  : _factory = factory,
        _key = key,
        _tag = tag,
        _dependsOn = dependsOn,
        _type = T,
        _dispose = dispose,
        _transient = transient,
        _decorators = decorators ?? const [];

  final DependyFactory<T> _factory;

  final Set<Type>? _dependsOn;
  late final DependyDispose<T?>? _dispose;
  final String? _key;
  final String? _tag;
  final Type _type;
  final bool _transient;
  final List<DependyDecorate<T>> _decorators;

  int get _decoratorCount => _decorators.length;

  T? _instance;

  bool _disposed = false;

  bool get disposed => _disposed;

  /// Disposes of the current provider and performs any cleanup defined in the [dispose] callback.
  void dispose() {
    _dispose?.call(_instance);

    _instance = null;
    _disposed = true;
  }

  /// Resets the provider by clearing the cached instance.
  ///
  /// If the provider has a resolved instance, the [dispose] callback
  /// is called on it before clearing.
  ///
  /// Unlike [dispose], the provider remains usable — the next resolution
  /// will re-run the factory (and decorators) to create a fresh instance.
  ///
  /// No-op for transient providers (no cached instance) and
  /// already-disposed providers.
  void reset() {
    if (_disposed || _transient) return;

    _dispose?.call(_instance);
    _instance = null;
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
      return _applyDecorators(
        await _factory(_resolveDependsOn(resolve)),
        resolve,
      );
    }
    return _instance ??= await _applyDecorators(
      await _factory(_resolveDependsOn(resolve)),
      resolve,
    );
  }

  Future<T> _applyDecorators(T instance, DependyResolve resolve) async {
    var result = instance;
    for (final decorator in _decorators) {
      result = await decorator(result, resolve);
    }
    return result;
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

    final found = _findProviderInGraph<T>(this, <DependyModule>{}, tag: tag);
    if (found == null) {
      throw DependyProviderNotFoundException((T, _key));
    }

    final (provider, owningModule) = found;
    return await provider._create(
      <K extends Object>({String? tag}) => owningModule.call<K>(tag: tag),
    ) as T;
  }

  /// Resets the cached instance for the provider matching type [T] and
  /// optional [tag].
  ///
  /// The provider's [dispose] callback is called on the old instance
  /// before clearing. The next [call] will re-create the instance.
  ///
  /// Cascades automatically — any cached provider whose [dependsOn]
  /// includes [T] is also reset, and so on transitively.
  ///
  /// Throws [DependyModuleDisposedException] if the module is disposed.
  /// Throws [DependyProviderNotFoundException] if no matching provider
  /// is found in this module or its submodules.
  void reset<T extends Object>({String? tag}) {
    if (_disposed) {
      throw DependyModuleDisposedException((this, _key));
    }

    final found = _findProviderInGraph<T>(this, <DependyModule>{}, tag: tag);
    if (found == null) {
      throw DependyProviderNotFoundException((T, _key));
    }

    found.$1.reset();
    _cascadeReset({T}, this);
  }

  /// Walks the module graph depth-first, calling [visitor] for each provider.
  ///
  /// If [visitor] returns `true`, the walk stops early.
  /// Returns `true` if any visitor call short-circuited.
  static bool _walkProviders(
    DependyModule module,
    Set<DependyModule> visited,
    bool Function(DependyProvider<Object> provider, DependyModule module)
        visitor,
  ) {
    for (final provider in module._providers) {
      if (visitor(provider, module)) return true;
    }

    visited.add(module);

    for (final sub in module._modules) {
      if (!visited.contains(sub)) {
        if (_walkProviders(sub, visited, visitor)) return true;
      }
    }

    return false;
  }

  /// Walks the module graph to find the first provider matching [T] and [tag].
  ///
  /// Returns the provider and the module it belongs to, or `null` if not found.
  static (DependyProvider<Object>, DependyModule)?
      _findProviderInGraph<T extends Object>(
    DependyModule module,
    Set<DependyModule> visited, {
    String? tag,
  }) {
    (DependyProvider<Object>, DependyModule)? result;
    _walkProviders(module, visited, (provider, owningModule) {
      if (provider._matches(T, tag)) {
        result = (provider, owningModule);
        return true;
      }
      return false;
    });
    return result;
  }

  static void _cascadeReset(
    Set<Type> resetTypes,
    DependyModule root,
  ) {
    final newlyReset = <Type>{};

    _walkProviders(root, <DependyModule>{}, (provider, _) {
      if (provider._disposed || provider._transient) return false;
      if (provider._instance == null) return false;

      if (provider._dependsOn case final deps?) {
        if (deps.any(resetTypes.contains)) {
          provider.reset();
          newlyReset.add(provider._type);
        }
      }
      return false;
    });

    if (newlyReset.isNotEmpty) {
      _cascadeReset(newlyReset, root);
    }
  }

  /// Creates a new [DependyModule] with the given [providers] replacing any
  /// existing providers that match by type and tag.
  ///
  /// If [modules] is provided, it replaces the submodules entirely.
  /// The original module is not modified.
  ///
  /// Verification runs on the new module, so misconfigurations are caught early.
  DependyModule overrideWith({
    Set<DependyProvider<Object>> providers = const {},
    Set<DependyModule>? modules,
    String? key,
  }) {
    final mergedProviders = <DependyProvider<Object>>{..._providers};

    for (final override in providers) {
      mergedProviders.removeWhere(
        (p) => p._type == override._type && p._tag == override._tag,
      );
      mergedProviders.add(override);
    }

    return DependyModule(
      providers: mergedProviders,
      modules: modules ?? _modules,
      key: key ?? _key,
    );
  }

  /// Returns a formatted string representing the module tree structure,
  /// including all providers and submodules.
  ///
  /// Useful during development for understanding and debugging the
  /// dependency graph.
  String debugGraph() {
    final buffer = StringBuffer();
    _writeDebugGraph(buffer, '', <DependyModule>{});
    return buffer.toString().trimRight();
  }

  void _writeDebugGraph(
    StringBuffer buffer,
    String indent,
    Set<DependyModule> visited,
  ) {
    final keyLabel = _key != null ? ' (key: $_key)' : '';
    final disposedLabel = _disposed ? ' [DISPOSED]' : '';
    buffer.writeln('DependyModule$keyLabel$disposedLabel');

    _writeModuleDebugGraph(
      buffer,
      this,
      indent,
      visited,
      _writeProviderDebug,
    );
  }

  static void _writeModuleDebugGraph(
    StringBuffer buffer,
    DependyModule module,
    String indent,
    Set<DependyModule> visited,
    void Function(
      StringBuffer buffer,
      DependyProvider<Object> provider,
      String prefix,
      String childIndent,
    ) writeProvider,
  ) {
    visited.add(module);

    final entries = <Object>[...module._providers, ...module._modules];
    for (var i = 0; i < entries.length; i++) {
      final isLast = i == entries.length - 1;
      final connector = isLast ? r'\-- ' : '+-- ';
      final childIndent = indent + (isLast ? '    ' : '|   ');
      final entry = entries[i];

      if (entry is DependyProvider<Object>) {
        writeProvider(buffer, entry, '$indent$connector', childIndent);
      } else if (entry is DependyModule) {
        final modKeyLabel = entry._key != null ? ' (key: ${entry._key})' : '';
        final modDisposed = entry._disposed ? ' [DISPOSED]' : '';
        buffer.writeln(
          '$indent$connector[module] DependyModule$modKeyLabel$modDisposed',
        );
        if (!visited.contains(entry)) {
          _writeModuleDebugGraph(
            buffer,
            entry,
            childIndent,
            visited,
            writeProvider,
          );
        } else {
          buffer.writeln('$childIndent(already listed above)');
        }
      }
    }
  }

  static void _writeProviderDebug(
    StringBuffer buffer,
    DependyProvider<Object> provider,
    String prefix,
    String childIndent,
  ) {
    final typeName = provider._type.toString();
    final tagLabel = provider._tag != null ? ' #${provider._tag}' : '';
    final keyLabel = provider._key != null ? ' (key: ${provider._key})' : '';
    final lifecycle = provider._transient ? 'transient' : 'singleton';
    final disposedLabel = provider._disposed ? ' [DISPOSED]' : '';

    String status;
    if (provider._disposed) {
      status = '';
    } else if (provider._transient) {
      status = ' - always new';
    } else {
      status = provider._instance != null ? ' - cached' : ' - pending';
    }

    buffer.writeln(
      '$prefix$typeName$tagLabel [$lifecycle]$keyLabel$disposedLabel$status',
    );

    if (provider._dependsOn case final deps? when deps.isNotEmpty) {
      final depNames = deps.map((d) => d.toString()).join(', ');
      buffer.writeln('$childIndent dependsOn: {$depNames}');
    }

    if (provider._decoratorCount > 0) {
      buffer.writeln(
        '$childIndent decorators: ${provider._decoratorCount}',
      );
    }
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
    _walkProviders(this, <DependyModule>{}, (provider, _) {
      if (provider._type == type) result.add(provider);
      return false;
    });
    return result;
  }

  void _verifyMissingProviders() {
    for (final provider in _providers) {
      if (provider._dependsOn case final dependencies?) {
        for (final dependency in dependencies) {
          final exists = _providers.any((p) => p._type == dependency) ||
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

  /// Returns a formatted string representing the eager module's resolved state.
  String debugGraph() {
    final buffer = StringBuffer();
    final keyLabel = _module._key != null ? ' (key: ${_module._key})' : '';
    final disposedLabel = disposed ? ' [DISPOSED]' : '';
    buffer.writeln('EagerDependyModule$keyLabel$disposedLabel');

    DependyModule._writeModuleDebugGraph(
      buffer,
      _module,
      '',
      <DependyModule>{},
      _writeEagerProviderDebug,
    );

    return buffer.toString().trimRight();
  }

  void _writeEagerProviderDebug(
    StringBuffer buffer,
    DependyProvider<Object> provider,
    String prefix,
    String childIndent,
  ) {
    final typeName = provider._type.toString();
    final tagLabel = provider._tag != null ? ' #${provider._tag}' : '';
    final lifecycle = provider._transient ? 'transient' : 'singleton';
    final resolved =
        _resolvedProviders.containsKey((provider._type, provider._tag));
    final status = resolved ? ' - resolved' : ' - pending';
    buffer.writeln('$prefix$typeName$tagLabel [$lifecycle]$status');

    if (provider._dependsOn case final deps? when deps.isNotEmpty) {
      final depNames = deps.map((d) => d.toString()).join(', ');
      buffer.writeln('$childIndent dependsOn: {$depNames}');
    }

    if (provider._decoratorCount > 0) {
      buffer.writeln(
        '$childIndent decorators: ${provider._decoratorCount}',
      );
    }
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
