import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recipe_sharing_app/home.dart';
import 'package:recipe_sharing_app/login.dart';
import 'package:recipe_sharing_app/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "login",
      routes: {
        "login": (context) => Login(),
        "signup": (context) => Signup(),
        "home": (context) => HomePage(),
      },
    );
  }
}
