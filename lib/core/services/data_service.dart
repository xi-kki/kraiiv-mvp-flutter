import 'package:hive/hive.dart';

/// Central data service managing all persistent state via Hive boxes.
///
/// Boxes:
///   - 'settings' → onboarding, user profile, daily goal progress, reminders
///   - 'meals'    → list of logged meals with timestamps + nutrition
///   - 'streaks'  → streak count, last log date, best streak
///   - 'tokens'   → KTC token balance, earning history
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
  static bool get isOnboardingComplete =>
      _settings.get('onboarding_complete', defaultValue: false);
  static Future<void> setOnboardingComplete() =>
      _settings.put('onboarding_complete', true);

  static String get userName =>
      _settings.get('user_name', defaultValue: '');
  static Future<void> setUserName(String name) =>
      _settings.put('user_name', name);

  static String get dietaryPreference =>
      _settings.get('dietary_preference', defaultValue: 'No restrictions');
  static Future<void> setDietaryPreference(String value) =>
      _settings.put('dietary_preference', value);

  static String get healthGoal =>
      _settings.get('health_goal', defaultValue: 'Eat more mindfully');
  static Future<void> setHealthGoal(String value) =>
      _settings.put('health_goal', value);

  static String get location =>
      _settings.get('location', defaultValue: '');
  static Future<void> setLocation(String value) =>
      _settings.put('location', value);

  static bool get notificationsEnabled =>
      _settings.get('notifications_enabled', defaultValue: false);
  static Future<void> setNotificationsEnabled(bool enabled) =>
      _settings.put('notifications_enabled', enabled);

  /// Legacy alias kept for compatibility.
  static bool get dailyRemindersEnabled => notificationsEnabled;
  static Future<void> setDailyReminders(bool enabled) =>
      setNotificationsEnabled(enabled);

  // ─── Daily Goals ───────────────────────────────────────────
  /// The four daily goals from the prototype, with KTC rewards.
  static const List<Map<String, Object>> dailyGoals = [
    {
      'title': 'Log a local and seasonal meal',
      'reward': 15,
    },
    {
      'title': 'Try a new vegetable from the farmer\'s market',
      'reward': 20,
    },
    {
      'title': 'Eat mindfully without distractions for one meal',
      'reward': 10,
    },
    {
      'title': 'Scan 3 food items to check nutrition facts',
      'reward': 25,
    },
  ];

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String? get _goalsDate => _settings.get('goals_date');

  /// Marks a goal complete for today and awards KTC.
  /// Returns the amount awarded (0 if already completed today).
  static Future<int> completeGoal(int index) async {
    if (index < 0 || index >= dailyGoals.length) return 0;
    final today = _today().toIso8601String();
    final completed = List<bool>.from(
      _settings.get('goals_completed', defaultValue: [false, false, false, false]),
    );
    if (_goalsDate != today) {
      completed.fillRange(0, completed.length, false);
      await _settings.put('goals_date', today);
    }
    if (index >= completed.length) completed.length = index + 1;
    if (completed[index]) return 0;

    completed[index] = true;
    await _settings.put('goals_completed', completed);

    final reward = dailyGoals[index]['reward'] as int;
    await _awardTokens(reward,
        reason: 'Daily goal: ${dailyGoals[index]['title']}');
    return reward;
  }

  static List<bool> get goalsCompletedToday {
    final completed = List<bool>.from(
      _settings.get('goals_completed', defaultValue: [false, false, false, false]),
    );
    if (_goalsDate != _today().toIso8601String()) {
      return [false, false, false, false];
    }
    return completed;
  }

  static int get goalsDoneToday =>
      goalsCompletedToday.where((done) => done).length;

  // ─── Meal Logging ──────────────────────────────────────────
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
    int? calories,
    double? protein,
    bool isLocal = false,
  }) async {
    final meals = loggedMeals;
    meals.insert(0, {
      'name': name,
      'category': category,
      'healthScore': healthScore,
      'feedback': feedback,
      'calories': calories,
      'protein': protein,
      'isLocal': isLocal,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Keep last 100 meals
    if (meals.length > 100) {
      meals.removeRange(100, meals.length);
    }
    await _meals.put('list', meals);
    await _updateStreak();

    // Base earn: 10 KTC per log, +5 healthy choice bonus, +3 streak bonus.
    var earned = 10;
    if (healthScore >= 8) earned += 5;
    if (currentStreak >= 3) earned += 3;
    await _awardTokens(earned, reason: 'Meal logged');
  }

  static int get totalMealsLogged => loggedMeals.length;

  /// Number of meals logged on each of the last 7 days (oldest first).
  static List<int> get weeklyMealCounts {
    final counts = List<int>.filled(7, 0);
    final today = _today();
    for (final meal in loggedMeals) {
      final ts = DateTime.tryParse(meal['timestamp'] as String? ?? '');
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      final diff = today.difference(day).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff] += 1;
      }
    }
    return counts;
  }

  /// Fraction (0..1) of the last 7 days with at least one meal logged.
  static double get weeklyCompletionRate {
    final today = _today();
    final activeDays = <String>{};
    for (final meal in loggedMeals) {
      final ts = DateTime.tryParse(meal['timestamp'] as String? ?? '');
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (today.difference(day).inDays < 7) {
        activeDays.add(day.toIso8601String());
      }
    }
    return activeDays.length / 7.0;
  }

  // ─── Habit stats (profile) ─────────────────────────────────
  static int get mindfulMeals =>
      loggedMeals.where((m) => (m['healthScore'] as int? ?? 0) >= 8).length;

  static int get localMeals =>
      loggedMeals.where((m) => m['isLocal'] == true).length;

  // ─── Streak Tracking ───────────────────────────────────────
  static int get currentStreak => _streaks.get('current', defaultValue: 0);
  static int get bestStreak => _streaks.get('best', defaultValue: 0);
  static int get currentDay => _streaks.get('day', defaultValue: 1);

  static DateTime? get _lastLogDate {
    final raw = _streaks.get('last_log_date');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  static Future<void> _updateStreak() async {
    final today = _today();
    final lastLog = _lastLogDate;

    if (lastLog == null) {
      await _streaks.put('current', 1);
      await _streaks.put('day', 1);
      await _streaks.put('last_log_date', today.toIso8601String());
      await _checkBestStreak(1);
      return;
    }

    final lastLogDay = DateTime(lastLog.year, lastLog.month, lastLog.day);
    final diff = today.difference(lastLogDay).inDays;

    if (diff == 0) {
      return; // Already logged today — no streak change
    } else if (diff == 1) {
      final newStreak = currentStreak + 1;
      final newDay = currentDay + 1;
      await _streaks.put('current', newStreak);
      await _streaks.put('day', newDay);
      await _streaks.put('last_log_date', today.toIso8601String());
      await _checkBestStreak(newStreak);
    } else {
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
    return _today() == DateTime(lastLog.year, lastLog.month, lastLog.day);
  }

  static bool get is7DayGoalComplete => currentDay >= 7;

  // ─── KTC Token System ──────────────────────────────────────
  static int get ktcBalance => _tokens.get('balance', defaultValue: 0);

  static List<Map<String, dynamic>> get tokenHistory {
    final raw = _tokens.get('history', defaultValue: <Map>[]);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<void> _awardTokens(int amount, {required String reason}) async {
    final newBalance = ktcBalance + amount;
    await _tokens.put('balance', newBalance);

    final history = tokenHistory;
    history.insert(0, {
      'amount': amount,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (history.length > 50) history.removeRange(50, history.length);
    await _tokens.put('history', history);
  }

  // ─── Reset / Debug ─────────────────────────────────────────
  static Future<void> resetAll() async {
    await _settings.clear();
    await _meals.clear();
    await _streaks.clear();
    await _tokens.clear();
  }
}
