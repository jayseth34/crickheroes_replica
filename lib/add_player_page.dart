import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPlayerPage extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const AddPlayerPage({
    required this.tournamentId,
    required this.tournamentName,
    Key? key,
  }) : super(key: key);

  @override
  State<AddPlayerPage> createState() => _AddPlayerPageState();
}

class _AddPlayerPageState extends State<AddPlayerPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? selectedGender;
  String? selectedHandedness;
  String? selectedRole;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> handednessOptions = ['Right-handed', 'Left-handed'];
  final List<String> roles = ['Batsman', 'Bowler', 'All-Rounder'];

  File? _selectedImage;
  String? _base64Image;
  String? _imageFileName; // To store the filename

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64Encode(bytes);
        _imageFileName = image.name; // Store the original filename
        // Debug print to confirm image path and base64 string
        print('Image selected path: ${image.path}');
        print('Base64 image length: ${_base64Image?.length ?? 0}');
        print('Image filename: $_imageFileName');
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> savePlayer() async {
    // Define the API endpoint URL
    final url =
        Uri.parse("https://sportsdecor.somee.com/api/Player/SavePlayer");

    // Create a MultipartRequest for sending form data, including files
    var request = http.MultipartRequest('POST', url);

    // Add text fields to the request. The field names must match the properties in your C# PlayerDto.
    request.fields['TournamentId'] = widget.tournamentId.toString();
    request.fields['Name'] = nameController.text.trim();
    request.fields['Village'] = villageController.text.trim();
    // Convert age to string, handling potential parsing errors
    request.fields['Age'] =
        (int.tryParse(ageController.text.trim()) ?? 0).toString();
    request.fields['Address'] = addressController.text.trim();
    // Provide default empty strings if dropdown values are null to avoid issues with non-nullable C# properties
    request.fields['Gender'] = selectedGender ?? '';
    request.fields['Handedness'] = selectedHandedness ?? '';
    request.fields['Role'] = selectedRole ?? '';
    // If you need to include TeamId, uncomment and set its value here.
    // request.fields['TeamId'] = 'null'; // Or the actual team ID if selected

    // Add the image file to the request if one has been selected
    if (_base64Image != null && _imageFileName != null) {
      // Decode the base64 string back to bytes
      Uint8List imageBytes = base64Decode(_base64Image!);
      request.files.add(http.MultipartFile.fromBytes(
        'ProfileImage', // This key must exactly match the 'ProfileImage' property name in your C# PlayerDto
        imageBytes,
        filename: _imageFileName, // Use the stored original filename
      ));
    }

    try {
      // Send the request and await the streamed response
      final streamedResponse = await request.send();
      // Convert the streamed response to a regular HTTP response
      final response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful (status code 200 OK)
      if (response.statusCode == 200) {
        // Parse the JSON response body
        final responseData = jsonDecode(response.body);
        // Check the 'success' flag from the API response
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    responseData['message'] ?? "Player added successfully")),
          );
          // Navigate back after successful player addition
          Navigator.pop(context);
        } else {
          // Show error message from API if available, otherwise a generic one
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(responseData['message'] ?? "Failed to add player")),
          );
        }
      } else {
        // Handle non-200 status codes (e.g., server errors, validation errors)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to add player. Status Code: ${response.statusCode}")),
        );
        // Print the response body for debugging purposes
        print("Response body: ${response.body}");
      }
    } catch (e) {
      // Catch any exceptions during the API call (e.g., network errors)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      // Print the error for debugging
      print("Error during API call: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Player'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Tournament: ${widget.tournamentName}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  // Changed this line to use MemoryImage from base64 string
                  backgroundImage: _base64Image != null
                      ? MemoryImage(base64Decode(_base64Image!))
                      : null,
                  child: _selectedImage == null
                      ? Icon(Icons.camera_alt, size: 40, color: Colors.black45)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Tap to select profile image"),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField('Player Name',
                          controller: nameController, isRequired: true),
                      const SizedBox(height: 16),
                      _buildTextField('Village', controller: villageController),
                      const SizedBox(height: 16),
                      _buildTextField('Age',
                          controller: ageController, isNumber: true),
                      const SizedBox(height: 16),
                      _buildTextField('Address', controller: addressController),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        label: "Select Gender",
                        value: selectedGender,
                        options: genders,
                        onChanged: (val) =>
                            setState(() => selectedGender = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Select Handedness",
                        value: selectedHandedness,
                        options: handednessOptions,
                        onChanged: (val) =>
                            setState(() => selectedHandedness = val),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Select Role",
                        value: selectedRole,
                        options: roles,
                        onChanged: (val) => setState(() => selectedRole = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Validate the form before attempting to save the player
                  final isValid = _formKey.currentState!.validate();
                  print('Form validation result: $isValid'); // Debug print
                  if (isValid) {
                    savePlayer();
                  } else {
                    // Show a SnackBar if validation fails
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Please fill in all required fields."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build a TextFormField
  Widget _buildTextField(String label,
      {required TextEditingController controller,
      bool isRequired = false,
      bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  // Helper widget to build a DropdownButtonFormField
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: options
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}
