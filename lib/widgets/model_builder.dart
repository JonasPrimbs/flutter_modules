import 'package:flutter/widgets.dart';

import '../models/models.dart';
import '../modules/modules.dart';

class ModelBuilder<T extends Model> extends StatefulWidget {
  /// The model's parent module type.
  final Type? fromModule;

  /// The builder function of the widget's child.
  final Widget Function(BuildContext context, T model) builder;

  /// A widget that uses a [builder] function to build a widget based on the
  /// model of type [T].
  ///
  /// If model is not exported up to the RootModule, use [fromModule] to specify
  /// the model's parent module type. This can be used for improved performance
  /// and to use a scoped model.
  const ModelBuilder({
    super.key,
    this.fromModule,
    required this.builder,
  });

  @override
  State<StatefulWidget> createState() => _ModelBuilderState<T>();
}

class _ModelBuilderState<T extends Model> extends State<ModelBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    // Get the model from root module or from specified submodule.
    final model = widget.fromModule != null
        ? RootModule.of(context).from(widget.fromModule!).get<T>()
        : RootModule.of(context).get<T>();

    // Check whether model is reactive to automatically update it.
    if (model is ReactiveModel) {
      // Model is reactive -> Update it when stateChange stream notifies changes.
      return StreamBuilder(
        stream: model.stateChange,
        builder: (context, _) => widget.builder(context, model),
      );
    } else {
      // Return widget builder with model.
      return widget.builder(context, model);
    }
  }
}
