import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:kraiiv/core/services/data_service.dart';
import 'package:kraiiv/main.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

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
    expect(find.text('Your Giant Goal'), findsOneWidget);
    expect(find.text('Eat more mindfully'), findsOneWidget);
    expect(find.text('Today\'s Goals'), findsOneWidget);

    // Tapping a mini goal records it as done for today. The KTC award
    // itself is covered by mini_goal_test.dart — Hive disk writes never
    // resolve inside the widget-test fake zone.
    final goal = DataService.miniGoalPlan.first;
    await tester.tap(find.text(goal.title).first);
    await tester.pump();
    expect(DataService.miniGoalDoneToday(goal.id), isTrue);
  });

  testWidgets(
      'bottom navigation switches between Home, Chat, Rewards and Profile',
      (tester) async {
    await tester.runAsync(() async {
      await DataService.setOnboardingComplete();
      await DataService.setUserName('Xi-kki');
    });

    await tester.pumpWidget(const ProviderScope(child: KraiivApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Bottom bar is present with all four tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Rewards tab.
    await tester.tap(find.text('Rewards'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Rewards Hub'), findsOneWidget);

    // Chat tab.
    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Klia'), findsWidgets);

    // Profile tab.
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('My Profile'), findsOneWidget);

    // Back to Home.
    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Xi-kki!'), findsOneWidget);
  });
  testWidgets('chat falls back to keyword answers when the AI API is down',
      (tester) async {
    await tester.runAsync(() async {
      await DataService.setOnboardingComplete();
      await DataService.setUserName('Xi-kki');
    });

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: KraiivApp()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Go to the Chat tab.
    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(milliseconds: 600));

    // Widget tests stub HTTP with 400 responses, so the model API call
    // fails fast and Klia answers from the local keyword logic.
    await tester.enterText(find.byType(TextField), 'what about protein?');
    await tester.tap(find.byIcon(LucideIcons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('what about protein?'), findsOneWidget);
    expect(find.textContaining('Great question'), findsOneWidget);
  });
}
