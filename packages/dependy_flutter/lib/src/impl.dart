import 'package:dependy/dependy.dart';
import 'package:flutter/material.dart';

/// A helper class to provide access to:
/// - `dependy`: Retrieves a dependency of type [T] from the dependency graph.
/// - `watchDependy`: Retrieves a [ChangeNotifier] of type [T] from the dependency graph
///    and listens for changes in the notifier.
final class ScopedDependy {
  const ScopedDependy._(this.dependy, this.watchDependy);

  /// Retrieves a dependency of type [T] from the dependency graph.
  final Future<T> Function<T extends Object>() dependy;

  /// Retrieves a [ChangeNotifier] dependency of type [T] from the dependency graph
  /// and registers a listener to rebuild the UI when the notifier changes.
  ///
  /// This method is safe to call multiple times, as the listener will only be registered once.
  final Future<T> Function<T extends ChangeNotifier>() watchDependy;
}

/// Retrieves the nearest [ScopedDependy] from the widget tree.
///
/// Throws an exception if no [dependy] provider is found.
///
/// Note: When retrieving a scope using this call and watching a service,
/// the rebuild will happen on the Widget that is providing the scope. To avoid it,
/// consider using [ScopedDependyConsumer].
ScopedDependy getDependyScope(BuildContext context) {
  return _ScopedDependyModuleProvider.scopedOf(context);
}

class _ScopedDependyModuleProvider extends InheritedWidget {
  const _ScopedDependyModuleProvider({
    required super.child,
    required this.scopedDependy,
    required this.moduleBuilder,
  });

  final DependyModule Function() moduleBuilder;

  final ScopedDependy scopedDependy;

  static ScopedDependy scopedOf(BuildContext context) {
    final scopedDependy = context
        .dependOnInheritedWidgetOfExactType<_ScopedDependyModuleProvider>()
        ?.scopedDependy;

    if (scopedDependy == null) {
      throw Exception('No ScopedDependyProvider found in context');
    }

    return scopedDependy;
  }

  static DependyModule moduleOf(BuildContext context) {
    final moduleBuilder = context
        .dependOnInheritedWidgetOfExactType<_ScopedDependyModuleProvider>()
        ?.moduleBuilder;

    if (moduleBuilder == null) {
      throw Exception('No ScopedDependyProvider found in context');
    }

    return moduleBuilder();
  }

  @override
  bool updateShouldNotify(_ScopedDependyModuleProvider oldWidget) =>
      scopedDependy != oldWidget.scopedDependy ||
      moduleBuilder != oldWidget.moduleBuilder;
}

/// A mixin to provide a [Widget] scope for a [dependy] module.
mixin ScopedDependyMixin<W extends StatefulWidget> on State<W> {
  DependyModule? _cachedDependyModule;

  final _listeningObjects = <ChangeNotifier, void Function()>{};

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();

    _listeningObjects.forEach((key, value) {
      key.removeListener(value);
    });
    _listeningObjects.clear();

    _cachedDependyModule?.dispose(disposeSubmodules: false);
  }

  /// Shares the actual scope with descendants widgets.
  @protected
  Widget shareDependyScope({
    required Widget child,
  }) {
    return _ScopedDependyModuleProvider(
      scopedDependy: ScopedDependy._(
        dependy,
        watchDependy,
      ),
      moduleBuilder: _cachedModuleBuilder,
      child: child,
    );
  }

  /// Retrieves a dependency of type [T] from the dependency graph.
  Future<T> dependy<T extends Object>() => _dependy<T>();

  /// Retrieves a [ChangeNotifier] dependency of type [T] from the dependency graph
  /// and registers a listener to rebuild the UI when the notifier changes.
  ///
  /// This method is safe to call multiple times, as the listener will only be registered once.
  Future<T> watchDependy<T extends ChangeNotifier>() =>
      _dependy<T>(watch: true);

  /// Retrieves a [DependyModule] from the nearest graph.
  DependyModule parentModule() {
    return _ScopedDependyModuleProvider.moduleOf(context);
  }

  /// Returns a [DependyModule] instance that should be scoped to the actual [Widget] tree.
  ///
  /// Note: Do not return a singleton module from here as that module will be disposed
  /// once the [Widget] is removed from the tree.
  ///
  /// If you are not overriding or providing any extra module or providers specifically for
  /// this [Widget], then you might not need to use the [ScopedDependyMixin].
  DependyModule moduleBuilder();

  DependyModule _cachedModuleBuilder() {
    return _cachedDependyModule ??= moduleBuilder();
  }

  Future<T> _dependy<T extends Object>({bool watch = false}) async {
    final module = _cachedModuleBuilder();
    final obj = await module<T>();

    if (watch) {
      if (obj case final ChangeNotifier notifier) {
        if (!_listeningObjects.containsKey(notifier)) {
          notifier.addListener(_reBuildUI);
          _listeningObjects[notifier] = _reBuildUI;
        }
      }
    }

    return obj;
  }

  void _reBuildUI() {
    setState(() {});
  }
}

