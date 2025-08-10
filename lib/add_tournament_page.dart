import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/foundation.dart'; // Import for debugPrint

class AddTournamentPage extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? tournament;
  final int? tournamentId;

  const AddTournamentPage({
    Key? key,
    this.isUpdate = false,
    this.tournament,
    this.tournamentId,
  }) : super(key: key);

  @override
  State<AddTournamentPage> createState() => _AddTournamentPageState();
}

class _AddTournamentPageState extends State<AddTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _adminControllers = [
    TextEditingController()
  ];
  File? _profileImage;
  Uint8List? _profileImageBytes; // New state variable for web image bytes
  String? _imagePickedFileName; // New state variable to show picked file name
  final picker = ImagePicker();

  String selectedSport = 'Cricket';
  final List<String> sports = [
    'Cricket',
    'Football',
    'Pickleball',
    'Throwball',
    'Badminton'
  ];

  int selectedTeamCount = 2;
  int paymentAmount = 0;

  final TextEditingController _tournamentNameController =
      TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _walletBalanceController =
      TextEditingController();
  final TextEditingController _playersPerTeamController =
      TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _matchDetailController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  bool _loading = false;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    if (widget.isUpdate) {
      if (widget.tournamentId == null) {
        throw Exception("tournamentId required for update");
      }
      _fetchTournamentDetails(widget.tournamentId!);
    }
  }

  // Function to fetch tournament details for update mode
  Future<void> _fetchTournamentDetails(int id) async {
    setState(() {
      _loading = true; // Show loading indicator
    });

    final url =
        'https://sportsdecor.somee.com/api/Tournament/GetTournament/$id';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> tournamentData = json.decode(response.body);
        setState(() {
          _tournamentNameController.text = tournamentData['name'] ?? '';
          _placeController.text =
              tournamentData['location'] ?? ''; // use 'location' from API
          selectedTeamCount = tournamentData['numberOfTeams'] ?? 2;
          _walletBalanceController.text =
              (tournamentData['teamWalletBalance'] ?? 0).toString();
          _playersPerTeamController.text =
              (tournamentData['playersPerTeam'] ?? 0).toString();
          _ownerNameController.text = tournamentData['ownerName'] ?? '';
          _basePriceController.text =
              (tournamentData['basePrice'] ?? 0).toString();
          _durationController.text =
              (tournamentData['duration'] ?? 0).toString();
          _matchDetailController.text =
              (tournamentData['matchDetail'] ?? 0).toString();
          selectedSport =
              (tournamentData['sportType'] ?? 'Cricket') ?? 'Cricket';
          _startDateController.text = tournamentData['startDate'] != null
              ? tournamentData['startDate'].toString().split('T')[0]
              : '';
          _endDateController.text = tournamentData['endDate'] != null
              ? tournamentData['endDate'].toString().split('T')[0]
              : '';

          // Update payment amount based on team count
          paymentAmount =
              selectedTeamCount > 2 ? (selectedTeamCount - 2) * 100 : 0;

          // Clear existing admin controllers and populate from API response
          _adminControllers.clear();
          if (tournamentData['admins'] != null &&
              tournamentData['admins'] is List) {
            for (var adminPhoneNumber in tournamentData['admins']) {
              _adminControllers.add(
                  TextEditingController(text: adminPhoneNumber.toString()));
            }
          }
          // Ensure at least one controller exists if no admins are returned
          if (_adminControllers.isEmpty) {
            _adminControllers.add(TextEditingController());
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tournament: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tournament: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } finally {
      setState(() {
        _loading = false; // Hide loading indicator
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          // For web, read bytes directly and use MemoryImage
          final bytes = await picked.readAsBytes();
          if (bytes.isNotEmpty) {
            setState(() {
              _profileImageBytes = bytes;
              _profileImage = null; // Clear File if using bytes
              _imagePickedFileName = picked.name;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected image file is empty or corrupted.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() {
              _profileImageBytes = null;
              _profileImage = null;
              _imagePickedFileName = null;
            });
          }
        } else {
          // For native, use FileImage
          setState(() {
            _profileImage = File(picked.path);
            _profileImageBytes = null; // Clear bytes if using File
            _imagePickedFileName = picked.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error picking image: $e. Try a different image or run natively.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _profileImageBytes = null;
        _profileImage = null;
        _imagePickedFileName = null;
      });
    }
  }

  // Validator for phone number input
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  // Function to construct and send a WhatsApp message with tournament details
  Future<void> _sendWhatsAppMessage() async {
    final tournamentName = _tournamentNameController.text;
    final place = _placeController.text;
    final sportType = selectedSport;
    final numberOfTeams = selectedTeamCount;
    final ownerName = _ownerNameController.text;
    final basePrice = _basePriceController.text;
    final duration = _durationController.text;
    final matchDetail = _matchDetailController.text;

    // Construct entry fee details
    String entryFeeDetails = '';
    if (int.tryParse(basePrice) != null && int.parse(basePrice) > 0) {
      entryFeeDetails += 'Player Base Price: ₹$basePrice\n';
    }
    if (paymentAmount > 0) {
      entryFeeDetails +=
          'Team Registration Fee: ₹$paymentAmount for $numberOfTeams teams\n';
    }
    if (entryFeeDetails.isEmpty) {
      entryFeeDetails = 'No entry fee specified.';
    }

    // Placeholder URLs for registration - REPLACE WITH YOUR ACTUAL APP URLs
    final registerTeamLink = "https://your-app-domain.com/register-team";
    final addPlayerLink = "https://your-app-domain.com/join-player";
    final contactInfo =
        "your-email@example.com or +91-XXXXXXXXXX"; // Replace with actual contact info

    final message = "🎉 *Tournament Details* \n\n"
        "We are excited to announce the upcoming *$tournamentName*, "
        "set to take place for *$duration days* at *$place*. "
        "This event promises thrilling matches, team spirit, and unforgettable moments!\n\n"
        "🏆 *Tournament Details:*\n"
        "Game/Sport: *$sportType*\n"
        "Location: *$place*\n"
        "Number of Teams: *$numberOfTeams*\n"
        "Match Details: *$matchDetail*\n"
        "Entry Fee:\n$entryFeeDetails\n"
        "👥 Whether you want to form a team or join as an individual player, we’ve got you covered!\n\n"
        "🔗 *Register Your Team:*\n"
        "$registerTeamLink\n\n"
        "🔗 *Add/Join as a Player:*\n"
        "$addPlayerLink\n\n"
        "📌 Hurry! Limited slots available. Deadline for registration: [Registration Deadline - e.g., 2025-07-31]\n" // Placeholder for deadline
        "For any queries or support, feel free to reach out at *$contactInfo*.\n\n"
        "Let the games begin! ⚡";

    // Encode the message to be safely included in a URL
    // Using wa.me for better compatibility in web environments
    final whatsappUrl = "https://wa.me/?text=${Uri.encodeComponent(message)}";

    // Check if the URL can be launched and then launch it
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      // Show a snackbar if launching fails (e.g., no browser or app to handle it)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open WhatsApp. Make sure it is installed or try from a mobile device.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addTournament() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final url = 'https://sportsdecor.somee.com/api/Tournament/SaveTournament';

    try {
      // Use http.MultipartRequest for form-data with files
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add text fields from your C# TournamentDto
      request.fields['Name'] = _tournamentNameController.text;
      request.fields['StartDate'] = _startDateController.text;
      request.fields['EndDate'] = _endDateController.text;
      request.fields['Location'] = _placeController.text;
      request.fields['SportType'] = selectedSport;
      request.fields['NumberOfTeams'] = selectedTeamCount.toString();
      request.fields['TeamWalletBalance'] = _walletBalanceController.text;
      request.fields['PlayersPerTeam'] = _playersPerTeamController.text;
      request.fields['OwnerName'] = _ownerNameController.text;
      request.fields['BasePrice'] = _basePriceController.text;
      request.fields['Duration'] = _durationController.text;
      request.fields['MatchDetail'] = _matchDetailController.text;
      if (widget.isUpdate && widget.tournamentId != null) {
        request.fields['id'] = widget.tournamentId.toString();
      }

      // Add admins as a list of strings
      final admins = _adminControllers
          .map((c) => c.text)
          .where((s) => s.isNotEmpty)
          .toList();
      for (int i = 0; i < admins.length; i++) {
        request.fields['Admins[$i]'] = admins[i];
      }

      // Add the image file
      // NOTE: This logic ensures the image is correctly added as a multipart file
      // using the field name 'ProfileImage' to match your C# endpoint.
      if (_profileImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'ProfileImage', // The name of the file field in your C# backend
          _profileImageBytes!,
          filename: _imagePickedFileName,
        ));
      } else if (_profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'ProfileImage', // The name of the file field in your C# backend
          _profileImage!.path,
          filename: _imagePickedFileName,
        ));
      }

      // Send the request and handle the response
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isUpdate
                ? "Tournament Updated Successfully"
                : "Tournament Added Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final respBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $respBody'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the image provider based on platform and selected image
    ImageProvider<Object>? avatarImageProvider;
    if (kIsWeb && _profileImageBytes != null) {
      avatarImageProvider = MemoryImage(_profileImageBytes!);
    } else if (!kIsWeb && _profileImage != null) {
      avatarImageProvider = FileImage(_profileImage!);
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isUpdate ? 'Update Tournament' : 'Add Tournament'),
          backgroundColor: lightBlue, // Use lightBlue
          foregroundColor: Colors.white, // Text on primary
        ),
        body: Center(
            child: CircularProgressIndicator(
                color: accentOrange)), // Accent orange
      );
    }

    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background to primaryBlue
      appBar: AppBar(
        title: Text(widget.isUpdate ? 'Update Tournament' : 'Add Tournament'),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white, // Text on primary
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6), // Slightly more padding
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: lightBlue, width: 3), // lightBlue border
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(
                                0.3), // primaryBlue tint for shadow
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65, // Slightly larger
                        backgroundColor:
                            lightBlue.withOpacity(0.5), // Light blue background
                        backgroundImage:
                            avatarImageProvider, // Use the determined image provider
                        child: (avatarImageProvider == null)
                            ? const Icon(Icons.add_a_photo,
                                size: 45,
                                color: accentOrange) // Accent orange icon
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap to add image',
                        style: TextStyle(color: Colors.white)) // White text
                  ],
                ),
              ),
              if (_imagePickedFileName != null) // Display selected file name
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected: $_imagePickedFileName',
                    style: TextStyle(
                        color: Colors.white70, // White70 text
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                elevation: 6, // Slightly more prominent shadow
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                shadowColor:
                    primaryBlue.withOpacity(0.2), // primaryBlue tint for shadow
                color:
                    lightBlue.withOpacity(0.7), // Card background with opacity
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField('Tournament Name',
                          controller: _tournamentNameController),
                      const SizedBox(height: 12),
                      _buildTextField('Place', controller: _placeController),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Admin Phone Numbers',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white), // Consistent text color
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: accentOrange), // Accent orange icon
                            onPressed: () {
                              setState(() {
                                _adminControllers.add(TextEditingController());
                              });
                            },
                          ),
                        ],
                      ),
                      ..._adminControllers.asMap().entries.map(
                        (entry) {
                          int index = entry.key;
                          TextEditingController controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                        color:
                                            Colors.white), // Input text color
                                    decoration: InputDecoration(
                                      hintText: 'Enter phone number',
                                      hintStyle: const TextStyle(
                                          color: Colors
                                              .white70), // Hint text color
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            12), // More rounded
                                        borderSide: BorderSide(
                                            color: lightBlue.withOpacity(0.5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: accentOrange,
                                            width: 2), // Accent orange
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: lightBlue), // lightBlue
                                      ),
                                      labelStyle: const TextStyle(
                                          color: Colors
                                              .white70), // Label text color
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 16), // Better padding
                                    ),
                                    validator: _validatePhoneNumber,
                                  ),
                                ),
                                if (_adminControllers.length >
                                    1) // Only show remove button if more than one
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _adminControllers.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                      DropdownButtonFormField<int>(
                        value: selectedTeamCount,
                        style: const TextStyle(
                            color: Colors.white), // Dropdown text color
                        dropdownColor: lightBlue, // Dropdown background color
                        decoration: InputDecoration(
                          labelText: 'Number of Teams',
                          labelStyle: const TextStyle(
                              color: Colors.white70), // Label text color
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: lightBlue.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: accentOrange, width: 2), // Accent orange
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: lightBlue), // lightBlue
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        items: [2, 4, 6, 8].map((count) {
                          return DropdownMenuItem<int>(
                            value: count,
                            child: Text('$count Teams',
                                style: const TextStyle(
                                    color: Colors.white)), // Item text color
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTeamCount = value ?? 2;
                            paymentAmount = selectedTeamCount > 2
                                ? (selectedTeamCount - 2) * 100
                                : 0;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          paymentAmount > 0
                              ? '💰 ₹$paymentAmount required for $selectedTeamCount teams.'
                              : '✅ No payment needed for 2 teams.',
                          style: TextStyle(
                            color: paymentAmount > 0
                                ? Colors.white
                                : Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField('Team Wallet Balance',
                          controller: _walletBalanceController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField('Players Per Team',
                          controller: _playersPerTeamController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField('Owner Name',
                          controller: _ownerNameController),
                      const SizedBox(height: 12),
                      _buildTextField('Player Base Price',
                          controller: _basePriceController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField('Duration (in days)',
                          controller: _durationController,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSport,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: lightBlue,
                        decoration: InputDecoration(
                          labelText: 'Sport Type',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: accentOrange, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightBlue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                        items: sports.map((sport) {
                          return DropdownMenuItem<String>(
                            value: sport,
                            child: Text(sport,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSport = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField('Match Details',
                          controller: _matchDetailController),
                      const SizedBox(height: 12),
                      _buildDateTextField('Start Date', _startDateController),
                      const SizedBox(height: 12),
                      _buildDateTextField('End Date', _endDateController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addTournament,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isUpdate
                            ? 'Update Tournament'
                            : 'Add Tournament',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendWhatsAppMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Share on WhatsApp',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      {TextEditingController? controller,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentOrange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildDateTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = pickedDate.toString().split(' ')[0];
          });
        }
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentOrange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue),
        ),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  int parseOrZero(String? value) {
    if (value == null || value.isEmpty) {
      return 0;
    }
    return int.tryParse(value) ?? 0;
  }
}
