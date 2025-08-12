import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match_detail_page.dart';
import 'RacquetSportApp.dart';
import 'players_page.dart';
import 'add_tournament_page.dart';
import 'view_tournaments_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final Tournament tournament;
  final int matchId;
  final bool isAdmin;

  const TournamentDetailPage(
      {super.key,
      required this.tournament,
      required this.matchId,
      this.isAdmin = true});

  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

  @override
  Widget build(BuildContext context) {
    // Ensure sportType is lowercase for consistent checks
    final String sportType = tournament.sportType?.toLowerCase() ?? 'cricket';

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: primaryBlue,
        appBar: AppBar(
          title: Text(
            tournament.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: lightBlue,
          bottom: const TabBar(
            labelColor: accentOrange,
            unselectedLabelColor: Colors.white,
            indicatorColor: accentOrange,
            isScrollable: true,
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Fixtures'),
              Tab(text: 'Teams'),
              Tab(text: 'Points Table'),
              Tab(text: 'Stats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AboutTab(tournament: tournament, isAdmin: isAdmin),
            FixturesTab(tournament: tournament, isAdmin: isAdmin),
            TeamsTab(tournamentId: tournament.id),
            PointsTableTab(sportType: sportType),
            StatsTab(sportType: sportType),
          ],
        ),
      ),
    );
  }
}

class AboutTab extends StatelessWidget {
  final Tournament tournament;
  final bool isAdmin;

  const AboutTab({super.key, required this.tournament, required this.isAdmin});

  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoTile(title: 'Tournament Name', value: tournament.name),
        InfoTile(title: 'Sport Type', value: tournament.sportType ?? 'N/A'),
        InfoTile(title: 'Start Date', value: tournament.startDate ?? 'N/A'),
        InfoTile(title: 'Organizer', value: tournament.ownerName ?? 'N/A'),
        InfoTile(title: 'Location', value: tournament.location ?? 'N/A'),
        InfoTile(
          title: 'Description',
          value:
              tournament.matchDetail?.toString() ?? 'No description available.',
        ),
        const SizedBox(height: 20),
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTournamentPage(
                    tournamentId: tournament.id,
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
                    },
                    isUpdate: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Update Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
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

  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: lightBlue.withOpacity(0.7),
      child: ListTile(
        title: Text(
          title,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class FixturesTab extends StatefulWidget {
  final Tournament tournament;
  final bool isAdmin;

  const FixturesTab(
      {super.key, required this.tournament, required this.isAdmin});

  @override
  State<FixturesTab> createState() => _FixturesTabState();
}

class _FixturesTabState extends State<FixturesTab> {
  final List<Map<String, String>> fixtures = [
    {
      'matchId': '1',
      'teamA': 'Team India',
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

  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);

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
  }

  void deleteFixture(int index) {
    setState(() {
      fixtures.removeAt(index);
    });
  }

  Future<void> _showAddFixtureDialog() async {
    final venueController = TextEditingController();
    DateTime? selectedDate;
    _selectedTeamA = null;
    _selectedTeamB = null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: primaryBlue,
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
                      dropdownColor: lightBlue,
                      style: const TextStyle(color: Colors.white),
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
                      dropdownColor: lightBlue,
                      style: const TextStyle(color: Colors.white),
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
                                  primary: accentOrange,
                                  onPrimary: Colors.white,
                                  surface: lightBlue,
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: primaryBlue,
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
                        backgroundColor: lightBlue,
                        foregroundColor: Colors.white,
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
                        'matchId': (fixtures.length + 1).toString(),
                        'teamA': _selectedTeamA!.teamName,
                        'teamB': _selectedTeamB!.teamName,
                        'venue': venueController.text,
                        'date': formatter.format(selectedDate!),
                        'score': '',
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
                    backgroundColor: accentOrange,
                    foregroundColor: Colors.white,
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
    final String sportType =
        widget.tournament.sportType?.toLowerCase() ?? 'unknown';
    return Scaffold(
      backgroundColor: primaryBlue,
      body: ListView.builder(
        itemCount: fixtures.length,
        itemBuilder: (context, index) {
          final match = fixtures[index];
          final fixtureDate = formatter.parse(match['date']!);
          final isUpcoming = fixtureDate.isAfter(now);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 5,
            color: lightBlue.withOpacity(0.7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () {
                if (sportType == 'cricket') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailPage(
                        matchId: int.parse(match['matchId']!),
                        match: {
                          'match': '${match['teamA']} vs ${match['teamB']}',
                          'teamA': match['teamA'],
                          'teamB': match['teamB'],
                        },
                      ),
                    ),
                  );
                } else if (['badminton', 'tennis', 'pickleball', 'throwball']
                    .contains(sportType)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RacquetSportApp(),
                    ),
                  );
                } else if (sportType == 'football') {
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
                        matchId: match['matchId']!,
                        team1Players: team1Players,
                        team2Players: team2Players,
                        team1Name: match['teamA']!,
                        team2Name: match['teamB']!,
                      ),
                    ),
                  );
                }
              },
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                '${match['teamA']} vs ${match['teamB']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venue: ${match['venue']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${match['date']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match['score']!.isNotEmpty
                          ? 'Result: ${match['score']}'
                          : 'Status: Upcoming',
                      style: TextStyle(
                        color: match['score']!.isNotEmpty
                            ? Colors.greenAccent
                            : accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: widget.isAdmin
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        deleteFixture(index);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showAddFixtureDialog,
              backgroundColor: accentOrange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
  static const Color lightBlue = Color(0xFF3F277B);
  static const Color accentOrange = Color(0xFFF26C4F);

  List<Team> _teams = [];

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue,
      body: _teams.isEmpty
          ? const Center(
              child: Text(
                'No teams found for this tournament.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return Card(
                  color: lightBlue.withOpacity(0.7),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.teamName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Implement join team logic
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Join Team'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white70, size: 16),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlayersPage(teamId: team.id),
                                  ),
                                );
                              },
                            ),
                          ],
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

