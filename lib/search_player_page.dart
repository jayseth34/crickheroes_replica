import 'package:flutter/material.dart';
import 'player_details_page.dart';
import 'dart:convert'; // Required for JSON decoding
import 'package:http/http.dart' as http; // Import http package for API calls

class SearchPlayerPage extends StatefulWidget {
  const SearchPlayerPage({super.key});

  @override
  State<SearchPlayerPage> createState() => _SearchPlayerPageState();
}

class _SearchPlayerPageState extends State<SearchPlayerPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allPlayers = [];
  List<Map<String, dynamic>> filteredPlayers = [];
  bool isLoading = true;
  String? errorMessage;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    _fetchPlayers(); // Call API to fetch players on init
    _searchController.addListener(_filterPlayers);
  }

  // Function to fetch player data from the API
  Future<void> _fetchPlayers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
          Uri.parse('https://sportsdecor.somee.com/api/Player/GetAllPlayers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        allPlayers = data.map((e) => e as Map<String, dynamic>).toList();

        // Map 'profileImage' from API to 'photoUrl' for consistency with existing UI logic
        // Also ensure 'sports' and 'tournaments' are handled, even if empty or not directly from API
        allPlayers = allPlayers.map((player) {
          return {
            'name': player['name'],
            'photoUrl': player['profileImage'], // Use profileImage from API
            'sports':
                [], // API response doesn't have 'sports', so provide an empty list
            'tournaments':
                [], // API response doesn't have 'tournaments', so provide an empty list
            'totalMatches': 0, // Default values
            'totalRuns': 0, // Default values
            'goals': 0, // Default values
            'id': player['id'], // Include other relevant fields from API
            'tournamentId': player['tournamentId'],
            'teamId': player['teamId'],
            'village': player['village'],
            'age': player['age'],
            'address': player['address'],
            'gender': player['gender'],
            'handedness': player['handedness'],
            'role': player['role'],
            'createdAt': player['createdAt'],
            'updatedAt': player['updatedAt'],
          };
        }).toList();
      } else {
        throw Exception('Failed to load players: ${response.statusCode}');
      }

      setState(() {
        filteredPlayers = allPlayers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch players: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _filterPlayers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPlayers = allPlayers;
      } else {
        filteredPlayers = allPlayers
            .where(
              (player) => player['name'].toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPlayers);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      appBar: AppBar(
        title:
            const Text('Search Players', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white, // Set foreground (text/icons) to white
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white), // Text input color
              decoration: InputDecoration(
                hintText: 'Search player by name...',
                hintStyle: TextStyle(color: Colors.white70), // Hint text color
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white70), // Icon color
                filled: true,
                fillColor: lightBlue.withOpacity(0.5), // Text field background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // No border line
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: accentOrange, width: 2), // Orange border on focus
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.white30), // Light border when enabled
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: accentOrange)) // Loading indicator color
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filteredPlayers.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.person_off,
                                  size: 60,
                                  color: Colors.white70), // Icon for no players
                              SizedBox(height: 10),
                              Text(
                                'No players found.',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70), // Text color
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: filteredPlayers.length,
                            itemBuilder: (context, index) {
                              final player = filteredPlayers[index];
                              return Card(
                                color: lightBlue.withOpacity(
                                    0.7), // Card background with opacity
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        primaryBlue, // Background for default image
                                    backgroundImage: player['photoUrl'] !=
                                                null &&
                                            player['photoUrl'].isNotEmpty
                                        ? NetworkImage(player['photoUrl'])
                                        : const AssetImage(
                                                'assets/default_profile.png') // Fallback image
                                            as ImageProvider,
                                  ),
                                  title: Text(player['name'],
                                      style: const TextStyle(
                                          color: Colors.white)), // Text color
                                  // Subtitle for sports is intentionally removed as per request
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16,
                                      color: accentOrange), // Accent orange
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlayerDetailsPage(player: player),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }
}
