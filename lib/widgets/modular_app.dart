import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../modules/modules.dart';

class ModularApp extends StatelessWidget {
  /// The widget's child.
  final Widget child;

  /// The app's loading screen.
  final Widget? loadingScreen;

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
    this.loadingScreen,
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
        context: context,
        child: child,
      ),
    );
  }
}

final class _AppLoader extends StatefulWidget {
  final Widget child;
  final Widget? loadingChild;
  final BuildContext context;

  const _AppLoader({
    this.loadingChild,
    required this.context,
    required this.child,
  });

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

final class _AppLoaderState extends State<_AppLoader> {
  bool _loaded = false;

  Future<void> _loadApp(BuildContext context) async {
    final rootModule = RootModule.of(context);
    rootModule.load(context);
    await rootModule.initialize(context);
  }

  @override
  void initState() {
    super.initState();

    _loadApp(widget.context).then((value) {
      setState(() {
        _loaded = true;
      });
    },);
  }

  @override
  Widget build(BuildContext context) {
        final loader = widget.loadingChild;
        if (loader != null && _loaded) {
          return loader;
        } else {
          return widget.child;
        }
  }
}
