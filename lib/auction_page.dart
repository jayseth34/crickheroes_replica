import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:uuid/uuid.dart'; // Required for generating unique IDs

// Custom painter to draw the angled background for player name/category
class AngledBackgroundPainter extends CustomPainter {
  final Color color;
  final double angleFactor; // Controls the angle of the cut

  AngledBackgroundPainter({required this.color, this.angleFactor = 0.95});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Define the points for the angled shape
    path.moveTo(0, 0); // Top-left
    path.lineTo(size.width * angleFactor, 0); // Top-right (slightly cut)
    path.lineTo(size.width, size.height); // Bottom-right (angled down)
    path.lineTo(
        size.width * (1 - angleFactor), size.height); // Bottom-left (angled up)
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// New Custom painter for the background lines
class LinePatternPainter extends CustomPainter {
  final Color lineColor;
  final Color backgroundColor;

  LinePatternPainter({required this.lineColor, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the background
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.1) // Subtle lines
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines from top-left to bottom-right
    double spacing = 50.0; // Spacing between lines
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), linePaint);
    }

    // Draw diagonal lines from top-right to bottom-left
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i - size.height, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AuctionPage extends StatefulWidget {
  final String tournamentName;

  const AuctionPage({required this.tournamentName, Key? key}) : super(key: key);

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  // Base URL for your simulated backend API
  final String _baseUrl = 'https://your-backend-api.com/api/Tournament';

  final Uuid _uuid = const Uuid(); // Instance to generate unique IDs

  final int basePrice = 400; // Changed to 400 PTS as per image
  int currentBid = 400; // Changed to 400 PTS as per image
  // Removed: int? previousBid;
  // Removed: int? formerBid;

  String playerName = "No Player"; // Current player being auctioned
  String playerCategory = "N/A"; // Added player category
  String? selectedTeam; // The team that currently has the highest bid
  String? soldTo; // The team the player was sold to, or 'Unsold'
  int bidIncrement = 10; // Initial bid increment value
  final TextEditingController _bidIncrementController = TextEditingController();

  String _auctionPhase =
      'setup'; // 'setup', 'mainAuction', 'unsoldAuction', 'finished'
  List<Map<String, dynamic>> _playersToAuction =
      []; // Players in current auction order
  int _currentPlayerIndex =
      0; // Index of the current player in _playersToAuction

  // Lists to store sold, unsold, and all players
  final List<Map<String, dynamic>> soldPlayers = [];
  final List<Map<String, dynamic>> unsoldPlayers = [];
  final List<Map<String, dynamic>> allPlayers = []; // List to hold all players

  // Initial list of teams (for fresh start or if not loaded from backend)
  final List<Map<String, dynamic>> _initialTeams = [
    {
      'name': 'Team A',
      'wallet': 1000,
      'logo':
          'https://placehold.co/100x100/FF5733/FFFFFF?text=Team+A', // Distinct color
    },
    {
      'name': 'Morkhiya stallions',
      'wallet': 800,
      'logo':
          'https://placehold.co/100x100/33FF57/000000?text=Stallions', // Distinct color
    },
    {
      'name': 'RSBL',
      'wallet': 600,
      'logo':
          'https://placehold.co/100x100/3357FF/FFFFFF?text=RSBL', // Distinct color
    },
    {
      'name': 'Riddhi siddhi bullions limited',
      'wallet': 600,
      'logo':
          'https://placehold.co/100x100/FF33A1/000000?text=R+S+B+L', // Distinct color
    },
    {
      'name': 'The shah and nahar cup',
      'wallet': 600,
      'logo':
          'https://placehold.co/100x100/33FFF5/000000?text=Cup', // Distinct color
    },
    {
      'name': 'Team F',
      'wallet': 600,
      'logo':
          'https://placehold.co/100x100/A133FF/FFFFFF?text=Team+F', // Distinct color
    },
  ];

  // List of participating teams with their wallets and logos (mutable)
  final List<Map<String, dynamic>> teams = [];

  // Admin mode toggle
  bool _isAdmin = true; // Set to true by default for admin functionality

  // New: Admin User ID and Current User ID for conditional access
  final String _adminUserId = '9920279905'; // The static admin mobile number
  String _currentUserId =
      '9920279905'; // Dummy current user ID, change for testing non-admin

  @override
  void initState() {
    super.initState();
    _bidIncrementController.text = bidIncrement.toString();
    _fetchInitialPlayersFromBackend(); // Ensure dummy data is always present initially
    _initializeDefaultTeams(); // Ensure default teams are present initially
    _loadAuctionStateFromBackend(); // Load persisted state, which will override if found
  }

  @override
  void dispose() {
    _bidIncrementController.dispose();
    super.dispose();
  }

  // Simulate API call to save the entire auction state to backend
  Future<void> _saveAuctionStateToBackend() async {
    final String tournamentId = widget.tournamentName;
    final String url =
        '$_baseUrl/saveAuctionState/$tournamentId'; // Example endpoint

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'auctionPhase': _auctionPhase,
          'currentPlayerIndex': _currentPlayerIndex,
          'currentBid': currentBid,
          // Removed: 'previousBid': previousBid,
          // Removed: 'formerBid': formerBid,
          'playerName': playerName,
          'playerCategory': playerCategory, // Save player category
          'selectedTeam': selectedTeam,
          'soldTo': soldTo,
          'bidIncrement': bidIncrement,
          'allPlayers': allPlayers,
          'soldPlayers': soldPlayers,
          'unsoldPlayers': unsoldPlayers,
          'teams': teams,
        }),
      );

      if (response.statusCode == 200) {
        print('Auction state saved successfully to backend for $tournamentId.');
      } else {
        print(
            'Failed to save auction state: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error saving auction state to backend: $e');
    }
  }

  // Simulate API call to update a single player's state in backend
  Future<void> _updatePlayerInBackend(
      Map<String, dynamic> playerToUpdate) async {
    final String tournamentId = widget.tournamentName;
    final String playerId =
        playerToUpdate['id'] as String; // Use the player's unique ID

    final String url = '$_baseUrl/updatePlayerStatus/$tournamentId/$playerId';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'playerId': playerId,
          'tournamentId': tournamentId,
          'isFavorite': playerToUpdate['isFavorite'],
          'status': playerToUpdate['status'], // 'Sold', 'Unsold', 'Upcoming'
          'soldPrice': playerToUpdate['soldPrice'], // Only if applicable
          'playerCategory': playerToUpdate['playerCategory'], // Update category
        }),
      );

      if (response.statusCode == 200) {
        print(
            'Player ${playerToUpdate['playerName']} updated successfully in backend.');
      } else {
        print(
            'Failed to update player: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating player in backend: $e');
    }
  }

  // Simulate API call to load the entire auction state from backend
  Future<void> _loadAuctionStateFromBackend() async {
    final String tournamentId = widget.tournamentName;
    final String url =
        '$_baseUrl/getAuctionState/$tournamentId'; // Example endpoint

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _auctionPhase = data['auctionPhase'] ?? 'setup';
          _currentPlayerIndex = data['currentPlayerIndex'] ?? 0;
          currentBid = data['currentBid'] ?? basePrice;
          // Removed: previousBid = data['previousBid'];
          // Removed: formerBid = data['formerBid'];
          playerName = data['playerName'] ?? "No Player";
          playerCategory =
              data['playerCategory'] ?? "N/A"; // Load player category
          selectedTeam = data['selectedTeam'];
          soldTo = data['soldTo'];
          bidIncrement = data['bidIncrement'] ?? 10;
          _bidIncrementController.text = bidIncrement.toString();

          allPlayers.clear();
          soldPlayers.clear();
          unsoldPlayers.clear();
          teams.clear();

          if (data['allPlayers'] is List) {
            allPlayers
                .addAll(List<Map<String, dynamic>>.from(data['allPlayers']));
          }
          if (data['soldPlayers'] is List) {
            soldPlayers
                .addAll(List<Map<String, dynamic>>.from(data['soldPlayers']));
          }
          if (data['unsoldPlayers'] is List) {
            unsoldPlayers
                .addAll(List<Map<String, dynamic>>.from(data['unsoldPlayers']));
          }
          if (data['teams'] is List) {
            teams.addAll(List<Map<String, dynamic>>.from(data['teams']));
          } else {
            _initializeDefaultTeams(); // Fallback if teams data is missing
          }

          if (_auctionPhase == 'mainAuction' && _playersToAuction.isEmpty) {
            _preparePlayersForMainAuction(shouldSaveState: false);
          } else if (_auctionPhase == 'unsoldAuction' &&
              _playersToAuction.isEmpty) {
            _preparePlayersForUnsoldAuction(shouldSaveState: false);
          }
          if (_auctionPhase == 'finished') {
            playerName = "Auction Finished!";
          }
        });
        print('Auction state loaded from backend for $tournamentId.');
      } else {
        print(
            'Failed to load auction state: ${response.statusCode} - ${response.body}');
        // Fallback to dummy data if API call fails or returns non-200
        _fetchInitialPlayersFromBackend();
        _initializeDefaultTeams();
        _saveAuctionStateToBackend(); // Save this initial state to backend
      }
    } catch (e) {
      print('Error loading auction state from backend: $e');
      // Fallback to dummy data on network error
      _fetchInitialPlayersFromBackend();
      _initializeDefaultTeams();
      _saveAuctionStateToBackend(); // Save this initial state to backend
    }
  }

  // Function to simulate fetching an initial set of players from a backend API
  void _fetchInitialPlayersFromBackend() {
    allPlayers.clear();
    final List<String> categories = [
      'Batsman',
      'Bowler',
      'All Rounder',
      'Wicketkeeper'
    ];
    for (int i = 1; i <= 15; i++) {
      allPlayers.add({
        'id': _uuid.v4(), // Generate a unique ID for each player
        'playerName': "Player $i",
        'playerCategory':
            categories[i % categories.length], // Assign a category
        'price': basePrice,
        'status': 'Upcoming',
        'isFavorite': false,
      });
    }
    // Example for AAKASH TIWARI as in the image
    allPlayers.insert(0, {
      'id': _uuid.v4(),
      'playerName': "AAKASH TIWARI",
      'playerCategory': "ALL ROUNDER",
      'price': 400, // Explicitly set for this player
      'status': 'Upcoming',
      'isFavorite': true,
    });
  }

  // Function to initialize the default teams list
  void _initializeDefaultTeams() {
    teams.clear();
    teams.addAll(_initialTeams.map((team) => Map<String, dynamic>.from(team)));
  }

  // Function to load the next player for auction from the _playersToAuction list
  void _loadNextPlayerForAuction() {
    if (_currentPlayerIndex < _playersToAuction.length) {
      final nextPlayer = _playersToAuction[_currentPlayerIndex];
      setState(() {
        playerName = nextPlayer['playerName'] as String;
        playerCategory =
            nextPlayer['playerCategory'] as String; // Load category
        currentBid = basePrice; // Reset bid for the new player
        // Removed: previousBid = null;
        // Removed: formerBid = null;
        selectedTeam = null;
        soldTo = null;
        _bidIncrementController.text =
            '10'; // Reset bid increment input to default
        bidIncrement = 10; // Reset bid increment value to default
      });
      _saveAuctionStateToBackend(); // Save state after loading next player
    } else {
      // All players for the current phase have been auctioned
      setState(() {
        playerName = "Auction Finished!";
        playerCategory = "N/A"; // Reset category
        currentBid = basePrice;
        // Removed: previousBid = null;
        // Removed: formerBid = null;
        selectedTeam = null;
        soldTo = null;
        if (_auctionPhase == 'mainAuction') {
          _auctionPhase = 'finished'; // Main auction finished
        } else if (_auctionPhase == 'unsoldAuction') {
          _auctionPhase = 'finished'; // Unsold auction finished
        }
      });
      _saveAuctionStateToBackend(); // Save state after phase finishes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All players in this phase have been auctioned!'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  // Function to prepare and sort players for the main auction
  void _preparePlayersForMainAuction({bool shouldSaveState = true}) {
    _playersToAuction =
        allPlayers.where((player) => player['status'] == 'Upcoming').toList();

    _playersToAuction.sort((a, b) {
      final aFavorite = a['isFavorite'] ?? false;
      final bFavorite = b['isFavorite'] ?? false;
      if (aFavorite && !bFavorite) return -1;
      if (!aFavorite && bFavorite) return 1;
      return (a['playerName'] as String).compareTo(b['playerName'] as String);
    });

    setState(() {
      _auctionPhase = 'mainAuction';
      _currentPlayerIndex = 0;
    });
    _loadNextPlayerForAuction(); // This will also save state
    if (shouldSaveState) {
      _saveAuctionStateToBackend(); // Save state when starting auction
    }
  }

  // Function to prepare and sort players for the unsold players auction
  void _preparePlayersForUnsoldAuction({bool shouldSaveState = true}) {
    _playersToAuction =
        allPlayers.where((player) => player['status'] == 'Unsold').toList();

    _playersToAuction.sort((a, b) =>
        (a['playerName'] as String).compareTo(b['playerName'] as String));

    setState(() {
      _auctionPhase = 'unsoldAuction';
      _currentPlayerIndex = 0;
    });
    _loadNextPlayerForAuction(); // This will also save state
    if (shouldSaveState) {
      _saveAuctionStateToBackend(); // Save state when starting unsold auction
    }
  }

  // Function to increase the current bid
  void increaseBid(String teamName) {
    final team = teams.firstWhere((t) => t['name'] == teamName);

    if (team['wallet'] < currentBid + bidIncrement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$teamName has insufficient funds!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      // Removed: formerBid = previousBid;
      // Removed: previousBid = currentBid;
      currentBid += bidIncrement; // Update current bid
      selectedTeam = teamName;
    });
  }

  // Function to show a dialog with players bought by a specific team
  void _showTeamPlayersDialog(String teamName) {
    final playersInTeam =
        soldPlayers.where((player) => player['soldTo'] == teamName).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              // Updated title to show count of players bought vs total players
              '$teamName Players (${playersInTeam.length} / ${allPlayers.length} bought)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueGrey,
              ),
            ),
          ),
          content: playersInTeam.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No players have been bought by this team yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: playersInTeam.map((player) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 2),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: Colors.deepPurple, size: 28),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player['playerName'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sold for: ${player['price']} PTS', // Changed to PTS
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to assign the player to the selected team
  void assignPlayer() {
    if (selectedTeam == null) return;

    final team = teams.firstWhere((t) => t['name'] == selectedTeam);

    if (team['wallet'] < currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedTeam has insufficient funds!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      soldTo = selectedTeam;
      team['wallet'] -= currentBid; // Deduct wallet balance

      final playerIndexInAllPlayers =
          allPlayers.indexWhere((p) => p['playerName'] == playerName);
      if (playerIndexInAllPlayers != -1) {
        allPlayers[playerIndexInAllPlayers]['status'] = 'Sold to $selectedTeam';
        allPlayers[playerIndexInAllPlayers]['soldPrice'] = currentBid;
        _updatePlayerInBackend(
            allPlayers[playerIndexInAllPlayers]); // Individual player update
      }

      soldPlayers.add({
        'playerName': playerName,
        'soldTo': selectedTeam,
        'price': currentBid,
      });
    });

    _saveAuctionStateToBackend(); // Save overall state (teams, etc.)

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Player Assigned'),
        content: Text(
            'Player sold to $selectedTeam for $currentBid PTS'), // Changed to PTS
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                refreshPlayer();
              },
              child: const Text('OK'))
        ],
      ),
    );
  }

  // Function to mark the current player as unsold
  void markUnsold() {
    setState(() {
      soldTo = 'Unsold';

      final playerIndexInAllPlayers =
          allPlayers.indexWhere((p) => p['playerName'] == playerName);
      if (playerIndexInAllPlayers != -1) {
        allPlayers[playerIndexInAllPlayers]['status'] = 'Unsold';
        _updatePlayerInBackend(
            allPlayers[playerIndexInAllPlayers]); // Individual player update
      }

      unsoldPlayers.add({
        'playerName': playerName,
        'price': basePrice,
      });
    });

    _saveAuctionStateToBackend(); // Save overall state

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Player Unsold'),
        content: const Text('Player was marked as unsold.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                refreshPlayer();
              },
              child: const Text('OK'))
        ],
      ),
    );
  }

  // Function to reset the current bid to the base price
  void resetBid() {
    setState(() {
      currentBid = basePrice;
      // Removed: previousBid = null;
      // Removed: formerBid = null;
      selectedTeam = null;
      _bidIncrementController.text = '10';
      bidIncrement = 10;
    });
    _saveAuctionStateToBackend(); // Save state after bid reset
  }

  // Function to refresh the player for the next auction round
  void refreshPlayer() {
    setState(() {
      _currentPlayerIndex++;
    });
    _loadNextPlayerForAuction(); // This will also save state
  }

  // Function to toggle favorite status of a player
  void toggleFavorite(int index) {
    setState(() {
      allPlayers[index]['isFavorite'] =
          !(allPlayers[index]['isFavorite'] ?? false);
    });
    _updatePlayerInBackend(allPlayers[index]); // Individual player update
  }

  // Function to explicitly re-fetch all players from the simulated backend
  Future<void> _refreshAllPlayersFromBackend() async {
    await _loadAuctionStateFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    bool isCurrentUserAdmin = (_currentUserId == _adminUserId);

    // Define custom colors
    const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
    const Color accentOrange = Color(0xFFF26C4F);
    const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue
    const Color darkBlue = Color(0xFF0D082A); // Even darker blue for elements
    const Color bidBoxColor = Color(0xFF2A1C63); // Color for bid display boxes

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: lightBlue, // App bar background
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // League Logo (Placeholder for now)
              Image.network(
                'https://placehold.co/40x40/FFD700/000000?text=MPL', // Example placeholder logo
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 10),
              Text(
                widget
                    .tournamentName, // e.g., "MORAGAON PREMIER LEAGUE SEASON-04 2025"
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: accentOrange, // Orange indicator for selected tab
            labelColor: Colors.white, // White text for selected tab
            unselectedLabelColor: Colors.grey, // Grey text for unselected tabs
            tabs: [
              Tab(icon: Icon(Icons.gavel), text: 'Auction'),
              Tab(icon: Icon(Icons.check_circle), text: 'Sold'),
              Tab(icon: Icon(Icons.cancel), text: 'Unsold'),
              Tab(icon: Icon(Icons.people), text: 'All Players'),
            ],
          ),
        ),
        body: Stack(
          // Use Stack to layer background and content
          children: [
            // Background with lines
            Positioned.fill(
              child: CustomPaint(
                painter: LinePatternPainter(
                  backgroundColor: primaryBlue, // The main background color
                  lineColor: lightBlue, // Color of the lines
                ),
              ),
            ),
            // Existing content (TabBarView)
            TabBarView(
              children: [
                // Tab 1: Main Auction View
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Admin/Non-Admin Toggle - Only visible to admin
                          if (isCurrentUserAdmin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Admin Mode',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Switch(
                                  value: _isAdmin,
                                  onChanged: (value) {
                                    setState(() {
                                      _isAdmin = value;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Switched to ${_isAdmin ? 'Admin' : 'Non-Admin'} Mode'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  activeColor: accentOrange,
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),

                          if (_auctionPhase == 'setup')
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isCurrentUserAdmin)
                                    Column(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed:
                                              _preparePlayersForMainAuction,
                                          icon: const Icon(Icons.play_arrow),
                                          label:
                                              const Text("Start Main Auction"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 32),
                                            textStyle:
                                                const TextStyle(fontSize: 20),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        if (unsoldPlayers.isNotEmpty)
                                          ElevatedButton.icon(
                                            onPressed:
                                                _preparePlayersForUnsoldAuction,
                                            icon: const Icon(Icons.redo),
                                            label: const Text(
                                                "Start Unsold Players Auction"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: lightBlue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 32),
                                              textStyle:
                                                  const TextStyle(fontSize: 20),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    const Text(
                                      "Auction is yet to be started.",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            )
                          else if (_auctionPhase == 'finished')
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Auction Finished!",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(height: 20),
                                  if (unsoldPlayers.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed:
                                          _preparePlayersForUnsoldAuction,
                                      icon: const Icon(Icons.redo),
                                      label: const Text(
                                          "Start Unsold Players Auction"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: lightBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 32),
                                        textStyle:
                                            const TextStyle(fontSize: 20),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _auctionPhase = 'setup';
                                        _currentPlayerIndex = 0;
                                        playerName = "No Player";
                                        playerCategory = "N/A";
                                        currentBid = basePrice;
                                        selectedTeam = null;
                                        soldTo = null;
                                        bidIncrement = 10;
                                        _bidIncrementController.text = '10';
                                        allPlayers.clear();
                                        soldPlayers.clear();
                                        unsoldPlayers.clear();
                                        _fetchInitialPlayersFromBackend();
                                        _initializeDefaultTeams();
                                      });
                                      _saveAuctionStateToBackend();
                                    },
                                    icon: const Icon(Icons.restart_alt),
                                    label: const Text("Reset All Auction Data"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 32),
                                      textStyle: const TextStyle(fontSize: 20),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                // Main Auction Display (Player Image + Details)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    bool isWideScreen =
                                        constraints.maxWidth > 600;
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Player Image Section (Left)
                                        Expanded(
                                          flex: isWideScreen ? 2 : 1,
                                          child: Container(
                                            height: isWideScreen ? 400 : 250,
                                            decoration: BoxDecoration(
                                              color: darkBlue.withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  spreadRadius: 2,
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                'https://placehold.co/400x400/CCCCCC/000000?text=PLAYER', // Placeholder for player image
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Center(
                                                  child: Icon(Icons.person,
                                                      size: 100,
                                                      color: Colors.grey[600]),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isWideScreen ? 20 : 16),
                                        // Auction Details Section (Right)
                                        Expanded(
                                          flex: isWideScreen ? 3 : 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Tournament Name (repeated from app bar for visual consistency with image)
                                              Text(
                                                widget.tournamentName
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Player Name
                                              CustomPaint(
                                                painter:
                                                    AngledBackgroundPainter(
                                                        color: accentOrange,
                                                        angleFactor: 0.9),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 12,
                                                      horizontal: 20),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'PLAYER NAME',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        playerName
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Player Category & Base Price
                                              CustomPaint(
                                                painter:
                                                    AngledBackgroundPainter(
                                                        color: lightBlue,
                                                        angleFactor: 0.9),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      vertical: 12,
                                                      horizontal: 20),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'PLAYER CATEGORY',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        playerCategory
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Text(
                                                        'BASE PRICE',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$basePrice PTS',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              // Current Bid
                                              _buildBidDisplayBox(
                                                'CURRENT BID',
                                                currentBid,
                                                Colors.greenAccent,
                                                Icons.trending_up,
                                              ),
                                              const SizedBox(height: 10),
                                              // Active Bid By
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 15),
                                                decoration: BoxDecoration(
                                                  color: bidBoxColor,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.white12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.person_pin,
                                                        color:
                                                            Colors.yellowAccent,
                                                        size: 24),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      // Use Expanded to allow text to take available space
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            'ACTIVE BID BY',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          Text(
                                                            selectedTeam ??
                                                                'N/A', // Display selected team or N/A
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  18, // Keep original font size
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines:
                                                                1, // Limit to 1 line
                                                            overflow: TextOverflow
                                                                .ellipsis, // Add ellipsis for overflow
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Bid Increment Input
                                TextField(
                                  controller: _bidIncrementController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Increase Bid By',
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: lightBlue),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: lightBlue),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                          const BorderSide(color: accentOrange),
                                    ),
                                    prefixIcon: const Icon(Icons.add,
                                        color: Colors.white70),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      bidIncrement = int.tryParse(value) ?? 10;
                                    });
                                    _saveAuctionStateToBackend();
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Teams Section (Funds Remaining)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'FUNDS REMAINING',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: teams.map((team) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_isAdmin &&
                                                isCurrentUserAdmin) {
                                              increaseBid(team['name']);
                                            } else {
                                              _showTeamPlayersDialog(
                                                  team['name']);
                                            }
                                          },
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                radius: 30,
                                                backgroundColor: Colors.white12,
                                                backgroundImage:
                                                    NetworkImage(team['logo']),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${team['wallet']} L', // Changed to L for Lacs as in image
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  team['name'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Action Buttons (Assign, Mark Unsold, Reset Bid)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: selectedTeam != null &&
                                                soldTo == null &&
                                                _isAdmin &&
                                                isCurrentUserAdmin
                                            ? assignPlayer
                                            : null,
                                        icon: const Icon(Icons.gavel),
                                        label: const Text("Assign Player"),
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty
                                              .resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(
                                                  MaterialState.disabled)) {
                                                return accentOrange
                                                    .withOpacity(0.5);
                                              }
                                              return accentOrange;
                                            },
                                          ),
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white),
                                          padding: MaterialStateProperty.all<
                                                  EdgeInsetsGeometry>(
                                              const EdgeInsets.symmetric(
                                                  vertical: 14)),
                                          shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: soldTo == null &&
                                                _isAdmin &&
                                                isCurrentUserAdmin
                                            ? markUnsold
                                            : null,
                                        icon: const Icon(Icons.cancel),
                                        label: const Text("Mark Unsold"),
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty
                                              .resolveWith<Color?>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(
                                                  MaterialState.disabled)) {
                                                return Colors.red[400]!
                                                    .withOpacity(0.5);
                                              }
                                              return Colors.red[400];
                                            },
                                          ),
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white),
                                          padding: MaterialStateProperty.all<
                                                  EdgeInsetsGeometry>(
                                              const EdgeInsets.symmetric(
                                                  vertical: 14)),
                                          shape: MaterialStateProperty.all<
                                                  OutlinedBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: soldTo == null &&
                                          _isAdmin &&
                                          isCurrentUserAdmin
                                      ? resetBid
                                      : null,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Reset Bid"),
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty
                                        .resolveWith<Color?>(
                                      (Set<MaterialState> states) {
                                        if (states
                                            .contains(MaterialState.disabled)) {
                                          return lightBlue.withOpacity(0.5);
                                        }
                                        return lightBlue;
                                      },
                                    ),
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    padding: MaterialStateProperty.all<
                                            EdgeInsetsGeometry>(
                                        const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 24)),
                                    shape: MaterialStateProperty.all<
                                            OutlinedBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'MPL PLAYER AUCTION 2025',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab 2: Sold Players List
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: soldPlayers.isEmpty
                        ? const Center(
                            child: Text(
                              'No players sold yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: soldPlayers.length,
                            itemBuilder: (context, index) {
                              final player = soldPlayers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: lightBlue
                                    .withOpacity(0.7), // Card background
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player['playerName'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Sold to: ${player['soldTo']} for ${player['price']} PTS', // Changed to PTS
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // Tab 3: Unsold Players List
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: unsoldPlayers.isEmpty
                        ? const Center(
                            child: Text(
                              'No players marked unsold yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: unsoldPlayers.length,
                            itemBuilder: (context, index) {
                              final player = unsoldPlayers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: lightBlue
                                    .withOpacity(0.7), // Card background
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.close,
                                          color: Colors.redAccent),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player['playerName'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Base Price: ${player['price']} PTS', // Changed to PTS
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // Tab 4: All Players List
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RefreshIndicator(
                      onRefresh: _refreshAllPlayersFromBackend,
                      color: accentOrange, // Refresh indicator color
                      child: allPlayers.isEmpty
                          ? const Center(
                              child: Text(
                                'No players generated yet. Pull down to refresh.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: allPlayers.length,
                              itemBuilder: (context, index) {
                                final player = allPlayers[index];
                                final isFavorite =
                                    player['isFavorite'] ?? false;
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: lightBlue
                                      .withOpacity(0.7), // Card background
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          player['status'] == 'Upcoming'
                                              ? Icons.hourglass_empty
                                              : player['status']
                                                      .startsWith('Sold')
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                          color: player['status'] == 'Upcoming'
                                              ? Colors.orange
                                              : player['status']
                                                      .startsWith('Sold')
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                player['playerName'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Category: ${player['playerCategory'] ?? 'N/A'}', // Display category
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Base Price: ${player['price']} PTS', // Changed to PTS
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              if (player['status']
                                                  .startsWith('Sold'))
                                                Text(
                                                  'Status: ${player['status']} for ${player['soldPrice']} PTS', // Changed to PTS
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                )
                                              else
                                                Text(
                                                  'Status: ${player['status']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Favorites button - Only visible to admin
                                        if (isCurrentUserAdmin)
                                          IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () =>
                                                toggleFavorite(index),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the bid display boxes
  Widget _buildBidDisplayBox(
      String label, int amount, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Color(0xFF2A1C63), // Dark blue background for bid boxes
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$amount L', // Changed to L for Lacs
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
