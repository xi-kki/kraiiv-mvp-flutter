import 'package:hive/hive.dart';

/// Central data service managing all persistent state via Hive boxes.
/// 
/// Boxes:
///   - 'settings'  → onboarding complete, user name, goals, daily reminders
///   - 'meals'     → list of logged meals with timestamps
///   - 'streaks'   → streak count, last log date, best streak
///   - 'tokens'    → KTC token balance, earning history
class DataService {
  static late Box _settings;
  static late Box _meals;
  static late Box _streaks;
  static late Box _tokens;

  static Future<void> initialize() async {
    _settings = await Hive.openBox('settings');
    _meals = await Hive.openBox('meals');
    _streaks = await Hive.openBox('streaks');
    _tokens = await Hive.openBox('tokens');
  }

  // ─── Onboarding ────────────────────────────────────────────
  static bool get isOnboardingComplete => _settings.get('onboarding_complete', defaultValue: false);
  static Future<void> setOnboardingComplete() => _settings.put('onboarding_complete', true);

  static String get userName => _settings.get('user_name', defaultValue: '');
  static Future<void> setUserName(String name) => _settings.put('user_name', name);

  static List<String> get selectedGoals => 
      List<String>.from(_settings.get('selected_goals', defaultValue: []));
  static Future<void> setSelectedGoals(List<String> goals) => _settings.put('selected_goals', goals);

  static bool get commitmentAccepted => _settings.get('commitment_accepted', defaultValue: false);
  static Future<void> setCommitmentAccepted() => _settings.put('commitment_accepted', true);

  // ─── Daily Reminders ──────────────────────────────────────
  static bool get dailyRemindersEnabled => _settings.get('daily_reminders', defaultValue: true);
  static Future<void> setDailyReminders(bool enabled) => _settings.put('daily_reminders', enabled);

  // ─── Meal Logging ─────────────────────────────────────────
  static List<Map<String, dynamic>> get loggedMeals {
    final raw = _meals.get('list', defaultValue: <Map>[]);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> addMeal({
    required String name,
    required String category,
    required int healthScore,
    required String feedback,
  }) async {
    final meals = loggedMeals;
    meals.insert(0, {
      'name': name,
      'category': category,
      'healthScore': healthScore,
      'feedback': feedback,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Keep last 100 meals
    if (meals.length > 100) {
      meals.removeRange(100, meals.length);
    }
    await _meals.put('list', meals);
    await _updateStreak();
    await _awardTokens(healthScore);
  }

  static int get totalMealsLogged => loggedMeals.length;

  // ─── Streak Tracking ──────────────────────────────────────
  static int get currentStreak => _streaks.get('current', defaultValue: 0);
  static int get bestStreak => _streaks.get('best', defaultValue: 0);
  static int get currentDay => _streaks.get('day', defaultValue: 1);

  static DateTime? get _lastLogDate {
    final raw = _streaks.get('last_log_date');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  static Future<void> _updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLog = _lastLogDate;

    if (lastLog == null) {
      // First ever log
      await _streaks.put('current', 1);
      await _streaks.put('day', 1);
      await _streaks.put('last_log_date', today.toIso8601String());
      await _checkBestStreak(1);
      return;
    }

    final lastLogDay = DateTime(lastLog.year, lastLog.month, lastLog.day);
    final diff = today.difference(lastLogDay).inDays;

    if (diff == 0) {
      // Already logged today — no streak change
      return;
    } else if (diff == 1) {
      // Consecutive day!
      final newStreak = currentStreak + 1;
      final newDay = currentDay + 1;
      await _streaks.put('current', newStreak);
      await _streaks.put('day', newDay);
      await _streaks.put('last_log_date', today.toIso8601String());
      await _checkBestStreak(newStreak);
    } else {
      // Streak broken — start fresh
      await _streaks.put('current', 1);
      await _streaks.put('day', 1);
      await _streaks.put('last_log_date', today.toIso8601String());
    }
  }

  static Future<void> _checkBestStreak(int streak) async {
    if (streak > bestStreak) {
      await _streaks.put('best', streak);
    }
  }

  static bool get hasLoggedToday {
    final lastLog = _lastLogDate;
    if (lastLog == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogDay = DateTime(lastLog.year, lastLog.month, lastLog.day);
    return today == lastLogDay;
  }

  static bool get is7DayGoalComplete => currentDay >= 7;

  // ─── KTC Token System ─────────────────────────────────────
  static int get ktcBalance => _tokens.get('balance', defaultValue: 0);

  static List<Map<String, dynamic>> get tokenHistory {
    final raw = _tokens.get('history', defaultValue: <Map>[]);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> _awardTokens(int healthScore) async {
    // Base earn: 10 KTC per log
    // Bonus: +5 if health score >= 8
    // Bonus: +3 if streak is 3+
    int base = 10;
    int bonus = 0;
    if (healthScore >= 8) bonus += 5;
    if (currentStreak >= 3) bonus += 3;
    final totalEarned = base + bonus;

    final newBalance = ktcBalance + totalEarned;
    await _tokens.put('balance', newBalance);

    final history = tokenHistory;
    history.insert(0, {
      'amount': totalEarned,
      'reason': healthScore >= 8 ? 'Healthy choice bonus' : 'Meal logged',
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (history.length > 50) history.removeRange(50, history.length);
    await _tokens.put('history', history);
  }

  // ─── Reset / Debug ────────────────────────────────────────
  static Future<void> resetAll() async {
    await _settings.clear();
    await _meals.clear();
    await _streaks.clear();
    await _tokens.clear();
  }
}
