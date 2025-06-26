import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'match_detail_page.dart'; // Assuming this file exists for cricket
import 'RacquetSportApp.dart'; // Import RacquetSportApp for badminton/pickleball navigation
import 'players_page.dart';
import 'add_tournament_page.dart'; // Make sure this exists

class TournamentDetailPage extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final int matchId;
  final bool isAdmin; // You can pass this as a parameter too

  const TournamentDetailPage(
      {super.key,
      required this.tournament,
      required this.matchId,
      this.isAdmin = true}); // Default isAdmin to true for testing

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            tournament['name'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.deepPurple,
          bottom: const TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'About'),
              Tab(text: 'Fixtures'),
              Tab(text: 'Teams'),
              Tab(text: 'Points Table'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AboutTab(tournament: tournament, isAdmin: isAdmin),
            // Pass the entire tournament map to FixturesTab
            FixturesTab(
                tournament:
                    tournament), // matchId no longer needed directly here
            const TeamsTab(),
            const PointsTableTab(),
          ],
        ),
      ),
    );
  }
}

class AboutTab extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final bool isAdmin;

  const AboutTab({super.key, required this.tournament, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoTile(title: 'Tournament Name', value: tournament['name']),
        // Ensure 'sportType' is fetched correctly
        InfoTile(title: 'Sport Type', value: tournament['sportType'] ?? 'N/A'),
        InfoTile(title: 'Start Date', value: tournament['startDate'] ?? 'N/A'),
        InfoTile(title: 'End Date', value: tournament['endDate'] ?? 'N/A'),
        InfoTile(title: 'Organizer', value: tournament['organizer'] ?? 'N/A'),
        InfoTile(title: 'Location', value: tournament['location'] ?? 'N/A'),
        InfoTile(
          title: 'Description',
          value: tournament['description'] ?? 'No description available.',
        ),
        const SizedBox(height: 20),
        if (isAdmin)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTournamentPage(
                    tournamentId: tournament['id'],
                    tournament: tournament,
                    isUpdate: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Update Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}

class FixturesTab extends StatefulWidget {
  final Map<String, dynamic> tournament; // Added to receive tournament data

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
  ];

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

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
    final teamANameController = TextEditingController(); // New controller
    final teamBNameController = TextEditingController(); // New controller
    final venueController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Fixture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teamANameController,
                  decoration: const InputDecoration(
                      labelText: 'Team A Name'), // New field
                ),
                TextField(
                  controller: teamBNameController,
                  decoration: const InputDecoration(
                      labelText: 'Team B Name'), // New field
                ),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
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
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (teamANameController.text.isNotEmpty &&
                    teamBNameController.text.isNotEmpty &&
                    venueController.text.isNotEmpty &&
                    selectedDate != null) {
                  final newFixture = {
                    'matchId': (fixtures.length + 1)
                        .toString(), // Simple dummy ID generation
                    'teamA': teamANameController.text,
                    'teamB': teamBNameController.text,
                    'venue': venueController.text,
                    'date': formatter.format(selectedDate!),
                    'score': '', // Score can be updated later
                  };
                  addFixture(newFixture);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please fill all fields and select a date.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Get the sport type from the tournament object passed to this widget
    final String sportType =
        widget.tournament['sportType']?.toLowerCase() ?? 'unknown';

    return Scaffold(
      body: ListView.builder(
        itemCount: fixtures.length,
        itemBuilder: (context, index) {
          final match = fixtures[index];
          final fixtureDate = formatter.parse(match['date']!);
          final isUpcoming = fixtureDate.isAfter(now);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 5,
            color: isUpcoming ? Colors.orange[100] : Colors.green[100],
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
                    sportType == 'throwball' ||
                    sportType == 'football') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RacquetSportApp(), // Navigates to the root of your racquet sport app
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
                color: isUpcoming ? Colors.orange : Colors.green,
                size: 32,
              ),
              title: Text(
                '${match['teamA']} vs ${match['teamB']}', // Display dynamic team names
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📅 ${match['date']}"),
                  Text("📍 ${match['venue']}"),
                  Text(isUpcoming
                      ? "Status: Upcoming"
                      : "📊 Score: ${match['score']}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Fixture'),
                      content: Text(
                          'Delete "${match['teamA']} vs ${match['teamB']}"?'), // Dynamic team names
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            deleteFixture(index);
                            Navigator.of(ctx).pop();
                          },
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
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  Map<String, List<String>> teamPlayers = {
    'Team A': ['Player A1', 'Player A2', 'Player A3'],
    'Team B': ['Player B1', 'Player B2'],
    'Team C': ['Player C1', 'Player C2', 'Player C3', 'Player C4'],
  };

  void deleteTeam(String teamName) {
    setState(() {
      teamPlayers.remove(teamName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: teamPlayers.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          color: Colors.lightBlue[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.groups, color: Colors.blueAccent),
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        title: const Text('Delete Team'),
                        content: Text(
                            'Are you sure you want to delete ${entry.key}?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              deleteTeam(entry.key);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayersPage(teamName: entry.key),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PointsTableTab extends StatelessWidget {
  const PointsTableTab({super.key});

  final List<Map<String, dynamic>> pointsData = const [
    {
      'team': 'Team A',
      'played': 3,
      'won': 3,
      'lost': 0,
      'nrr': '+1.25',
      'points': 6
    },
    {
      'team': 'Team B',
      'played': 3,
      'won': 2,
      'lost': 1,
      'nrr': '+0.67',
      'points': 4
    },
    {
      'team': 'Team C',
      'played': 3,
      'won': 0,
      'lost': 3,
      'nrr': '-1.10',
      'points': 0
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Center(
            child: Text(
              'Points Table',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.deepPurple[100]),
            dataRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Team')),
              DataColumn(label: Text('P')),
              DataColumn(label: Text('W')),
              DataColumn(label: Text('L')),
              DataColumn(label: Text('NRR')),
              DataColumn(label: Text('Pts')),
            ],
            rows: pointsData.map((team) {
              return DataRow(cells: [
                DataCell(Text(team['team'])),
                DataCell(Text(team['played'].toString())),
                DataCell(Text(team['won'].toString())),
                DataCell(Text(team['lost'].toString())),
                DataCell(Text(team['nrr'].toString())),
                DataCell(Text(team['points'].toString())),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
