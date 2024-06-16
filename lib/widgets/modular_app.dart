import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../modules/modules.dart';

class ModularApp extends StatelessWidget {
  /// The widget's child.
  final Widget child;

  /// The app's loading screen.
  final Widget loadingScreen;

  /// Modules to import.
  final Map<Type, ModuleBuilderFunction> imports;

  /// Models to provide.
  final Map<Type, ModelBuilderFunction> provides;

  /// A modular app that [imports] modules and [provides] models to the context
  /// of its [child] widgets.
  const ModularApp({
    super.key,
    required this.imports,
    this.provides = const {},
    required this.loadingScreen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Loads the RootModule instance and provides imported modules and models
    // to child widgets.
    return Provider(
      create: (context) => RootModule(
        imports: imports,
        provides: provides,
      ),
      lazy: false,
      child: _AppLoader(
        loadingChild: loadingScreen,
        child: child,
      ),
    );
  }
}

class _AppLoader extends StatelessWidget {
  final Widget child;
  final Widget loadingChild;

  const _AppLoader({
    required this.loadingChild,
    required this.child,
  });

  Future<bool> loadApp(BuildContext context) async {
    final rootModule = RootModule.of(context);
    rootModule.load(context);
    await rootModule.initialize(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadApp(context),
      builder: (context, snapshot) {
        if (snapshot.data ?? false) {
          return child;
        } else {
          return loadingChild;
        }
      },
    );
  }
}