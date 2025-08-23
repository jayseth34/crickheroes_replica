import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class MyProfilePage extends StatefulWidget {
  final bool startInEditMode;
  final Map<String, dynamic>? initialData;

  const MyProfilePage({
    super.key,
    this.startInEditMode = false,
    this.initialData,
  });

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> _userProfile = {
    'name': 'Guest Player',
    'photoBase64': null,
    'bio': 'Tell us about yourself!',
    'favoriteSport': null,
    'location': '',
    'age': null,
    'gender': null,
    'email': '',
    'phone': '',
    'playingStyle': '',
    'sports': [],
    'tournaments': [],
    'achievements': [],
    'imageUrl': null,
    'handedness': '',
    'address': '',
    'role': '',
    'tournamentId': '',
    'teamId': '',
  };

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

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
  final TextEditingController _handednessController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  String? _selectedFavoriteSport;
  String? _selectedGender;
  File? _pickedImageFile;
  String? _pickedImageBase64;
  String? _pickedImageFileName;
  Uint8List? _pickedImageBytes;
  bool _hasNewImage = false;
  String? _profileImageUrl;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _allSportsOptions = [
    'Cricket',
    'Football',
    'Badminton',
    'Table Tennis',
    'Pickleball',
    'Basketball',
    'Tennis'
  ];

  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);
  static const Color cardColor = Color(0xFF2E1C59);

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode;

    if (widget.initialData != null) {
      _userProfile = {
        ..._userProfile,
        ...widget.initialData!,
        'sports':
            (widget.initialData!['sports'] as List?)?.cast<String>() ?? [],
        'achievements':
            (widget.initialData!['achievements'] as List?)?.cast<String>() ??
                [],
        'tournaments': (widget.initialData!['tournaments'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      };
      _isLoading = false;
      _populateFields();
    } else {
      _fetchProfileDetails();
    }
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
    _handednessController.dispose();
    _addressController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _populateFields() {
    _nameController.text = _userProfile['name'] ?? '';
    _bioController.text = _userProfile['bio'] ?? '';
    _locationController.text = _userProfile['village'] ?? '';
    _ageController.text = (_userProfile['age'] ?? '').toString();
    _emailController.text = _userProfile['email'] ?? '';
    _phoneController.text = _userProfile['mobNo'] ?? '';
    _playingStyleController.text = _userProfile['playingStyle'] ?? '';
    _handednessController.text = _userProfile['handedness'] ?? '';
    _addressController.text = _userProfile['address'] ?? '';
    _roleController.text = _userProfile['role'] ?? '';

    // Correctly handle favSport
    final favSport = _userProfile['favSport'];
    _selectedFavoriteSport = (favSport != null && favSport.isNotEmpty)
        ? favSport
        : _allSportsOptions.isNotEmpty
            ? _allSportsOptions.first
            : null;

    // Correctly handle gender
    final gender = _userProfile['gender'];
    _selectedGender = (gender != null && gender.isNotEmpty)
        ? gender
        : _genderOptions.isNotEmpty
            ? _genderOptions.first
            : null;

    _pickedImageBase64 = _userProfile['photoBase64'];
    _profileImageUrl = _userProfile['imageUrl'] ?? _userProfile['profileImage'];
    _hasNewImage = false;

    // Handle sports and achievements which might be JSON strings inside a list
    final sportsData = _userProfile['sports'];
    if (sportsData is List && sportsData.isNotEmpty) {
      final firstElement = sportsData.first;
      if (firstElement is String) {
        try {
          final decodedList = json.decode(firstElement);
          if (decodedList is List) {
            _userProfile['sports'] = decodedList.cast<String>();
          }
        } catch (e) {
          print('Failed to decode sports string: $e');
        }
      }
    }

    final achievementsData = _userProfile['achievements'];
    if (achievementsData is List && achievementsData.isNotEmpty) {
      final firstElement = achievementsData.first;
      if (firstElement is String) {
        try {
          final decodedList = json.decode(firstElement);
          if (decodedList is List) {
            _userProfile['achievements'] = decodedList.cast<String>();
          }
        } catch (e) {
          print('Failed to decode achievements string: $e');
        }
      }
    }
  }

  Widget _buildTournamentList(dynamic tournamentsData) {
    final tournaments = (tournamentsData is List)
        ? tournamentsData.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    if (tournaments.isEmpty) {
      return const Text(
        "No tournaments yet.",
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tournaments.map((tournament) {
        final String name =
            tournament['tournamentName']?.toString().trim().isNotEmpty == true
                ? tournament['tournamentName']
                : 'Unnamed Tournament';

        final String start =
            tournament['startDate']?.toString().trim().isNotEmpty == true
                ? tournament['startDate']
                : 'Unknown Start';

        final String end =
            tournament['endDate']?.toString().trim().isNotEmpty == true
                ? tournament['endDate']
                : 'Unknown End';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.emoji_events, color: accentOrange),
          title: Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'From $start to $end',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _fetchProfileDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final playerId = prefs.getInt('playerId');
      if (playerId == null) {
        print('Player ID not found in SharedPreferences.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final String playerApiUrl =
          'https://localhost:7116/api/Player/GetPlayer/$playerId';
      final playerResponse = await http.get(Uri.parse(playerApiUrl));

      if (playerResponse.statusCode == 200) {
        final Map<String, dynamic> fetchedData =
            json.decode(playerResponse.body);
        _userProfile = fetchedData;
        _populateFields();
      } else {
        print('Failed to fetch player details: ${playerResponse.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _pickedImageBytes = bytes;
            _pickedImageFile = null;
            _pickedImageFileName = image.name;
            _hasNewImage = true;
            _profileImageUrl = null;
          });
        } else {
          setState(() {
            _pickedImageFile = File(image.path);
            _pickedImageBytes = null;
            _pickedImageFileName = image.name;
            _hasNewImage = true;
            _profileImageUrl = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

    setState(() {
      _isSaving = true;
    });

    const String apiUrl = 'https://localhost:7116/api/Player/SavePlayer';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      final prefs = await SharedPreferences.getInstance();
      final playerId = prefs.getInt('playerId');

      final fields = {
        'Id': (playerId ?? 0).toString(),
        'TournamentId': (_userProfile['tournamentId'] ?? '').toString(),
        'TeamId': (_userProfile['teamId'] ?? '').toString(),
        'Name': _nameController.text,
        'Village': _locationController.text,
        'Age': (int.tryParse(_ageController.text) ?? 0).toString(),
        'Gender': _selectedGender ?? '',
        'FavoriteSport': _selectedFavoriteSport ?? '',
        'Email': _emailController.text,
        'MobNo': _phoneController.text,
        'PlayingStyle': _playingStyleController.text,
        'Handedness': _handednessController.text,
        'Address': _addressController.text,
        'Role': _roleController.text,
        'Bio': _bioController.text,
      };

      final List<String> sportsList =
          _userProfile['sports']?.cast<String>() ?? [];
      final List<String> achievementsList =
          _userProfile['achievements']?.cast<String>() ?? [];

      request.fields['Sports'] = jsonEncode(sportsList);
      request.fields['Achievements'] = jsonEncode(achievementsList);

      if (_hasNewImage) {
        if (_pickedImageBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'ProfileImage',
            _pickedImageBytes!,
            filename: _pickedImageFileName,
          ));
        } else if (_pickedImageFile != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'ProfileImage',
            _pickedImageFile!.path,
            filename: _pickedImageFileName,
          ));
        }
      } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        fields['ImageUrl'] = _profileImageUrl!;
      }

      request.fields.addAll(fields);

      print('Sending request to: $apiUrl');
      print('--- REQUEST FIELDS ---');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });
      print('--- END OF FIELDS ---');
      print('Request files: ${request.files.length} files');

      final response = await request.send();
      final respBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $respBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(respBody);

        setState(() {
          _userProfile = {
            ..._userProfile,
            ...responseData,
          };
          _profileImageUrl = responseData['imageUrl'] ?? _profileImageUrl;
          _isSaving = false;
          _isEditing = false;
          _hasNewImage = false;
        });

        _populateFields();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $respBody"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarImageProvider;
    if (_profileImageUrl != null && !_hasNewImage) {
      avatarImageProvider = NetworkImage(_profileImageUrl!);
    } else if (_hasNewImage && _pickedImageBytes != null) {
      avatarImageProvider = MemoryImage(_pickedImageBytes!);
    } else if (_hasNewImage && _pickedImageFile != null) {
      avatarImageProvider = FileImage(_pickedImageFile!);
    }

    Widget? _getImageWidget() {
      if (_hasNewImage && _pickedImageBytes != null) return null;
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) return null;
      if (_pickedImageBase64 != null) return null;
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue,
        iconTheme: const IconThemeData(
            color: Colors.white), // 👈 This makes the back arrow white
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.visibility : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isSaving) return;
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: lightBlue,
                            backgroundImage: avatarImageProvider,
                            child: _getImageWidget(),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: accentOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isEditing && _pickedImageFileName != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Selected: $_pickedImageFileName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildProfileSection('General Information'),
                    _buildTextField(
                        'Name', _nameController, _isEditing, 'Enter your name'),
                    _buildDropdownField(
                        'Gender', _genderOptions, _selectedGender, (value) {
                      setState(() {
                        _selectedGender = value as String?;
                      });
                    }, _isEditing),
                    _buildTextField(
                        'Age', _ageController, _isEditing, 'Enter your age',
                        keyboardType: TextInputType.number),
                    _buildTextField('Location', _locationController, _isEditing,
                        'Enter your location'),
                    _buildTextField('Address', _addressController, _isEditing,
                        'Enter your address'),
                    _buildTextField('Email', _emailController, _isEditing,
                        'Enter your email',
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField('Phone', _phoneController, _isEditing,
                        'Enter your phone',
                        keyboardType: TextInputType.phone),
                    _buildTextField('Bio', _bioController, _isEditing,
                        'Tell us about yourself!',
                        maxLines: 3),
                    const SizedBox(height: 20),
                    _buildProfileSection('Sports Information'),
                    _buildDropdownField('Favorite Sport', _allSportsOptions,
                        _selectedFavoriteSport, (value) {
                      setState(() {
                        _selectedFavoriteSport = value as String?;
                      });
                    }, _isEditing),
                    _buildTextField('Playing Style', _playingStyleController,
                        _isEditing, 'e.g. Left arm fast, all-rounder'),
                    _buildTextField('Handedness', _handednessController,
                        _isEditing, 'e.g. Right-handed, Left-handed'),
                    _buildTextField('Role', _roleController, _isEditing,
                        'e.g. Bowler, Batsman'),
                    const SizedBox(height: 10),
                    _buildListEditor(
                      'Sports',
                      _userProfile['sports'],
                      _newSportController,
                      _isEditing,
                    ),
                    const SizedBox(height: 10),
                    _buildListEditor(
                      'Achievements',
                      _userProfile['achievements'],
                      _newAchievementController,
                      _isEditing,
                    ),
                    const SizedBox(height: 20),
                    _buildProfileSection('Tournaments'),
                    _buildTournamentList(_userProfile['tournaments']),
                    if (_isEditing)
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Saving...',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: accentOrange,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      bool isEditing, String hintText,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: !isEditing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: isEditing ? cardColor : primaryBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightBlue.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentOrange, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (label == 'Name' && (value == null || value.isEmpty)) {
            return 'Name is required';
          }
          if (label == 'Phone' &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^\d{10}$').hasMatch(value)) {
            return 'Enter a valid 10-digit phone number';
          }
          if (label == 'Email' &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField<T>(String label, List<T> options, T? selectedValue,
      Function(T?) onChanged, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: selectedValue,
        onChanged: isEditing ? onChanged : null,
        style: const TextStyle(color: Colors.white),
        dropdownColor: cardColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: isEditing ? cardColor : primaryBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightBlue.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentOrange, width: 2),
          ),
        ),
        items: options.map<DropdownMenuItem<T>>((T value) {
          return DropdownMenuItem<T>(
            value: value,
            child: Text(value.toString(),
                style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListEditor(
    String label,
    dynamic itemsData,
    TextEditingController controller,
    bool isEditing,
  ) {
    final items = (itemsData is List)
        ? itemsData.whereType<String>().toList()
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'No entries yet.',
            style: TextStyle(color: Colors.white70),
          )
        else
          Wrap(
            spacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: lightBlue,
                labelStyle: const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
        if (isEditing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add new $label',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: primaryBlue,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addToList(label, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _addToList(String label, String value) {
    if (value.trim().isEmpty) return;

    setState(() {
      final key = label.toLowerCase(); // 'sports' or 'achievements'
      final currentList = (_userProfile[key] is List)
          ? List<String>.from(_userProfile[key])
          : <String>[];

      currentList.add(value.trim());
      _userProfile[key] = currentList;
    });

    if (label == 'Sports') {
      _newSportController.clear();
    } else if (label == 'Achievements') {
      _newAchievementController.clear();
    }
  }
}
