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
            tournament['name'],
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
            const TeamsTab(),
            const PointsTableTab(),
            const StatsTab(), // New Stats Tab Content
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

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

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
          backgroundColor: primaryBlue, // Dialog background
          title:
              const Text('Add Fixture', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            // Added SingleChildScrollView for dialog content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: teamANameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Team A Name',
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
                TextField(
                  controller: teamBNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Team B Name',
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
                            colorScheme: const ColorScheme.dark(
                              primary: accentOrange, // Header background color
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
                      selectedDate = pickedDate;
                      if (mounted) {
                        setState(() {});
                      }
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
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Get the sport type from the tournament object passed to this widget
    final String sportType =
        widget.tournament['sportType']?.toLowerCase() ?? 'unknown';

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
                              style: TextStyle(color: Colors.white70)),
                        ),
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
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

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
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      body: ListView(
        children: teamPlayers.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            color: lightBlue.withOpacity(0.7), // Card background
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading:
                  const Icon(Icons.groups, color: accentOrange), // Icon color
              title: Text(
                entry.key,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white), // Title text color
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
                          backgroundColor: primaryBlue, // Dialog background
                          title: const Text('Delete Team',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                              'Are you sure you want to delete ${entry.key}?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white70))),
                            ElevatedButton(
                              onPressed: () {
                                deleteTeam(entry.key);
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
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: accentOrange), // Icon color
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
      ),
    );
  }
}

class PointsTableTab extends StatelessWidget {
  const PointsTableTab({super.key});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

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
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                lightBlue,
                primaryBlue
              ]), // Gradient using theme colors
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
          // Ensures the DataTable is horizontally scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing:
                  60, // Increased spacing between columns for better look
              horizontalMargin: 16, // Margin from the card edges
              dataRowMinHeight: 40, // Minimum height for data rows
              dataRowMaxHeight: 60, // Maximum height for data rows
              headingRowHeight: 50, // Height for heading row
              dividerThickness: 1.5, // Thicker dividers for better separation
              decoration: BoxDecoration(
                // Added border to the table
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              headingRowColor: MaterialStateProperty.all(
                  lightBlue.withOpacity(0.5)), // Header background
              dataRowColor: MaterialStateProperty.all(Colors.white.withOpacity(
                  0.9)), // Consistent white background for data rows
              columns: pointsData[0]
                  .keys
                  .map((header) => DataColumn(
                        // Dynamically create columns
                        label: Text(
                          header
                              .toUpperCase(), // Convert to uppercase for headers
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white), // Header text color
                        ),
                      ))
                  .toList(),
              rows: pointsData.map((team) {
                return DataRow(cells: [
                  DataCell(Text(team['team'].toString(),
                      style: const TextStyle(
                          color: primaryBlue))), // Data cell text color
                  DataCell(Text(team['played'].toString(),
                      style: const TextStyle(color: primaryBlue))),
                  DataCell(Text(team['won'].toString(),
                      style: const TextStyle(color: primaryBlue))),
                  DataCell(Text(team['lost'].toString(),
                      style: const TextStyle(color: primaryBlue))),
                  DataCell(Text(team['nrr'].toString(),
                      style: const TextStyle(color: primaryBlue))),
                  DataCell(Text(team['points'].toString(),
                      style: const TextStyle(color: primaryBlue))),
                ]);
              }).toList(),
            ),
          ),
          if (pointsData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('No data available for Points Table.',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
    );
  }
}

