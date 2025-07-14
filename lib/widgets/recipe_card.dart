import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        'Recipe liked status updated for ${widget.title}: New likes count: $updatedLikesCount',
      );
    } catch (e) {
      print('Error updating like status in Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like status: $e'),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing ${widget.title} recipe!'),
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