class PointsTableTab extends StatefulWidget {
  final String sportType;

  const PointsTableTab({super.key, required this.sportType});

  @override
  State<PointsTableTab> createState() => _PointsTableTabState();
}

class _PointsTableTabState extends State<PointsTableTab> {
  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);
  static const Color lightBlueWithOpacity = Color(0x603F277B);

  late List<Map<String, dynamic>> pointsData;

  @override
  void initState() {
    super.initState();
    _loadPointsData();
  }

  // A helper function to load different mock data based on sport type
  void _loadPointsData() {
    setState(() {
      if (widget.sportType == 'cricket') {
        pointsData = [
          {
            'team': 'Team Alpha',
            'wins': 5,
            'losses': 0,
            'draws': 1,
            'points': 16,
            'nrr': 1.250
          },
          {
            'team': 'Team Beta',
            'wins': 4,
            'losses': 1,
            'draws': 1,
            'points': 13,
            'nrr': 0.890
          },
          {
            'team': 'Team Gamma',
            'wins': 3,
            'losses': 2,
            'draws': 1,
            'points': 10,
            'nrr': 0.120
          },
          {
            'team': 'Team Delta',
            'wins': 2,
            'losses': 3,
            'draws': 1,
            'points': 7,
            'nrr': -0.050
          },
          {
            'team': 'Team Epsilon',
            'wins': 1,
            'losses': 4,
            'draws': 1,
            'points': 4,
            'nrr': -0.780
          },
        ];
      } else if (widget.sportType == 'football') {
        pointsData = [
          {
            'team': 'FC Dragons',
            'wins': 8,
            'losses': 2,
            'draws': 0,
            'points': 24,
            'goals_for': 25,
            'goals_against': 10
          },
          {
            'team': 'United FC',
            'wins': 7,
            'losses': 2,
            'draws': 1,
            'points': 22,
            'goals_for': 20,
            'goals_against': 12
          },
          {
            'team': 'Spartans',
            'wins': 5,
            'losses': 4,
            'draws': 1,
            'points': 16,
            'goals_for': 18,
            'goals_against': 15
          },
          {
            'team': 'Dynamo',
            'wins': 3,
            'losses': 6,
            'draws': 1,
            'points': 10,
            'goals_for': 12,
            'goals_against': 20
          },
        ];
      } else if (['badminton', 'tennis', 'pickleball', 'throwball']
          .contains(widget.sportType)) {
        pointsData = [
          {
            'team': 'Shuttle Masters',
            'wins': 6,
            'losses': 1,
            'matches_played': 7,
            'points': 12
          },
          {
            'team': 'Smash Kings',
            'wins': 5,
            'losses': 2,
            'matches_played': 7,
            'points': 10
          },
          {
            'team': 'Court Dominators',
            'wins': 4,
            'losses': 3,
            'matches_played': 7,
            'points': 8
          },
          {
            'team': 'Feather Fury',
            'wins': 2,
            'losses': 5,
            'matches_played': 7,
            'points': 4
          },
        ];
      } else {
        // Default to cricket if sport type is not recognized
        pointsData = [
          {
            'team': 'Team Alpha',
            'wins': 5,
            'losses': 0,
            'draws': 1,
            'points': 16,
            'nrr': 1.250
          },
          {
            'team': 'Team Beta',
            'wins': 4,
            'losses': 1,
            'draws': 1,
            'points': 13,
            'nrr': 0.890
          },
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns;
    List<DataRow> rows;

    if (widget.sportType == 'cricket') {
      columns = const [
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('W',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('L',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('D',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Pts',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('NRR',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = pointsData
          .map((data) => DataRow(cells: [
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['wins'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['losses'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['draws'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['points'].toString(),
                    style: const TextStyle(color: accentOrange))),
                DataCell(Text(data['nrr'].toString(),
                    style: const TextStyle(color: Colors.white70))),
              ]))
          .toList();
    } else if (widget.sportType == 'football') {
      columns = const [
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('W',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('L',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('D',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Pts',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('GF',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('GA',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = pointsData
          .map((data) => DataRow(cells: [
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['wins'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['losses'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['draws'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['points'].toString(),
                    style: const TextStyle(color: accentOrange))),
                DataCell(Text(data['goals_for'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['goals_against'].toString(),
                    style: const TextStyle(color: Colors.white70))),
              ]))
          .toList();
    } else if (['badminton', 'tennis', 'pickleball', 'throwball']
        .contains(widget.sportType)) {
      columns = const [
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('MP',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('W',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('L',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Pts',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = pointsData
          .map((data) => DataRow(cells: [
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['matches_played'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['wins'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['losses'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['points'].toString(),
                    style: const TextStyle(color: accentOrange))),
              ]))
          .toList();
    } else {
      columns = const [
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('W',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('L',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Pts',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = pointsData
          .map((data) => DataRow(cells: [
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['wins'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['losses'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['points'].toString(),
                    style: const TextStyle(color: accentOrange))),
              ]))
          .toList();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Points Table',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Card(
            color: lightBlueWithOpacity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              columnSpacing: 16.0,
              dataRowHeight: 56.0,
              headingRowHeight: 56.0,
              horizontalMargin: 12.0,
              columns: columns,
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsTab extends StatefulWidget {
  final String sportType;

  const StatsTab({super.key, required this.sportType});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  static const Color primaryBlue = Color(0xFF1A0F49);
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B);
  static const Color lightBlueWithOpacity = Color(0x603F277B);

  String _sortBy = 'most_runs'; // Default sort criteria for cricket

  List<Map<String, dynamic>> cricketStats = [
    {'player': 'Player 1', 'team': 'Team Alpha', 'runs': 250, 'wickets': 15},
    {'player': 'Player 2', 'team': 'Team Beta', 'runs': 180, 'wickets': 18},
    {'player': 'Player 3', 'team': 'Team Alpha', 'runs': 120, 'wickets': 12},
    {'player': 'Player 4', 'team': 'Team Gamma', 'runs': 300, 'wickets': 5},
    {'player': 'Player 5', 'team': 'Team Beta', 'runs': 90, 'wickets': 20},
  ];

  List<Map<String, dynamic>> footballStats = [
    {'player': 'Striker A', 'team': 'FC Dragons', 'goals': 15, 'assists': 8},
    {'player': 'Midfielder B', 'team': 'United FC', 'goals': 10, 'assists': 12},
    {'player': 'Winger C', 'team': 'FC Dragons', 'goals': 9, 'assists': 5},
    {'player': 'Defender D', 'team': 'Spartans', 'goals': 2, 'assists': 3},
  ];

  List<Map<String, dynamic>> racquetSportsStats = [
    {
      'player': 'Shuttle Master 1',
      'team': 'Shuttle Masters',
      'points': 150,
      'aces': 25
    },
    {
      'player': 'Smash King 1',
      'team': 'Smash Kings',
      'points': 120,
      'aces': 30
    },
    {
      'player': 'Shuttle Master 2',
      'team': 'Shuttle Masters',
      'points': 100,
      'aces': 15
    },
    {
      'player': 'Feather Fury 1',
      'team': 'Feather Fury',
      'points': 80,
      'aces': 10
    },
  ];

  List<Map<String, dynamic>> getSortedStats() {
    List<Map<String, dynamic>> stats;
    final String sportType = widget.sportType;

    if (sportType == 'cricket') {
      stats = List.from(cricketStats);
      if (_sortBy == 'most_runs') {
        stats.sort((a, b) => b['runs'].compareTo(a['runs']));
      } else if (_sortBy == 'most_wickets') {
        stats.sort((a, b) => b['wickets'].compareTo(a['wickets']));
      }
    } else if (sportType == 'football') {
      stats = List.from(footballStats);
      if (_sortBy == 'most_goals') {
        stats.sort((a, b) => b['goals'].compareTo(a['goals']));
      }
    } else if (['badminton', 'tennis', 'pickleball', 'throwball']
        .contains(sportType)) {
      stats = List.from(racquetSportsStats);
      if (_sortBy == 'most_points') {
        stats.sort((a, b) => b['points'].compareTo(a['points']));
      }
    } else {
      stats = [];
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sortedStats = getSortedStats();
    List<DataColumn> columns;
    List<DataRow> rows;

    if (widget.sportType == 'cricket') {
      columns = const [
        DataColumn(
            label: Text('Player',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Runs',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Wickets',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = sortedStats
          .map((data) => DataRow(cells: [
                DataCell(Text(data['player'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['runs'].toString(),
                    style: const TextStyle(color: accentOrange))),
                DataCell(Text(data['wickets'].toString(),
                    style: const TextStyle(color: accentOrange))),
              ]))
          .toList();
    } else if (widget.sportType == 'football') {
      columns = const [
        DataColumn(
            label: Text('Player',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Goals',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Assists',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = sortedStats
          .map((data) => DataRow(cells: [
                DataCell(Text(data['player'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['goals'].toString(),
                    style: const TextStyle(color: accentOrange))),
                DataCell(Text(data['assists'].toString(),
                    style: const TextStyle(color: Colors.white70))),
              ]))
          .toList();
    } else if (['badminton', 'tennis', 'pickleball', 'throwball']
        .contains(widget.sportType)) {
      columns = const [
        DataColumn(
            label: Text('Player',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Points',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Aces',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = sortedStats
          .map((data) => DataRow(cells: [
                DataCell(Text(data['player'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['points'].toString(),
                    style: const TextStyle(color: accentOrange))),
                DataCell(Text(data['aces'].toString(),
                    style: const TextStyle(color: Colors.white70))),
              ]))
          .toList();
    } else {
      columns = const [
        DataColumn(
            label: Text('Player',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
        DataColumn(
            label: Text('Team',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))),
      ];
      rows = sortedStats
          .map((data) => DataRow(cells: [
                DataCell(Text(data['player'].toString(),
                    style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['team'].toString(),
                    style: const TextStyle(color: Colors.white70))),
              ]))
          .toList();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Player Stats (${widget.sportType.toUpperCase()})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Buttons for sorting
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (widget.sportType == 'cricket') ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = 'most_runs';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _sortBy == 'most_runs' ? accentOrange : lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Most Runs'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = 'most_wickets';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _sortBy == 'most_wickets' ? accentOrange : lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Most Wickets'),
                  ),
                ],
                if (widget.sportType == 'football') ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = 'most_goals';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _sortBy == 'most_goals' ? accentOrange : lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Most Goals'),
                  ),
                ],
                if (['badminton', 'tennis', 'pickleball', 'throwball']
                    .contains(widget.sportType)) ...[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = 'most_points';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _sortBy == 'most_points' ? accentOrange : lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Most Points'),
                  ),
                ],
              ],
            ),
          ),
          Card(
            color: lightBlueWithOpacity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              columnSpacing: 16.0,
              dataRowHeight: 56.0,
              headingRowHeight: 56.0,
              horizontalMargin: 12.0,
              columns: columns,
              rows: rows,
            ),
          ),
        ],
      ),
    );
  }
}