// New StatsTab Widget - now StatefulWidget
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  // Default selected category
  String _selectedStatCategory = 'Most Runs';

  // List of available stat categories for the dropdown
  final List<String> _statCategories = [
    'Most Runs',
    'Most Fours',
    'Most Sixes',
    'Most Wickets',
    'Best Economy',
    'Best Bowlers',
    'Most Points Scored', // Added for racquet sports
  ];

  // Mock data for various stats
  final List<Map<String, dynamic>> mostRuns = const [
    {'name': 'Player Runs A', 'runs': 750},
    {'name': 'Player Runs B', 'runs': 680},
    {'name': 'Player Runs C', 'runs': 620},
  ];

  final List<Map<String, dynamic>> bestBowlers = const [
    {'name': 'Player X', 'wickets': 15, 'economy': 6.5},
    {'name': 'Player Y', 'wickets': 12, 'economy': 7.0},
    {'name': 'Player Z', 'wickets': 10, 'economy': 6.0},
  ];

  final List<Map<String, dynamic>> mostFours = const [
    {'name': 'Player A', 'fours': 50},
    {'name': 'Player B', 'fours': 45},
    {'name': 'Player C', 'fours': 40},
  ];

  final List<Map<String, dynamic>> mostSixes = const [
    {'name': 'Player D', 'sixes': 30},
    {'name': 'Player E', 'sixes': 25},
    {'name': 'Player F', 'sixes': 20},
  ];

  final List<Map<String, dynamic>> mostWickets = const [
    {'name': 'Player G', 'wickets': 18},
    {'name': 'Player H', 'wickets': 16},
    {'name': 'Player I', 'wickets': 14},
  ];

  final List<Map<String, dynamic>> bestEconomy = const [
    {'name': 'Player J', 'economy': 5.5},
    {'name': 'Player K', 'economy': 5.8},
    {'name': 'Player L', 'economy': 6.2},
  ];

  // Mock data for Most Points Scored
  final List<Map<String, dynamic>> mostPointsScored = const [
    {'name': 'Racquet Player 1', 'points': 250},
    {'name': 'Racquet Player 2', 'points': 220},
    {'name': 'Racquet Player 3', 'points': 190},
  ];

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  // Helper method to get the data based on the selected category
  List<Map<String, dynamic>> _getCurrentStatsData() {
    switch (_selectedStatCategory) {
      case 'Most Runs':
        return mostRuns;
      case 'Most Fours':
        return mostFours;
      case 'Most Sixes':
        return mostSixes;
      case 'Most Wickets':
        return mostWickets;
      case 'Best Economy':
        return bestEconomy;
      case 'Best Bowlers':
        return bestBowlers;
      case 'Most Points Scored':
        return mostPointsScored;
      default:
        return [];
    }
  }

  // Helper method to get column headers based on the selected category
  List<String> _getCurrentColumnHeaders() {
    switch (_selectedStatCategory) {
      case 'Most Runs':
        return ['Player', 'Runs'];
      case 'Most Fours':
        return ['Player', 'Fours'];
      case 'Most Sixes':
        return ['Player', 'Sixes'];
      case 'Most Wickets':
        return ['Player', 'Wickets'];
      case 'Best Economy':
        return ['Player', 'Economy'];
      case 'Best Bowlers':
        return ['Player', 'Wickets', 'Economy'];
      case 'Most Points Scored':
        return ['Player', 'Points'];
      default:
        return [];
    }
  }

  // Helper method to build DataCells based on the selected category
  List<DataCell> _getCurrentRowBuilder(Map<String, dynamic> data) {
    switch (_selectedStatCategory) {
      case 'Most Runs':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['runs'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Most Fours':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['fours'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Most Sixes':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['sixes'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Most Wickets':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['wickets'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Best Economy':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['economy'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Best Bowlers':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['wickets'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['economy'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      case 'Most Points Scored':
        return [
          DataCell(Text(data['name'].toString(),
              style: const TextStyle(color: primaryBlue))),
          DataCell(Text(data['points'].toString(),
              style: const TextStyle(color: primaryBlue))),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown for selecting stats category
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 4,
              color: lightBlue.withOpacity(0.7), // Card background
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatCategory,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: accentOrange), // Icon color
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(
                        color: Colors.orange, // Text color
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedStatCategory = newValue!;
                      });
                    },
                    items: _statCategories
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Display the selected stats section
            _buildStatsSection(
              context,
              _selectedStatCategory,
              _getCurrentStatsData(),
              _getCurrentColumnHeaders(),
              _getCurrentRowBuilder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context,
      String title,
      List<Map<String, dynamic>> data,
      List<String> columnHeaders,
      List<DataCell> Function(Map<String, dynamic>) rowBuilder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      color: lightBlue.withOpacity(0.7), // Card background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                lightBlue,
                primaryBlue
              ]), // Gradient using theme colors
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            width: double.infinity,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SingleChildScrollView(
            // Ensure horizontal scrollability for tables
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing:
                  60, // Increased spacing between columns for better look
              horizontalMargin: 16, // Margin from the card edges
              dataRowMinHeight: 40, // Minimum height for data rows
              dataRowMaxHeight: 60, // Maximum height for data rows
              headingRowHeight: 50, // Height for heading row
              dividerThickness: 1.5, // Thicker dividers for better separation
              decoration: BoxDecoration(
                // Added border to the table
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              headingRowColor: MaterialStateProperty.all(
                  lightBlue.withOpacity(0.5)), // Header background
              dataRowColor: MaterialStateProperty.all(Colors.white.withOpacity(
                  0.9)), // Consistent white background for data rows
              columns: columnHeaders
                  .map((header) => DataColumn(
                        label: Text(
                          header,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white), // Header text color
                        ),
                      ))
                  .toList(),
              rows:
                  data.map((item) => DataRow(cells: rowBuilder(item))).toList(),
            ),
          ),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('No data available for $title.',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
        ],
      ),
    );
  }
}
