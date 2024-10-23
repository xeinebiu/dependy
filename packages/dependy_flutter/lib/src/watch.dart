import 'package:flutter/material.dart';

/// A widget that listens to a [ChangeNotifier] and rebuilds its child
/// whenever the notifier's state changes.
///
///
/// [DependyNotifierListener] accepts a [notifier] and a [builder] function.
/// The [builder] function is called every time the notifier calls `notifyListeners()`.
class DependyNotifierListener<T extends ChangeNotifier> extends StatefulWidget {
  /// Creates a [DependyNotifierListener] that listens to the provided [notifier].
  ///
  /// The [builder] function will be called with the current context and the
  /// [notifier] every time the notifier changes.
  const DependyNotifierListener({
    super.key,
    required this.notifier,
    required this.builder,
  });

  /// The [ChangeNotifier] that this widget will listen to.
  ///
  /// The [DependyNotifierListener] rebuilds whenever this [notifier] calls
  /// `notifyListeners()`.
  final T notifier;

  /// A function that builds a widget using the provided [BuildContext] and
  /// the [notifier].
  ///
  /// This builder will be called every time the [notifier] calls
  /// `notifyListeners()`.
  final Widget Function(BuildContext context, T notifier) builder;

  @override
  State createState() => _DependyNotifierListenerState<T>();
}

class _DependyNotifierListenerState<T extends ChangeNotifier>
    extends State<DependyNotifierListener<T>> {
  @override
  void initState() {
    super.initState();

    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }
}
