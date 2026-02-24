import 'dart:async';

import 'package:dependy/dependy.dart';
import 'package:dependy_flutter/dependy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Test helpers ---

class _Counter extends ChangeNotifier {
  int value = 0;

  void increment() {
    value++;
    notifyListeners();
  }
}

class _PlainService {
  final String label;
  _PlainService(this.label);
}

/// Wraps the [child] inside a [ScopedDependyProvider] backed by [module].
Widget _scopeApp({
  required DependyModule module,
  required Widget child,
}) {
  return MaterialApp(
    home: ScopedDependyProvider(
      moduleBuilder: (_) => module,
      shareScope: true,
      builder: (context, scope) => child,
    ),
  );
}

// --- Tests ---

void main() {
  group('ScopedDependyAsyncBuilder', () {
    testWidgets('snapshot is loading before resolution completes',
        (tester) async {
      final completer = Completer<_PlainService>();

      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => completer.future,
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) => Text(value.label),
              _ => const Text('loading'),
            },
          ),
        ),
      );

      // First frame: loading phase.
      await tester.pump();
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('hello'), findsNothing);

      // Complete the future and let it resolve.
      completer.complete(_PlainService('hello'));
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(find.text('loading'), findsNothing);
    });

    testWidgets('snapshot has data after resolution', (tester) async {
      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => _PlainService('resolved'),
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) => Text(value.label),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('resolved'), findsOneWidget);
    });

    testWidgets('snapshot has error on resolution failure', (tester) async {
      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => throw Exception('boom'),
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyError(:final error) => Text('error: $error'),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('error:'), findsOneWidget);
    });

    testWidgets('snapshot exposes stackTrace on error', (tester) async {
      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => throw Exception('kaboom'),
          ),
        },
      );

      late AsyncDependySnapshot<_PlainService> captured;

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            builder: (context, snapshot) {
              captured = snapshot;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(captured, isA<AsyncDependyError<_PlainService>>());
      final error = captured as AsyncDependyError<_PlainService>;
      expect(error.error, isA<Exception>());
      expect(error.stackTrace, isNotNull);
    });

    testWidgets('rebuilds when watched ChangeNotifier fires', (tester) async {
      final counter = _Counter();

      final module = DependyModule(
        providers: {
          DependyProvider<_Counter>(
            (_) => counter,
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_Counter>(
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) =>
                Text('count: ${value.value}'),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('count: 0'), findsOneWidget);

      counter.increment();
      await tester.pump();

      expect(find.text('count: 1'), findsOneWidget);
    });

    testWidgets('resolves tagged provider correctly', (tester) async {
      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => _PlainService('default'),
          ),
          DependyProvider<_PlainService>(
            (_) => _PlainService('tagged'),
            tag: 'special',
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            tag: 'special',
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) => Text(value.label),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('tagged'), findsOneWidget);
    });

    testWidgets('resolves from provided module instead of scope',
        (tester) async {
      final scopeModule = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => _PlainService('from-scope'),
          ),
        },
      );

      final explicitModule = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => _PlainService('from-module'),
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: scopeModule,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            module: explicitModule,
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) => Text(value.label),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('from-module'), findsOneWidget);
    });

    testWidgets('removes listeners on dispose', (tester) async {
      final counter = _Counter();

      final module = DependyModule(
        providers: {
          DependyProvider<_Counter>(
            (_) => counter,
          ),
        },
      );

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_Counter>(
            builder: (context, snapshot) => switch (snapshot) {
              AsyncDependyData(:final value) =>
                Text('count: ${value.value}'),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('count: 0'), findsOneWidget);

      // Replace the entire widget tree so the async builder is disposed.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      // Incrementing after dispose should not throw (listener removed).
      counter.increment();
      expect(counter.value, 1);
    });

    testWidgets('re-resolves on didUpdateWidget (tag change)', (tester) async {
      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => _PlainService('default'),
          ),
          DependyProvider<_PlainService>(
            (_) => _PlainService('other'),
            tag: 'other',
          ),
        },
      );

      String? currentTag;

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => currentTag = 'other'),
                    child: const Text('switch'),
                  ),
                  ScopedDependyAsyncBuilder<_PlainService>(
                    tag: currentTag,
                    builder: (context, snapshot) => switch (snapshot) {
                      AsyncDependyData(:final value) => Text(value.label),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('default'), findsOneWidget);

      // Tap the button to change the tag.
      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      expect(find.text('other'), findsOneWidget);
    });

    testWidgets('snapshot is AsyncDependyLoading initially', (tester) async {
      final completer = Completer<_PlainService>();

      final module = DependyModule(
        providers: {
          DependyProvider<_PlainService>(
            (_) => completer.future,
          ),
        },
      );

      late AsyncDependySnapshot<_PlainService> captured;

      await tester.pumpWidget(
        _scopeApp(
          module: module,
          child: ScopedDependyAsyncBuilder<_PlainService>(
            builder: (context, snapshot) {
              captured = snapshot;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pump();

      expect(captured, isA<AsyncDependyLoading<_PlainService>>());

      completer.complete(_PlainService('done'));
      await tester.pumpAndSettle();

      expect(captured, isA<AsyncDependyData<_PlainService>>());
    });

    testWidgets(
        'button resolved via scope increments same instance watched by builder',
        (tester) async {
      final servicesModule = DependyModule(
        providers: {
          DependyProvider<_Counter>(
            (_) => _Counter(),
          ),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScopedDependyProvider(
            moduleBuilder: (_) => DependyModule(
              providers: {},
              modules: {servicesModule},
            ),
            shareScope: true,
            builder: (context, scope) {
              return Column(
                children: [
                  // Display — watches the counter via ScopedDependyAsyncBuilder.
                  ScopedDependyAsyncBuilder<_Counter>(
                    builder: (context, snapshot) => switch (snapshot) {
                      AsyncDependyData(:final value) =>
                        Text('count: ${value.value}'),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                  // Button — resolves from scope on press (like CounterButton).
                  Builder(
                    builder: (context) {
                      final scope = getDependyScope(context);
                      return ElevatedButton(
                        onPressed: () async {
                          final counter =
                              await scope.dependy<_Counter>();
                          counter.increment();
                        },
                        child: const Text('increment'),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('count: 0'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pumpAndSettle();

      expect(find.text('count: 1'), findsOneWidget);

      await tester.tap(find.text('increment'));
      await tester.pumpAndSettle();

      expect(find.text('count: 2'), findsOneWidget);
    });
  });
}
