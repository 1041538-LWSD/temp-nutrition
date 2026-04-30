class NutritionData {
  String productName;
  String ingredients;
  String calories;
  String protein;
  String carbs;
  String fat;
  String extraInfo;
  String? keyDetails;

  NutritionData({
    required this.productName,
    required String ingredients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.extraInfo,
    this.keyDetails,
  }) : ingredients = _formatIngredients(ingredients);

  static String _formatIngredients(String text) {
    if (text == 'Not found' || text.isEmpty) return text;
    return text.toLowerCase().replaceAllMapped(
      RegExp(r'\b\w'),
      (match) => match.group(0)!.toUpperCase(),
    );
  }

  factory NutritionData.empty() {
    return NutritionData(
      productName: 'Unknown Product',
      ingredients: 'Not found',
      calories: '0',
      protein: '0',
      carbs: '0',
      fat: '0',
      extraInfo: '',
    );
  }
}