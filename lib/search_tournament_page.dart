import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'add_team_page.dart';
import 'add_player_page.dart';
import 'auction_page.dart';

class Tournament {
  final int id;
  final String name;

  Tournament({required this.id, required this.name});

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
    );
  }
}

class SearchTournamentPage extends StatefulWidget {
  final String mode;

  const SearchTournamentPage({required this.mode, Key? key}) : super(key: key);

  @override
  State<SearchTournamentPage> createState() => _SearchTournamentPageState();
}

class _SearchTournamentPageState extends State<SearchTournamentPage> {
  final TextEditingController searchController = TextEditingController();
  List<Tournament> allTournaments = [];
  List<Tournament> filteredTournaments = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchTournaments();
    searchController.addListener(_filterTournaments);
  }

  Future<void> fetchTournaments() async {
    const apiUrl =
        'https://sportsdecor.somee.com/api/Tournament/GetAllTournaments';

    print('--- Fetching Tournaments ---');
    print('Request: GET $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('Error fetching tournaments: $e');
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
          .where((t) => t.name.toLowerCase().contains(query))
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
            ),
          ),
        );
        break;
      case 'auction':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuctionPage(
              tournamentName: tournament.name,
            ),
          ),
        );
        break;
    }
  }

  String getModeLabel() {
    switch (widget.mode) {
      case 'addTeam':
        return 'Add Teams 🏏';
      case 'addPlayer':
        return 'Add Players 👤';
      case 'auction':
        return 'Start Auction 🛎️';
      default:
        return 'Search Tournament';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getModeLabel()),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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
                          decoration: InputDecoration(
                            hintText: 'Search tournaments...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
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
                                        size: 60, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text(
                                      'No tournaments found.',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  itemCount: filteredTournaments.length,
                                  itemBuilder: (context, index) {
                                    final tournament =
                                        filteredTournaments[index];
                                    final input = searchController.text;
                                    final matchIndex = tournament.name
                                        .toLowerCase()
                                        .indexOf(input.toLowerCase());

                                    final beforeMatch = matchIndex >= 0
                                        ? tournament.name
                                            .substring(0, matchIndex)
                                        : tournament.name;
                                    final matchText = matchIndex >= 0
                                        ? tournament.name.substring(matchIndex,
                                            matchIndex + input.length)
                                        : '';
                                    final afterMatch = matchIndex >= 0
                                        ? tournament.name.substring(
                                            matchIndex + input.length)
                                        : '';

                                    return Card(
                                      color: Colors.white,
                                      elevation: 4,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.indigo,
                                          child: Icon(Icons.emoji_events,
                                              color: Colors.white),
                                        ),
                                        title: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black),
                                            children: [
                                              TextSpan(text: beforeMatch),
                                              TextSpan(
                                                text: matchText,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo),
                                              ),
                                              TextSpan(text: afterMatch),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey),
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
      ),
    );
  }
}
