import 'package:bus_tracker/core/models/vehicule_model.dart';
import 'package:bus_tracker/core/widgets/assign_driver_dropdown.dart';
import 'package:bus_tracker/rapidapi_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final currentYear = DateTime.now().year;
  List<String> uploadedPhotos = [];
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  String? companyId;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _arabicLetterController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _assignedDriverIdController =
      TextEditingController();

  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedType;
  int? _selectedYear;

  List<String> types = ['Sedan', 'SUV', 'Hatchback', 'Truck'];

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    _numberController.dispose();
    _arabicLetterController.dispose();
    _provinceController.dispose();
    _assignedDriverIdController.dispose();
    super.dispose();
  }

  // Save car data
  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to add a car')),
        );
      }
      return;
    }

    final vehicleRef = FirebaseFirestore.instance
        .collection('vehicles') // 🔁 Now saving in top-level
        .doc();

    final vehicleId = vehicleRef.id;

    final assignedDriverId = _assignedDriverIdController.text.trim();
    if (_selectedBrand == null ||
        _selectedType == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select brand, type, and year')),
      );
      return;
    }

    final vehicle = Vehicle(
      vid: vehicleId,
      companyId: companyId!,
      brand: _selectedBrand!,
      model: _modelController.text.trim(),
      type: _selectedType!,
      year: _selectedYear!,
      matricule: fullMatricule,
      createdAt: DateTime.now(),
      photosURL: uploadedPhotos,
      assignedDriverId: assignedDriverId.isNotEmpty ? assignedDriverId : null,
      location: {
        'latitude': 0.0,
        'longitude': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      await vehicleRef.set(vehicle.toMap()); // Save to top-level
      if (!mounted) return;

      showCustomSnackBar(context, 'Car saved successfully!');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Error saving car: $e', isError: true);
    }
  }

  void showCustomSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final color = isError ? Colors.red[600] : Colors.green[600];
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String get fullMatricule =>
      '${_numberController.text}-${_arabicLetterController.text}-${_provinceController.text}';
  // Pick and upload photo to Firebase Storage (optional)
  Future<String?> pickAndUploadCarPhoto(String vehicleId) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final Uint8List fileBytes = await pickedFile.readAsBytes();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName = '${vehicleId}_${const Uuid().v4()}.jpg';
      final filePath = 'vehicle-images/${user.uid}/$fileName';

      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      await storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return filePath; // ⬅️ Return the Storage path, not the URL
    } catch (e) {
      return null;
    }
  }
  // Fetch car brand suggestions from API



  Future<void> loadCompanyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User is not logged in — show message and maybe redirect to login page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to add a car.')),
        );
      }
      return;
    }

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin data not found.')),
          );
        }
        return;
      }

      final data = adminDoc.data();
      if (data == null || data['companyId'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company ID not found.')),
          );
        }
        return;
      }

      setState(() {
        companyId = data['companyId'] as String;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load company ID: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadCompanyId();
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
            icon: const Icon(Icons.arrow_back_ios,
                color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Please fill in the details of your car to get started.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Basic Information Section
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

                          // Brand with TypeAhead
                          TypeAheadFormField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _brandController,
                              decoration: InputDecoration(
                                label: RichText(
                                  text: TextSpan(
                                    text: 'Car Brand ',
                                    style: TextStyle(
                                      color:
                                          Colors.grey[700], // Match label style
                                      fontSize: 16,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBrand = null;
                                  _modelController.clear();
                                });
                              },
                            ),
                            suggestionsCallback: (pattern) async {
                              return await fetchBrandSuggestions(pattern);
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(title: Text(suggestion));
                            },
                            onSuggestionSelected: (suggestion) {
                              _brandController.text = suggestion;
                              setState(() {
                                _selectedBrand = suggestion;
                              });
                            },
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Please enter a brand'
                                    : null,
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('No brands found'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Model TextField
                          TypeAheadFormField<String>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _modelController,
                              decoration: InputDecoration(
                                label: RichText(
                                  text: TextSpan(
                                    text: 'Car Model ',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                                hintText: 'e.g., C-Class, Corolla',
                                border: const OutlineInputBorder(),
                                errorBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
                                ),
                              ),
                            ),
                            suggestionsCallback: (pattern) async {
                              if (_selectedBrand == null ||
                                  _selectedBrand!.isEmpty) {
                                return [];
                              }
                              return await fetchModelSuggestions(
                                  _selectedBrand!, pattern);
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(title: Text(suggestion));
                            },
                            onSuggestionSelected: (suggestion) {
                              _modelController.text = suggestion;
                              setState(() {
                                _selectedModel = suggestion;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a model';
                              }
                              return null;
                            },
                            noItemsFoundBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('No models found'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              label: RichText(
                                text: const TextSpan(
                                  text: 'Car Type ',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              errorBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            items: types
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
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
                            decoration: InputDecoration(
                              label: RichText(
                                text: const TextSpan(
                                  text: 'Year ',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              errorBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            items: List.generate(currentYear - 2000 + 1,
                                    (index) => 2000 + index)
                                .map(
                                  (year) => DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (int? value) {
                              setState(() {
                                _selectedYear = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Please select a year' : null,
                          ),

                          const SizedBox(height: 8),

                          // Matricule TextField
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Stack(
                              children: [
                                // The box around inputs
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      // Number
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: _numberController,
                                          decoration: const InputDecoration(
                                            labelText: 'Number',
                                            hintText: '12345',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(5),
                                          ],
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Required'
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Arabic Letter
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _arabicLetterController,
                                          decoration: const InputDecoration(
                                            labelText: 'Letter',
                                            hintText: 'ب',
                                            border: OutlineInputBorder(),
                                          ),
                                          textDirection: TextDirection.rtl,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[\u0621-\u064A]')),
                                            LengthLimitingTextInputFormatter(1),
                                          ],
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Required'
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Province
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _provinceController,
                                          decoration: const InputDecoration(
                                            labelText: 'Province',
                                            hintText: '1',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Required'
                                                  : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Updated "License Plate *" label
                                Positioned(
                                  left: 16,
                                  top: 0,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: RichText(
                                      text: const TextSpan(
                                        text: 'License Plate ',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54),
                                        children: [
                                          TextSpan(
                                            text: '*',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          (companyId == null || companyId!.isEmpty)
                              ? const Center(child: CircularProgressIndicator())
                              : AssignDriverDropdown(
                                  companyId: companyId!,
                                  controller: _assignedDriverIdController,
                                ),
                          const SizedBox(height: 10),

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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () async {},
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(12),
                                      // ignore: deprecated_member_use
                                      color: Colors.grey.shade200
                                          .withAlpha((0.3 * 255).round()),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.image, size: 40),
                                        const SizedBox(height: 10),
                                        const Text('Drag and drop photos here'),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user == null) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'You must be logged in')),
                                              );
                                              return;
                                            }

                                            // Generate a temporary vehicleId if not already assigned
                                            final vehicleId = const Uuid().v4();

                                            // Upload and get the image storage path (not URL)
                                            final imageStoragePath =
                                                await pickAndUploadCarPhoto(
                                                    vehicleId);

                                            if (!context.mounted) return;

                                            if (imageStoragePath != null) {
                                              setState(() {
                                                uploadedPhotos.add(
                                                    imageStoragePath); // Store storage path (not URL)
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Image uploaded successfully!')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Image upload failed')),
                                              );
                                            }
                                          },
                                          child: const Text('Upload Photo'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      'Save Car',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
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
            )));
  }
}
