import 'dart:async';

import './model.dart';

/// Implements the the [stateChange] stream that notifies listeners about state
/// changes and the [updateState] method which triggers the stream.
///
/// Reactive models allow automated widget updates when state changes are
/// notified using the [updateState] method.
abstract interface class IReactiveModel extends Model {
  /// Gets a stream which notifies about state changes.
  Stream get stateChange;

  /// Notifies listeners about state changes.
  void updateState();
}

/// Mixes in the [IReactiveModel] interface implementation to any [Model].
mixin WithReactiveModel on Model implements IReactiveModel {
  /// The stream controller to notify listeners about state changes.
  final _stateChangeController = StreamController<void>.broadcast();

  /// Gets a stream which notifies about state changes.
  @override
  Stream get stateChange => _stateChangeController.stream;

  /// Notifies listeners about state changes.
  @override
  void updateState() {
    // Notify listeners about state changes.
    _stateChangeController.add(null);
  }
}

/// A base class of a [Model] that already implements reactivity of the
/// [IReactiveModel] interface.
class ReactiveModel extends Model with WithReactiveModel {}
