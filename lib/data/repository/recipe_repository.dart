/// Local & Seasonal recipe ideas shown on the home screen.
/// Mirrors the prototype's "Local & Seasonal Ideas" carousel.
class Recipe {
  final String title;
  final String subtitle;
  final String description;
  final List<String> ingredients;
  final String icon; // lucide icon name lookup happens in the UI layer

  const Recipe({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.ingredients,
    required this.icon,
  });
}

class RecipeRepository {
  static const List<Recipe> recipes = [
    Recipe(
      title: 'Seasonal Vegetable Harmony Bowl',
      subtitle: 'Fresh, colourful and light',
      description:
          'A balanced bowl with fresh seasonal vegetables and tahini dressing. '
          'Perfect for a light lunch that keeps you energised.',
      ingredients: [
        'Seasonal vegetables (carrot, cabbage, cucumber)',
        'Steamed rice or quinoa',
        'Boiled eggs or grilled chicken',
        'Tahini dressing',
        'Fresh herbs',
      ],
      icon: 'salad',
    ),
    Recipe(
      title: 'Farmers Market Frittata',
      subtitle: 'Made with eggs and seasonal produce',
      description:
          'Made with fresh eggs and seasonal produce from your region. '
          'A protein-packed breakfast that uses up whatever is at the market.',
      ingredients: [
        '4 fresh eggs',
        'Seasonal vegetables (peppers, spinach, onions)',
        'Small handful of cheese',
        'Salt, pepper and dried herbs',
      ],
      icon: 'egg',
    ),
    Recipe(
      title: 'Local Berry Breakfast Smoothie',
      subtitle: 'An energising, plant-based blend',
      description:
          'An energising smoothie made with seasonal berries and plant-based '
          'ingredients. A 5-minute breakfast full of vitamins.',
      ingredients: [
        'Seasonal berries (or any local fruit)',
        '1 ripe banana',
        'Oat milk or plain yoghurt',
        'A spoon of groundnut butter',
        'Optional: oats for thickness',
      ],
      icon: 'apple',
    ),
  ];
}
