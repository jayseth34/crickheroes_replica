import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match_detail_page.dart'; // Assuming this file exists for cricket
import 'RacquetSportApp.dart'; // Import RacquetSportApp for badminton/pickleball navigation
import 'players_page.dart';
import 'add_tournament_page.dart'; // Make sure this exists
import 'view_tournaments_page.dart'; // Import the Tournament class
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON decoding
import 'FootballScoringScreen.dart';

// Define the Team class to match your API response
class Team {
  final int id;
  final String teamName;

  Team({required this.id, required this.teamName});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      teamName: json['team_name'] as String,
    );
  }
}

class TournamentDetailPage extends StatelessWidget {
  final Tournament tournament; // Changed type from Map<String, dynamic>
  final int matchId;
  final bool isAdmin; // You can pass this as a parameter too

  const TournamentDetailPage(
      {super.key,
      required this.tournament,
      required this.matchId,
      this.isAdmin = true}); // Default isAdmin to true for testing

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Increased to 5 for the new 'Stats' tab
      child: Scaffold(
        backgroundColor: primaryBlue, // Set scaffold background
        appBar: AppBar(
          title: Text(
            tournament.name, // Access directly
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: lightBlue, // Set app bar to lightBlue
          bottom: const TabBar(
            labelColor: accentOrange, // Orange for selected tab
            unselectedLabelColor: Colors.white,
            indicatorColor: accentOrange, // Orange indicator
            isScrollable: true, // Make tabs scrollable if many
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Fixtures'),
              Tab(text: 'Teams'),
              Tab(text: 'Points Table'),
              Tab(text: 'Stats'), // New Stats Tab
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AboutTab(tournament: tournament, isAdmin: isAdmin),
            FixturesTab(tournament: tournament),
            TeamsTab(tournamentId: tournament.id),
            const PointsTableTab(),
            const StatsTab(), // New Stats Tab Content
          ],
        ),
      ),
    );
  }
}

class AboutTab extends StatelessWidget {
  final Tournament tournament; // Changed type
  final bool isAdmin;

  const AboutTab({super.key, required this.tournament, required this.isAdmin});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoTile(
            title: 'Tournament Name',
            value: tournament.name), // Access directly
        // Ensure 'sportType' is fetched correctly
        InfoTile(
            title: 'Sport Type',
            value: tournament.sportType ?? 'N/A'), // Access directly
        InfoTile(
            title: 'Start Date',
            value: tournament.startDate ?? 'N/A'), // Access directly
        InfoTile(
            title: 'Organizer',
            value: tournament.ownerName ?? 'N/A'), // Access directly
        InfoTile(
            title: 'Location',
            value: tournament.location ?? 'N/A'), // Access directly
        InfoTile(
          title: 'Description',
          value: tournament.matchDetail?.toString() ??
              'No description available.', // Assuming matchDetail is description for now
        ),
        const SizedBox(height: 20),
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTournamentPage(
                    tournamentId: tournament.id, // Access directly
                    tournament: {
                      'id': tournament.id,
                      'name': tournament.name,
                      'startDate': tournament.startDate,
                      'endDate': tournament.endDate,
                      'location': tournament.location,
                      'sportType': tournament.sportType,
                      'createdAt': tournament.createdAt,
                      'updatedAt': tournament.updatedAt,
                      'numberOfTeams': tournament.numberOfTeams,
                      'teamWalletBalance': tournament.teamWalletBalance,
                      'playersPerTeam': tournament.playersPerTeam,
                      'ownerName': tournament.ownerName,
                      'basePrice': tournament.basePrice,
                      'duration': tournament.duration,
                      'matchDetail': tournament.matchDetail,
                    }, // Pass as Map for AddTournamentPage
                    isUpdate: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Update Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange, // Use accentOrange for button
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const InfoTile({super.key, required this.title, required this.value});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: lightBlue.withOpacity(0.7), // Card background with opacity
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white), // Text color
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white70), // Subtitle text color
        ),
      ),
    );
  }
}

class FixturesTab extends StatefulWidget {
  final Tournament tournament; // Changed type

  const FixturesTab(
      {super.key, required this.tournament}); // Updated constructor

  @override
  State<FixturesTab> createState() => _FixturesTabState();
}

class _FixturesTabState extends State<FixturesTab> {
  // Sample data for fixtures. In a real app, this would likely come from a database.
  final List<Map<String, String>> fixtures = [
    {
      'matchId': '1', // Added a dummy ID for now
      'teamA': 'Team India', // Changed to separate team names
      'teamB': 'Team South Africa',
      'date': '2025-05-18',
      'venue': 'Stadium A',
      'score': '122/6 (20) - 121/8 (20)',
    },
    {
      'matchId': '2',
      'teamA': 'Team C',
      'teamB': 'Team D',
      'date': '2025-05-27',
      'venue': 'Stadium B',
      'score': '',
    },
    {
      'matchId': '3',
      'teamA': 'Player 1',
      'teamB': 'Player 2',
      'date': '2025-06-01',
      'venue': 'Court 1',
      'score': '21-15, 21-18',
    },
    {
      'matchId': '4',
      'teamA': 'Team Alpha',
      'teamB': 'Team Beta',
      'date': '2025-06-05',
      'venue': 'Arena X',
      'score': 'Upcoming',
    },
    {
      'matchId': '5',
      'teamA': 'Player A',
      'teamB': 'Player B',
      'date': '2025-06-10',
      'venue': 'Court Y',
      'score': 'Upcoming',
    },
  ];

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  List<Team> _availableTeams = [];
  Team? _selectedTeamA;
  Team? _selectedTeamB;

