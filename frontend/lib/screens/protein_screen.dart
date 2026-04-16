import 'package:flutter/material.dart';
import 'package:frontend/models/recipe.dart';

class ProteinScreen extends StatelessWidget {
  final RecipeResponse recipeResponse;
  const ProteinScreen({super.key, required this.recipeResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Protein Detayları")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: recipeResponse.proteins
                  .map(
                    (item) => ListTile(
                      title: Text(item.ingredient),
                      trailing: Text('${item.protein_g}g'),
                    ),
                  )
                  .toList(),
            ),
          ),
          Text("Toplam Protein: ${recipeResponse.total_protein}g"),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("İpucu: ${recipeResponse.tip}"),
          ),
        ],
      ),
    );
  }
}
