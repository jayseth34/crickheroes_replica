import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tournament_detail_page.dart';

class ViewTournamentsPage extends StatefulWidget {
  const ViewTournamentsPage({super.key});

  @override
  State<ViewTournamentsPage> createState() => _ViewTournamentsPageState();
}

class _ViewTournamentsPageState extends State<ViewTournamentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTournaments = [];
  List<Map<String, dynamic>> _filteredTournaments = [];
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
          final name = tournament['name']?.toLowerCase() ?? '';
          final sport = tournament['sportType']?.toLowerCase() ?? '';
          final startDate = tournament['startDate']?.toLowerCase() ?? '';
          return name.contains(query) ||
              sport.contains(query) ||
              formatDate(tournament['startDate'])
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
          _allTournaments = data.map<Map<String, dynamic>>((t) {
            return {
              'id': t['id'],
              'name': t['name'],
              'startDate': t['startDate'],
              'sportType': t['sportType'],
              'tournament': t, // full object for details page
            };
          }).toList();
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
                                  tournament['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  "Sport: ${tournament['sportType']}  •  Starts: ${formatDate(tournament['startDate'])}",
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
                                          tournament: tournament['tournament']),
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
