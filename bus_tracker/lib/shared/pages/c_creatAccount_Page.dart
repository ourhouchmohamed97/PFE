import 'package:bus_tracker/shared/pages/d_login_Page.dart';
import 'package:bus_tracker/shared/pages/f_verifyEmail.dart';
import 'package:bus_tracker/core/services/auth_service.dart';
import 'package:bus_tracker/core/utils/validators/input_validator.dart';
import 'package:bus_tracker/core/widgets/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum UserRole { admin, driver }

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Admin-specific
  final _companyNameController = TextEditingController();
  String? _selectedBusinessType;

  // Driver-specific
  final _adminEmailController = TextEditingController();

  final AuthService _authService = AuthService();
  UserRole? _role;

  final List<String> _businessTypes = [
    'Car Rental Agency',
    'Private School',
    'Transport Company',
    'Delivery Service',
    'Logistics',
    'Other',
  ];

  void _submit() async {
    if (_role == null) {
      _showToast("Please select a role");
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showToast("Passwords do not match");
        return;
      }

      String? error = await _authService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        password: _passwordController.text,
        role: _role == UserRole.admin ? 'admin' : 'driver',
        adminEmail:
            _role == UserRole.driver ? _adminEmailController.text.trim() : null,
        companyName:
            _role == UserRole.admin ? _companyNameController.text.trim() : null,
        businessType: _role == UserRole.admin ? _selectedBusinessType : null,
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
              const Text("Create account",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 🟩 Common Inputs
              CustomTextField(
                labelText: 'Name',
                controller: _nameController,
                validator: FieldValidator.validateNotEmpty,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: FieldValidator.validateEmail,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                controller: _phoneNumberController,
                validator: FieldValidator.validatePhoneNumber,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Password',
                isPassword: true,
                controller: _passwordController,
                validator: FieldValidator.validateSignupPassword,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                labelText: 'Confirm Password',
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (value) => FieldValidator.confirmPasswordValidator(
                    value, _passwordController.text),
              ),
              const SizedBox(height: 30),

              // 🟦 Role Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Role:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    title: const Text('Admin'),
                    leading: Radio<UserRole>(
                      value: UserRole.admin,
                      groupValue: _role,
                      onChanged: (UserRole? value) {
                        setState(() => _role = value);
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Driver'),
                    leading: Radio<UserRole>(
                      value: UserRole.driver,
                      groupValue: _role,
                      onChanged: (UserRole? value) {
                        setState(() => _role = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🟧 Admin-specific fields
              if (_role == UserRole.admin) ...[
                CustomTextField(
                  labelText: 'Company Name',
                  controller: _companyNameController,
                  validator: FieldValidator.validateNotEmpty,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _businessTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedBusinessType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a business type' : null,
                ),
              ],

              // 🟨 Driver-specific fields
              if (_role == UserRole.driver)
                CustomTextField(
                  labelText: "Admin Email",
                  controller: _adminEmailController,
                  validator: FieldValidator.validateEmail,
                ),

              const SizedBox(height: 30),
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
                      style: TextStyle(
                          color: blueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
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
