import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPlayerPage extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;
  final Map<String, dynamic>
      tournament; // Added to receive the full tournament object

  const AddPlayerPage({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournament, // Initialize the new parameter
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

  // Define role options based on sport type
  Map<String, List<String>> sportRoles = {
    'Cricket': ['Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper'],
    'Football': ['Striker', 'Midfielder', 'Defender', 'Goalkeeper'],
    // Add more sports and their roles as needed
  };

  // This list will hold the roles currently displayed in the dropdown
  List<String> currentRoles = [];

  // Removed _selectedImage and _imageFileName as image picker is removed
  String? _base64Image; // To store the base64 string of the profile image

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    // Use the sportType from the full tournament object
    _updateRolesForSport(widget.tournament['sportType'] ?? '');

    // Initialize a dummy base64 image for demonstration purposes
    // In a real application, you would fetch the existing profile image or
    // ensure it's set before this page is accessed if it's mandatory.
    // For this demonstration, we'll assume a dummy image exists if not explicitly provided.
    _base64Image =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="; // A 1x1 transparent PNG base64
  }

  // Function to update roles based on the sport name
  void _updateRolesForSport(String sportName) {
    setState(() {
      print('Updating roles for sport: $sportName'); // Debug print
      // Convert sportName to lowercase for case-insensitive matching
      String normalizedSportName = sportName.toLowerCase();

      if (normalizedSportName.contains('cricket')) {
        currentRoles = sportRoles['Cricket']!;
      } else if (normalizedSportName.contains('football')) {
        currentRoles = sportRoles['Football']!;
      } else if (normalizedSportName.contains('badminton') ||
          normalizedSportName.contains('table tennis') ||
          normalizedSportName.contains('racquet')) {
        currentRoles = []; // No roles for these sports
        selectedRole = ''; // Set role to empty string for racquet sports
      } else {
        currentRoles =
            []; // Default to no roles if sport not explicitly handled
        selectedRole = ''; // Set role to empty string
      }
      print('Current roles after update: $currentRoles'); // Debug print
    });
  }

  // Removed pickImage method

  Future<void> savePlayer() async {
    // Check if a profile image is present
    if (_base64Image == null || _base64Image!.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: primaryBlue, // Dialog background
          title: const Text('Profile Image Required',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Please update your profile image first (e.g., in your profile settings) before adding a player.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(color: accentOrange)),
            ),
          ],
        ),
      );
      return; // Stop execution if no image
    }

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
    request.fields['Role'] = selectedRole ??
        ''; // Send the selected role (will be '' for racquet sports)

    // Add the image file to the request if one has been selected
    // Since image picker is removed, we assume _base64Image is pre-populated or handled elsewhere
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      Uint8List imageBytes = base64Decode(_base64Image!);
      request.files.add(http.MultipartFile.fromBytes(
        'ProfileImage', // This key must exactly match the 'ProfileImage' property name in your C# PlayerDto
        imageBytes,
        filename: 'profile_image.png', // Generic filename since no picker
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
      backgroundColor: primaryBlue, // Set scaffold background
      appBar: AppBar(
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white, // Set foreground (text/icons) to white
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
                  color: Colors.white, // Text color
                ),
              ),
              const SizedBox(height: 24),
              // Removed GestureDetector for image picking
              CircleAvatar(
                radius: 50,
                backgroundColor:
                    lightBlue.withOpacity(0.5), // Light blue with opacity
                backgroundImage:
                    _base64Image != null && _base64Image!.isNotEmpty
                        ? MemoryImage(base64Decode(_base64Image!))
                        : null,
                child: (_base64Image == null || _base64Image!.isEmpty)
                    ? Icon(Icons.person,
                        size: 40, color: accentOrange) // Generic person icon
                    : null,
              ),
              const SizedBox(height: 10),
              const Text("Profile Image (Required)",
                  style: TextStyle(color: Colors.white)), // Text color
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                color:
                    lightBlue.withOpacity(0.7), // Card background with opacity
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
                        isRequired: true, // Gender is always required
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: "Select Handedness",
                        value: selectedHandedness,
                        options: handednessOptions,
                        onChanged: (val) =>
                            setState(() => selectedHandedness = val),
                        isRequired: true, // Handedness is always required
                      ),
                      const SizedBox(height: 16),
                      // Conditionally display the role dropdown
                      if (currentRoles.isNotEmpty)
                        _buildDropdown(
                          label: "Select Role",
                          value: selectedRole,
                          options: currentRoles, // Use the dynamic roles list
                          onChanged: (val) =>
                              setState(() => selectedRole = val),
                          isRequired: true, // Role is required if visible
                        ),
                      if (currentRoles.isNotEmpty) const SizedBox(height: 16),
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
                    savePlayer(); // This will now handle the image check
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
                icon: const Icon(Icons.check, color: Colors.white),
                label:
                    const Text('Submit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange, // Accent orange
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
      style: const TextStyle(color: Colors.white), // Input text color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white70), // Label text color
        filled: true,
        fillColor: primaryBlue.withOpacity(0.3), // Primary blue with opacity
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: accentOrange, width: 2), // Accent orange
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: lightBlue), // Light blue
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
    bool isRequired = true, // Added isRequired parameter, default to true
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.white), // Dropdown text color
      dropdownColor: lightBlue, // Dropdown background color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white70), // Label text color
        filled: true,
        fillColor: primaryBlue.withOpacity(0.3), // Primary blue with opacity
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: accentOrange, width: 2), // Accent orange
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: lightBlue), // Light blue
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: options
          .map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(opt,
                  style:
                      const TextStyle(color: Colors.white)))) // Item text color
          .toList(),
      onChanged: onChanged,
      // Only apply validator if isRequired is true and there are options to select from
      validator: isRequired && options.isNotEmpty
          ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
