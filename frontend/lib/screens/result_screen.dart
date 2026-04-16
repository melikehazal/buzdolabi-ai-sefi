import 'package:flutter/material.dart';
import 'package:frontend/models/recipe.dart';
import 'package:frontend/screens/protein_screen.dart';

class ResultScreen extends StatelessWidget {
  final RecipeResponse recipeResponse;

  const ResultScreen({super.key, required this.recipeResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sizin için 3 öneri hazırladık!")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final recipe = recipeResponse.recipes[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.emoji,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        Text(" ${recipe.emoji} : "),
                        const SizedBox(height: 8.0),
                        Text("Tarif Adı: ${recipe.recipe_name} "),
                        const SizedBox(height: 8.0),

                        Text("Adımlar:"),
                        ...recipe.steps.map((step) => Text("• $step")).toList(),
                      ],
                    ),
                  ),
                );
              },
              itemCount: recipeResponse.recipes.length,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProteinScreen(recipeResponse: recipeResponse),
                  ),
                );
              },
              child: Text("Protein detayını gör."),
            ),
          ),
        ],
      ),
    );
  }
}
