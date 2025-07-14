import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:like_button/like_button.dart';

class RecipeDetailScreen extends StatefulWidget {
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
  final String category; // New: Add category to the constructor

  const RecipeDetailScreen({
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
    required this.category, // Make it required
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late bool _isLiked;
  late int _currentLikes;
  late List<String> _currentLikesBy;
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.likes;
    _currentLikesBy = List.from(widget.likesBy);
    _isLiked =
        widget.currentUserId != null &&
        _currentLikesBy.contains(widget.currentUserId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<bool> _onLikeButtonTap(bool isLiked) async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to log in to like a recipe.'),
          backgroundColor: Colors.red,
        ),
      );
      return isLiked;
    }

    DocumentReference recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId);

    setState(() {
      if (isLiked) {
        _currentLikesBy.remove(widget.currentUserId);
        _currentLikes--;
      } else {
        _currentLikesBy.add(widget.currentUserId!);
        _currentLikes++;
      }
      _isLiked = !_isLiked;
    });

    try {
      await recipeRef.update({
        'likes': _currentLikes,
        'likesBy': _currentLikesBy,
      });
      print(
        'Recipe liked status updated: ${widget.title}, new likes: $_currentLikes',
      );
      return !isLiked;
    } catch (e) {
      print('Error updating like status from detail screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Revert changes if update fails
      setState(() {
        if (isLiked) {
          _currentLikesBy.add(widget.currentUserId!);
          _currentLikes++;
        } else {
          _currentLikesBy.remove(widget.currentUserId);
          _currentLikes--;
        }
        _isLiked = isLiked;
      });
      return isLiked;
    }
  }

  Future<void> _addComment() async {
    if (widget.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to log in to add a comment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment cannot be empty.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      String? userName = _auth.currentUser?.displayName;
      // Fetch user name from 'users' collection if displayName is null or empty
      if (userName == null || userName.isEmpty) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.currentUserId)
                .get();
        userName = userDoc.data()?['name'] ?? 'Anonymous';
      }

      // Add the comment to a subcollection named 'comments' under the specific recipe document
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .collection('comments') // This is the new subcollection
          .add({
            'userId': widget.currentUserId,
            'userName': userName,
            'commentText': _commentController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
          });
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6A33),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.imageUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
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
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.broken_image,
                          size: 70,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                )
                : Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'No Image Available',
                      style: TextStyle(color: Colors.grey, fontSize: 20),
                    ),
                  ),
                ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6A33),
                    ),
                  ),
                ),
                LikeButton(
                  size: 35,
                  isLiked: _isLiked,
                  likeCount: _currentLikes,
                  animationDuration: const Duration(milliseconds: 500),
                  countPostion: CountPostion.right,
                  mainAxisAlignment: MainAxisAlignment.end,
                  likeBuilder: (bool isLiked) {
                    return Image.asset(
                      isLiked
                          ? "assets/images/heart2.png"
                          : "assets/images/heart1.png",
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    );
                  },
                  onTap: _onLikeButtonTap,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "By: ${widget.authorName} • ${widget.cookingTime} minutes",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            // New: Display Category
            Text(
              "Category: ${widget.category}",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Description:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Ingredients:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  widget.ingredients
                      .map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "• $ingredient",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 30),

            const Text(
              "Comments:",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (widget.currentUserId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: _addComment,
                      backgroundColor: const Color(0xFFFF6A33),
                      mini: true,
                      elevation: 0,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 15.0),
                child: Text(
                  'Log in to add a comment.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // StreamBuilder to display comments from the subcollection
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('recipes')
                      .doc(widget.recipeId)
                      .collection(
                        'comments',
                      ) // Target the 'comments' subcollection
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading comments: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to comment!'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot commentDoc = snapshot.data!.docs[index];
                    Map<String, dynamic> comment =
                        commentDoc.data() as Map<String, dynamic>;

                    String userName = comment['userName'] ?? 'Anonymous';
                    String commentText = comment['commentText'] ?? '';
                    Timestamp? timestamp = comment['timestamp'];

                    // Format time difference
                    String timeAgo = '';
                    if (timestamp != null) {
                      DateTime commentTime = timestamp.toDate();
                      Duration difference = DateTime.now().difference(
                        commentTime,
                      );
                      if (difference.inDays > 0) {
                        timeAgo = '${difference.inDays}d ago';
                      } else if (difference.inHours > 0) {
                        timeAgo = '${difference.inHours}h ago';
                      } else if (difference.inMinutes > 0) {
                        timeAgo = '${difference.inMinutes}m ago';
                      } else {
                        timeAgo = 'Just now';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 0,
                      ),
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              commentText,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
