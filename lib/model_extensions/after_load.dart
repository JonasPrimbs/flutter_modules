/// Implements the [afterLoad] method that is called after the model is loaded.
abstract interface class AfterLoad {
  /// Called after loading all submodules and models of the model's module.
  void afterLoad();
}
