import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../modules/modules.dart';

class ModularApp extends StatelessWidget {
  /// The widget's child.
  final Widget child;

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
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Loads the RootModule instance and provides imported modules and models
    // to child widgets.
    return Provider(
      create: (context) {
        final module = RootModule(
          imports: imports,
          provides: provides,
        );
        module.load(context);
        module.initialize(context);
        return module;
      },
      child: child,
    );
  }
}
