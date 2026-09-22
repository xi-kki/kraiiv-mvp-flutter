import 'dart:math';

import 'package:hive/hive.dart';

import '../../core/models/mini_goal.dart';

/// Result returned after logging a meal, containing anti-fraud feedback
/// and any auto-completed daily goals / KTC earned.
class MealLogResult {
  final bool success;
  final String message;
  final int ktcEarned;
  final List<String> completedGoals;

  const MealLogResult({
    required this.success,
    required this.message,
    this.ktcEarned = 0,
    this.completedGoals = const [],
  });
}

/// Central data service managing all persistent state via Hive boxes.
///
/// Boxes:
///   - 'settings' → onboarding, user profile, daily goal progress, reminders
///   - 'meals'    → list of logged meals with timestamps + nutrition
///   - 'streaks'  → streak count, last log date, best streak
///   - 'tokens'   → KTC token balance, earning history
///   - 'miniGoals' → weekly mini-goal plan, per-day completions
class DataService {
  static late Box _settings;
  static late Box _meals;
  static late Box _streaks;
  static late Box _tokens;
  static late Box _mini;

  static Future<void> initialize() async {
    _settings = await Hive.openBox('settings');
    _meals = await Hive.openBox('meals');
    _streaks = await Hive.openBox('streaks');
    _tokens = await Hive.openBox('tokens');
    _mini = await Hive.openBox('miniGoals');
  }

  // ─── Onboarding ────────────────────────────────────────────
  static bool get isOnboardingComplete =>
      _settings.get('onboarding_complete', defaultValue: false);
  static Future<void> setOnboardingComplete() =>
      _settings.put('onboarding_complete', true);
  static Future<void> completeOnboarding({
    required String name,
    required String dietaryPreference,
    required String healthGoal,
    required String location,
  }) async {
    await setUserName(name);
    await setDietaryPreference(dietaryPreference);
    await setHealthGoal(healthGoal);
    await setLocation(location);
    await setOnboardingComplete();
  }
  /// True when the user has an active session. Onboarding creates the
  /// session; Login restores it; Log Out clears it without wiping profile.
  static bool get isLoggedIn =>
      _settings.get('is_logged_in', defaultValue: false);
  static Future<void> setLoggedIn(bool value) =>
      _settings.put('is_logged_in', value);
  static Future<void> logIn() => setLoggedIn(true);
  static Future<void> logOut() => setLoggedIn(false);

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

  static Future<void> updateProfile({
    required String name,
    required String dietaryPreference,
    required String healthGoal,
    required String location,
  }) async {
    await setUserName(name);
    await setDietaryPreference(dietaryPreference);
    await setHealthGoal(healthGoal);
    await setLocation(location);
  }

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

  static bool get loggedLocalMealToday {
    final today = _today().toIso8601String();
    return loggedMeals.any((m) {
      final ts = DateTime.tryParse(m['timestamp'] as String? ?? '');
      return ts != null &&
          DateTime(ts.year, ts.month, ts.day).toIso8601String() == today &&
          m['isLocal'] == true;
    });
  }

