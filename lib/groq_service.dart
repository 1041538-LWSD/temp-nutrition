import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'nutrition_data.dart';
import 'dart:typed_data'; 

class GroqService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _analysisPrompt = 
      'Provide a concise analysis formatted into three clear sections: 1. Possible Allergens, 2. Alarming Ingredients, 3. Overall Quality. '
      'Use plain text only. Do not use any markdown symbols like # or *. '
      'Under each section, provide 2-3 bullet points starting with a simple dash (-). '
      'Ensure there is a blank line between each section for readability.';

  static Future<NutritionData> parseLabel(XFile imageFile) async {
    final bytes = await File(imageFile.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    return _sendRequest(base64Image, 'image/jpeg');
  }

  static Future<NutritionData> parseLabelFromBytes(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    return _sendRequest(base64Image, 'image/png');
  }

  static Future<NutritionData> _sendRequest(String base64Image, String mimeType) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'response_format': {"type": "json_object"},
          'messages': [
            {
              'role': 'system',
              'content': 'You are a precise nutrition data extraction assistant. Extract data from the image. Always return a strict JSON object with these exact keys: "productName" (string, guess the food name based on the label), "ingredients" (string), "calories" (string), "protein" (string), "carbs" (string), "fat" (string), "extraInfo" (string), "keyDetails" (string). If a value is missing, return "0" for macros or "Not found" for ingredients. Put all other items into "extraInfo". For "keyDetails", $_analysisPrompt',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Extract the exact nutritional values per serving, ingredients, guess the product name, and provide key details analysis from this label. Output in JSON.',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
                },
              ],
            },
          ],
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String content = jsonResponse['choices'][0]['message']['content'];
        content = content.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?'), '').trim();
        final Map<String, dynamic> parsedJson = jsonDecode(content);

        return NutritionData(
          productName: parsedJson['productName']?.toString() ?? 'Unknown Product',
          ingredients: parsedJson['ingredients']?.toString() ?? 'Not found',
          calories: parsedJson['calories']?.toString() ?? '0',
          protein: parsedJson['protein']?.toString() ?? '0',
          carbs: parsedJson['carbs']?.toString() ?? '0',
          fat: parsedJson['fat']?.toString() ?? '0',
          extraInfo: parsedJson['extraInfo']?.toString() ?? '',
          keyDetails: parsedJson['keyDetails']?.toString(),
        );
      }
      return NutritionData.empty();
    } catch (e) {
      return NutritionData.empty();
    }
  }

  static Future<String?> fetchKeyDetails(NutritionData data) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a nutrition expert. Analyze the provided food data. $_analysisPrompt',
            },
            {
              'role': 'user',
              'content': 'Product: ${data.productName}\nIngredients: ${data.ingredients}\nCalories: ${data.calories}\nProtein: ${data.protein}\nCarbs: ${data.carbs}\nFat: ${data.fat}\nExtra Info: ${data.extraInfo}',
            },
          ],
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}