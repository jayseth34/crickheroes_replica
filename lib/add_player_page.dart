import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(
        child: Text('This is the My Profile page.'),
      ),
    );
  }
}

class AddPlayerPage extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;
  final Map<String, dynamic> tournament;

  const AddPlayerPage({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournament,
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
  final TextEditingController mobileNumberController = TextEditingController();

  String? selectedGender;
  String? selectedHandedness;
  String? selectedRole;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> handednessOptions = ['Right-handed', 'Left-handed'];

  Map<String, List<String>> sportRoles = {
    'Cricket': ['Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper'],
    'Football': ['Striker', 'Midfielder', 'Defender', 'Goalkeeper'],
  };

  List<String> currentRoles = [];
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isProfileComplete = false;
  String _storedMobileNumber = '';
  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    _updateRolesForSport(widget.tournament['sportType'] ?? '');
    _loadAndFetchPlayerData();
  }

  @override
  void dispose() {
    nameController.dispose();
    villageController.dispose();
    ageController.dispose();
    addressController.dispose();
    mobileNumberController.dispose();
    super.dispose();
  }

  // New method to load player ID and fetch data
  Future<void> _loadAndFetchPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final int playerId = prefs.getInt('playerId') ?? 0;
    print(playerId);
    final storedNumber = prefs.getString('mobileNumber');
    if (storedNumber != null) {
      setState(() {
        _storedMobileNumber = storedNumber;
      });
    }
    if (playerId != 0) {
      await _fetchPlayerData(playerId);
    } else {
      setState(() {
        _isLoading = false;
        _isProfileComplete = false;
      });
    }
  }

  // New method to fetch player data from API
  Future<void> _fetchPlayerData(int playerId) async {
    // Note: The original URL was localhost, which won't work in a web environment.
    // I'm using the same domain as the other APIs for consistency.
    final String apiUrl =
        'https://sportsdecor.somee.com/api/Player/GetPlayer/$playerId';
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _bindPlayerData(responseData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching player data: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _bindPlayerData(Map<String, dynamic> data) {
    setState(() {
      nameController.text = data['name'] ?? '';
      villageController.text = data['village'] ?? '';
      ageController.text = (data['age'] ?? '').toString();
      addressController.text = data['address'] ?? '';
      mobileNumberController.text = _storedMobileNumber ?? '';
      selectedGender = data['gender'];
      selectedHandedness = data['handedness'];
      selectedRole = data['role'];
      _profileImageUrl = data['profileImage'];

      _isProfileComplete =
          _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
    });
  }

  void _updateRolesForSport(String sportName) {
    setState(() {
      String normalizedSportName = sportName.toLowerCase();
      if (normalizedSportName.contains('cricket')) {
        currentRoles = sportRoles['Cricket']!;
      } else if (normalizedSportName.contains('football')) {
        currentRoles = sportRoles['Football']!;
      } else if (normalizedSportName.contains('badminton') ||
          normalizedSportName.contains('table tennis') ||
          normalizedSportName.contains('racquet')) {
        currentRoles = [];
        selectedRole = '';
      } else {
        currentRoles = [];
        selectedRole = '';
      }
    });
  }

  void _checkProfileCompletionAndSave() {
    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: primaryBlue,
          title: const Text('Profile Image Required',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Please complete your profile by adding a profile image before adding a player.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Redirect to MyProfilePage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyProfilePage()),
                );
              },
              child: const Text('Go to Profile',
                  style: TextStyle(color: accentOrange)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: accentOrange)),
            ),
          ],
        ),
      );
    } else {
      if (_formKey.currentState!.validate()) {
        savePlayer();
      }
    }
  }

  Future<void> savePlayer() async {
    // API call logic remains the same
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
    request.fields['MobNo'] = _storedMobileNumber;
    request.fields['ProfileImage'] = _profileImageUrl ?? '';

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
      backgroundColor: primaryBlue,
      appBar: AppBar(
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: lightBlue.withOpacity(0.5),
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(Icons.person,
                              size: 50, color: Colors.white.withOpacity(0.8))
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(nameController, 'Player Name'),
                    const SizedBox(height: 16),
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
                        isRequired: false,
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
                        onPressed: _isProfileComplete
                            ? _checkProfileCompletionAndSave
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    T? value,
    required List<T> options,
    required void Function(T?) onChanged,
    required bool isRequired,
  }) {
    return DropdownButtonFormField<String>(
      value: value as String?,
      style: const TextStyle(color: Colors.white),
      dropdownColor: lightBlue,
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
      items: options
          .map((opt) => DropdownMenuItem(
              value: opt.toString(),
              child: Text(opt.toString(),
                  style: const TextStyle(color: Colors.white))))
          .toList(),
      onChanged: onChanged as void Function(String?)?,
      validator: isRequired && options.isNotEmpty
          ? (val) => val == null || val.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}
