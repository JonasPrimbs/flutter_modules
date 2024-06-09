/// Implements the [initialize] method that asynchronously initializes the model
/// after all models are loaded.
abstract interface class OnInit {
  /// Initializes the model after all models are loaded.
  Future<void> initialize();
}
