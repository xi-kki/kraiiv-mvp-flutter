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

  testWidgets('Home dashboard shows mini goals after onboarding',
      (tester) async {
    // Widget tests run in a fake-async zone where real file IO (Hive disk
    // writes) never completes, so the write-side setup goes through runAsync.
    await tester.runAsync(() async {
      await DataService.setOnboardingComplete();
      await DataService.setUserName('Xi-kki');
      await DataService.setHealthGoal('Eat more mindfully');
    });

    // Tall viewport so the whole home feed (mini goals included) is built.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: KraiivApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Greeting text is time-of-day dependent, so match on the name only.
    expect(find.textContaining('Xi-kki!'), findsOneWidget);
    expect(find.text('Your Mini Goals'), findsOneWidget);
    expect(find.text('Today\'s Goals'), findsOneWidget);

    // Tapping a mini goal records it as done for today. The KTC award
    // itself is covered by mini_goal_test.dart — Hive disk writes never
    // resolve inside the widget-test fake zone.
    final goal = DataService.miniGoalPlan.first;
    await tester.tap(find.text(goal.title).first);
    await tester.pump();
    expect(DataService.miniGoalDoneToday(goal.id), isTrue);
  });
}
