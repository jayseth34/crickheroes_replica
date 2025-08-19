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
      final response = await http
          .get(Uri.parse('https://localhost:7116/api/Player/GetAllPlayers'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Null check for the entire data response
        if (data is List) {
          // Filter out players with a null or empty name before mapping
          final List<dynamic> validPlayers = data
              .where((e) => e['name'] != null && e['name'].isNotEmpty)
              .toList();

          allPlayers =
              validPlayers.map((e) => e as Map<String, dynamic>).toList();

          // Null checks within the mapping process
          allPlayers = allPlayers.map((player) {
            return {
              'id': player['id'] ?? '',
              'tournamentId': player['tournamentId'] ?? '',
              'teamId': player['teamId'] ?? '',
              'name': player['name'] ?? 'Unknown Player',
              'village': player['village'] ?? 'N/A',
              'age': player['age'] ?? 'N/A',
              'address': player['address'] ?? 'N/A',
              'gender': player['gender'] ?? 'N/A',
              'handedness': player['handedness'] ?? 'N/A',
              'role': player['role'] ?? 'N/A',
              'profileImage': player['profileImage'] ?? '',
              'createdAt': player['createdAt'] ?? '',
              'updatedAt': player['updatedAt'] ?? '',
              'isSold': player['isSold'] ?? false,
              'mobNo': player['mobNo'] ?? 'N/A',
              'email': player['email'] ?? 'N/A',
              'bio': player['bio'] ?? 'No bio available.',
              'favSport': player['favSport'] ?? 'N/A',
              'playingStyle': player['playingStyle'] ?? 'N/A',
              'achievements':
                  (player['achievements'] as List?)?.cast<String>() ?? [],
              'sports': (player['sports'] as List?)?.cast<String>() ?? [],
              'tournaments': (player['tournaments'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [],
            };
          }).toList();
        } else {
          throw Exception('Invalid API response format.');
        }
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
              (player) =>
                  player['name'] != null &&
                  player['name'].toLowerCase().contains(query),
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
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: accentOrange),
                filled: true,
                fillColor: lightBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: accentOrange, width: 2),
                ),
              ),
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentOrange),
                ),
              ),
            )
          else if (errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else if (filteredPlayers.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No players found.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredPlayers.length,
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      elevation: 4,
                      color: lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: (player['profileImage'] != null &&
                                  (player['profileImage'] as String).isNotEmpty)
                              ? NetworkImage(player['profileImage']!)
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        ),
                        title: Text(
                          player['name'] ?? 'Unknown Player',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          player['village'] ?? 'N/A',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: accentOrange),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailsPage(player: player),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
