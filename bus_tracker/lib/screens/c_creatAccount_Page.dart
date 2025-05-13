import 'package:bus_tracker/screens/d_login_Page.dart';
import 'package:bus_tracker/screens/f_verify.dart';
import 'package:bus_tracker/services/auth_service.dart';
import 'package:bus_tracker/utils/validators/input_validator.dart';
import 'package:bus_tracker/widgets/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showToast("Passwords do not match");
        return;
      }

      String? error = await _authService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (error == null) {
        _showToast("Verification email sent. Please check your email.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationPage(email: _emailController.text),
          ),
        );
      } else {
        _showToast("Error: $error");
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'CarTrack'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Create account", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              CustomTextField(
                labelText: 'Name',
                controller: _nameController,
                validator: FieldValidator.validateNotEmpty,
              ),
              const SizedBox(height: 30),
              CustomTextField(
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: FieldValidator.validateEmail,
              ),
              const SizedBox(height: 30),
              CustomTextField(
                labelText: 'Password',
                isPassword: true,
                controller: _passwordController,
                validator: FieldValidator.validateSignupPassword,
              ),
              const SizedBox(height: 30),
              CustomTextField(
                labelText: 'Confirm Password',
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (value) => FieldValidator.confirmPasswordValidator(value, _passwordController.text),
              ),
              const SizedBox(height: 40),
               Mybutton(text: "CREATE ACCOUNT", onTap: _submit),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text(
                      'Sign in',
                          style: TextStyle(color: Colors.white),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}