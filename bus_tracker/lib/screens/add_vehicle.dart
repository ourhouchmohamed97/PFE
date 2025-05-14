import 'package:bus_tracker/models/vehicule_model.dart';
import 'package:bus_tracker/utils/validators/matricule_formatter.dart';
import 'package:bus_tracker/utils/validators/matricule_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  String? _selectedBrand;
  String? _selectedType;
  int? _selectedYear;

  // Sample data (replace with real data)
  List<String> brands = ['Toyota', 'Honda', 'Ford', 'Tesla'];
  List<String> types = ['Sedan', 'SUV', 'Hatchback', 'Truck'];

//  function to save car data
  void _saveCar() async {
  if (_formKey.currentState!.validate()) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a car')),
      );
      return;
    }

    // Step 1: Create Firestore doc ref to get vehicleId
    final vehicleRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .doc(); // Auto-generated ID

    final vehicleId = vehicleRef.id;

    // Step 2: Upload image to Supabase
    final imageUrl = await pickAndUploadCarPhoto(vehicleId);

    // Step 3: Create Vehicle model instance
    final vehicle = Vehicle(
      vid: vehicleId,
      ownerId: user.uid,
      brand: _selectedBrand!,
      model: _modelController.text.trim(),
      type: _selectedType!,
      year: _selectedYear!,
      matricule: _matriculeController.text.trim(),
      createdAt: DateTime.now(),
      photosURL: imageUrl != null ? [imageUrl] : [],
    );

    try {
      // Step 4: Save to Firestore
      await vehicleRef.set(vehicle.toMap());

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car saved successfully!')),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving car: ${e.toString()}')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
  }
}

  //function to pick and upload car photo
Future<String?> pickAndUploadCarPhoto(String vehicleId) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return null;

  final imageFile = File(pickedFile.path);
  final fileName = '${vehicleId}_${const Uuid().v4()}.jpg';

  try {
    final supabase = Supabase.instance.client;

    // Upload the image to Supabase storage (will throw if it fails)
    await supabase.storage
        .from('vehicle-images')
        .upload('public/$fileName', imageFile);

    // Get and return the public URL of the uploaded image
    final publicUrl = supabase.storage
        .from('vehicle-images')
        .getPublicUrl('public/$fileName');

    return publicUrl;
  } catch (e) {
    print('Upload to Supabase failed: $e');
    return null;
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Add New Car',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE5E7EB), // Gray background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Text Only
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please fill in the details of your car to get started.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🚗 Basic Information Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Brand Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: const InputDecoration(
                          labelText: 'Car Brand',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        items: brands.map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(brand),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBrand = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a brand' : null,
                      ),

                      const SizedBox(height: 10),

                      // Car Model TextField
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Car Model',
                          hintText: 'e.g., C-Class, Corolla',
                          border: OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a model';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // Car Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Car Type',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        items: types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a type' : null,
                      ),

                      const SizedBox(height: 10),

                      // Year Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        items: List.generate(50, (index) => index + 2000)
                            .map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedYear = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a year' : null,
                      ),
                      const SizedBox(height: 10),

                      // marticule TextField
                      TextFormField(
                        controller: _matriculeController,
                        decoration: const InputDecoration(
                          labelText: 'Matricule',
                          hintText: 'e.g., NN|ب|NNNNN',
                          border: OutlineInputBorder(),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        inputFormatters: [MatriculeInputFormatter()],
                        validator: MatriculeValidator.validate,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🖼️ Car Photos Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Car Photos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                            // ignore: deprecated_member_use
                            color: Colors.grey.shade200.withOpacity(0.3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image, size: 40),
                              const SizedBox(height: 10),
                              const Text('Drag and drop photos here'),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('You must be logged in')),
                                    );
                                    return;
                                  }

                                  final vehicleId = const Uuid().v4();

                                  final imageUrl =
                                      await pickAndUploadCarPhoto(vehicleId);
                                  if (imageUrl != null) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Image uploaded successfully!')),
                                    );

                                    // Optional: Save the URL to Firestore under a temporary or existing vehicle
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('vehicles')
                                        .doc(
                                            vehicleId) // Or an existing vehicle doc ID
                                        .set({
                                      'photos': [imageUrl],
                                      'uploadedAt': DateTime.now(),
                                    }, SetOptions(merge: true));
                                  } else {
                                    
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Image upload failed')),
                                    );
                                  }
                                },
                                child: const Text('Upload Photos'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Action Buttons Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            foregroundColor: Colors.black87,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save Car',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
