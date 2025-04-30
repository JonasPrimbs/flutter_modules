import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../model_extensions/model_extensions.dart';
import '../models/models.dart';
import './module_builder_function.dart';

class Module {
  /// Builder functions of modules to import.
  final Map<Type, ModuleBuilderFunction> _imports;

  /// Builder functions of models to provide.
  final Map<Type, ModelBuilderFunction> _provides;

  /// Set of model types to be exported.
  final Set<Type> _exports;

  /// Imported sub-modules.
  final _modules = <Type, Module>{};

  /// Gets all submodules.
  Iterable<Module> get modules => _modules.values;

  /// Provided models.
  final _models = <Type, Model>{};
  Iterable<Model> get models => _models.values;

  /// Gets all models that are exported.
  Iterable<Model> get exportedModels => _exports
      .map(
        (type) => _models[type],
      )
      .nonNulls;

  /// Gets all models that are not exported.
  Iterable<Model> get internalModels => models.whereNot(
        (model) => _exports.contains(model.runtimeType),
      );

  /// Creates a module that [imports] modules, [provides] models, and [exports]
  /// provided or imported models.
  Module({
    Map<Type, ModuleBuilderFunction> imports = const {},
    Map<Type, ModelBuilderFunction> provides = const {},
    Set<Type> exports = const {},
  })  : _exports = exports,
        _provides = provides,
        _imports = imports;

  /// Gets a provided model by its type [T].
  T get<T extends Model>() {
    if (!_models.containsKey(T)) {
      throw 'Model of type "${T.runtimeType}" not found!';
    }
    return _models[T] as T;
  }

  /// Gets a provided reactive model by its type [T].
  T getReactive<T extends IReactiveModel>() {
    return _models[T] as T;
  }

  /// Gets all provided models which implement the type [T].
  Iterable<T> getWith<T>() {
    return _models.values.whereType<T>();
  }

  /// Whether the module provides a model of type [T].
  bool provides<T extends Model>() {
    return _models.containsKey(T);
  }

  /// Whether the module provides a model of type [T].
  bool providesReactive<T extends IReactiveModel>() {
    return _models.containsKey(T);
  }

  /// Gets an imported module by its type [T].
  Module from(Type module) {
    return _modules[module]!;
  }

  /// Creates module of a specific [type] using a [createModule] function from
  /// build [context].
  Module _createModule(
    Type type,
    ModuleBuilderFunction createModule,
    BuildContext context,
  ) {
    // Create instance of module to import.
    final module = createModule(context);

    // Ensure that module type matches expected type.
    if (module.runtimeType != type) {
      throw 'Module builder function returns instance of type "${module.runtimeType}" but expected instance of type "$type"!';
    }

    return module;
  }

  /// Registers a [module].
  void _registerModule(Module module) {
    // Ensure that module is not yet registered.
    if (_modules.containsKey(module.runtimeType)) {
      throw 'Module of type "${module.runtimeType}" already registered!';
    }

    // Register module.
    _modules[module.runtimeType] = module;
  }

  /// Imports all submodules or creates them using a build [context].
  /// All loaded modules will be propagated through the entire [modulePath] up
  /// to the root module.
  void _importModules(
    BuildContext context, [
    Iterable<Module> modulePath = const Iterable<Module>.empty(),
  ]) {
    // Import all submodules.
    for (final import in _imports.entries) {
      // Check whether module is already imported in this module.
      if (_modules.containsKey(import.key)) {
        // Module already imported.
        continue;
      }

      // Check whether model was already imported to root module.
      if (modulePath.firstOrNull?._modules.containsKey(import.key) ?? false) {
        // Check for circular dependencies.
        final circularModule = modulePath.firstWhereOrNull(
          (parentModule) => parentModule.runtimeType == import.key,
        );
        // Throw exception if circularModule was found.
        if (circularModule != null) {
          throw 'Circular dependency detected! Module "${circularModule.runtimeType}" imports module "${import.key}"!';
        }

        // Get module from root module.
        final module = modulePath.first._modules[import.key] as Module;

        // Register module in this module.
        _registerModule(module);
        // Register module to all parent modules if provided.
        for (final parentModule in modulePath) {
          // Register created module to parent module if not already registered.
          if (!parentModule._modules.containsKey(import.key)){
            parentModule._registerModule(module);
          }
        }
      } else {
        // Create new module instance.
        final module = _createModule(import.key, import.value, context);

        // Register module in this module.
        _registerModule(module);
        // Register module to all parent modules if provided.
        for (final parentModule in modulePath) {
          // Register created module to parent module.
          parentModule._registerModule(module);
        }

        // Import the submodule. Therefore, this module is appended to the
        // modulePath at the end to keep track from root module to this module
        // in the module tree.
        module._importModules(context, [...modulePath, this]);
      }
    }
  }

  /// Creates a model of a specific [type] using a [createModel] function from
  /// build [context].
  Model _createModel(
    Type type,
    ModelBuilderFunction createModel,
    BuildContext context,
  ) {
    // Create instance of model.
    final model = createModel(context, this);

    // Ensure that model matches expected type.
    if (model.runtimeType != type) {
      throw 'Model builder function returns instance of type "${model.runtimeType}" but expected instance of type "$type"!';
    }

    return model;
  }

  /// Registers a [model].
  void _registerModel(Model model) {
    // Ensure that model is not yet registered.
    if (_models.containsKey(model.runtimeType)) {
      throw 'Module of type "${model.runtimeType}" already registered!';
    }

    // Register model.
    _models[model.runtimeType] = model;
  }

  /// Imports all models if exported from submodules or creates them using a
  /// build [context].
  void _loadModels(BuildContext context) {
    // Load all submodules and export their exported models.
    for (final module in _modules.values) {
      // Load submodule.
      module._loadModels(context);

      // Export submodule's exported models.
      for (final modelType in module._exports) {
        // Ensure that model was not yet exported.
        if (_models.containsKey(modelType)) {
          continue;
        }

        // Ensure that model is provided by module.
        if (!module._models.containsKey(modelType)) {
          throw 'Exported model of type "$modelType" is not provided by module "${module.runtimeType}"!';
        }

        // Export the model from submodule
        final model = module._models[modelType]!;

        // Import the model to this module.
        _registerModel(model);
      }
    }

    // Load this module's models.
    for (final providerEntry in _provides.entries) {
      // Ensure that model is not yet registered.
      if (_models.containsKey(providerEntry.key)) {
        continue;
      }

      // Create new model instance.
      final model = _createModel(
        providerEntry.key,
        providerEntry.value,
        context,
      );

      // Register created model instance.
      _registerModel(model);
    }

    // Run afterLoad lifecycle function on all models.
    for (final model in _models.values.whereType<AfterLoad>()) {
      // Run afterLoad lifecycle function and hand over instance of this module.
      model.afterLoad();
    }
  }

  /// Loads the module.
  void load(BuildContext context) {
    // Import and create all modules.
    _importModules(context);

    // Creates all models.
    _loadModels(context);
  }
}
