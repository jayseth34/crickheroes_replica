import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Import http package

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>(); // Added for form validation

  // Initial user profile data (default values if no data is fetched)
  Map<String, dynamic> _userProfile = {
    'name': 'Guest Player',
    'photoBase64': null,
    'bio': 'Tell us about yourself!',
    'favoriteSport': null, // Set to null initially for dropdown
    'location': '',
    'age': null, // Set to null for initial empty state
    'gender': null, // Set to null for initial empty state
    'email': '',
    'phone': '',
    'playingStyle': '',
    'sports': [], // Empty initially
    'tournaments': [], // Empty initially
    'achievements': [], // Empty initially
  };

  bool _isEditing = false; // To toggle edit mode
  bool _isLoading = true; // To show loading indicator while fetching data

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _playingStyleController = TextEditingController();
  final TextEditingController _newSportController = TextEditingController();
  final TextEditingController _newAchievementController =
      TextEditingController();

  String? _selectedFavoriteSport;
  String? _selectedGender;
  File? _pickedImageFile;
  String? _pickedImageBase64;
  String? _pickedImageFileName;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  // Example list of all possible sports for favorite sport dropdown
  final List<String> _allSportsOptions = [
    'Cricket',
    'Football',
    'Badminton',
    'Table Tennis',
    'Pickleball',
    'Basketball',
    'Tennis'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileDetails(); // Fetch profile details on page load
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _playingStyleController.dispose();
    _newSportController.dispose();
    _newAchievementController.dispose();
    super.dispose();
  }

  // Method to populate controllers and state from _userProfile
  void _populateFields() {
    _nameController.text = _userProfile['name'] ?? '';
    _bioController.text = _userProfile['bio'] ?? '';
    _locationController.text = _userProfile['location'] ?? '';
    _ageController.text = (_userProfile['age'] ?? '').toString();
    _emailController.text = _userProfile['email'] ?? '';
    _phoneController.text = _userProfile['phone'] ?? '';
    _playingStyleController.text = _userProfile['playingStyle'] ?? '';
    _selectedFavoriteSport = _userProfile['favoriteSport'];
    _selectedGender = _userProfile['gender'];
    _pickedImageBase64 = _userProfile['photoBase64'];
  }

  Future<void> _fetchProfileDetails() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    // Simulate API call to get player details
    // Replace with your actual API endpoint for GET request
    const String getApiUrl =
        'https://your-api-url.com/api/user/getprofiledetails';
    // For demonstration, we'll simulate a response
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // Simulated API response (replace with actual http.get call)
    final Map<String, dynamic>? fetchedData = {
      'name': 'Jane Smith',
      'photoBase64': null, // Or provide a base64 string for a default image
      'bio': 'Avid footballer and tennis player.',
      'favoriteSport': 'Football',
      'location': 'London, UK',
      'age': 28,
      'gender': 'Female',
      'email': 'jane.smith@example.com',
      'phone': '+44 7123 456789',
      'playingStyle': 'Attacking Midfielder',
      'sports': ['Football', 'Tennis'],
      'tournaments': [
        {'name': 'Football City Cup', 'date': 'Sept 1 - Oct 1'},
        {'name': 'Tennis Open 2024', 'date': 'Aug 10 - Aug 20'},
      ],
      'achievements': [
        'Top Scorer Football Cup 2023',
        'Tennis Singles Champion 2022',
      ],
    };

    // Uncomment and use actual API call when ready
    /*
    try {
      final response = await http.get(Uri.parse(getApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data != null && data.isNotEmpty) {
          _userProfile = data;
        }
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    */

    // For demonstration: if fetchedData is null or empty, _userProfile remains default
    if (fetchedData != null && fetchedData.isNotEmpty) {
      _userProfile = fetchedData;
    }

    setState(() {
      _populateFields(); // Populate text controllers and state with fetched or default data
      _isLoading = false; // End loading
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImageFile = File(image.path);
        _pickedImageBase64 = base64Encode(bytes);
        _pickedImageFileName = image.name;
        print('Image selected path: ${image.path}');
        print('Base64 image length: ${_pickedImageBase64?.length ?? 0}');
        print('Image filename: $_pickedImageFileName');
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields correctly."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update local _userProfile with current controller values before sending
    _userProfile['name'] = _nameController.text;
    _userProfile['bio'] = _bioController.text;
    _userProfile['location'] = _locationController.text;
    _userProfile['age'] = int.tryParse(_ageController.text) ?? 0;
    _userProfile['gender'] = _selectedGender;
    _userProfile['favoriteSport'] = _selectedFavoriteSport;
    _userProfile['email'] = _emailController.text;
    _userProfile['phone'] = _phoneController.text;
    _userProfile['playingStyle'] = _playingStyleController.text;
    _userProfile['photoBase64'] =
        _pickedImageBase64; // Update with new image base64

    setState(() {
      _isEditing = false; // Exit edit mode immediately
    });

    // Simulate API call for saving profile
    const String apiUrl =
        'https://your-api-url.com/api/user/updateprofile'; // Replace with your actual API endpoint

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Add text fields
    request.fields['name'] = _userProfile['name'];
    request.fields['bio'] = _userProfile['bio'];
    request.fields['location'] = _userProfile['location'];
    request.fields['age'] = _userProfile['age'].toString();
    request.fields['gender'] = _userProfile['gender'] ?? '';
    request.fields['favoriteSport'] = _userProfile['favoriteSport'] ?? '';
    request.fields['email'] = _userProfile['email'];
    request.fields['phone'] = _userProfile['phone'];
    request.fields['playingStyle'] = _userProfile['playingStyle'];
    request.fields['sports'] =
        jsonEncode(_userProfile['sports']); // Send list as JSON string
    request.fields['achievements'] =
        jsonEncode(_userProfile['achievements']); // Send list as JSON string

    // Add image file if selected
    if (_pickedImageFile != null && _pickedImageFileName != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profileImage', // This key should match the parameter name in your backend API (e.g., IFormFile profileImage)
        _pickedImageFile!.path,
        filename: _pickedImageFileName,
      ));
    } else if (_userProfile['photoBase64'] != null) {
      // If no new image picked but an existing one is present (from initial load),
      // you might want to send it as a base64 string if your backend prefers that for existing images.
      // Or, if your backend handles missing file parts by keeping the existing image, you might not need this.
      // For this example, we'll send it as a field if no new file is picked but a base64 exists.
      request.fields['photoBase64'] = _userProfile['photoBase64'];
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Profile update successful: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['message'] ?? 'Profile Saved Successfully!')),
        );
      } else {
        print(
            'Profile update failed: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  void _addSport() {
    final newSport = _newSportController.text.trim();
    if (newSport.isNotEmpty && !_userProfile['sports'].contains(newSport)) {
      setState(() {
        _userProfile['sports'].add(newSport);
        _newSportController.clear();
      });
    }
  }

  void _removeSport(String sport) {
    setState(() {
      _userProfile['sports'].remove(sport);
      if (_selectedFavoriteSport == sport) {
        _selectedFavoriteSport = null;
      }
    });
  }

  void _addAchievement() {
    final newAchievement = _newAchievementController.text.trim();
    if (newAchievement.isNotEmpty &&
        !_userProfile['achievements'].contains(newAchievement)) {
      setState(() {
        _userProfile['achievements'].add(newAchievement);
        _newAchievementController.clear();
      });
    }
  }

  void _removeAchievement(String achievement) {
    setState(() {
      _userProfile['achievements'].remove(achievement);
    });
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ),
    );
  }

  // Helper for text fields that can be edited
  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    TextAlign textAlign = TextAlign.start,
    TextStyle? textStyle,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: textAlign,
              style: textStyle,
              decoration: InputDecoration(
                labelText: label,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: isRequired
                  ? (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null
                  : null,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  controller.text.isEmpty ? 'N/A' : controller.text,
                  style: textStyle ??
                      const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }

  // Helper for dropdowns that can be edited
  Widget _buildEditableDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _isEditing
          ? DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: onChanged,
              validator: isRequired
                  ? (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null
                  : null,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }

  Widget _buildTournamentList(List<dynamic> tournaments) {
    if (tournaments.isEmpty) {
      return const Text("No tournaments played yet.",
          style: TextStyle(color: Colors.grey));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: tournaments
            .map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  t['date'],
                  style: const TextStyle(color: Colors.grey),
                ),
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
        ),
        body: const Center(
          child: CircularProgressIndicator(), // Show loading indicator
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile(); // Call async save profile
              } else {
                setState(() {
                  _isEditing = true; // Enter edit mode
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          // Wrap with Form for validation
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _pickedImageBase64 != null
                      ? MemoryImage(base64Decode(_pickedImageBase64!))
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                  child: _pickedImageBase64 == null && _isEditing
                      ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.black45)
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              // Name (always centered, but editable)
              _buildEditableTextField(
                controller: _nameController,
                label: 'Name',
                textAlign: TextAlign.center,
                textStyle:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                isRequired: true,
              ),
              const SizedBox(height: 8),
              // Bio (always centered, but editable)
              _buildEditableTextField(
                controller: _bioController,
                label: 'Bio',
                textAlign: TextAlign.center,
                textStyle: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Personal Details'),
                      _buildEditableTextField(
                        controller: _locationController,
                        label: 'Location',
                        textStyle: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      _buildEditableTextField(
                        controller: _ageController,
                        label: 'Age',
                        keyboardType: TextInputType.number,
                        textStyle: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      _buildEditableDropdown(
                        label: 'Gender',
                        value: _selectedGender,
                        options: _genderOptions,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                      ),
                      _buildEditableTextField(
                        controller: _playingStyleController,
                        label: 'Playing Style',
                        textStyle: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Contact Information'),
                      _buildEditableTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textStyle: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      _buildEditableTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        textStyle: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Favorite Sport Dropdown
              _buildEditableDropdown(
                label: 'Favorite Sport',
                value: _selectedFavoriteSport,
                options:
                    _allSportsOptions, // Use the comprehensive list of all sports
                onChanged: (newValue) {
                  setState(() {
                    _selectedFavoriteSport = newValue;
                  });
                },
                isRequired: true, // Favorite sport is required
              ),
              const SizedBox(height: 16),

              // Editable Sports List
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('My Sports'),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _userProfile['sports'].map<Widget>((sport) {
                          return Chip(
                            label: Text(sport),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            deleteIcon: _isEditing
                                ? const Icon(Icons.cancel, size: 18)
                                : null,
                            onDeleted:
                                _isEditing ? () => _removeSport(sport) : null,
                          );
                        }).toList(),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newSportController,
                          decoration: InputDecoration(
                            hintText: 'Add new sport',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addSport,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addSport(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Tournaments Section
              _sectionTitle('Tournaments Played'),
              const SizedBox(height: 10),
              _buildTournamentList(_userProfile['tournaments']),

              const SizedBox(height: 30),

              // Achievements Section
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Achievements'),
                      if (_isEditing) ...[
                        if (_userProfile['achievements'].isEmpty)
                          const Text("No achievements yet. Add some!",
                              style: TextStyle(color: Colors.grey)),
                        ..._userProfile['achievements']
                            .map<Widget>((achievement) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.star, color: Colors.amber),
                            title: Text(
                              achievement,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeAchievement(achievement),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newAchievementController,
                          decoration: InputDecoration(
                            hintText: 'Add new achievement',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addAchievement,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addAchievement(),
                        ),
                      ] else ...[
                        _userProfile['achievements'].isEmpty
                            ? const Text("No achievements yet.",
                                style: TextStyle(color: Colors.grey))
                            : Column(
                                children: _userProfile['achievements']
                                    .map<Widget>((achievement) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.star,
                                        color: Colors.amber),
                                    title: Text(
                                      achievement,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
