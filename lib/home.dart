import 'package:flutter/material.dart';
import 'package:recipe_sharing_app/pages/AddRecipe.dart';
import 'package:recipe_sharing_app/pages/Profile.dart';
import 'package:recipe_sharing_app/pages/Recipes.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final secreens = [Recipes(), Addrecipe(), Profile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),

      bottomNavigationBar: NavigationBar(
        // indicatorColor: Colors.amber,
        selectedIndex: _index,
        onDestinationSelected:
            (index) => {
              setState(() {
                _index = index;
              }),
              print(index),
            },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home, size: 30),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF6A33), size: 30),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.create, size: 30),
            selectedIcon: Icon(
              Icons.create,
              color: Color(0xFFFF6A33),
              size: 30,
            ),
            label: "Add Recipt",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_box, size: 30),

            selectedIcon: Icon(
              Icons.account_box,
              color: Color(0xFFFF6A33),
              size: 30,
            ),
            label: "Profile",
          ),
        ],
      ),
      body: secreens[_index],
    );
  }
}
