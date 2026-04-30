import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'nutrition_data.dart';

class ReviewScreen extends StatefulWidget {
  final NutritionData nutritionData;

  const ReviewScreen({super.key, required this.nutritionData});

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController nameController;
  late TextEditingController ingredientsController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  late TextEditingController extraInfoController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.nutritionData.productName);
    ingredientsController = TextEditingController(text: widget.nutritionData.ingredients);
    caloriesController = TextEditingController(text: widget.nutritionData.calories);
    proteinController = TextEditingController(text: widget.nutritionData.protein);
    carbsController = TextEditingController(text: widget.nutritionData.carbs);
    fatController = TextEditingController(text: widget.nutritionData.fat);
    extraInfoController = TextEditingController(text: widget.nutritionData.extraInfo);
  }

  @override
  void dispose() {
    nameController.dispose();
    ingredientsController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    extraInfoController.dispose();
    super.dispose();
  }

  void _saveData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in. Scan not saved to history, but viewing AI analysis!')),
      );
      Navigator.pop(context, true); 
      return; 
    }

    final scanData = {
      'userId': user.uid,
      'productName': nameController.text,
      'calories': caloriesController.text,
      'protein': proteinController.text,
      'carbs': carbsController.text,
      'fat': fatController.text,
      'ingredients': ingredientsController.text,
      'extraInfo': extraInfoController.text,
      'keyDetails': widget.nutritionData.keyDetails,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('scans').add(scanData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your history!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save to cloud.')),
      );
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Data")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTextField(nameController, 'Product Name', TextInputType.text),
            const SizedBox(height: 16),
            _buildTextField(caloriesController, 'Calories', TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(proteinController, 'Protein (g)', TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(carbsController, 'Carbs (g)', TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(fatController, 'Fat (g)', TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(extraInfoController, 'Other Info (Cholesterol, Sodium, etc.)', TextInputType.text, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(ingredientsController, 'Ingredients', TextInputType.text, maxLines: 5),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Save & View AI Analysis', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}