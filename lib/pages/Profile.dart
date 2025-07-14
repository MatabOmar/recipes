import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_sharing_app/pages/recipe_details_page.dart';

class Profile extends StatefulWidget {
  Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentAuthorId = "";
  String? _currentAuthorName;
  String? _currentAuthorEmail = "";
  bool _isLoadingUserData = true;
  bool _isLoadingRecipes = true;
  List<Map<String, dynamic>> _userRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndRecipes();
  }

  Future<void> _loadCurrentUserAndRecipes() async {
    setState(() {
      _isLoadingUserData = true;
      _isLoadingRecipes = true;
    });

    User? user = _auth.currentUser;

    if (user != null) {
      _currentAuthorId = user.uid;

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _currentAuthorName = userDoc['name'];
            _currentAuthorEmail = userDoc['email'];
          });
        } else {
          print('User document not found in Firestore for UID: ${user.uid}');
          setState(() {
            _currentAuthorName = user.email ?? 'Unknown User';
            _currentAuthorEmail = user.email ?? 'No Email';
          });
        }
      } catch (e) {
        print('Error fetching user document from Firestore: $e');
        setState(() {
          _currentAuthorName = user.email ?? 'Unknown User';
          _currentAuthorEmail = user.email ?? 'No Email';
        });
      } finally {
        setState(() {
          _isLoadingUserData = false;
        });
        await _fetchUserRecipes();
      }
    } else {
      print('No user is currently logged in.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
      setState(() {
        _isLoadingUserData = false;
        _isLoadingRecipes = false;
      });
    }
  }

  Future<void> _fetchUserRecipes() async {
    if (_currentAuthorId == null || _currentAuthorId!.isEmpty) {
      print("Current user ID is not available to fetch recipes.");
      setState(() {
        _isLoadingRecipes = false;
        _userRecipes = [];
      });
      return;
    }

    setState(() {
      _isLoadingRecipes = true;
    });
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('recipes')
              .where('authorId', isEqualTo: _currentAuthorId)
              .get();
      setState(() {
        _userRecipes =
            querySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
      print(
        'Fetched ${_userRecipes.length} recipes for user ID: $_currentAuthorId',
      );
    } catch (e) {
      print('Error fetching user recipes: $e');
    } finally {
      setState(() {
        _isLoadingRecipes = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushNamed(context, "login");
      if (mounted) {
        Navigator.pushNamed(context, "login");
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6A33),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoadingUserData || _isLoadingRecipes
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6A33)),
              )
              : Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Image.asset("assets/images/user.png", width: 100),
                        const SizedBox(height: 10),
                        Text(
                          _currentAuthorName ?? "Unknown User",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 23,
                          ),
                        ),
                        Text(_currentAuthorEmail ?? "No Email"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.only(top: 40),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFD1D0D0),
                            width: 2.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      width: double.infinity,
                      child: Text(
                        "My Recipes (${_userRecipes.length})",
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _userRecipes.isEmpty
                              ? const Center(
                                child: Text(
                                  "You haven't created any recipes yet.",
                                ),
                              )
                              : ListView.builder(
                                itemCount: _userRecipes.length,
                                itemBuilder: (context, index) {
                                  final recipe = _userRecipes[index];
                                  return RecipeCard(recipeData: recipe);
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
  final Map<String, dynamic> recipeData;

  const RecipeCard({super.key, required this.recipeData});

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final String title = widget.recipeData['title'] ?? 'No Title';
    final String description =
        widget.recipeData['description'] ?? 'No description';
    final String authorName =
        widget.recipeData['authorName'] ?? 'Unknown Author';
    final String minutes = widget.recipeData['minutes']?.toString() ?? 'N/A';
    final String likes = widget.recipeData['likes']?.toString() ?? '0';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 30),
      color: Colors.white,
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "By: $authorName . $minutes minutes",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
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
                          likes,
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
                                (context) => RecipeDetailsPage(
                                  recipeData: widget.recipeData,
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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Login Page!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => Profile()),
                );
              },
              child: const Text('Simulate Login'),
            ),
          ],
        ),
      ),
    );
  }
}
