import 'package:flutter/widgets.dart';

import '../modules/modules.dart';
import './model.dart';

typedef ModelBuilderFunction = Model Function(
  BuildContext context,
  Module module,
);
