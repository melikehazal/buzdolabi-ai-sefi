class ProteinItem {
  String ingredient;
  double protein_g;

  ProteinItem(this.ingredient, this.protein_g);

  factory ProteinItem.fromJson(Map<String, dynamic> json) {
    return ProteinItem(
      json['ingredient'] as String,
      (json['protein_g'] as num).toDouble(),
    );
  }
}

class SingleRecipe {
  String recipe_name;
  String emoji;
  List<String> steps;

  SingleRecipe(this.recipe_name, this.emoji, this.steps);

  factory SingleRecipe.fromJson(Map<String, dynamic> json) {
    return SingleRecipe(
      json['recipe_name'] as String,
      json['emoji'] as String,
      List<String>.from(json['steps']),
    );
  }
}

class RecipeResponse {
  List<SingleRecipe> recipes;
  List<ProteinItem> proteins;
  double total_protein;
  String tip;

  RecipeResponse(this.recipes, this.proteins, this.total_protein, this.tip);

  factory RecipeResponse.fromJson(Map<String, dynamic> json) {
    return RecipeResponse(
      List<SingleRecipe>.from(
        json['recipes'].map((x) => SingleRecipe.fromJson(x)),
      ),
      List<ProteinItem>.from(
        json['proteins'].map((x) => ProteinItem.fromJson(x)),
      ),
      (json['total_protein'] as num).toDouble(),
      json['tip'] as String,
    );
  }
}
