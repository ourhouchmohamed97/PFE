import 'package:bus_tracker/screens/d_login_Page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  User? user;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  File? _imageFile;
  String imageUrl = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      var userData = await _firestore.collection('users').doc(user!.uid).get();
      if (userData.exists) {
        setState(() {
          usernameController.text = userData['name'];
          emailController.text = userData['email'];
          phoneController.text = userData['phone'] ?? '';
          imageUrl = userData['profilePic'] ?? "";
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Upload the new image to Firebase Storage
      try {
        setState(() {
          isLoading = true;
        });

        Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user!.uid}.jpg');
        await storageRef.putFile(_imageFile!);

        String uploadedImageUrl = await storageRef.getDownloadURL();

        // Update the user's profile image in Firestore
        await _firestore.collection('users').doc(user!.uid).update({
          'profilePic': uploadedImageUrl,
        });

        // Update the local image URL
        setState(() {
          imageUrl = uploadedImageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile(String password) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Reauthenticate the user if updating the password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user!.reauthenticateWithCredential(credential);

      String? uploadedImageUrl;
      if (_imageFile != null) {
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user!.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        uploadedImageUrl = await storageRef.getDownloadURL();
      }

      // Update Firestore with the new profile details
      await _firestore.collection('users').doc(user!.uid).update({
        'name': usernameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'profilePic': uploadedImageUrl ?? imageUrl,
      });

      // Check if email has changed and update Firebase Authentication
      if (emailController.text != user!.email) {
        await user!.updateEmail(emailController.text);
        // Also update the email in Firestore
        await _firestore.collection('users').doc(user!.uid).update({
          'email': emailController.text,
        });
      }

      // Update password if provided
      if (newPasswordController.text.isNotEmpty &&
          newPasswordController.text == confirmPasswordController.text) {
        await user!.updatePassword(newPasswordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showPasswordDialog() {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Update"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter your current password",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfile(passwordController.text);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

   // Log out function
  Future<void> logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();  // Sign the user out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),  // Navigate to login page
      );
    } catch (e) {
      print('Error logging out: $e');
      // Handle errors (optional)
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(0, 86, 210, 1),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 120,
                    color: const Color.fromRGBO(0, 86, 210, 1),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                            as ImageProvider
                                        : const AssetImage("assets/profile_placeholder.png")),
                              ),
                            ),
                            Positioned(
                              bottom: -5,
                              left: 0,
                              right: 0,
                              child: TextButton(
                                onPressed: _showImageSourceDialog,
                                child: const Text(
                                  "Change Picture",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormField("Username", usernameController),
                              const SizedBox(height: 16),
                              _buildFormField("Email", emailController),
                              const SizedBox(height: 16),
                              _buildFormField("Phone Number", phoneController),
                              const SizedBox(height: 16),
                              _buildPasswordField("New Password", newPasswordController),
                              const SizedBox(height: 16),
                              _buildPasswordField("Confirm Password", confirmPasswordController),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _showPasswordDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromRGBO(0, 86, 210, 1),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Update",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:(){logOut(context);} ,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Log Out",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}