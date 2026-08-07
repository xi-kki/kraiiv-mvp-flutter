import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:kraiiv/core/services/data_service.dart';
import 'package:kraiiv/main.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('kraiiv_test');
    Hive.init(tempDir.path);
    await DataService.initialize();
  });

  testWidgets('Kraiiv app renders the splash brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KraiivApp()),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Kraiiv'), findsOneWidget);
    expect(find.text('Be intentional with every bite'), findsOneWidget);

    // Let the splash timer fire and navigate away cleanly.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
