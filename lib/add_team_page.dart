import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddTeamPage extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const AddTeamPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<AddTeamPage> createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController coachController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  File? _profileImageFile;
  String? _base64Image;
  String? _imageFileName;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageFile = File(image.path);
        _base64Image = base64Encode(bytes);
        _imageFileName = image.name;
        print('Image selected path: ${image.path}');
        print('Base64 image length: ${_base64Image?.length ?? 0}');
        print('Image filename: $_imageFileName');
      });
    } else {
      print('No image selected.');
    }
  }

  // --- API Integration Logic ---
  Future<void> _submitTeam() async {
    // Check if the form is valid before proceeding
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop if validation fails
    }

    // Replace with your actual API endpoint URL
    const String apiUrl = 'https://sportsdecor.somee.com/api/Team/SaveTeam';
    final url = Uri.parse(apiUrl);

    // Prepare the team data as a JSON object, matching the TeamDto structure
    final teamData = {
      // The OwnerId is a required field. You might need to get this from user authentication.
      // For this example, we use a placeholder.
      "ownerId": 1,
      "tournamentId": widget.tournamentId,
      "teamName": teamNameController.text.trim(),
      "ownerName": ownerController.text.trim(),
      "coachName": coachController.text.trim(),
      "homeCity": cityController.text.trim(),
      // Send the base64 encoded image string as LogoUrl
      "logoUrl": _base64Image,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Set Content-Type for JSON
        },
        body: jsonEncode(teamData), // Encode the map to a JSON string
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(responseData['message'] ?? "Team Added Successfully")),
          );
          // Navigate back after a successful save
          Navigator.pop(context);
        } else {
          // Handle API-specific errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ?? "Failed to add team")),
          );
        }
      } else {
        // Handle HTTP status code errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error saving team. Status: ${response.statusCode}, Body: ${response.body}")),
        );
      }
    } catch (e) {
      // Handle network or other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to the server: $e")),
      );
      print("Error during API call: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('Add Team', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue,
        foregroundColor: Colors.white,
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: lightBlue.withOpacity(0.5),
                  backgroundImage: _base64Image != null
                      ? MemoryImage(base64Decode(_base64Image!))
                      : null,
                  child: _base64Image == null
                      ? const Icon(Icons.camera_alt,
                          size: 36, color: accentOrange)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Tap to select team logo",
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: lightBlue.withOpacity(0.7),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField('Team Name',
                          controller: teamNameController, isRequired: true),
                      const SizedBox(height: 16),
                      _buildTextField('Team Owner',
                          controller: ownerController, isRequired: true),
                      const SizedBox(height: 16),
                      _buildTextField('Coach Name',
                          controller: coachController),
                      const SizedBox(height: 16),
                      _buildTextField('Home City', controller: cityController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _submitTeam, // Call the API integration method
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Save Team',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
        filled: true,
        fillColor: primaryBlue.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: accentOrange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: lightBlue),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: isRequired
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
