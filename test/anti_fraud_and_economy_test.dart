import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:kraiiv/core/services/airtime_service.dart';
import 'package:kraiiv/core/services/data_service.dart';
import 'package:kraiiv/core/services/zebedee_service.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('kraiiv_security_test');
    Hive.init(tempDir.path);
    await DataService.initialize();
    await DataService.resetAll();
  });

  group('Economic Parity & Sats Conversion', () {
    test('1 KTC = 1 Sat maps to approx 1 Naira', () {
      expect(ZebedeeService.satToNairaRate, 1.02);
      expect(ZebedeeService.satsToNaira(100), 102);
      expect(ZebedeeService.nairaToSats(100), 98);
    });

    test('Fresh user starts with strict 0 KTC baseline', () {
      expect(DataService.ktcBalance, 0);
      expect(DataService.ktcEarnedToday, 0);
      expect(DataService.tokenHistory, isEmpty);
    });
  });

  group('Automated Airtime Telco Detection', () {
    test('correctly identifies MTN numbers', () {
      expect(AirtimeService.detectNetwork('08031234567'), 'MTN');
      expect(AirtimeService.detectNetwork('08069876543'), 'MTN');
      expect(AirtimeService.detectNetwork('+2348130001122'), 'MTN');
      expect(AirtimeService.detectNetwork('0903 444 5555'), 'MTN');
    });

    test('correctly identifies Airtel numbers', () {
      expect(AirtimeService.detectNetwork('08021112233'), 'Airtel');
      expect(AirtimeService.detectNetwork('08089998877'), 'Airtel');
      expect(AirtimeService.detectNetwork('+2349020003344'), 'Airtel');
    });

    test('correctly identifies Glo numbers', () {
      expect(AirtimeService.detectNetwork('08051234567'), 'Glo');
      expect(AirtimeService.detectNetwork('08077778888'), 'Glo');
      expect(AirtimeService.detectNetwork('+2348159990011'), 'Glo');
    });

    test('correctly identifies 9mobile numbers', () {
      expect(AirtimeService.detectNetwork('08091112233'), '9mobile');
      expect(AirtimeService.detectNetwork('08189998877'), '9mobile');
      expect(AirtimeService.detectNetwork('+2349091234567'), '9mobile');
    });

    test('normalizes various phone formatting styles', () {
      expect(AirtimeService.normalizePhone('+234 803 123 4567'), '08031234567');
      expect(AirtimeService.normalizePhone('234-802-111-2233'), '08021112233');
      expect(AirtimeService.normalizePhone('0805 123 4567'), '08051234567');
    });
  });

  group('Anti-Cheat & Anti-Fraud Guardrails', () {
    test('enforces 5-minute cooldown between meal logs', () async {
      final first = await DataService.addMeal(
        name: 'Jollof Rice',
        category: 'Lunch',
        healthScore: 8,
        feedback: 'Delicious',
        isLocal: true,
      );
      expect(first.success, isTrue);

      // Immediate second log should be blocked by cooldown
      final second = await DataService.addMeal(
        name: 'Egusi Soup',
        category: 'Lunch',
        healthScore: 9,
        feedback: 'Great',
        isLocal: true,
      );
      expect(second.success, isFalse);
      expect(second.message, contains('Please wait'));
    });

    test('blocks duplicate food logged on the same day', () async {
      final first = await DataService.addMeal(
        name: 'Moi Moi',
        category: 'Breakfast',
        healthScore: 8,
        feedback: 'Good protein',
        isLocal: true,
      );
      expect(first.success, isTrue);

      // Simulate waiting past 5 minutes by updating the timestamp
      final meals = DataService.loggedMeals;
      meals.first['timestamp'] = DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String();
      await Hive.box('meals').put('list', meals);

      // Attempting to log the exact same food again today should be rejected
      final duplicate = await DataService.addMeal(
        name: 'Moi Moi',
        category: 'Lunch',
        healthScore: 8,
        feedback: 'Same thing',
        isLocal: true,
      );
      expect(duplicate.success, isFalse);
      expect(duplicate.message, contains('already logged Moi Moi today'));
    });

    test('enforces daily reward cap of 4 meals per day', () async {
      final dishes = ['Akara', 'Yam and Egg', 'Afang Soup', 'Pepper Soup', 'Suya'];

      for (var i = 0; i < 4; i++) {
        final res = await DataService.addMeal(
          name: dishes[i],
          category: 'Meal',
          healthScore: 8,
          feedback: 'Healthy',
          isLocal: true,
        );
        expect(res.success, isTrue, reason: 'Meal ${i + 1} should succeed');

        // Age timestamp to bypass cooldown for the next loop iteration
        final meals = DataService.loggedMeals;
        meals.first['timestamp'] = DateTime.now().subtract(Duration(minutes: (4 - i) * 10)).toIso8601String();
        await Hive.box('meals').put('list', meals);
      }

      // 5th meal must be capped
      final fifth = await DataService.addMeal(
        name: dishes[4],
        category: 'Snack',
        healthScore: 7,
        feedback: 'Late snack',
        isLocal: true,
      );
      expect(fifth.success, isFalse);
      expect(fifth.message, contains('Daily meal reward limit reached (4/4 meals)'));
    });

    test('enforces hard daily earning cap of 75 KTC', () async {
      // Award up to 70 KTC
      await DataService.completeGoal(0); // +15 KTC
      await DataService.completeGoal(1); // +20 KTC
      await DataService.completeGoal(2); // +10 KTC
      await DataService.completeGoal(3); // +25 KTC
      // Total earned: 15 + 20 + 10 + 25 = 70 KTC

      expect(DataService.ktcEarnedToday, 70);
      expect(DataService.ktcBalance, 70);

      // Now add a mini goal worth 5 points -> exactly hits 75 cap
      final goal = DataService.miniGoalPlan.first;
      final awarded = await DataService.completeMiniGoal(goal.id);
      expect(awarded, goal.points);
      expect(DataService.ktcEarnedToday, 75);

      // Any further actions award 0 KTC
      final secondGoal = DataService.miniGoalPlan[1];
      final cappedAward = await DataService.completeMiniGoal(secondGoal.id);
      expect(cappedAward, 0);
      expect(DataService.ktcBalance, 75);
      expect(DataService.ktcEarnedToday, 75);
    });
  });

  group('Automated Goal-to-KTC Conversion', () {
    test('logging a local dish automatically completes Goal 0 and awards 15 KTC', () async {
      expect(DataService.goalsCompletedToday[0], isFalse);

      final result = await DataService.addMeal(
        name: 'Jollof Rice',
        category: 'Lunch',
        healthScore: 9,
        feedback: 'Classic',
        isLocal: true,
      );

      expect(result.success, isTrue);
      expect(DataService.goalsCompletedToday[0], isTrue);
      expect(result.completedGoals.any((g) => g.contains('Log a local and seasonal meal')), isTrue);
    });

    test('3rd scan automatically completes Goal 3 and awards 25 KTC', () async {
      expect(DataService.goalsCompletedToday[3], isFalse);

      // Perform 2 scans (non-local)
      await DataService.recordScanAndTick(isLocal: false);
      await DataService.recordScanAndTick(isLocal: false);
      expect(DataService.scansToday, 2);
      expect(DataService.goalsCompletedToday[3], isFalse);

      // 3rd scan triggers completion
      final awarded = await DataService.recordScanAndTick(isLocal: false);
      expect(DataService.scansToday, 3);
      expect(DataService.goalsCompletedToday[3], isTrue);
      expect(awarded, 25);
    });
  });
}
