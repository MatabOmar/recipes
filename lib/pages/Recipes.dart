import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_sharing_app/pages/recipe_detail_screen.dart'; // Ensure this path is correct

// Extension to capitalize the first letter of a string and make others lowercase
extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.toCapitalized()).join(' ');
}

class Recipes extends StatefulWidget {
  const Recipes({super.key});

  @override
  State<Recipes> createState() => _RecipesState();
}

class _RecipesState extends State<Recipes> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  String? _selectedCategory; // null means 'All Categories'

  List<String> _uniqueCategories = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _fetchUniqueCategories(); // Fetch categories when the widget initializes
  }

  Future<void> _fetchUniqueCategories() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('recipes').get();

      Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data != null && data.containsKey('category')) {
          // Normalize category string from Firestore: trim whitespace and convert to Title Case
          String category = (data['category'] as String).trim().toTitleCase();
          categories.add(category);
        }
      }

      setState(() {
        _uniqueCategories = categories.toList()..sort();
        // Ensure fixed categories are not duplicated if they also exist in _uniqueCategories
        _uniqueCategories.removeWhere(
          (cat) => ['Breakfast', 'Lunch', 'Dinner'].contains(cat.toTitleCase()),
        );
      });
      print('Fetched unique categories: $_uniqueCategories');
    } catch (e) {
      print('Error fetching unique categories: $e');
      // Show a user-friendly message for category loading errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to create a category button
  Widget _buildCategoryButton(
    String categoryName,
    String? currentSelectedCategory,
  ) {
    // Normalize the category name for both the button and the comparison
    final normalizedCategoryName = categoryName.trim().toTitleCase();
    final normalizedSelectedCategory =
        currentSelectedCategory?.trim().toTitleCase();

    bool isSelected = normalizedSelectedCategory == normalizedCategoryName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            // Store the normalized category name in _selectedCategory for the query
            _selectedCategory = normalizedCategoryName;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? const Color(0xFFFF6A33) // Active color
                  : Colors.grey[300], // Inactive color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          normalizedCategoryName, // Display the normalized name on the button
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Recipes",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6A33),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Category filter buttons
            SizedBox(
              height: 50, // Height for the horizontal button row
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Button for 'All Categories'
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null; // Set to null for 'All'
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedCategory == null
                                  ? const Color(0xFFFF6A33) // Active color
                                  : Colors.grey[300], // Inactive color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "All Categories",
                          style: TextStyle(
                            color:
                                _selectedCategory == null
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Specific buttons for common meal categories (normalized explicitly)
                    _buildCategoryButton('Breakfast', _selectedCategory),
                    _buildCategoryButton('Lunch', _selectedCategory),
                    _buildCategoryButton('Dinner', _selectedCategory),

                    // Dynamically generated buttons for other unique categories (already normalized)
                    ..._uniqueCategories.map((category) {
                      return _buildCategoryButton(category, _selectedCategory);
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15), // Space between buttons and recipe list

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // The stream now uses the normalized _selectedCategory
                stream:
                    _selectedCategory == null
                        ? FirebaseFirestore.instance
                            .collection('recipes')
                            .orderBy('createdAt', descending: true)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('recipes')
                            .where(
                              'category',
                              isEqualTo: _selectedCategory,
                            ) // This query uses the normalized string
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print('Error fetching recipes: ${snapshot.error}');
                    // Display a more specific error message to the user
                    return Center(
                      child: Text('Error loading recipes: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedCategory == null
                            ? 'No recipes found yet.'
                            : 'No recipes found for "${_selectedCategory ?? 'this'}" category.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> recipe =
                          doc.data() as Map<String, dynamic>;

                      // Ensure all these fields are handled gracefully if they might be missing
                      String recipeId = doc.id;
                      String title = recipe['title'] ?? 'No Title';
                      String description =
                          recipe['description'] ?? 'No Description';
                      String cookingTime = recipe['cookingTime'] ?? 'N/A';
                      String imageUrl = recipe['imageUrl'] ?? '';
                      List<dynamic> ingredientsDynamic =
                          recipe['ingredients'] ?? [];
                      List<String> ingredients =
                          ingredientsDynamic.map((e) => e.toString()).toList();
                      String authorName =
                          recipe['authorName'] ?? 'Unknown Author';
                      String authorId = recipe['authorId'] ?? '';
                      // Normalize category when retrieving from doc to ensure consistent display in card
                      String category =
                          (recipe['category'] as String?)
                              ?.trim()
                              .toTitleCase() ??
                          'Uncategorized';

                      int likes = recipe['likes'] ?? 0;
                      List<dynamic> likesByDynamic = recipe['likesBy'] ?? [];
                      List<String> likesBy =
                          likesByDynamic.map((e) => e.toString()).toList();

                      return RecipeCard(
                        recipeId: recipeId,
                        title: title,
                        description: description,
                        cookingTime: cookingTime,
                        imageUrl: imageUrl,
                        ingredients: ingredients,
                        authorName: authorName,
                        authorId: authorId,
                        likes: likes,
                        likesBy: likesBy,
                        currentUserId: _currentUserId,
                        category:
                            category, // Pass normalized category to RecipeCard
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCard extends StatefulWidget {
  final String recipeId;
  final String title;
  final String description;
  final String cookingTime;
  final String imageUrl;
  final List<String> ingredients;
  final String authorName;
  final String authorId;
  final int likes;
  final List<String> likesBy;
  final String? currentUserId;
  final String category; // New: Add category

  const RecipeCard({
    super.key,
    required this.recipeId,
    required this.title,
    required this.description,
    required this.cookingTime,
    required this.imageUrl,
    required this.ingredients,
    required this.authorName,
    required this.authorId,
    required this.likes,
    required this.likesBy,
    this.currentUserId,
    required this.category, // Required category
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked =
        widget.currentUserId != null &&
        widget.likesBy.contains(widget.currentUserId);
  }

  Future<void> _toggleLike() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to log in to like a recipe.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DocumentReference recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId);

    List<String> updatedLikesBy = List.from(widget.likesBy);
    int updatedLikesCount = widget.likes;

    if (_isLiked) {
      updatedLikesBy.remove(widget.currentUserId);
      updatedLikesCount--;
    } else {
      updatedLikesBy.add(widget.currentUserId!);
      updatedLikesCount++;
    }

    try {
      await recipeRef.update({
        'likes': updatedLikesCount,
        'likesBy': updatedLikesBy,
      });

      setState(() {
        _isLiked = !_isLiked;
      });
      print(
        'Recipe liked status updated: ${widget.title}, new likes: $updatedLikesCount',
      );
    } catch (e) {
      print('Error updating like status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 30),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.imageUrl.isNotEmpty
              ? Image.network(
                widget.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              )
              : Container(
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
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "By: ${widget.authorName} . ${widget.cookingTime} minutes",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Category: ${widget.category}", // Display category
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                if (widget.ingredients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ingredients:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.ingredients.join(', ')),
                    ],
                  ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Image.asset(
                            _isLiked
                                ? "assets/images/heart2.png"
                                : "assets/images/heart1.png",
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${widget.likes}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RecipeDetailScreen(
                                  recipeId: widget.recipeId,
                                  title: widget.title,
                                  description: widget.description,
                                  cookingTime: widget.cookingTime,
                                  imageUrl: widget.imageUrl,
                                  ingredients: widget.ingredients,
                                  authorName: widget.authorName,
                                  authorId: widget.authorId,
                                  likes: widget.likes,
                                  likesBy: widget.likesBy,
                                  currentUserId: widget.currentUserId,
                                  category: widget.category, // Pass category
                                ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A33),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "View Recipe",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
