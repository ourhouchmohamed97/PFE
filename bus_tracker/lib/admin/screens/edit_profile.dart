import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bus_tracker/shared/pages/d_login_Page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPasswordFields = false;
  File? _imageFile;
  String? imageUrl;

  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          usernameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          setState(() {
            imageUrl = data['profilePic'];
          });
        }
      } catch (e) {
        print("User data error: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    try {
      setState(() => _isLoading = true);

      String? uploadedUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_pictures/${user!.uid}.jpg');
        await ref.putFile(_imageFile!);
        uploadedUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(user!.uid).update({
        'name': usernameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        if (uploadedUrl != null) 'profilePic': uploadedUrl,
      });

      if (emailController.text != user!.email) {
        await user!.updateEmail(emailController.text);
      }

      if (_showPasswordFields &&
          newPasswordController.text.isNotEmpty &&
          newPasswordController.text == confirmPasswordController.text) {
        await user!.updatePassword(newPasswordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _promptCurrentPassword() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Identity'),
        content: TextField(
          controller: currentPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPasswordController.text,
                );
                await user!.reauthenticateWithCredential(credential);
                setState(() => _showPasswordFields = true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect password")),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  Widget _formField(String label, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : const AssetImage("assets/images/profile.png"))
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _formField("Username", usernameController),
                  const SizedBox(height: 16),
                  _formField("Email", emailController),
                  const SizedBox(height: 16),
                  _formField("Phone", phoneController),
                  const SizedBox(height: 16),
                  if (_showPasswordFields) ...[
                    _formField("New Password", newPasswordController, obscure: true),
                    const SizedBox(height: 16),
                    _formField("Confirm Password", confirmPasswordController, obscure: true),
                    const SizedBox(height: 16),
                  ] else
                    Center(
                      child: TextButton(
                        onPressed: _promptCurrentPassword,
                        child: const Text("Change Password", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateProfile,
                     child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                   ElevatedButton(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Log Out"),
                  ),
                ],
              ),
            ),
    );
  }
}
