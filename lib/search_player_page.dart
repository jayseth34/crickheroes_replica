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
      appBar: AppBar(
        title: const Text('Search Players'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search player by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filteredPlayers.isEmpty
                        ? const Center(child: Text('No players found'))
                        : ListView.builder(
                            itemCount: filteredPlayers.length,
                            itemBuilder: (context, index) {
                              final player = filteredPlayers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: player['photoUrl'] != null &&
                                          player['photoUrl'].isNotEmpty
                                      ? NetworkImage(player['photoUrl'])
                                      : const AssetImage(
                                              'assets/default_profile.png')
                                          as ImageProvider,
                                ),
                                title: Text(player['name']),
                                // Subtitle for sports is intentionally removed as per request
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlayerDetailsPage(player: player),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }
}
