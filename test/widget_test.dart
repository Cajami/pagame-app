import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pagame/main.dart';

void main() {
  testWidgets('shows empty categories state', (WidgetTester tester) async {
    await tester.pumpWidget(const PagameApp());

    expect(find.text('Págame'), findsOneWidget);
    expect(find.text('Aún no tienes categorías'), findsOneWidget);
    expect(find.text('Crear primera categoría'), findsOneWidget);
    expect(find.text('Nueva categoría'), findsNothing);
  });

  testWidgets('creates a category from the form', (WidgetTester tester) async {
    await tester.pumpWidget(const PagameApp());

    await tester.tap(find.text('Crear primera categoría'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva categoría'), findsAtLeastNWidgets(1));

    await tester.enterText(find.byType(TextFormField), 'Streaming');

    await tester.tap(find.text('Guardar categoría'));
    await tester.pumpAndSettle();

    expect(find.text('Streaming'), findsOneWidget);
    expect(find.text('Aún no tienes categorías'), findsNothing);
    expect(find.text('Nueva categoría'), findsOneWidget);
  });

  testWidgets('creates Prime Video service inside category', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PagameApp());

    await tester.tap(find.text('Crear primera categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Streaming');
    await tester.tap(find.text('Guardar categoría'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes servicios'), findsOneWidget);
    await tester.tap(find.text('Crear primer servicio'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Prime Video');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Prime Video'), findsOneWidget);
    expect(find.text('Aún no tienes servicios'), findsNothing);
  });

  testWidgets('creates year and month inside a service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PagameApp());

    await tester.tap(find.text('Crear primera categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Streaming');
    await tester.tap(find.text('Guardar categoría'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear primer servicio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Prime Video');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prime Video'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes años'), findsOneWidget);
    await tester.tap(find.text('Crear primer año'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar año'));
    await tester.pumpAndSettle();

    final yearFinder = find.byWidgetPredicate((widget) {
      return widget is Text &&
          RegExp(r'^20(2[5-8])$').hasMatch(widget.data ?? '');
    });

    expect(yearFinder, findsAtLeastNWidgets(1));

    await tester.tap(yearFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes meses'), findsOneWidget);
    await tester.tap(find.text('Crear primer mes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar mes'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes meses'), findsNothing);
  });

  testWidgets('creates payment inside selected month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PagameApp());

    await tester.tap(find.text('Crear primera categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Streaming');
    await tester.tap(find.text('Guardar categoría'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear primer servicio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Prime Video');
    await tester.tap(find.text('Guardar servicio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prime Video'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear primer año'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar año'));
    await tester.pumpAndSettle();

    final yearFinder = find.byWidgetPredicate((widget) {
      return widget is Text &&
          RegExp(r'^20(2[5-8])$').hasMatch(widget.data ?? '');
    });

    await tester.tap(yearFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear primer mes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar mes'));
    await tester.pumpAndSettle();

    expect(find.text('Sin pagos registrados'), findsOneWidget);
    await tester.tap(find.text('Sin pagos registrados'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes pagos'), findsOneWidget);
    await tester.tap(find.text('Crear primer pago'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '35.90');
    await tester.tap(find.text('Guardar pago'));
    await tester.pumpAndSettle();

    expect(find.textContaining('S/ 35.90'), findsOneWidget);
  });
}
