import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:kraiiv/core/models/mini_goal.dart';
import 'package:kraiiv/core/services/data_service.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('kraiiv_mini_test');
    Hive.init(tempDir.path);
    await DataService.initialize();
    await DataService.resetAll();
  });

  group('Mini goal plan', () {
    test('generates 5 goals matching the user\'s health goal', () {
      DataService.setHealthGoal('Feel more energized');
      final plan = DataService.miniGoalPlan;
      expect(plan.length, DataService.miniGoalsPerWeek);
      expect(plan.length, 5);
      final ids = plan.map((g) => g.id).toSet();
      expect(ids.length, 5, reason: 'plan must not contain duplicates');
      for (final g in plan) {
        expect(g.points, greaterThan(0));
        expect(miniGoalLibrary['energy']!.any((x) => x.id == g.id), isTrue,
            reason: 'goal ${g.id} must come from the energy library');
      }
    });

    test('falls back to general library for unknown goals', () {
      DataService.setHealthGoal('Something custom');
      final plan = DataService.miniGoalPlan;
      for (final g in plan) {
        expect(miniGoalLibrary['general']!.any((x) => x.id == g.id), isTrue);
      }
    });

    test('plan is stable within a week (lazy regeneration is a no-op)', () {
      DataService.setHealthGoal('Improve overall health');
      final first = DataService.miniGoalPlan.map((g) => g.id).toList();
      final second = DataService.miniGoalPlan.map((g) => g.id).toList();
      expect(first, second);
    });
  });

  group('Completing mini goals', () {
    test('awards points and credits the KTC balance', () async {
      DataService.setHealthGoal('Eat more mindfully');
      final goal = DataService.miniGoalPlan.first;
      final before = DataService.ktcBalance;
      final awarded = await DataService.completeMiniGoal(goal.id);
      expect(awarded, goal.points);
      expect(DataService.ktcBalance, before + goal.points);
      expect(DataService.miniGoalDoneToday(goal.id), isTrue);
      expect(DataService.tokenHistory.first['reason'],
          'Mini goal: ${goal.title}');
    });

    test('second completion the same day awards nothing', () async {
      DataService.setHealthGoal('Try more local foods');
      final goal = DataService.miniGoalPlan.first;
      await DataService.completeMiniGoal(goal.id);
      final before = DataService.ktcBalance;
      final awarded = await DataService.completeMiniGoal(goal.id);
      expect(awarded, 0);
      expect(DataService.ktcBalance, before);
    });

    test('unknown goal id is rejected', () async {
      final awarded = await DataService.completeMiniGoal('nope');
      expect(awarded, 0);
    });
  });

  group('Weekly stats', () {
    test('count actions, points and streak', () async {
      DataService.setHealthGoal('Feel more energized');
      for (final goal in DataService.miniGoalPlan) {
        await DataService.completeMiniGoal(goal.id);
      }
      expect(DataService.miniGoalsDoneThisWeek, 5);
      final expectedPoints = DataService.miniGoalPlan
          .fold<int>(0, (a, g) => a + g.points);
      expect(DataService.miniGoalPointsThisWeek, expectedPoints);
      expect(DataService.miniGoalStreak, 1);
      // 5 completions fit inside the week total of 35 possible actions.
      expect(DataService.miniGoalsTotalThisWeek, 35);
    });

    test('per-goal weekly count reflects completed days', () async {
      DataService.setHealthGoal('Eat more mindfully');
      final goal = DataService.miniGoalPlan.first;
      await DataService.completeMiniGoal(goal.id);
      expect(DataService.miniGoalDoneThisWeek(goal.id), 1);
    });

    test('mini goals appear in the day drill-down list', () async {
      DataService.setHealthGoal('Eat more mindfully');
      final goal = DataService.miniGoalPlan.first;
      await DataService.completeMiniGoal(goal.id);
      final done = DataService.miniGoalsDoneOn(DateTime.now());
      expect(done.any((g) => g.id == goal.id), isTrue);
    });
  });
}
