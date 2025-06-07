import 'dart:convert';
import 'dart:io';

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
  final List<String> roles = ['Batsman', 'Bowler', 'All-Rounder', 'Goalkeeper'];

  File? _selectedImage;
  String? _base64Image;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> savePlayer() async {
    final url =
        Uri.parse("https://sportsdecor.somee.com/api/Player/SavePlayer");

    final Map<String, dynamic> playerData = {
      "tournamentId": widget.tournamentId,
      "name": nameController.text.trim(),
      "village": villageController.text.trim(),
      "age": int.tryParse(ageController.text.trim()) ?? 0,
      "address": addressController.text.trim(),
      "gender": selectedGender,
      "handedness": selectedHandedness,
      "role": selectedRole,
      "profileImage": _base64Image ?? "",
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(playerData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Player added successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add player")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
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
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
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
                  if (_formKey.currentState!.validate()) {
                    savePlayer();
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
