import 'package:bus_tracker/driver/driver_home.dart';
import 'package:bus_tracker/driver/permission_waiting.dart';
import 'package:bus_tracker/shared/pages/c_creatAccount_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_tracker/shared/pages/e_forgotPassword_Page.dart';
import 'package:bus_tracker/admin/screens/admin_home.dart';
import 'package:bus_tracker/core/services/google_auth.dart';
import 'package:bus_tracker/core/utils/validators/input_validator.dart';
import 'package:bus_tracker/core/widgets/constants.dart';

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

      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        // 🔽 Get role from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');

          Widget targetPage;

          if (role == 'admin') {
            targetPage = const AdminHomePage();
          } else if (role == 'driver') {
            final status = userDoc.get('status') ?? 'pending';
            if (status == 'approved') {
              targetPage = const DriverHomePage();
            } else {
              targetPage = DriverWaitingForPermissionPage();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Unknown role.")),
            );
            return;
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => targetPage),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User data not found.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before logging in.'),
          ),
        );
        await user?.sendEmailVerification();
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
                              // Fetch role from Firestore
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();
                              if (userDoc.exists) {
                                String role = userDoc.get('role');
                                Widget targetPage;
                                if (role == 'admin') {
                                  targetPage = const AdminHomePage();
                                } else if (role == 'driver') {
                                  final status =
                                      userDoc.get('status') ?? 'pending';
                                  if (status == 'approved') {
                                    targetPage = const DriverHomePage();
                                  } else {
                                    targetPage =
                                        DriverWaitingForPermissionPage();
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Unknown role.")));
                                  return;
                                }
                                if (mounted) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => targetPage));
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("User data not found.")));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please verify your email.')));
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Google sign-in failed.')));
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
