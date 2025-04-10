import 'package:bus_tracker/pages/creatAccount.dart';
import 'package:bus_tracker/pages/forgotPasswordPage.dart';
import 'package:bus_tracker/pages/view_buses.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/pages/services/google_auth.dart';
import 'package:bus_tracker/pages/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables to store error messages
  String? _emailError;
  String? _passwordError;

 void signUserIn() async {
  if (!_formKey.currentState!.validate()) return;

  // Clear previous error messages
  setState(() {
    _emailError = null;
    _passwordError = null;
  });

  try {
    // Sign in with email and password
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Check if the email is verified
    if (userCredential.user!.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );

      // Navigate to the "view buses" page after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ViewBuses(), // Replace with your "view buses" page
        ),
      );
    } else {
      // If email is not verified, show a message and prompt the user to verify their email
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email before logging in.'),
        ),
      );

      // Optionally, send a new verification email
      await userCredential.user!.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification email has been sent.'),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    // Map Firebase error codes to custom user-friendly messages
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'User not found. Please register.';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password. Please try again.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address. Please check your email.';
        break;
      default:
        // Handle the generic error message
        if (e.message?.contains("supplied auth credential is incorrect") == true) {
          errorMessage = 'Incorrect email or password. Please try again.';
        } else {
          errorMessage = 'An error occurred. Please try again.'; // Generic fallback message
        }
    }

    // Set the appropriate error message
    if (e.code == 'user-not-found' || e.code == 'invalid-email') {
      setState(() {
        _emailError = errorMessage;
      });
    } else if (e.code == 'wrong-password' || e.code == 'too-many-requests') {
      setState(() {
        _passwordError = errorMessage;
      });
    } else {
      // For generic errors, display the message under the password field
      setState(() {
        _passwordError = errorMessage;
      });
    }
  } catch (e) {
    // Handle any other errors
    setState(() {
      _passwordError = 'An unexpected error occurred. Please try again.';
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'TRIPS',
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/images/darkCar.png',
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    errorText: _emailError, // Pass the email error message
                  ),
                  const SizedBox(height: 50),
                  CustomTextField(
                    labelText: 'Password',
                    isPassword: true, // Enable password visibility toggle
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            "forgot password?",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Mybutton(onTap: signUserIn, text: "Sign in"),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1.0,
                            color: Colors.grey[400],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text("Or continue with"),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1.0,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      squareTile(
                        imagePath: 'assets/images/google.png',
                        onTap: () => AuthService().signInWithGoogle(),
                      ),
                      const SizedBox(width: 20),
                      squareTile(
                        imagePath: 'assets/images/apple.png',
                        onTap: () => AuthService().signInWithGoogle(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Not a member?'),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateAccount(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
