import 'package:flutter/widgets.dart';

/// Implements the [initialize] method that asynchronously initializes the model
/// after all models are loaded.
abstract interface class OnInit {
  /// Initializes the model after all models are loaded.
  Future<void> initialize(BuildContext context);
}
