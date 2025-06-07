import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  bool _loading = false;

  Map<String, dynamic>? tournamentData;

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

  Future<void> _fetchTournamentDetails(int id) async {
    setState(() {
      _loading = true;
    });

    final url =
        'https://sportsdecor.somee.com/api/Tournament/GetTournament/$id';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> tournamentData = json.decode(response.body);
        print(tournamentData);
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

          // Update payment amount based on team count
          paymentAmount =
              selectedTeamCount > 2 ? (selectedTeamCount - 2) * 100 : 0;

          // Clear and add one empty admin controller because your response doesn't have admins
          _adminControllers.clear();
          _adminControllers.add(TextEditingController());
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
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isUpdate ? 'Update Tournament' : 'Add Tournament'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdate ? 'Update Tournament' : 'Add Tournament'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepPurple, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap to add image',
                        style: TextStyle(color: Colors.grey))
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                shadowColor: Colors.deepPurple.shade100,
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
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.deepPurple),
                            onPressed: () {
                              setState(() {
                                _adminControllers.add(TextEditingController());
                              });
                            },
                          ),
                        ],
                      ),
                      ..._adminControllers.map(
                        (controller) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: _validatePhoneNumber,
                          ),
                        ),
                      ),
                      DropdownButtonFormField<int>(
                        value: selectedTeamCount,
                        decoration: InputDecoration(
                          labelText: 'Number of Teams',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [2, 4, 6, 8].map((count) {
                          return DropdownMenuItem<int>(
                            value: count,
                            child: Text('$count Teams'),
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
                                  ? Colors.deepOrange
                                  : Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNumberField('Team Wallet Balance',
                          controller: _walletBalanceController),
                      const SizedBox(height: 12),
                      _buildNumberField('Players per Team',
                          controller: _playersPerTeamController),
                      const SizedBox(height: 12),
                      _buildTextField('Owner Name',
                          controller: _ownerNameController),
                      const SizedBox(height: 12),
                      _buildNumberField('Base Price of Player',
                          controller: _basePriceController),
                      const SizedBox(height: 12),
                      _buildNumberField('Event Duration (Days)',
                          controller: _durationController),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSport,
                        decoration: InputDecoration(
                          labelText: 'Type of Sport',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        items: sports
                            .map((sport) => DropdownMenuItem(
                                  value: sport,
                                  child: Text(sport),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSport = value ?? 'Cricket';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildNumberField(
                          selectedSport == 'Cricket'
                              ? 'Overs per Match'
                              : selectedSport == 'Football'
                                  ? 'Halves per Match'
                                  : 'Sets per Match',
                          controller: _matchDetailController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (paymentAmount > 0) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Payment Required'),
                          content: Text(
                              'You need to pay ₹$paymentAmount to proceed.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _processPayment();
                              },
                              child: const Text('Pay Now'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      _submitTournament();
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: Text(widget.isUpdate ? 'Update Tournament' : 'Submit',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildNumberField(String label, {TextEditingController? controller}) {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  void _processPayment() async {
    await Future.delayed(const Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment Successful!'),
        backgroundColor: Colors.green,
      ),
    );
    _submitTournament();
  }

  Future<void> _submitTournament() async {
    final url = 'https://sportsdecor.somee.com/api/Tournament/SaveTournament';

    int parseOrZero(String text) => int.tryParse(text) ?? 0;

    final tournamentData = {
      if (widget.isUpdate && widget.tournamentId != null)
        "id": widget.tournamentId,
      "name": _tournamentNameController.text,
      "place": _placeController.text,
      "admins": _adminControllers.map((e) => e.text).toList(),
      "numberOfTeams": selectedTeamCount,
      "teamWalletBalance": parseOrZero(_walletBalanceController.text),
      "playersPerTeam": parseOrZero(_playersPerTeamController.text),
      "ownerName": _ownerNameController.text,
      "basePrice": parseOrZero(_basePriceController.text),
      "duration": parseOrZero(_durationController.text),
      "sport": selectedSport,
      "matchDetail": parseOrZero(_matchDetailController.text),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(tournamentData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isUpdate
                ? "Tournament Updated Successfully"
                : "Tournament Added Successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.body}'),
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
    }
  }
}
