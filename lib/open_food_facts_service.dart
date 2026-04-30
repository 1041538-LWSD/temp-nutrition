import 'package:openfoodfacts/openfoodfacts.dart';
import 'nutrition_data.dart';

class OpenFoodFactsService {
  static Future<NutritionData?> fetchNutritionByBarcode(String barcode) async {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'NutritionApp',
      url: '',
    );

    final queryConfig = ProductQueryConfiguration(
      barcode,
      version: ProductQueryVersion.v3,
      language: OpenFoodFactsLanguage.ENGLISH,
    );

    try {
      final result = await OpenFoodAPIClient.getProductV3(queryConfig);

      if (result.status == ProductResultV3.statusSuccess && result.product != null) {
        final product = result.product!;
        List<String> extras = [];
        
        final sodium = product.nutriments?.getValue(Nutrient.sodium, PerSize.serving);
        final fiber = product.nutriments?.getValue(Nutrient.fiber, PerSize.serving);
        
        if (sodium != null) extras.add('Sodium: $sodium');
        if (fiber != null) extras.add('Fiber: $fiber');

        return NutritionData(
          productName: product.productName ?? 'Unknown Product',
          ingredients: product.ingredientsText ?? 'Ingredients not listed',
          calories: product.nutriments?.getValue(Nutrient.energyKCal, PerSize.serving)?.toString() ?? '0',
          protein: product.nutriments?.getValue(Nutrient.proteins, PerSize.serving)?.toString() ?? '0',
          carbs: product.nutriments?.getValue(Nutrient.carbohydrates, PerSize.serving)?.toString() ?? '0',
          fat: product.nutriments?.getValue(Nutrient.fat, PerSize.serving)?.toString() ?? '0',
          extraInfo: extras.join(', '),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}