  static Future<MealLogResult> addMeal({
    required String name,
    required String category,
    required int healthScore,
    required String feedback,
    int? calories,
    double? protein,
    bool isLocal = false,
  }) async {
    final now = DateTime.now();
    final todayIso = _today().toIso8601String();
    final meals = loggedMeals;

    // Edge Case 1: Spam / Cooldown Protection (Minimum 5 minutes between logs)
    if (meals.isNotEmpty) {
      final lastTs = DateTime.tryParse(meals.first['timestamp'] as String? ?? '');
      if (lastTs != null) {
        final diffMinutes = now.difference(lastTs).inMinutes;
        if (diffMinutes < 5) {
          final wait = 5 - diffMinutes;
          return MealLogResult(
            success: false,
            message: 'You just logged a meal! Please wait $wait minute(s) before logging your next meal.',
          );
        }
      }
    }

    // Edge Case 2: Daily Meal Cap (Max 4 rewarded meals per day: Breakfast, Lunch, Dinner, Snack)
    final mealsToday = meals.where((m) {
      final ts = DateTime.tryParse(m['timestamp'] as String? ?? '');
      return ts != null && DateTime(ts.year, ts.month, ts.day).toIso8601String() == todayIso;
    }).length;

    if (mealsToday >= 4) {
      return const MealLogResult(
        success: false,
        message: 'Daily meal reward limit reached (4/4 meals). Great job staying consistent today!',
      );
    }

    // Edge Case 3: Duplicate Meal Detection (Cannot log the exact same food twice in one day)
    final alreadyLoggedSame = meals.any((m) {
      final ts = DateTime.tryParse(m['timestamp'] as String? ?? '');
      final isSameDay = ts != null && DateTime(ts.year, ts.month, ts.day).toIso8601String() == todayIso;
      return isSameDay && (m['name'] as String? ?? '').toLowerCase() == name.toLowerCase();
    });

    if (alreadyLoggedSame) {
      return MealLogResult(
        success: false,
        message: 'You already logged $name today! Vary your meals for balanced nutrition.',
      );
    }

    // Record meal
    meals.insert(0, {
      'name': name,
      'category': category,
      'healthScore': healthScore,
      'feedback': feedback,
      'calories': calories,
      'protein': protein,
      'isLocal': isLocal,
      'timestamp': now.toIso8601String(),
    });

    if (meals.length > 100) meals.removeRange(100, meals.length);
    await _meals.put('list', meals);
    await _updateStreak();

    // Base earn: 10 KTC per log, +5 healthy choice bonus, +3 streak bonus
    var earned = 10;
    if (healthScore >= 8) earned += 5;
    if (currentStreak >= 3) earned += 3;
    final awarded = await _awardTokens(earned, reason: 'Meal logged: $name');

    // Auto-tick daily goals!
    final completedGoalsList = <String>[];
    final autoTickAwarded = await recordScanAndTick(isLocal: isLocal);

    if (isLocal && goalsCompletedToday[0]) {
      completedGoalsList.add('Log a local and seasonal meal (+15 KTC)');
    }
    if (scansToday >= 3 && goalsCompletedToday[3]) {
      completedGoalsList.add('Scan 3 food items (+25 KTC)');
    }

    final totalKtc = awarded + autoTickAwarded;

    return MealLogResult(
      success: true,
      message: 'Meal logged successfully!',
      ktcEarned: totalKtc,
      completedGoals: completedGoalsList,
    );
  }

  // ─── Scan auto-tick (Daily Steps) ────────────────────────────
  static int get scansToday {
    final today = _today().toIso8601String();
    if (_settings.get('scans_date') != today) return 0;
    return _settings.get('scans_count', defaultValue: 0);
  }

  static Future<int> _incrementScanCount() async {
    final today = _today().toIso8601String();
    final storedDate = _settings.get('scans_date');
    int count;
    if (storedDate != today) {
      count = 1;
      await _settings.put('scans_date', today);
    } else {
      count = (_settings.get('scans_count', defaultValue: 0) as int) + 1;
    }
    await _settings.put('scans_count', count);
    return count;
  }

