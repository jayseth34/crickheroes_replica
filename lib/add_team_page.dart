import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Added this import to use jsonDecode
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

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
  final TextEditingController mobileNumberController =
      TextEditingController(); // New controller for mobile number

  // State variables for handling image selection
  // These are updated based on the platform (web vs. native)
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  String? _imagePickedFileName;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read bytes directly
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImageBytes = bytes;
            _profileImageFile = null; // Clear native File if using bytes
            _imagePickedFileName = pickedFile.name;
          });
        } else {
          // For native platforms, use a File
          setState(() {
            _profileImageFile = File(pickedFile.path);
            _profileImageBytes = null; // Clear bytes if using native File
            _imagePickedFileName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      // In case of any errors during image picking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to submit the team data with the image as a multipart request
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
    const String apiUrl = 'https://localhost:7116/api/Team/SaveTeam';
    final url = Uri.parse(apiUrl);

    try {
      // Use http.MultipartRequest for form-data with files
      var request = http.MultipartRequest('POST', url);

      // Add text fields from your C# TeamDto
      // The `TeamId` is nullable, so we check if it's needed
      // "TeamId": "0", // Assuming 0 for new teams
      // "OwnerId": "1", // Placeholder, you should get this from authentication
      request.fields['TournamentId'] = widget.tournamentId.toString();
      request.fields['TeamName'] = teamNameController.text.trim();
      request.fields['OwnerName'] = ownerController.text.trim();
      request.fields['CoachName'] = coachController.text.trim();
      request.fields['HomeCity'] = cityController.text.trim();
      request.fields['MobileNumber'] =
          mobileNumberController.text.trim(); // Add mobile number as a string
      // Send an empty string for LogoUrl as requested
      request.fields['LogoUrl'] = "";

      // Add the image file to the multipart request
      // Use the 'ProfileImage' field name to match your C# `TeamDto`
      if (_profileImageBytes != null) {
        // For web, use the bytes directly
        request.files.add(http.MultipartFile.fromBytes(
          'ProfileImage',
          _profileImageBytes!,
          filename: _imagePickedFileName,
        ));
      } else if (_profileImageFile != null) {
        // For native, use the file path
        request.files.add(await http.MultipartFile.fromPath(
          'ProfileImage',
          _profileImageFile!.path,
          filename: _imagePickedFileName,
        ));
      }

      // Send the request and handle the response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle the response based on the status code
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(responseData['message'] ?? "Team Added Successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back after a successful save
          Navigator.pop(context);
        } else {
          // Handle API-specific errors with a 200 status code but 'success: false'
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? "Failed to add team"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 400) {
        // Handle 400 Bad Request and extract the message from the body
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                "Bad request. Please check your data."),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Handle other HTTP status code errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Error saving team. Status: ${response.statusCode}, Body: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle network or other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect to the server: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper widget to build text fields with consistent styling
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

  @override
  Widget build(BuildContext context) {
    // Determine the image provider based on platform and selected image
    ImageProvider<Object>? avatarImageProvider;
    if (kIsWeb && _profileImageBytes != null) {
      avatarImageProvider = MemoryImage(_profileImageBytes!);
    } else if (!kIsWeb && _profileImageFile != null) {
      avatarImageProvider = FileImage(_profileImageFile!);
    }

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: lightBlue.withOpacity(0.5),
                      backgroundImage: avatarImageProvider,
                      child: (avatarImageProvider == null)
                          ? const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.white70)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _imagePickedFileName ?? "Tap to add Team Logo",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('Team Name*',
                  controller: teamNameController, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField('Owner Name', controller: ownerController),
              const SizedBox(height: 16),
              _buildTextField('Coach Name', controller: coachController),
              const SizedBox(height: 16),
              _buildTextField('Home City', controller: cityController),
              const SizedBox(height: 16),
              _buildTextField('Mobile Number*',
                  controller: mobileNumberController, isRequired: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitTeam,
                child: Text('Add Team'),
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
}
