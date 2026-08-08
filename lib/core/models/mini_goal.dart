/// Mini goals — small daily actions chipped from the user's giant goal.
///
/// Each week the app picks [MiniGoal.miniGoalsPerWeek] goals from the
/// library matching the user's health goal (set during onboarding).
/// Completing one awards dummy KTC points for now; the earning pipeline
/// (`DataService._awardTokens`) is the single swap point for stablecoins later.
class MiniGoal {
  final String id;
  final String title;
  final int points;
  final String category; // hydration | movement | nutrition | mindfulness | sleep | local | general
  final String icon; // lucide icon key (mapped in the UI layer)

  const MiniGoal({
    required this.id,
    required this.title,
    required this.points,
    required this.category,
    required this.icon,
  });

  factory MiniGoal.fromJson(Map<String, dynamic> json) => MiniGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        points: json['points'] as int,
        category: json['category'] as String,
        icon: json['icon'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'points': points,
        'category': category,
        'icon': icon,
      };
}

/// The action library, keyed by giant-goal family (see DataService._libraryFor).
const Map<String, List<MiniGoal>> miniGoalLibrary = {
  'energy': [
    MiniGoal(
      id: 'e1',
      title: 'Drink a bottle of water (2L goal)',
      points: 10,
      category: 'hydration',
      icon: 'glassWater',
    ),
    MiniGoal(
      id: 'e2',
      title: 'Walk for 20 minutes',
      points: 15,
      category: 'movement',
      icon: 'footprints',
    ),
    MiniGoal(
      id: 'e3',
      title: 'Get 7-8 hours of sleep',
      points: 12,
      category: 'sleep',
      icon: 'bedDouble',
    ),
    MiniGoal(
      id: 'e4',
      title: 'Eat a protein-rich breakfast',
      points: 12,
      category: 'nutrition',
      icon: 'egg',
    ),
    MiniGoal(
      id: 'e5',
      title: 'Skip sugary drinks today',
      points: 10,
      category: 'nutrition',
      icon: 'coffee',
    ),
    MiniGoal(
      id: 'e6',
      title: 'Do 15 minutes of exercise',
      points: 15,
      category: 'movement',
      icon: 'heartPulse',
    ),
    MiniGoal(
      id: 'e7',
      title: 'Get sunlight within 30 minutes of waking',
      points: 8,
      category: 'general',
      icon: 'sunrise',
    ),
  ],
  'mindful': [
    MiniGoal(
      id: 'm1',
      title: 'Eat one meal without distractions',
      points: 15,
      category: 'mindfulness',
      icon: 'timer',
    ),
    MiniGoal(
      id: 'm2',
      title: 'Pause and breathe before each meal',
      points: 10,
      category: 'mindfulness',
      icon: 'brain',
    ),
    MiniGoal(
      id: 'm3',
      title: 'Journal your hunger before snacking',
      points: 10,
      category: 'mindfulness',
      icon: 'penLine',
    ),
    MiniGoal(
      id: 'm4',
      title: 'No phone at the dinner table',
      points: 12,
      category: 'mindfulness',
      icon: 'smartphone',
    ),
    MiniGoal(
      id: 'm5',
      title: 'Chew slowly, pause between bites',
      points: 10,
      category: 'mindfulness',
      icon: 'utensils',
    ),
    MiniGoal(
      id: 'm6',
      title: 'Rate your mood before and after a meal',
      points: 8,
      category: 'mindfulness',
      icon: 'heartPulse',
    ),
    MiniGoal(
      id: 'm7',
      title: 'Meditate for 5 minutes',
      points: 12,
      category: 'mindfulness',
      icon: 'sparkles',
    ),
  ],
  'health': [
    MiniGoal(
      id: 'h1',
      title: 'Eat 2 servings of vegetables',
      points: 15,
      category: 'nutrition',
      icon: 'carrot',
    ),
    MiniGoal(
      id: 'h2',
      title: 'Drink a bottle of water (2L goal)',
      points: 10,
      category: 'hydration',
      icon: 'glassWater',
    ),
    MiniGoal(
      id: 'h3',
      title: 'Add a fruit to your day',
      points: 10,
      category: 'nutrition',
      icon: 'apple',
    ),
    MiniGoal(
      id: 'h4',
      title: 'Walk for 30 minutes',
      points: 15,
      category: 'movement',
      icon: 'footprints',
    ),
    MiniGoal(
      id: 'h5',
      title: 'Try a new healthy recipe',
      points: 12,
      category: 'nutrition',
      icon: 'chefHat',
    ),
    MiniGoal(
      id: 'h6',
      title: 'Get 7-8 hours of sleep',
      points: 12,
      category: 'sleep',
      icon: 'bedDouble',
    ),
    MiniGoal(
      id: 'h7',
      title: 'Eat a balanced plate (protein + veg + whole grain)',
      points: 12,
      category: 'nutrition',
      icon: 'salad',
    ),
  ],
  'local': [
    MiniGoal(
      id: 'l1',
      title: 'Eat a local meal today',
      points: 15,
      category: 'local',
      icon: 'leaf',
    ),
    MiniGoal(
      id: 'l2',
      title: 'Visit the farmer\'s market',
      points: 20,
      category: 'local',
      icon: 'store',
    ),
    MiniGoal(
      id: 'l3',
      title: 'Try a new local vegetable',
      points: 12,
      category: 'local',
      icon: 'carrot',
    ),
    MiniGoal(
      id: 'l4',
      title: 'Buy from a local vendor',
      points: 12,
      category: 'local',
      icon: 'shoppingBasket',
    ),
    MiniGoal(
      id: 'l5',
      title: 'Share a photo of your local meal',
      points: 10,
      category: 'local',
      icon: 'camera',
    ),
    MiniGoal(
      id: 'l6',
      title: 'Learn the story behind a local dish',
      points: 8,
      category: 'local',
      icon: 'bookOpen',
    ),
    MiniGoal(
      id: 'l7',
      title: 'Choose a local snack over a processed one',
      points: 12,
      category: 'local',
      icon: 'apple',
    ),
  ],
  'general': [
    MiniGoal(
      id: 'g1',
      title: 'Log a meal in Kraiiv',
      points: 10,
      category: 'nutrition',
      icon: 'bookOpen',
    ),
    MiniGoal(
      id: 'g2',
      title: 'Drink a bottle of water',
      points: 10,
      category: 'hydration',
      icon: 'glassWater',
    ),
    MiniGoal(
      id: 'g3',
      title: 'Walk for 15 minutes',
      points: 10,
      category: 'movement',
      icon: 'footprints',
    ),
    MiniGoal(
      id: 'g4',
      title: 'Eat mindfully without distractions',
      points: 10,
      category: 'mindfulness',
      icon: 'timer',
    ),
    MiniGoal(
      id: 'g5',
      title: 'Try a new food today',
      points: 12,
      category: 'nutrition',
      icon: 'sparkles',
    ),
    MiniGoal(
      id: 'g6',
      title: 'Complete all 4 daily goals',
      points: 20,
      category: 'general',
      icon: 'checkCheck',
    ),
    MiniGoal(
      id: 'g7',
      title: 'Share your progress with a friend',
      points: 10,
      category: 'general',
      icon: 'heartPulse',
    ),
  ],
};
