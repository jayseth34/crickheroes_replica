import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tournament_detail_page.dart';
import 'add_player_page.dart'; // Import the AddPlayerPage

// Define the Tournament class with sportType (if not already globally defined)
// If you have a shared models file, this can be removed from here.
class Tournament {
  final int id;
  final String name;
  final String? sportType; // Added sportType
  final String? startDate; // Added startDate for display in subtitle

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
}

class ViewTournamentsPage extends StatefulWidget {
  const ViewTournamentsPage({super.key});

  @override
  State<ViewTournamentsPage> createState() => _ViewTournamentsPageState();
}

class _ViewTournamentsPageState extends State<ViewTournamentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Tournament> _allTournaments = []; // Changed to use Tournament model
  List<Tournament> _filteredTournaments = []; // Changed to use Tournament model
  bool _isLoading = true;

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();
    fetchTournaments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTournaments = List.from(_allTournaments);
      } else {
        _filteredTournaments = _allTournaments.where((tournament) {
          final name = tournament.name.toLowerCase();
          final sport = tournament.sportType?.toLowerCase() ??
              ''; // Use sportType from model
          final startDate = tournament.startDate?.toLowerCase() ??
              ''; // Use startDate from model
          return name.contains(query) ||
              sport.contains(query) ||
              formatDate(tournament.startDate ??
                      '') // Use formatDate with model property
                  .toLowerCase()
                  .contains(query) ||
              startDate.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchTournaments() async {
    final url = Uri.parse(
        "https://sportsdecor.somee.com/api/Tournament/GetAllTournaments");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _allTournaments =
              data.map((t) => Tournament.fromJson(t)).toList(); // Use fromJson
          _filteredTournaments = List.from(_allTournaments);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load tournaments");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "Unknown date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Set background to primaryBlue
      appBar: AppBar(
        title: const Text('Tournaments', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Set app bar to lightBlue
        foregroundColor: Colors.white, // Set foreground (text/icons) to white
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: accentOrange)) // Loading indicator color
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: Colors.white), // Text input color
                    decoration: InputDecoration(
                      hintText: 'Search tournaments...',
                      hintStyle:
                          TextStyle(color: Colors.white70), // Hint text color
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white70), // Icon color
                      filled: true,
                      fillColor:
                          lightBlue.withOpacity(0.5), // Text field background
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
                            color: Colors.white30), // Light border when enabled
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredTournaments.isEmpty
                      ? const Center(
                          child: Text("No tournaments found",
                              style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTournaments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tournament = _filteredTournaments[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                              color: lightBlue.withOpacity(
                                  0.7), // Card background with opacity
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                title: Text(
                                  tournament.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white, // Title text color
                                  ),
                                ),
                                subtitle: Text(
                                  "Sport: ${tournament.sportType ?? 'N/A'}  •  Starts: ${formatDate(tournament.startDate ?? '')}",
                                  style: const TextStyle(
                                    color:
                                        Colors.white70, // Subtitle text color
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: accentOrange, // Trailing icon color
                                  size: 20,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TournamentDetailPage(
                                        tournament: {
                                          'id': tournament.id,
                                          'name': tournament.name,
                                          'sportType': tournament.sportType,
                                          'startDate': tournament.startDate,
                                          // Add other fields if needed by AddPlayerPage
                                        },
                                        matchId:
                                            0, // Placeholder, adjust as needed
                                      ),
                                    ),
                                  );
                                },
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
