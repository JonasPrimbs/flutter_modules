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
        child: child,
      ),
    );
  }
}

final class _AppLoader extends StatefulWidget {
  final Widget child;
  final Widget? loadingChild;

  const _AppLoader({
    this.loadingChild,
    required this.child,
  });

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

final class _AppLoaderState extends State<_AppLoader> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();

    _initFuture = _loadApp(context).catchError((error, stack) {
      // Make sure it is surfaced in Flutter's error pipeline:
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_modules',
          context: ErrorDescription('while initializing RootModule'),
        ),
      );

      // Keep the Future failed so FutureBuilder can show an error UI.
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _loadApp(BuildContext context) async {
    final rootModule = RootModule.of(context);
    rootModule.load(context);
    await rootModule.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingChild ?? const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }

        return widget.child;
      },
    );
  }
}
