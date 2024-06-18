import 'package:flutter/material.dart';
import 'package:flutter_modules/flutter_modules.dart';
import 'package:flutter_test/flutter_test.dart';

class ModelA extends Model {
  static int n = 0;
  int a = 10;
  ModelA() {
    print('Create ModelA');
    n++;
  }
}

class ModelB extends Model {
  static int n = 0;
  int b = 20;
  ModelB() {
    print('Create ModelB');
    n++;
  }
}

class ModelC extends Model {
  static int n = 0;
  int c = 30;
  ModelC() {
    print('Create ModelC');
    n++;
  }
}

class ModuleA extends Module {
  static int n = 0;
  ModuleA()
      : super(
          imports: {
            ModuleB: (context) => ModuleB(),
          },
          provides: {
            ModelA: (context, model) => ModelA(),
          },
        ) {
    n++;
  }
}

class ModuleB extends Module {
  static int n = 0;
  ModuleB()
      : super(
          provides: {
            ModelB: (context, model) => ModelB(),
          },
          exports: {
            ModelB,
          },
        ) {
    n++;
  }
}

void main() {
  testWidgets(
      'ModularApp loads modules, provides exported models and does not provide non-exported models',
      (tester) async {
    await tester.pumpWidget(
      ModularApp(
        imports: {
          ModuleA: (context) => ModuleA(),
        },
        provides: {
          ModelC: (context, module) => ModelC(),
        },
        child: MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                if (RootModule.of(context).provides<ModelA>())
                  ModelBuilder<ModelA>(
                    builder: (context, model) => Text(
                      'main: ${model.a}',
                    ),
                  ),
                if (RootModule.of(context).provides<ModelB>())
                  ModelBuilder<ModelB>(
                    builder: (context, model) => Text(
                      'main: ${model.b}',
                    ),
                  ),
                if (RootModule.of(context).provides<ModelC>())
                  ModelBuilder<ModelC>(
                    builder: (context, model) => Text(
                      'main: ${model.c}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleA).provides<ModelA>())
                  ModelBuilder<ModelA>(
                    fromModule: ModuleA,
                    builder: (context, model) => Text(
                      'a: ${model.a}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleA).provides<ModelB>())
                  ModelBuilder<ModelB>(
                    fromModule: ModuleA,
                    builder: (context, model) => Text(
                      'a: ${model.b}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleA).provides<ModelC>())
                  ModelBuilder<ModelC>(
                    fromModule: ModuleA,
                    builder: (context, model) => Text(
                      'a: ${model.c}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleB).provides<ModelA>())
                  ModelBuilder<ModelA>(
                    fromModule: ModuleB,
                    builder: (context, model) => Text(
                      'b: ${model.a}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleB).provides<ModelB>())
                  ModelBuilder<ModelB>(
                    fromModule: ModuleB,
                    builder: (context, model) => Text(
                      'b: ${model.b}',
                    ),
                  ),
                if (RootModule.of(context).from(ModuleB).provides<ModelC>())
                  ModelBuilder<ModelC>(
                    fromModule: ModuleB,
                    builder: (context, model) => Text(
                      'b: ${model.c}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final a = find.text('main: 10');
    final b = find.text('main: 20');
    final c = find.text('main: 30');
    final aa = find.text('a: 10');
    final ab = find.text('a: 20');
    final ac = find.text('a: 30');
    final ba = find.text('b: 10');
    final bb = find.text('b: 20');
    final bc = find.text('b: 30');

    // Check that models are only provided in module which provide the model or
    // import it from submodules that export the model.
    expect(a, findsNothing);
    expect(b, findsOneWidget);
    expect(c, findsOneWidget);
    expect(aa, findsOneWidget);
    expect(ab, findsOneWidget);
    expect(ac, findsNothing);
    expect(ba, findsNothing);
    expect(bb, findsOneWidget);
    expect(bc, findsNothing);

    // Check that model and module instances are only generated once.
    expect(ModelA.n, equals(1));
    expect(ModelB.n, equals(1));
    expect(ModelC.n, equals(1));
    expect(ModuleA.n, equals(1));
    expect(ModuleB.n, equals(1));
  });
}
