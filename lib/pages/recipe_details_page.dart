// recipe_details_page.dart
import 'package:flutter/material.dart';

class RecipeDetailsPage extends StatelessWidget {
  final Map<String, dynamic> recipeData;

  const RecipeDetailsPage({super.key, required this.recipeData});

  @override
  Widget build(BuildContext context) {
    final String title = recipeData['title'] ?? 'Recipe Details';
    final String description =
        recipeData['description'] ?? 'No description provided.';
    final String authorName = recipeData['authorName'] ?? 'Unknown Author';
    final String minutes = recipeData['minutes']?.toString() ?? 'N/A';
    final String likes = recipeData['likes']?.toString() ?? '0';
    final List<dynamic> ingredients = recipeData['ingredients'] ?? [];
    final List<dynamic> instructions = recipeData['instructions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6A33),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Text(
                  'No Image',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "By: $authorName . $minutes minutes",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 24),
                      const SizedBox(width: 5),
                      Text(
                        likes,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  if (ingredients.isNotEmpty) ...[
                    const Text(
                      "Ingredients:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          ingredients
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    "• $item",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (instructions.isNotEmpty) ...[
                    const Text(
                      "Instructions:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          instructions.asMap().entries.map((entry) {
                            int idx = entry.key + 1;
                            String instruction = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "$idx. $instruction",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
