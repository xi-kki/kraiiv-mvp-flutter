/// Local & Seasonal recipe ideas shown on the home screen.
/// Mirrors the prototype's "Local & Seasonal Ideas" carousel — with real food
/// photos matching C:/tmp/kraiiv-prototype-preview.html / video frames 130-180.
class Recipe {
  final String title;
  final String subtitle;
  final String description;
  final List<String> ingredients;
  final String icon; // lucide icon name lookup happens in the UI layer
  final String imageUrl; // Unsplash food photo — prototype uses real images

  const Recipe({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.ingredients,
    required this.icon,
    required this.imageUrl,
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
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80&auto=format&fit=crop',
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
      imageUrl:
          'https://images.unsplash.com/photo-1482049016688-2d3e1b31122d?w=600&q=80&auto=format&fit=crop',
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
      imageUrl:
          'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=600&q=80&auto=format&fit=crop',
    ),
  ];
}