  /// Called on every successful scan/log. Auto-ticks:
  ///  • "Scan 3 food items" (index 3) when scansToday >= 3
  ///  • "Log a local and seasonal meal" (index 0) when isLocal
  /// Returns total KTC awarded from auto-ticked goals (0 if none).
  static Future<int> recordScanAndTick({required bool isLocal}) async {
    var awarded = 0;
    final scans = await _incrementScanCount();
    if (scans >= 3) {
      awarded += await completeGoal(3);
    }
    if (isLocal) {
      awarded += await completeGoal(0);
    }
    return awarded;
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

  // ─── KTC Token System & Long-term Economic Sustainability ───
  /// Maximum KTC a user can earn per 24-hour day to prevent farming/bot drain.
  static const int maxDailyKtcEarn = 75;

  static int get ktcBalance => _tokens.get('balance', defaultValue: 0);

  static int get ktcEarnedToday {
    final today = _today().toIso8601String();
    if (_tokens.get('earned_today_date') != today) return 0;
    return _tokens.get('earned_today_amount', defaultValue: 0) as int;
  }

  static List<Map<String, dynamic>> get tokenHistory {
    final raw = _tokens.get('history', defaultValue: <Map>[]);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static Future<int> _awardTokens(int amount, {required String reason}) async {
    final today = _today().toIso8601String();
    final storedDate = _tokens.get('earned_today_date');
    int currentToday;

    if (storedDate != today) {
      currentToday = 0;
      await _tokens.put('earned_today_date', today);
      await _tokens.put('earned_today_amount', 0);
    } else {
      currentToday = _tokens.get('earned_today_amount', defaultValue: 0) as int;
    }

    final availableToday = maxDailyKtcEarn - currentToday;
    if (availableToday <= 0) {
      return 0; // Daily cap reached — habits still logged, but no additional minting
    }

    final granted = amount > availableToday ? availableToday : amount;
    final newBalance = ktcBalance + granted;
    await _tokens.put('balance', newBalance);
    await _tokens.put('earned_today_amount', currentToday + granted);

    final lifetime = (_tokens.get('lifetime', defaultValue: 0) as int) + granted;
    await _tokens.put('lifetime', lifetime);

    final history = tokenHistory;
    history.insert(0, {
      'amount': granted,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (history.length > 50) history.removeRange(50, history.length);
    await _tokens.put('history', history);
    return granted;
  }

  // ─── Redemptions ─────────────────────────────────────────
  static List<Map<String, dynamic>> get redemptions {
    final raw = _tokens.get('redemptions', defaultValue: <Map>[]);
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// Redeems [cost] KTC for [title]: validates the balance, deducts KTC,
  /// generates a voucher code, and records the redemption.
  ///
  /// Returns the redemption record (with its [code]) or `null` when the
  /// balance is insufficient (nothing is changed in that case).
  static Future<Map<String, dynamic>?> redeemKTC({
    required int cost,
    required String title,
  }) async {
    if (cost <= 0) return null;
    if (ktcBalance < cost) return null;

    await _tokens.put('balance', ktcBalance - cost);

    final record = <String, dynamic>{
      'title': title,
      'cost': cost,
      'code': _generateVoucherCode(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final all = redemptions;
    all.insert(0, record);
    if (all.length > 50) all.removeRange(50, all.length);
    await _tokens.put('redemptions', all);
    return record;
  }

  // ─── Web 2.5 Auth State ────────────────────────────────────
  static bool get isLoggedInWithGoogle =>
      _settings.get('auth_google', defaultValue: false);
  static String get userEmail =>
      _settings.get('user_email', defaultValue: '');
  static Future<void> signInWithGoogle({required String email, required String name}) async {
    await _settings.put('auth_google', true);
    await _settings.put('user_email', email);
    if (name.isNotEmpty && userName.isEmpty) {
      await setUserName(name);
    }
  }

  // ─── Profile & Habit Stats ─────────────────────────────────
  // KTC starts strictly at 0 and grows only as user takes steps / completes goals
  static int get totalKTC => ktcBalance;
  static int get lifetimeKTC => _tokens.get('lifetime', defaultValue: 0);
  static int get streak => currentStreak;
  static String get joinDate => _settings.get('join_date', defaultValue: 'September 2026');
  static int get totalMeals => loggedMeals.length;

  static int get hydrationCount => _settings.get('count_hydration', defaultValue: 0);
  static int get movementCount => _settings.get('count_movement', defaultValue: 0);
  static int get nutritionCount => loggedMeals.length;
  static int get mindfulnessCount => mindfulMeals;
  static int get sleepCount => _settings.get('count_sleep', defaultValue: 0);
  static int get localCount => localMeals;

  static int get totalMiniGoalsDone => _miniCompletions.length;
  static int get localMealsCount => localMeals;

  static List<Map<String, dynamic>> get redemptionHistory => redemptions;

  static Future<Map<String, dynamic>?> redeemReward(dynamic a, [int? b, String? c]) async {
    if (a is Map<String, dynamic>) {
      final name = a['name'] as String? ?? 'Reward';
      final cost = (a['cost'] as num?)?.toInt() ?? 100;
      return redeemKTC(cost: cost, title: name);
    } else if (a is String && b != null) {
      return redeemKTC(cost: b, title: a);
    }
    return null;
  }

  /// Random `KRV-XXXX-XXXX` voucher code, avoiding ambiguous characters.
  static String _generateVoucherCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    String block() => List.generate(
          4,
          (_) => alphabet[rand.nextInt(alphabet.length)],
        ).join();
    return 'KRV-${block()}-${block()}';
  }

  // ─── Mini Goals (weekly plan chipped from the giant goal) ──
  /// Number of mini goals active per week. Each is completable once per day.
  static const int miniGoalsPerWeek = 5;

  /// ISO week key of [date] in the form '2026-W32' (Monday-start weeks).
  static (int, int) _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final year = thursday.year;
    final jan1 = DateTime(year, 1, 1);
    final firstThursday = jan1.add(Duration(days: (4 - jan1.weekday) % 7));
    final week = (thursday.difference(firstThursday).inDays / 7).floor() + 1;
    return (year, week);
  }

  static String get _isoWeekKey {
    final (year, week) = _isoWeek(DateTime.now());
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  static DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  static Map<String, int> get _miniCompletions =>
      Map<String, int>.from(
          _mini.get('completions', defaultValue: <String, int>{}));

  /// The five mini goals active for the current week, rotated by week so
  /// returning users see variety. Lazily (re)generated when the week rolls
  /// over or the user's health goal changes.
  static List<MiniGoal> get miniGoalPlan {
    _ensureMiniPlan();
    final raw = _mini.get('plan', defaultValue: <Map>[]) as List;
    return [
      for (final e in raw) MiniGoal.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  static void _ensureMiniPlan() {
    // Key the plan by both week and goal: editing the health goal mid-week
    // (profile screen) must swap in a matching plan, not keep the stale one.
    final planKey = '$_isoWeekKey|${healthGoal.trim()}';
    if (_mini.get('plan_key') == planKey) return;
    final library = _libraryFor(healthGoal);
    final offset = _isoWeekKey.hashCode.abs() % library.length;
    final plan = <MiniGoal>[
      for (var i = 0; i < miniGoalsPerWeek; i++)
        library[(offset + i) % library.length],
    ];
    _mini.putAll({
      'plan_key': planKey,
      'plan': [for (final g in plan) g.toJson()],
    });
  }

  static List<MiniGoal> _libraryFor(String goal) {
    final key = goal.trim().toLowerCase();
    if (key.contains('energ')) return miniGoalLibrary['energy']!;
    if (key.contains('mindful')) return miniGoalLibrary['mindful']!;
    if (key.contains('health')) return miniGoalLibrary['health']!;
    if (key.contains('local')) return miniGoalLibrary['local']!;
    return miniGoalLibrary['general']!;
  }

  static DateTime? _completionDate(String key) {
    // Keys are '$goalId:2026-08-08T00:00:00.000' — the timestamp contains
    // colons, so split from the FIRST one (goal ids never contain ':').
    final date = DateTime.tryParse(key.substring(key.indexOf(':') + 1));
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  /// Completions recorded inside the current ISO week (goalId → points).
  static Map<String, int> get _miniWeekCompletions {
    final start = _weekStart;
    return Map<String, int>.fromEntries(_miniCompletions.entries.where((e) {
      final date = _completionDate(e.key);
      return date != null && !date.isBefore(start);
    }));
  }

  static bool miniGoalDoneToday(String id) =>
      _miniCompletions.containsKey('$id:${_today().toIso8601String()}');

  /// Days this week the given mini goal was completed (0-7).
  static int miniGoalDoneThisWeek(String id) =>
      _miniWeekCompletions.keys.where((k) => k.startsWith('$id:')).length;

  static int get miniGoalsDoneThisWeek => _miniWeekCompletions.length;
  static int get miniGoalsTotalThisWeek => miniGoalsPerWeek * 7;
  static int get miniGoalPointsThisWeek =>
      _miniWeekCompletions.values.fold(0, (a, b) => a + b);

  /// Consecutive days (ending today) with at least one mini goal completed.
  static int get miniGoalStreak {
    final keys = _miniCompletions.keys;
    var streak = 0;
    var day = _today();
    while (keys.any((k) => k.endsWith(':${day.toIso8601String()}'))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Marks a mini goal complete for today and awards its KTC points
  /// (dummy currency — later swapped for stablecoins at _awardTokens).
  /// Returns the amount awarded (0 if already done today or unknown goal).
  static Future<int> completeMiniGoal(String id) async {
    _ensureMiniPlan();
    MiniGoal? goal;
    for (final g in miniGoalPlan) {
      if (g.id == id) {
        goal = g;
        break;
      }
    }
    if (goal == null) return 0;

    final key = '$id:${_today().toIso8601String()}';
    final completions = _miniCompletions;
    if (completions.containsKey(key)) return 0;
    completions[key] = goal.points;
    await _mini.put('completions', completions);

    await _awardTokens(goal.points, reason: 'Mini goal: ${goal.title}');
    return goal.points;
  }

  // ─── Chart helpers (interactive dashboards) ────────────────
  /// Meals logged on the given calendar day, newest first.
  static List<Map<String, dynamic>> mealsOn(DateTime day) {
    final iso = DateTime(day.year, day.month, day.day).toIso8601String();
    return loggedMeals.where((m) {
      final ts = DateTime.tryParse(m['timestamp'] as String? ?? '');
      if (ts == null) return false;
      return DateTime(ts.year, ts.month, ts.day).toIso8601String() == iso;
    }).toList();
  }

  /// Mini-goal completions recorded on the given calendar day.
  static List<MiniGoal> miniGoalsDoneOn(DateTime day) {
    final iso = DateTime(day.year, day.month, day.day).toIso8601String();
    final plan = miniGoalPlan;
    return [
      for (final g in plan)
        if (_miniCompletions.containsKey('${g.id}:$iso')) g,
    ];
  }

  // ─── Reset / Debug ─────────────────────────────────────────
  static Future<void> resetAll() async {
    await _settings.clear();
    await _meals.clear();
    await _streaks.clear();
    await _tokens.clear();
    await _mini.clear();
  }

  static Future<void> wipeAllData() => resetAll();
}
