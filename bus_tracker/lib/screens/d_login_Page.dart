import 'package:bus_tracker/screens/c_creatAccount_Page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_tracker/screens/e_forgotPassword_Page.dart';
import 'package:bus_tracker/screens/home.dart';
import 'package:bus_tracker/services/google_auth.dart';
import 'package:bus_tracker/utils/validators/input_validator.dart';
import 'package:bus_tracker/widgets/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  void signUserIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ActiveVehiclesPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before logging in.'),
          ),
        );
        await userCredential.user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new verification email has been sent.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'User not found. Please register.';
          setState(() => _emailError = errorMessage);
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          setState(() => _emailError = errorMessage);
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          setState(() => _passwordError = errorMessage);
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later.';
          setState(() => _passwordError = errorMessage);
          break;
        default:
          errorMessage = e.message ?? 'An error occurred. Try again.';
          setState(() => _passwordError = errorMessage);
      }
    } catch (_) {
      setState(() {
        _passwordError = 'Unexpected error. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const CustomAppBar(title: 'TRIPS'),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset('assets/images/darkCar.png', height: 80),
                  const SizedBox(height: 10),
                  const Text(
                    "Sign in",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: FieldValidator.validateEmail,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 50),
                  CustomTextField(
                    labelText: 'Password',
                    isPassword: true,
                    controller: _passwordController,
                    validator: FieldValidator.validateLoginPassword,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Mybutton(onTap: signUserIn, text: "Sign in"),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1.0, color: Colors.grey[400]),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        child: Text("Or continue with"),
                      ),
                      Expanded(
                        child: Divider(thickness: 1.0, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      squareTile(
                        imagePath: 'assets/images/google.png',
                        onTap: () async {
                          final user = await AuthService().signInWithGoogle();
                          if (user != null) {
                            if (user.emailVerified ||
                                user.providerData
                                    .any((p) => p.providerId == 'google.com')) {
                              // Navigate to homepage
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ActiveVehiclesPage()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please verify your email.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Google sign-in failed.')),
                            );
                          }
                        },
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
                          // Replace with actual Register page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAccountScreen(),
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
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
