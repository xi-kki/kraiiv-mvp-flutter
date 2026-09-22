/// Local & Seasonal recipe ideas shown on the home screen.
/// Mirrors the prototype's "Local & Seasonal Ideas" carousel — with real food
/// photos matching C:/tmp/kraiiv-prototype-preview.html / video frames 130-180.
class Recipe {
  final String title;
  final String subtitle;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String icon; // lucide icon name lookup happens in the UI layer
  final String imageUrl; // Unsplash food photo — prototype uses real images
  final int healthScore;
  final bool isLocal;
  final String kiaTip;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const Recipe({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.icon,
    required this.imageUrl,
    required this.healthScore,
    required this.isLocal,
    required this.kiaTip,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class RecipeRepository {
  static final List<Recipe> recipes = [
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
      instructions: [
        'Chop all vegetables into bite-sized pieces',
        'Cook rice or quinoa according to package instructions',
        'Boil eggs for 7-8 minutes, then peel and halve',
        'Arrange vegetables, rice, and eggs in a bowl',
        'Drizzle with tahini dressing and garnish with fresh herbs',
      ],
      icon: 'salad',
      imageUrl:
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80&auto=format&fit=crop',
      healthScore: 9,
      isLocal: true,
      kiaTip: 'Add a handful of fresh herbs for extra micronutrients and flavor.',
      calories: 420,
      protein: 18.5,
      carbs: 52.0,
      fat: 14.2,
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
      instructions: [
        'Preheat oven to 180°C',
        'Whisk eggs with salt, pepper, and herbs',
        'Sauté vegetables until tender',
        'Pour egg mixture over vegetables in oven-safe pan',
        'Sprinkle cheese on top',
        'Bake for 12-15 minutes until set and golden',
      ],
      icon: 'egg',
      imageUrl:
          'https://images.unsplash.com/photo-1482049016688-2d3e1b31122d?w=600&q=80&auto=format&fit=crop',
      healthScore: 8,
      isLocal: true,
      kiaTip: 'Use the freshest eggs you can find for the best flavor and nutrition.',
      calories: 280,
      protein: 22.0,
      carbs: 8.5,
      fat: 18.5,
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
      instructions: [
        'Add all ingredients to a blender',
        'Blend until smooth and creamy',
        'Taste and adjust sweetness if needed',
        'Pour into a glass and enjoy immediately',
      ],
      icon: 'apple',
      imageUrl:
          'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=600&q=80&auto=format&fit=crop',
      healthScore: 7,
      isLocal: true,
      kiaTip: 'Frozen berries work just as well and are often more affordable.',
      calories: 310,
      protein: 12.5,
      carbs: 42.0,
      fat: 10.8,
    ),
  ];
}