  @override
  void initState() {
    super.initState();
    _fetchTeamsForTournament();
  }

  Future<void> _fetchTeamsForTournament() async {
    final url = Uri.parse(
        "https://sportsdecor.somee.com/api/Team/GetAllTeamsByTournamentId?id=${widget.tournament.id}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _availableTeams = data.map((t) => Team.fromJson(t)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to load teams: Status ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching teams: ${e.toString()}")),
      );
    }
  }

  void addFixture(Map<String, String> newFixture) {
    setState(() {
      fixtures.add(newFixture);
    });
    // TODO: Implement API call to save the new fixture to your backend
    // Example:
    // final saveUrl = Uri.parse("YOUR_SAVE_FIXTURE_API_ENDPOINT");
    // await http.post(saveUrl, body: json.encode(newFixture));
  }

  void deleteFixture(int index) {
    setState(() {
      fixtures.removeAt(index);
    });
  }

  Future<void> _showAddFixtureDialog() async {
    final venueController = TextEditingController();
    DateTime? selectedDate;

    // Reset selected teams when dialog opens
    _selectedTeamA = null;
    _selectedTeamB = null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: primaryBlue, // Dialog background
              title: const Text('Add Fixture',
                  style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Team>(
                      value: _selectedTeamA,
                      hint: const Text('Select Team A',
                          style: TextStyle(color: Colors.white70)),
                      dropdownColor: lightBlue, // Dropdown background color
                      style: const TextStyle(
                          color: Colors.white), // Selected item text color
                      decoration: InputDecoration(
                        labelText: 'Team A',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightBlue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentOrange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _availableTeams
                          .where((team) => team != _selectedTeamB)
                          .map((team) => DropdownMenuItem<Team>(
                                value: team,
                                child: Text(team.teamName),
                              ))
                          .toList(),
                      onChanged: (Team? newValue) {
                        setState(() {
                          _selectedTeamA = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Team>(
                      value: _selectedTeamB,
                      hint: const Text('Select Team B',
                          style: TextStyle(color: Colors.white70)),
                      dropdownColor: lightBlue, // Dropdown background color
                      style: const TextStyle(
                          color: Colors.white), // Selected item text color
                      decoration: InputDecoration(
                        labelText: 'Team B',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightBlue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentOrange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _availableTeams
                          .where((team) => team != _selectedTeamA)
                          .map((team) => DropdownMenuItem<Team>(
                                value: team,
                                child: Text(team.teamName),
                              ))
                          .toList(),
                      onChanged: (Team? newValue) {
                        setState(() {
                          _selectedTeamB = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venueController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Venue',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightBlue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: accentOrange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary:
                                      accentOrange, // Header background color
                                  onPrimary: Colors.white, // Header text color
                                  surface: lightBlue, // Body background color
                                  onSurface: Colors.white, // Body text color
                                ),
                                dialogBackgroundColor:
                                    primaryBlue, // Dialog background
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightBlue, // Button background
                        foregroundColor: Colors.white, // Button text color
                      ),
                      child: Text(selectedDate == null
                          ? "Select Date"
                          : formatter.format(selectedDate!)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedTeamA != null &&
                        _selectedTeamB != null &&
                        venueController.text.isNotEmpty &&
                        selectedDate != null) {
                      final newFixture = {
                        'matchId': (fixtures.length + 1)
                            .toString(), // Simple dummy ID generation
                        'teamA': _selectedTeamA!.teamName,
                        'teamB': _selectedTeamB!.teamName,
                        'venue': venueController.text,
                        'date': formatter.format(selectedDate!),
                        'score': '', // Score can be updated later
                      };
                      addFixture(newFixture);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select both teams, fill venue, and select a date.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange, // Save button background
                    foregroundColor: Colors.white, // Save button text color
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Get the sport type from the tournament object passed to this widget
    final String sportType = widget.tournament.sportType?.toLowerCase() ??
        'unknown'; // Access directly

    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      body: ListView.builder(
        itemCount: fixtures.length,
        itemBuilder: (context, index) {
          final match = fixtures[index];
          final fixtureDate = formatter.parse(match['date']!);
          final isUpcoming = fixtureDate.isAfter(now);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 5,
            color: lightBlue.withOpacity(0.7), // Card background
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () {
                // Conditional redirection based on sportType
                if (sportType == 'cricket') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailPage(
                        matchId: int.parse(
                            match['matchId']!), // Pass dynamic matchId
                        match: {
                          'match': '${match['teamA']} vs ${match['teamB']}',
                          'teamA': match['teamA'], // Pass dynamic team names
                          'teamB': match['teamB'], // Pass dynamic team names
                        },
                      ),
                    ),
                  );
                } else if (sportType == 'badminton' ||
                    sportType == 'pickleball' ||
                    sportType == 'throwball') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RacquetSportApp(),
                    ),
                  );
                } else if (sportType == 'football') {
                  // Create dummy player lists for football for demonstration
                  List<String> team1Players = [
                    '${match['teamA']} Player 1',
                    '${match['teamA']} Player 2',
                    '${match['teamA']} Player 3',
                    '${match['teamA']} Player 4',
                    '${match['teamA']} Player 5',
                    '${match['teamA']} Player 6',
                    '${match['teamA']} Player 7',
                    '${match['teamA']} Player 8',
                    '${match['teamA']} Player 9',
                    '${match['teamA']} Player 10',
                    '${match['teamA']} Player 11'
                  ];
                  List<String> team2Players = [
                    '${match['teamB']} Player 1',
                    '${match['teamB']} Player 2',
                    '${match['teamB']} Player 3',
                    '${match['teamB']} Player 4',
                    '${match['teamB']} Player 5',
                    '${match['teamB']} Player 6',
                    '${match['teamB']} Player 7',
                    '${match['teamB']} Player 8',
                    '${match['teamB']} Player 9',
                    '${match['teamB']} Player 10',
                    '${match['teamB']} Player 11'
                  ];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FootballScoringScreen(
                        team1Name: match['teamA']!,
                        team2Name: match['teamB']!,
                        team1Players: team1Players,
                        team2Players: team2Players,
                        matchId: match[
                            'matchId']!, // Make sure your match data includes an ID
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Navigation not defined for $sportType fixtures.')),
                  );
                }
              },
              leading: Icon(
                isUpcoming ? Icons.schedule : Icons.check_circle,
                color: isUpcoming ? accentOrange : Colors.green, // Icon color
                size: 32,
              ),
              title: Text(
                '${match['teamA']} vs ${match['teamB']}', // Display dynamic team names
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // Title text color
              ),
              subtitle: Column(
                // Use Column to ensure text wraps
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Date: ${match['date']}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Venue: ${match['venue']}",
                      style: const TextStyle(color: Colors.white70)),
                  Text(
                      isUpcoming
                          ? "Status: Upcoming"
                          : "Score: ${match['score']}",
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: primaryBlue, // Dialog background
                      title: const Text('Delete Fixture',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                          'Delete "${match['teamA']} vs ${match['teamB']}"?', // Dynamic team names
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white70))),
                        ElevatedButton(
                          onPressed: () {
                            deleteFixture(index);
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                accentOrange, // Delete button background
                            foregroundColor:
                                Colors.white, // Delete button text color
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFixtureDialog,
        backgroundColor: accentOrange, // FAB color
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TeamsTab extends StatefulWidget {
  final int tournamentId;

  const TeamsTab({super.key, required this.tournamentId});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

  List<Team> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse(
        "https://sportsdecor.somee.com/api/Team/GetAllTeamsByTournamentId?id=${widget.tournamentId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _teams = data.map((t) => Team.fromJson(t)).toList();
        });
      } else {
        setState(() {
          _error = "Failed to load teams: Status ${response.statusCode}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching teams: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // A simple function to delete a team by id. This would need to be implemented on the backend.
  void _deleteTeam(int teamId) {
    // This is a placeholder. You would call a DELETE API here.
    // Example: await http.delete(Uri.parse("your_delete_api_url/$teamId"));
    setState(() {
      _teams.removeWhere((team) => team.id == teamId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Team deleted (placeholder)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: accentOrange));
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (_teams.isEmpty) {
      return const Center(
        child: Text(
          "No teams available for this tournament.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryBlue,
      body: ListView.builder(
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            color: lightBlue.withOpacity(0.7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.groups, color: accentOrange),
              title: Text(
                team.teamName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: primaryBlue,
                          title: const Text('Delete Team',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                              'Are you sure you want to delete ${team.teamName}?',
                              style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white70))),
                            ElevatedButton(
                              onPressed: () {
                                _deleteTeam(team.id);
                                Navigator.of(ctx).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentOrange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayersPage(teamId: team.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Placeholder for the Points Table tab
class PointsTableTab extends StatelessWidget {
  const PointsTableTab({super.key});
  static const Color primaryBlue = Color(0xFF1A0F49);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Points Table is coming soon!',
        style: TextStyle(fontSize: 18, color: Colors.white70),
      ),
    );
  }
}

// Placeholder for the Stats tab
class StatsTab extends StatelessWidget {
  const StatsTab({super.key});
  static const Color primaryBlue = Color(0xFF1A0F49);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Stats are coming soon!',
        style: TextStyle(fontSize: 18, color: Colors.white70),
      ),
    );
  }
}
