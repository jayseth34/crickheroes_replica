import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package

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
  final TextEditingController mobileNumberController =
      TextEditingController(); // New controller for mobile number

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
    _loadMobileNumber(); // Load the mobile number on startup

    // Initialize a dummy base64 image for demonstration purposes
    _base64Image =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="; // A 1x1 transparent PNG base64
  }

  @override
  void dispose() {
    nameController.dispose();
    villageController.dispose();
    ageController.dispose();
    addressController.dispose();
    mobileNumberController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Function to load the mobile number from shared preferences
  void _loadMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMobileNumber = prefs.getString('mobileNumber');
    if (storedMobileNumber != null) {
      setState(() {
        mobileNumberController.text = storedMobileNumber;
      });
    }
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

  Future<void> savePlayer() async {
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

    final url =
        Uri.parse("https://sportsdecor.somee.com/api/Player/SavePlayer");

    var request = http.MultipartRequest('POST', url);

    request.fields['TournamentId'] = widget.tournamentId.toString();
    request.fields['Name'] = nameController.text.trim();
    request.fields['Village'] = villageController.text.trim();
    request.fields['Age'] =
        (int.tryParse(ageController.text.trim()) ?? 0).toString();
    request.fields['Address'] = addressController.text.trim();
    request.fields['Gender'] = selectedGender ?? '';
    request.fields['Handedness'] = selectedHandedness ?? '';
    request.fields['Role'] = selectedRole ?? '';
    request.fields['MobNo'] =
        mobileNumberController.text; // Use the new controller's value

    if (_base64Image != null && _base64Image!.isNotEmpty) {
      Uint8List imageBytes = base64Decode(_base64Image!);
      request.files.add(http.MultipartFile.fromBytes(
        'ProfileImage',
        imageBytes,
        filename: 'profile_image.png',
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    responseData['message'] ?? "Player added successfully")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(responseData['message'] ?? "Failed to add player")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to add player. Status Code: ${response.statusCode}")),
        );
        print("Response body: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
              CircleAvatar(
                radius: 50,
                backgroundColor:
                    lightBlue.withOpacity(0.5), // Light blue with opacity
                backgroundImage:
                    _base64Image != null && _base64Image!.isNotEmpty
                        ? MemoryImage(base64Decode(_base64Image!))
                        : null,
                child: _base64Image == null || _base64Image!.isEmpty
                    ? Icon(Icons.person,
                        size: 50, color: Colors.white.withOpacity(0.8))
                    : null,
              ),
              const SizedBox(height: 24),
              _buildTextField(nameController, 'Player Name'),
              const SizedBox(height: 16),
              // Mobile Number Input Field
              _buildTextField(
                mobileNumberController,
                'Mobile Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField<String>(
                label: 'Gender',
                value: selectedGender,
                options: genders,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGender = newValue;
                  });
                },
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(villageController, 'Village'),
              const SizedBox(height: 16),
              _buildTextField(ageController, 'Age',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(addressController, 'Address'),
              const SizedBox(height: 16),
              // Display role dropdown only if there are roles for the sport
              if (currentRoles.isNotEmpty)
                _buildDropdownField<String>(
                  label: 'Role',
                  value: selectedRole,
                  options: currentRoles,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue;
                    });
                  },
                  isRequired: false, // Role is not required
                ),
              if (currentRoles.isNotEmpty) const SizedBox(height: 16),
              _buildDropdownField<String>(
                label: 'Handedness',
                value: selectedHandedness,
                options: handednessOptions,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedHandedness = newValue;
                  });
                },
                isRequired: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      savePlayer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Save Player',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for a consistent TextFormField design
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white), // Input text color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w500, color: Colors.white70), // Label color
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
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
    );
  }

  // Helper method for a consistent DropdownButtonFormField design
  Widget _buildDropdownField<T>({
    required String label,
    T? value,
    required List<T> options,
    required void Function(T?) onChanged,
    required bool isRequired,
  }) {
    return DropdownButtonFormField<String>(
      value: value as String?,
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
              value: opt.toString(),
              child: Text(opt.toString(),
                  style:
                      const TextStyle(color: Colors.white)))) // Item text color
          .toList(),
      onChanged: onChanged as void Function(String?)?,
      // Only apply validator if isRequired is true and there are options to select from
      validator: isRequired && options.isNotEmpty
          ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
