import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model_extensions/model_extensions.dart';
import './initialization_state.dart';
import './module.dart';

final class RootModule extends Module implements OnInit {
  /// The singleton instance of the last root module that was loaded.
  static late final RootModule _instance;

  /// Gets the latest singleton instance that was loaded.
  static RootModule get instance => _instance;

  /// Gets the RootModule instance from the current [context].
  static RootModule of(BuildContext context) {
    return Provider.of<RootModule>(context);
  }

  /// The current initialization state.
  InitializationState _initState = InitializationState.none;

  /// Gets the current initialization state.
  InitializationState get initState => _initState;

  /// Set the new initialization [state].
  void _setInitState(InitializationState state) {
    _initState = state;
    _initController.add(state);
  }

  /// Stream controller to notify listeners about changed initialization state.
  final _initController = StreamController<InitializationState>.broadcast();

  /// Gets a stream that notifies about changed initialization states.
  Stream<InitializationState> get initChange => _initController.stream;

  /// A root module that [imports] modules and [provides] models.
  RootModule({
    super.imports,
    super.provides,
  });

  /// Loads the root module using the specified [context].
  @override
  void load(BuildContext context) {
    // Make this module instance to the static singleton instance.
    RootModule._instance = this;

    // Load the root module.
    super.load(context);
  }

  /// Initializes the models.
  @override
  Future<void> initialize(BuildContext context) async {
    // Ensure that module does not initialize twice.
    if (_initState != InitializationState.none) {
      throw 'Initialization has already been started';
    }

    // Update initialization state.
    _setInitState(InitializationState.initializing);

    /// Gets all models from this and submodules of a specific type [T].
    Iterable<T> getAllModelsWhereType<T>() {
      return [
        // Non-exported models of submodules:
        ...modules
            .map(
              (module) => module.internalModels.whereType<T>(),
            )
            .flattened,

        // Models exported to this module and own models.
        ...models.whereType<T>(),
      ];
    }

    try {
      // Initialize all models that implement OnInit at once.
      await Future.wait(
        getAllModelsWhereType<OnInit>().map(
          // Initialize the model asynchronously.
          (model) async => await model.initialize(context),
        ),
      );
    } catch (error) {
      throw 'Failed to initialize all models: $error';
    }

    // Update initialization state.
    _setInitState(InitializationState.initialized);

    // Post-initialize all models that implement AfterInit at once.
    await Future.wait(
      getAllModelsWhereType<AfterInit>().map(
        // Initialize the model asynchronously.
        (model) async => await model.postInitialize(),
      ),
    );
  }
}
