import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> _signup() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('All fields are required!', Colors.red);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.', Colors.red);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        print('User created successfully: ${user.email}, UID: ${user.uid}');

        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Account created successfully!', Colors.green);
        Navigator.pushNamed(context, "home");

        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = e.message ?? 'An unknown authentication error occurred.';
      }
      _showSnackBar(message, Colors.red);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
      print('Error during signup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "SignUp",
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
            const SizedBox(height: 50),
            Image.asset(
              "assets/images/logo.png",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 50),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Enter Your Username",
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter Your Email",
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
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Enter Your Password",
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
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Confirm Password",
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

            FilledButton(
              onPressed: _isLoading ? null : _signup,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color(0xFFFF6A33),
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text(
                          "SignUp",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("I have an account, "),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "login");
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Color(0xFFFF6A33)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
