import 'package:dependy/dependy.dart';
import 'package:flutter/material.dart';

import 'ui/ui.dart';

class MyButton extends WButton {
  @override
  Widget call({
    required String title,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}

late final EagerDependyModule _materialModuleSync;
late final EagerDependyModule _cupertinoModuleSync;

Future<void> _initializeUIModule() async {
  final extendedMaterialModule = DependyModule(
    providers: {
      DependyProvider<WButton>(
        (dependencies) => MyButton(),
      ),
    },
    modules: {
      materialModule,
    },
  );

  _materialModuleSync = await extendedMaterialModule.asEager();
  _cupertinoModuleSync = await cupertinoModule.asEager();
}

Future<void> main() async {
  await _initializeUIModule();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final homeKey = GlobalKey();

class _MyAppState extends State<MyApp> {
  var uiModule = _materialModuleSync;

  @override
  Widget build(BuildContext context) {
    return WThemeProvider(
      child: Builder(
        builder: (context) {
          final ui = WThemeProvider.of(context);
          return ui<WApp>()(
            title: 'Flutter Demo',
            home: MyHomePage(
              key: homeKey,
              title: 'Flutter Demo Home Page',
              toggleTheme: () {
                setState(() {
                  if (uiModule == _cupertinoModuleSync) {
                    uiModule = _materialModuleSync;
                  } else {
                    uiModule = _cupertinoModuleSync;
                  }
                });
              },
            ),
          );
        },
      ),
      themeModule: uiModule,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.toggleTheme,
  });

  final String title;
  final VoidCallback toggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = WThemeProvider.of(context);
    return ui<WScaffold>()(
      appBar: ui<WAppBar>()(title: "Hello Dependy"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            SizedBox(
              height: 8.0,
            ),
            Text(
              '$_counter',
            ),
            SizedBox(
              height: 8.0,
            ),
            ui<WButton>()(
              title: "Increment",
              onPressed: () {
                _incrementCounter();
              },
            ),
            SizedBox(
              height: 8.0,
            ),
            ui<WButton>()(
              title: "Toggle Theme",
              onPressed: widget.toggleTheme,
            ),
          ],
        ),
      ),
    );
  }
}