/// A [Widget] that provides a scoped dependency module.
class ScopedDependyProvider extends StatefulWidget {
  const ScopedDependyProvider({
    super.key,
    required this.builder,
    required this.moduleBuilder,
    this.shareScope = false,
  });

  /// Build the widget with access to `ScopedDependy` for dependency injection.
  final Widget Function(
    BuildContext context,
    ScopedDependy scope,
  ) builder;

  /// Returns a [DependyModule] instance that should be scoped to the actual [Widget] tree.
  ///
  /// Note: Do not return a singleton module from here as that module will be disposed
  /// once the [Widget] is removed from the tree.
  ///
  /// If you are not overriding or providing any extra module or providers specifically for
  /// this [Widget], then you might not need to use the [ScopedDependyMixin].
  final DependyModule Function(
    DependyModule Function() parentModule,
  ) moduleBuilder;

  /// if true, shares the actual scope with descendant widgets.
  final bool shareScope;

  @override
  State<ScopedDependyProvider> createState() => _ScopedDependyProviderState();
}

class _ScopedDependyProviderState extends State<ScopedDependyProvider>
    with ScopedDependyMixin {
  @override
  Widget build(BuildContext context) {
    final view = widget.builder(
      context,
      ScopedDependy._(dependy, watchDependy),
    );

    if (widget.shareScope) {
      return shareDependyScope(child: view);
    }

    return view;
  }

  @override
  DependyModule moduleBuilder() {
    return widget.moduleBuilder(parentModule);
  }
}

/// A widget that consumes a dependency module.
///
/// This is useful when you need to watch for changes on specific services
/// or retrieve a module from the nearest tree.
class ScopedDependyConsumer extends StatefulWidget {
  const ScopedDependyConsumer({
    super.key,
    required this.builder,
    this.module,
  });

  /// Called on each build with a given [BuildContext] and [ScopedDependy].
  ///
  /// Use the [ScopedDependy] to resolve dependencies.
  final Widget Function(
    BuildContext context,
    ScopedDependy scope,
  ) builder;

  /// If provided, the [ScopedDependyConsumer] will use the given [DependyModule].
  /// Otherwise, it will look for a [DependyModule] in the nearest graph.
  final DependyModule? module;

  @override
  State<ScopedDependyConsumer> createState() => _ScopedDependyConsumerState();
}

class _ScopedDependyConsumerState extends State<ScopedDependyConsumer> {
  final _listeningObjects = <ChangeNotifier, void Function()>{};

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      ScopedDependy._(
        <T extends Object>() => _dependy<T>(context),
        <T extends ChangeNotifier>() => _dependy<T>(
          context,
          watch: true,
        ),
      ),
    );
  }

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();

    _listeningObjects.forEach((key, value) {
      key.removeListener(value);
    });
    _listeningObjects.clear();
  }

  Future<T> _dependy<T extends Object>(
    BuildContext context, {
    bool watch = false,
  }) async {
    final providedModule = widget.module;
    T obj;
    if (providedModule != null) {
      obj = await providedModule<T>();
    } else {
      final module = getDependyScope(context);
      obj = await module.dependy<T>();
    }

    if (watch) {
      if (obj case final ChangeNotifier notifier) {
        if (!_listeningObjects.containsKey(notifier)) {
          notifier.addListener(_reBuildUI);
          _listeningObjects[notifier] = _reBuildUI;
        }
      }
    }

    return obj;
  }

  void _reBuildUI() {
    setState(() {});
  }
}
