import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import the shared_preferences package
import 'add_team_page.dart';
import 'add_player_page.dart';
import 'auction_page.dart';

// Updated Tournament class to include sportType
class Tournament {
  final int id;
  final String name;
  final String? sportType; // Added sportType
  final String?
      startDate; // Added startDate for consistency and potential future use

  Tournament(
      {required this.id, required this.name, this.sportType, this.startDate});

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      sportType: json['sportType'], // Parse sportType from JSON
      startDate: json['startDate'], // Parse startDate from JSON
    );
  }

  // Helper to convert Tournament object to a Map for AddPlayerPage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportType': sportType,
      'startDate': startDate,
      // Add other fields if AddPlayerPage needs them
    };
  }
}

class SearchTournamentPage extends StatefulWidget {
  final String mode;
  final bool isAdmin;

  const SearchTournamentPage(
      {required this.mode, this.isAdmin = false, Key? key})
      : super(key: key);

  @override
  State<SearchTournamentPage> createState() => _SearchTournamentPageState();
}

class _SearchTournamentPageState extends State<SearchTournamentPage> {
  final TextEditingController searchController = TextEditingController();
  List<Tournament> allTournaments = []; // Changed to use Tournament model
  List<Tournament> filteredTournaments = []; // Changed to use Tournament model
  bool isLoading = true;
  bool isError = false;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue
  String _storedMobileNumber = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    searchController.addListener(_filterTournaments);
  }

  Future<void> _initialize() async {
    await _loadStoredMobileNumber(); // ✅ works now
    await fetchTournaments();
  }

  Future<void> _loadStoredMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNumber = prefs.getString('mobileNumber');
    if (storedNumber != null) {
      setState(() {
        _storedMobileNumber = storedNumber;
      });
    }
  }

  Future<void> fetchTournaments() async {
    print(widget.isAdmin);
    final String apiUrl = widget.isAdmin
        ? 'https://localhost:7116/api/Tournament/GetAdminTournaments?mobNo=$_storedMobileNumber'
        : 'https://sportsdecor.somee.com/api/Tournament/GetAllTournaments';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        allTournaments = data.map((json) => Tournament.fromJson(json)).toList();
        setState(() {
          filteredTournaments = List.from(allTournaments);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load tournaments');
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  void _filterTournaments() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredTournaments = allTournaments
          .where((t) =>
              t.name.toLowerCase().contains(query) ||
              (t.sportType?.toLowerCase().contains(query) ??
                  false)) // Filter by sportType too
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _navigateToNextPage(Tournament tournament) {
    switch (widget.mode) {
      case 'addTeam':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTeamPage(
              tournamentId: tournament.id,
              tournamentName: tournament.name,
            ),
          ),
        );
        break;
      case 'addPlayer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddPlayerPage(
              tournamentId: tournament.id,
              tournamentName: tournament.name,
              tournament: tournament.toMap(),
              isAdmin: widget
                  .isAdmin, // Pass the Tournament object converted to a Map
            ),
          ),
        );
        break;
      case 'auction':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuctionPage(
                tournamentName: tournament.name, tournamentId: tournament.id),
          ),
        );
        break;
    }
  }

  String getModeLabel() {
    switch (widget.mode) {
      case 'addTeam':
        return 'Add Teams';
      case 'addPlayer':
        return 'Add Players';
      case 'auction':
        return 'Start Auction';
      default:
        return 'Search Tournament';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      appBar: AppBar(
        title:
            Text(getModeLabel(), style: const TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white, // Set foreground (text/icons) to white
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: accentOrange)) // Loading indicator color
            : isError
                ? const Center(
                    child: Text(
                      'Error loading tournaments. Please try again later.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : Column(
                    children: [
                      TextField(
                        controller: searchController,
                        style: const TextStyle(
                            color: Colors.white), // Text input color
                        decoration: InputDecoration(
                          hintText: 'Search tournaments...',
                          hintStyle: TextStyle(
                              color: Colors.white70), // Hint text color
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white70), // Icon color
                          filled: true,
                          fillColor: lightBlue
                              .withOpacity(0.5), // Text field background
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none, // No border line
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: accentOrange,
                                width: 2), // Orange border on focus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Colors
                                    .white30), // Light border when enabled
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: filteredTournaments.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.error_outline,
                                      size: 60,
                                      color: Colors.white70), // Icon color
                                  SizedBox(height: 10),
                                  Text(
                                    'No tournaments found.',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70), // Text color
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: filteredTournaments.length,
                                itemBuilder: (context, index) {
                                  final tournament = filteredTournaments[index];
                                  final input = searchController.text;
                                  final matchIndex = tournament.name
                                      .toLowerCase()
                                      .indexOf(input.toLowerCase());

                                  final beforeMatch = matchIndex >= 0
                                      ? tournament.name.substring(0, matchIndex)
                                      : tournament.name;
                                  final matchText = matchIndex >= 0
                                      ? tournament.name.substring(
                                          matchIndex, matchIndex + input.length)
                                      : '';
                                  final afterMatch = matchIndex >= 0
                                      ? tournament.name
                                          .substring(matchIndex + input.length)
                                      : '';

                                  return Card(
                                    color: lightBlue.withOpacity(
                                        0.7), // Card background with opacity
                                    elevation: 4,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor:
                                            accentOrange, // Accent orange
                                        child: Icon(Icons.emoji_events,
                                            color: Colors.white),
                                      ),
                                      title: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color:
                                                  Colors.white), // Text color
                                          children: [
                                            TextSpan(text: beforeMatch),
                                            TextSpan(
                                              text: matchText,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      accentOrange), // Accent orange
                                            ),
                                            TextSpan(text: afterMatch),
                                          ],
                                        ),
                                      ),
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: accentOrange), // Accent orange
                                      onTap: () =>
                                          _navigateToNextPage(tournament),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
