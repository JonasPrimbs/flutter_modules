# Flutter Modules

A package to modularize Flutter applications.

## Introduction

There are two foundational components to modularize Flutter applications:

1. **Models**, which store data and implement how to handle these data.
2. **Modules**, which encapsulate related models to easily import them.

Models are provided by modules.
Modules can be imported by other modules.

The `RootModule` is provided in the application's context and allows access to
the imported modules and provided, exported models.

An example is depicted in the following graph:
```
+--------------------------------------------+
|                 RootModule                 |
+--------------------------------------------+
    |                    ^
    | imports            | exports [ModelB]
    v                    |
+-----------------------------+
|           ModuleA           |
+-----------------------------+
  |           |          ^
  | provides  | imports  | exports [ModelB]
  v           v          | 
[ModelA]    +-----------------+
            |     ModuleB     |
            +-----------------+
              |
              | provides
              v
            [ModelB]
```

## Practical Examples

### Create a model

To create a new model, create a new class, e.g., `CartModel`, which extends the class `Model`.

Add properties and functions which hold and process your data.

Whenever the value of a public property in the model changes, call `notifyListeners()` to propagate the change through the UI.

```dart
class CartModel extends Model {
  final _items = List<CartItem>();

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);

  int get itemCount => _items.length;

  void add(CartItem item) {
    _items.add(item);

    // IMPORTANT: call this to propagate the change to the UI.
    notifyListeners();
  }

  void remove(CartItem item) {
    _items.remove(item);

    // IMPORTANT: call this to propagate the change to the UI.
    notifyListeners();
  }
}
```

### Create a module

To create a new model, create a new class, e.g., `CartModule`, which extends the class `Module`.

```dart
class AppModule extends Module {
  AppModule() : super(
    imports: {
      // Add functions calling the constructor of imported modules:
      PaymentModule: (context) => PaymentModule(),
    },
    provides: {
      // Add functions calling the constructor of imported models:
      CartModel: (context, module) => CartModel(),
    },
    exports: {
      CartModel,
    },
  );
}
```

### Load Application

To load a module (e.g., `AppModule`) into your app, use the `ModularApp` widget.
It provides the `RootModule` in the context of all child widgets.

```dart
Widget build(BuildContext build) {
  return ModularApp(
    imports: {
      AppModule: (context) => AppModule(),
    },
    provides: {
      ConfigModel: (context, module) => ContextModel(),
    },
    child: MaterialApp(
      ...
    ),
  );
}
```

### Access Model

To access a model, use the `ModelBuilder` and select the desired model using
generics, e.g., `ModelBuilder<CartModel>` to get the `CartModel`.
Keep in mind that this will only provide models which are exported by any
imported module or which are provided directly in the `RootModule`.
If you want to import models that are provided by a specific module or exported
by any of its submodules, use the attribute `fromModule` to indicate which
module.

```dart
Widget build(BuildContext build) {
  return Column(
    children: [
      if (RootModule.of(context).provides<CartModel>())
        ModelBuilder<CartModel>(
          builder: (context, model) => Text('Item count: ${model.itemCount}'),
        ),
      if (RootModule.of(context).from(PaymentModule).provides<PaymentModel>())
        ModelBuilder<PaymentModel>(
          fromModule: PaymentModule,
          builder: (context, model) => Text('Price: ${model.price}'),
        ),
    ],
  );
}
```

You can also check whether a model is provided by a specific module, using
`RootModule.of(context).provides<CartModule>()`.
