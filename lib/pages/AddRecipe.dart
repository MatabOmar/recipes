import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Addrecipe extends StatefulWidget {
  const Addrecipe({super.key});

  @override
  State<Addrecipe> createState() => _AddrecipeState();
}

class _AddrecipeState extends State<Addrecipe> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _cookingTime = TextEditingController();
  final TextEditingController _ingredientController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  List<String> _ingredients = [];
  bool _isLoading = false;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentAuthorId;
  String? _currentAuthorName;

  // New: List of recipe categories
  final List<String> _recipeCategories = ['Breakfast', 'Lunch', 'Dinner'];

  // New: Variable to hold the selected category
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    User? user = _auth.currentUser;

    if (user != null) {
      _currentAuthorId = user.uid;

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _currentAuthorName = userDoc['name'];
          });
          print(
            'Loaded current user: ${_currentAuthorName} (ID: ${_currentAuthorId})',
          );
        } else {
          print('User document not found in Firestore for UID: ${user.uid}');
          setState(() {
            _currentAuthorName = user.email ?? 'Unknown User';
          });
        }
      } catch (e) {
        print('Error fetching user document from Firestore: $e');
        setState(() {
          _currentAuthorName = user.email ?? 'Unknown User';
        });
      }
    } else {
      print('No user is currently logged in.');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (_currentAuthorId == null || _currentAuthorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add a recipe.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String title = _title.text.trim();
    final String description = _description.text.trim();
    final String cookingTime = _cookingTime.text.trim();

    // New: Check if a category is selected
    if (title.isEmpty ||
        description.isEmpty ||
        cookingTime.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in the Title, Description, Cooking Time, and select a Category.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = _storage.ref().child(
          'recipe_images/$fileName.jpg',
        );
        UploadTask uploadTask = storageRef.putFile(_selectedImage!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
        print('Image uploaded to Firebase Storage. URL: $imageUrl');
      } else {
        print('No image selected for upload (optional).');
      }

      Map<String, dynamic> recipeData = {
        'title': title,
        'description': description,
        'cookingTime': cookingTime,
        'imageUrl': imageUrl,
        'ingredients': _ingredients,
        'likesBy': [],
        'comments': [],
        'likes': 0,
        'authorName': _currentAuthorName,
        'authorId': _currentAuthorId,
        'createdAt': FieldValue.serverTimestamp(),
        'category': _selectedCategory, // New: Add the selected category
      };

      await _firestore.collection('recipes').add(recipeData);
      print('Recipe data saved to Cloud Firestore:');
      print(recipeData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _title.clear();
      _description.clear();
      _cookingTime.clear();
      _ingredientController.clear();
      setState(() {
        _selectedImage = null;
        _ingredients.clear();
        _selectedCategory = null; // New: Clear selected category
      });
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _cookingTime.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Add Recipe",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6A33),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(
                hintText: "Enter The Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter The Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cookingTime,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter The Cooking Time (minutes)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New: Dropdown for Recipe Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text("Select Category"),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xffdddddd),
                    width: 2,
                  ),
                ),
              ),
              items:
                  _recipeCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            _selectedImage == null
                ? Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xffdddddd),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No image selected',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
                : Image.file(
                  _selectedImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
            const SizedBox(height: 20),
            // Commented out the image upload button
            /*
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFFF6A33),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Pick Image",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            */
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      hintText: "Add ingredient",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xffdddddd),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xffdddddd),
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (value) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _addIngredient,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A33),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_ingredients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ingredients:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(_ingredients[index]),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecipe,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: const Color(0xFFFF6A33),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        "Save Recipe",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
