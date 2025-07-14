import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email and password cannot be empty.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        _showSnackBar('Logged in successfully!', Colors.green);
        print('User logged in: ${user.email}, UID: ${user.uid}');

        _emailController.clear();
        _passwordController.clear();

        Navigator.pushNamed(context, "home");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        default:
          message = e.message ?? 'An unknown error occurred during login.';
          break;
      }
      _showSnackBar(message, Colors.red);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnackBar('An unexpected error occurred.', Colors.red);
      print('Error during login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Login",
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
            const SizedBox(height: 100),
            Image.asset(
              "assets/images/logo.png",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 50),

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

            FilledButton(
              onPressed: _isLoading ? null : _login,
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
                          "Login",
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
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "signup");
                  },
                  child: const Text(
                    "Sign Up",
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
