import 'package:dependy/dependy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// region WApp
abstract class WApp {
  Widget call({
    required String title,
    required Widget home,
  });
}

class WAppCupertino extends WApp {
  @override
  Widget call({
    required String title,
    required Widget home,
  }) {
    return CupertinoApp(
      title: title,
      home: home,
    );
  }
}

class WAppMaterial extends WApp {
  @override
  Widget call({
    required String title,
    required Widget home,
  }) {
    return MaterialApp(
      title: title,
      home: home,
    );
  }
}
// endregion

// region WScaffold
abstract class WScaffold {
  Widget call({
    required PreferredSizeWidget appBar,
    required Widget body,
  });
}

class WScaffoldCupertino extends WScaffold {
  @override
  Widget call({
    required PreferredSizeWidget appBar,
    required Widget body,
  }) {
    return CupertinoPageScaffold(
      navigationBar: appBar as ObstructingPreferredSizeWidget,
      child: body,
    );
  }
}

class WScaffoldMaterial extends WScaffold {
  @override
  Widget call({
    required PreferredSizeWidget appBar,
    required Widget body,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
    );
  }
}
// endregion

// region WAppBar
abstract class WAppBar {
  PreferredSizeWidget call({
    required String title,
  });
}

class WAppBarCupertino extends WAppBar {
  @override
  PreferredSizeWidget call({required String title}) {
    return CupertinoNavigationBar(
      middle: Text(title),
    );
  }
}

class WAppBarMaterial extends WAppBar {
  @override
  PreferredSizeWidget call({
    required String title,
  }) {
    return AppBar(
      title: Text(title),
    );
  }
}
// endregion

// region Button
abstract class WButton {
  Widget call({
    required String title,
    required VoidCallback onPressed,
  });
}

class WButtonCupertino extends WButton {
  @override
  Widget call({
    required String title,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}

class WButtonMaterial extends WButton {
  @override
  Widget call({
    required String title,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
// endregion

final cupertinoModule = DependyModule(
  providers: {
    DependyProvider<WApp>(
      (dependencies) => WAppCupertino(),
    ),
    DependyProvider<WScaffold>(
      (dependencies) => WScaffoldCupertino(),
    ),
    DependyProvider<WButton>(
      (dependencies) => WButtonCupertino(),
    ),
    DependyProvider<WAppBar>(
      (dependencies) => WAppBarCupertino(),
    ),
  },
);

final materialModule = DependyModule(
  providers: {
    DependyProvider<WApp>(
      (dependencies) => WAppMaterial(),
    ),
    DependyProvider<WScaffold>(
      (dependencies) => WScaffoldMaterial(),
    ),
    DependyProvider<WButton>(
      (dependencies) => WButtonMaterial(),
    ),
    DependyProvider<WAppBar>(
      (dependencies) => WAppBarMaterial(),
    ),
  },
);

class WThemeProvider extends InheritedWidget {
  const WThemeProvider({
    super.key,
    required super.child,
    required this.themeModule,
  });

  final EagerDependyModule themeModule;

  @override
  bool updateShouldNotify(WThemeProvider old) {
    return old.child != child || old.themeModule != themeModule;
  }

  static EagerDependyModule of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<WThemeProvider>();

    if (result == null) throw Exception('No WThemeProvider found in context');

    return result.themeModule;
  }
}
