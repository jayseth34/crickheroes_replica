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

  // This method is kept for demonstration if you were using static data,
  // but the primary fetchTournaments will use the API.

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
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tournaments...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredTournaments.isEmpty
                      ? const Center(child: Text("No tournaments found"))
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                title: Text(
                                  tournament.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "Sport: ${tournament.sportType ?? 'N/A'}  •  Starts: ${formatDate(tournament.startDate ?? '')}",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.blueAccent,
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
                                          // Add other fields from the Tournament object that TournamentDetailPage expects
                                          // For example, if your Tournament class has 'endDate', 'organizer', 'location', 'description'
                                          // 'endDate': tournament.endDate,
                                          // 'organizer': tournament.organizer,
                                          // 'location': tournament.location,
                                          // 'description': tournament.description,
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
