import 'package:bus_tracker/core/models/vehicule_model.dart';
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

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _arabicLetterController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();

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

    // Create Firestore doc ref to get vehicleId
    final vehicleRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .doc();

    final vehicleId = vehicleRef.id;

    // Upload image to Supabase
    final imageUrl = await pickAndUploadCarPhoto(vehicleId);

    // Create Vehicle instance
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
      await vehicleRef.set(vehicle.toMap());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving car: $e')),
      );
    }
  }

  String get fullMatricule =>
      '${_numberController.text}-${_arabicLetterController.text}-${_provinceController.text}';

  // Pick and upload photo to Supabase Storage
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

      // Just await the upload — no need to store the result if unused
      await storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
  // Fetch car brand suggestions from API

  Future<List<String>> fetchBrandSuggestions(String query) async {
    final uri = Uri.https(
      'car-api2.p.rapidapi.com',
      '/api/makes',
      {
        'sort': 'id',
        'direction': 'asc',
        'verbose': 'yes',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-RapidAPI-Key':
              '2cdc31e33fmsh484d3a30022930ap1bde81jsn9d05d1360cc1', 
          'X-RapidAPI-Host': 'car-api2.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming the API returns a list of brands in a field called 'data'
        if (data is Map && data['data'] is List) {
          final List<dynamic> brands = data['data'];
          // Filter by query and return brand names as strings
          return brands
              .map((brand) => brand['name']?.toString() ?? '')
              .where((name) => name.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchModelSuggestions(String brand, String query) async {
    final uri = Uri.https(
      'car-api2.p.rapidapi.com',
      '/api/models',
      {
        'make': brand.toLowerCase(),
        'sort': 'id',
        'direction': 'asc',
        'year': '2020',
        'verbose': 'yes',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-RapidAPI-Key':
              '2cdc31e33fmsh484d3a30022930ap1bde81jsn9d05d1360cc1', // replace with your actual key
          'X-RapidAPI-Host': 'car-api2.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> models = decoded['data'];
        return models
            .map((model) => model['name'].toString())
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
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
                              decoration: const InputDecoration(
                                labelText: 'Car Brand',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBrand = value;
                                  // When brand changes manually, you may want to clear selected model & controller
                                  _modelController.clear();
                                  _selectedBrand = null;
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
                                // Clear the model field when a new brand is selected
                                _modelController.clear();
                                _selectedBrand = null;
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
                              decoration: const InputDecoration(
                                labelText: 'Car Model',
                                hintText: 'e.g., C-Class, Corolla',
                                border: OutlineInputBorder(),
                                errorBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 2),
                                ),
                              ),
                            ),
                            suggestionsCallback: (pattern) async {
                              if (_selectedBrand == null ||
                                  _selectedBrand!.isEmpty) {
                                // No brand selected, no suggestions
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
                            decoration: const InputDecoration(
                              labelText: 'Car Type',
                              labelStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
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
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              labelStyle: TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(),
                              errorBorder: OutlineInputBorder(
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

                          const SizedBox(height: 10),

                          // Matricule TextField
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // This is the "Matricule" legend text
                                Positioned(
                                  left: 16,
                                  top: 0,
                                  child: Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: const Text(
                                      'license plate',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

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

                                            final vehicleId = const Uuid().v4();
                                            final imageUrl =
                                                await pickAndUploadCarPhoto(
                                                    vehicleId);

                                            if (!context.mounted) return;

                                            if (imageUrl != null) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Image uploaded successfully!')),
                                              );

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .collection('vehicles')
                                                  .doc(vehicleId)
                                                  .set({
                                                'photos': [imageUrl],
                                                'uploadedAt': DateTime.now(),
                                              }, SetOptions(merge: true));
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
