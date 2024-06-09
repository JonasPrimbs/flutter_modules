/// Implements the [postInitialize] method that is called after all models are
/// initialized.
abstract interface class AfterInit {
  /// Called after the model was initialized.
  Future<void> postInitialize();
}
