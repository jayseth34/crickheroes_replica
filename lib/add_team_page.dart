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

  File?
      _profileImageFile; // Stores the File object from image_picker (not directly used for web upload)
  String?
      _base64Image; // To store the base64 encoded image for display and upload
  String?
      _imageFileName; // To store the original filename (optional for JSON payload)

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageFile = File(image
            .path); // Keep the File object if needed for other platform-specific ops
        _base64Image = base64Encode(
            bytes); // Convert to base64 for display and sending in JSON
        _imageFileName =
            image.name; // Get the original filename (optional for JSON)
        print('Image selected path: ${image.path}');
        print('Base64 image length: ${_base64Image?.length ?? 0}');
        print('Image filename: $_imageFileName');
      });
    } else {
      print('No image selected.');
    }
  }

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

    final url =
        Uri.parse('https://www.sportsdecor.somee.com/api/Team/SaveTeam');

    // Prepare the team data as a JSON object
    final teamData = {
      "ownerId": 3, // Replace with actual owner ID or make dynamic
      "tournamentId": widget.tournamentId,
      "teamName": teamNameController.text.trim(),
      "ownerName": ownerController.text.trim(),
      "coachName": coachController.text.trim(),
      "homeCity": cityController.text.trim(),
      // Send the base64 encoded image string.
      // The key 'profileImageBase64' should match a string property in your C# TeamDto.
      "profileImageBase64":
          _base64Image ?? '', // Send empty string if no image selected
      // You might also want to send the filename if your backend needs it
      "profileImageFileName": _imageFileName ?? '',
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json', // Set Content-Type to application/json
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
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ?? "Failed to add team")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect: $e")),
      );
      print("Error during API call: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Team'),
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
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  // Use MemoryImage from base64 string for display
                  backgroundImage: _base64Image != null
                      ? MemoryImage(base64Decode(_base64Image!))
                      : null,
                  child:
                      _base64Image == null // Check base64Image for icon display
                          ? const Icon(Icons.camera_alt,
                              size: 36, color: Colors.black45)
                          : null,
                ),
              ),
              const SizedBox(height: 10), // Reduced space
              const Text("Tap to select team logo"), // Added text for clarity
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitTeam();
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
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
}
