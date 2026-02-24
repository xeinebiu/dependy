import 'package:dependy/dependy.dart';
import 'package:flutter/material.dart';

import '../dependy_flutter.dart';

/// A snapshot of the current state of an async dependency resolution.
///
/// Use pattern matching to handle each state:
/// ```dart
/// switch (snapshot) {
///   AsyncDependyLoading() => const CircularProgressIndicator(),
///   AsyncDependyData(:final value) => Text('$value'),
///   AsyncDependyError(:final error) => Text('$error'),
/// }
/// ```
sealed class AsyncDependySnapshot<T> {
  const AsyncDependySnapshot();
}

/// The dependency is being resolved.
class AsyncDependyLoading<T> extends AsyncDependySnapshot<T> {
  const AsyncDependyLoading();
}

/// The dependency has been resolved successfully.
class AsyncDependyData<T> extends AsyncDependySnapshot<T> {
  const AsyncDependyData(this.value);

  /// The resolved instance.
  final T value;
}

/// The dependency resolution failed.
class AsyncDependyError<T> extends AsyncDependySnapshot<T> {
  const AsyncDependyError(this.error, this.stackTrace);

  /// The error that occurred during resolution.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;
}

/// A widget that resolves an async dependency of type [T] and provides an
/// [AsyncDependySnapshot] to a single builder — removing the need to nest
/// [ScopedDependyConsumer] with [FutureBuilder].
///
/// When [watch] is true and [T] is a [ChangeNotifier], the widget
/// automatically listens for changes and rebuilds.
///
/// ```dart
/// ScopedDependyAsyncBuilder<CounterService>(
///   builder: (context, snapshot) {
///     if (snapshot case AsyncDependyData(:final value)) {
///       return Text('${value.counter}');
///     }
///     return const CircularProgressIndicator();
///   },
/// )
/// ```
class ScopedDependyAsyncBuilder<T extends Object> extends StatefulWidget {
  const ScopedDependyAsyncBuilder({
    super.key,
    required this.builder,
    this.module,
    this.tag,
    this.watch = true,
  });

  /// Builds the widget with the current [AsyncDependySnapshot].
  final Widget Function(BuildContext context, AsyncDependySnapshot<T> snapshot)
      builder;

  /// If provided, resolves from this module instead of the widget tree scope.
  final DependyModule? module;

  /// Optional tag for tagged provider resolution.
  final String? tag;

  /// When true, listens to the resolved [ChangeNotifier] and rebuilds on
  /// changes.
  final bool watch;

  @override
  State<ScopedDependyAsyncBuilder<T>> createState() =>
      _ScopedDependyAsyncBuilderState<T>();
}

class _ScopedDependyAsyncBuilderState<T extends Object>
    extends State<ScopedDependyAsyncBuilder<T>> {
  AsyncDependySnapshot<T> _snapshot = AsyncDependyLoading<T>();
  bool _hasResolved = false;

  final _listeningObjects = <ChangeNotifier, VoidCallback>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasResolved) {
      _resolve();
    }
  }

  @override
  void didUpdateWidget(covariant ScopedDependyAsyncBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tag != widget.tag ||
        oldWidget.module != widget.module ||
        oldWidget.watch != widget.watch) {
      _removeListeners();
      _resolve();
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _removeListeners() {
    _listeningObjects.forEach((notifier, callback) {
      notifier.removeListener(callback);
    });
    _listeningObjects.clear();
  }

  Future<void> _resolve() async {
    if (!_hasResolved) {
      setState(() {
        _snapshot = AsyncDependyLoading<T>();
      });
    }

    try {
      final T instance;
      final providedModule = widget.module;
      if (providedModule != null) {
        instance = await providedModule<T>(tag: widget.tag);
      } else {
        final scope = getDependyScope(context);
        instance = await scope.dependy<T>(tag: widget.tag);
      }

      if (widget.watch) {
        if (instance case final ChangeNotifier notifier) {
          if (!_listeningObjects.containsKey(notifier)) {
            notifier.addListener(_onNotifierChanged);
            _listeningObjects[notifier] = _onNotifierChanged;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _snapshot = AsyncDependyData<T>(instance);
        _hasResolved = true;
      });
    } catch (e, st) {
      if (!mounted) return;

      setState(() {
        _snapshot = AsyncDependyError<T>(e, st);
        _hasResolved = true;
      });
    }
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _snapshot);
  }
}
