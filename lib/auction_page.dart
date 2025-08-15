import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final int tournamentId;
  const AuctionPage(
      {required this.tournamentName, required this.tournamentId, Key? key})
      : super(key: key);

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  // Define custom colors at the class level to be accessible everywhere
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F);
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue
  static const Color darkBlue =
      Color(0xFF0D082A); // Even darker blue for elements
  static const Color bidBoxColor =
      Color(0xFF2A1C63); // Color for bid display boxes

  // Base URL for your simulated backend API
  final String _baseUrl = 'https://sportsdecor.somee.com/api/Tournament';

  final Uuid _uuid = const Uuid(); // Instance to generate unique IDs

  final int basePrice = 400; // Changed to 400 PTS as per image
  int currentBid = 400; // Changed to 400 PTS as per image

  String playerName = "No Player"; // Current player being auctioned
  String playerCategory = "N/A"; // Added player category
  String playerImageUrl =
      'https://placehold.co/100x100/333333/FFFFFF?text=Player'; // Placeholder for player image
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

  // List of participating teams with their wallets and logos (mutable)
  final List<Map<String, dynamic>> teams = [];

  // Admin mode toggle
  bool _isAdmin = false;
  bool _isActualAdmin = false;

  // New: Admin User ID and Current User ID for conditional access
  static const String _adminUserId =
      '9920279905'; // The static admin mobile number
  String _currentUserId =
      ''; // Dummy current user ID, change for testing non-admin
  String _storedMobileNumber = '';

  @override
  void initState() {
    super.initState();
    _bidIncrementController.text = bidIncrement.toString();
    _loadStoredMobileNumber(); // Load the mobile number from SharedPreferences
    // Load initial state from backend after getting the mobile number
    _loadAuctionStateFromBackend();
  }

  @override
  void dispose() {
    _bidIncrementController.dispose();
    super.dispose();
  }

  // --- NEW: FUNCTION TO LOAD STORED MOBILE NUMBER ---
  void _loadStoredMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNumber = prefs.getString('mobileNumber');
    if (storedNumber != null) {
      setState(() {
        _storedMobileNumber = storedNumber;
        _currentUserId = storedNumber;
        _isAdmin = storedNumber ==
            _adminUserId; // Check if the stored number is the admin number
        _isActualAdmin = storedNumber == _adminUserId;
      });
    } else {
      // If no number is stored, default to a non-admin state
      setState(() {
        _isAdmin = false;
        _currentUserId = '';
      });
    }
  }

  // --- FUNCTION TO FETCH TEAMS FROM API ---
  Future<void> _fetchTeamsFromApi() async {
    final String url =
        'https://localhost:7116/api/Team/GetAllTeamsByTournamentId?id=${widget.tournamentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> teamData = json.decode(response.body);
        setState(() {
          teams.clear();
          for (var teamJson in teamData) {
            teams.add({
              'id': teamJson['id'],
              'players_per_team': teamJson['players_per_team'] ??
                  10, // Default to 10 if not provided
              'name': teamJson['team_name'],
              'wallet': teamJson['team_wallet_balance'],
              'logo': teamJson['logo_url'], // The URL is a base64 string
            });
          }
        });
        print('Teams loaded successfully from API.');
      } else {
        print('Failed to load teams from API: ${response.statusCode}');
        _showSnackbar('Failed to load teams from API. Please try again later.');
      }
    } catch (e) {
      print('Error fetching teams from API: $e');
      _showSnackbar('Error fetching teams. Please check your connection.');
    }
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
            _fetchTeamsFromApi(); // Fallback if teams data is missing
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
        // Fallback to fetching new data if API call fails or returns non-200
        _fetchInitialPlayersFromBackend();
        _fetchTeamsFromApi(); // Fallback to fetching teams from API
        _saveAuctionStateToBackend(); // Save this initial state to backend
      }
    } catch (e) {
      print('Error loading auction state from backend: $e');
      // Fallback to fetching new data on network error
      _fetchInitialPlayersFromBackend();
      _fetchTeamsFromApi(); // Fallback to fetching teams from API
      _saveAuctionStateToBackend(); // Save this initial state to backend
    }
  }

  // Function to fetch players from the new backend API
  Future<void> _fetchInitialPlayersFromBackend() async {
    final String url =
        'https://localhost:7116/api/Player/GetAllPlayersByTourId/${widget.tournamentId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> playerData = json.decode(response.body);
        setState(() {
          allPlayers.clear();
          for (var playerJson in playerData) {
            allPlayers.add({
              'id': playerJson['id'].toString(), // Use id from API
              'playerName': playerJson['name'], // Map 'name' to 'playerName'
              'playerCategory':
                  playerJson['role'], // Map 'role' to 'playerCategory'
              'price': playerJson['isSold']
                  ? 0
                  : basePrice, // Assuming base price for unsold
              'status': playerJson['isSold']
                  ? 'Sold'
                  : 'Upcoming', // Map 'isSold' to 'status'
              'isFavorite':
                  false, // No 'isFavorite' in API, so default to false
              'imageUrl': playerJson['profileImage'] ??
                  'https://placehold.co/100x100/333333/FFFFFF?text=Player',
            });
          }
        });
        print('Players loaded successfully from API.');
      } else {
        print('Failed to load players from API: ${response.statusCode}');
        _showSnackbar(
            'Failed to load players from API. Please try again later.');
        // _initializeDefaultPlayers(); // Fallback to a dummy function if needed for testing
      }
    } catch (e) {
      print('Error fetching players from API: $e');
      _showSnackbar('Error fetching players. Please check your connection.');
      // _initializeDefaultPlayers(); // Fallback on error if needed for testing
    }
  }

  // Helper function for showing snackbars
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Function to load the next player for auction from the _playersToAuction list
  void _loadNextPlayerForAuction() {
    if (_currentPlayerIndex < _playersToAuction.length) {
      final nextPlayer = _playersToAuction[_currentPlayerIndex];
      setState(() {
        playerName = nextPlayer['playerName'] as String;
        playerCategory =
            nextPlayer['playerCategory'] as String; // Load category
        playerImageUrl = nextPlayer['imageUrl'] as String? ??
            'https://placehold.co/100x100/333333/FFFFFF?text=Player';
        currentBid = basePrice; // Reset bid for the new player
        selectedTeam = null;
        soldTo = null;
        // The bid increment field will keep its last value
      });
      _saveAuctionStateToBackend(); // Save state after loading next player
    } else {
      // All players for the current phase have been auctioned
      setState(() {
        playerName = "Auction Finished!";
        playerCategory = "N/A"; // Reset category
        playerImageUrl = 'https://placehold.co/100x100/333333/FFFFFF?text=Done';
        currentBid = basePrice;
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
    // Only allow admin to increase bid
    if (!_isAdmin) {
      _showSnackbar('Only the admin can increase bids.');
      return;
    }

    final team = teams.firstWhere((t) => t['name'] == teamName);
    final playersBoughtCount =
        soldPlayers.where((player) => player['soldTo'] == teamName).length;
    final playersPerTeamLimit = team['players_per_team'] as int;

    // Check if the team has reached its player limit
    if (playersBoughtCount >= playersPerTeamLimit) {
      _showSnackbar(
          '$teamName has reached its player limit of $playersPerTeamLimit!');
      return;
    }

    // Use a try-catch to handle potential parsing errors from the input field
    int increment;
    try {
      increment = int.parse(_bidIncrementController.text);
    } catch (e) {
      _showSnackbar('Invalid bid increment. Please enter a number.');
      return;
    }

    if (team['wallet'] < currentBid + increment) {
      _showSnackbar('$teamName has insufficient funds!');
      return;
    }
    setState(() {
      currentBid += increment; // Update current bid
      selectedTeam = teamName;
    });
    _saveAuctionStateToBackend(); // Save state after bid
  }

  // New API call to fetch a team's players
  Future<List<Map<String, dynamic>>> _fetchTeamPlayers(int teamId) async {
    final String url =
        'https://localhost:7116/api/Player/GetPlayerListByTeam/$teamId';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> playerData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(playerData);
      } else {
        throw Exception('Failed to load team players from API.');
      }
    } catch (e) {
      print('Error fetching team players: $e');
      return []; // Return an empty list on error
    }
  }

  // Function to show a dialog with players bought by a specific team
  void _showTeamPlayersDialog(String teamName, int teamId) {
    final team = teams.firstWhere((t) => t['name'] == teamName);
    final playersPerTeamLimit = team['players_per_team'] as int;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              '$teamName Players',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueGrey,
              ),
            ),
          ),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTeamPlayers(teamId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SizedBox(
                  height: 100,
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              } else if (snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No players have been bought by this team yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              } else {
                final playersInTeam = snapshot.data!;
                final boughtCount = playersInTeam.length;
                return SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Players: ($boughtCount/$playersPerTeamLimit)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playersInTeam.length,
                          itemBuilder: (context, index) {
                            final player = playersInTeam[index];
                            final soldPrice = soldPlayers.firstWhere(
                              (p) => p['playerName'] == player['name'],
                              orElse: () => {'price': 'N/A'},
                            )['price'];
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
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(player[
                                              'profileImage'] ??
                                          'https://placehold.co/100x100/333333/FFFFFF?text=Player'),
                                      radius: 20,
                                      backgroundColor: Colors.transparent,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Role: ${player['role']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (soldPrice != 'N/A')
                                            Text(
                                              'Sold for: $soldPrice PTS',
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
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
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
    if (selectedTeam == null) {
      _showSnackbar('No team has bid yet!');
      return;
    }
    final team = teams.firstWhere((t) => t['name'] == selectedTeam);
    final playersBoughtCount =
        soldPlayers.where((player) => player['soldTo'] == selectedTeam).length;
    final playersPerTeamLimit = team['players_per_team'] as int;

    // Final check for player limit before assigning
    if (playersBoughtCount >= playersPerTeamLimit) {
      _showSnackbar(
          '$selectedTeam has reached its player limit of $playersPerTeamLimit!');
      return;
    }

    if (team['wallet'] < currentBid) {
      _showSnackbar('$selectedTeam has insufficient funds!');
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
        'imageUrl': playerImageUrl,
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
        'imageUrl': playerImageUrl,
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
      selectedTeam = null;
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: lightBlue, // App bar background
          foregroundColor: Colors.white,
          title: Text(
            widget.tournamentName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            // Admin-only toggle button
            if (_isActualAdmin)
              Row(
                children: [
                  const Text(
                    'Admin Mode',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Switch(
                    value: _isAdmin,
                    onChanged: (value) {
                      setState(() {
                        _isAdmin = value;
                      });
                    },
                    activeColor: accentOrange,
                  ),
                ],
              ),
          ],
          bottom: const TabBar(
            labelColor: accentOrange,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentOrange,
            tabs: [
              Tab(text: 'Auction'),
              Tab(text: 'All'),
              Tab(text: 'Sold'),
              Tab(text: 'Unsold'),
            ],
          ),
        ),
        body: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: LinePatternPainter(
                lineColor: primaryBlue,
                backgroundColor: darkBlue,
              ),
            ),
            TabBarView(
              children: [
                _buildAuctionView(),
                _buildPlayersTab('All'),
                _buildPlayersTab('Sold'),
                _buildPlayersTab('Unsold'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionView() {
    // If auction is not started, show the 'Start Auction' button (only for admin)
    if (_auctionPhase == 'setup' && _isAdmin) {
      return Center(
        child: ElevatedButton(
          onPressed: () => _preparePlayersForMainAuction(),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          child: const Text(
            'Start Main Auction',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    if (_auctionPhase == 'finished' || playerName == "Auction Finished!") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Auction Finished!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (unsoldPlayers.isNotEmpty && _isAdmin)
              ElevatedButton(
                onPressed: () => _preparePlayersForUnsoldAuction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: const Text(
                  'Start Unsold Players Auction',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // The main auction view logic, now with responsive layout.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a different layout for wide screens (e.g., web)
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildPlayerInfoSection(),
              ),
              Expanded(
                flex: 1,
                child: _buildTeamBiddingSection(isWideScreen: true),
              ),
            ],
          );
        } else {
          // Keep the existing mobile-first layout for smaller screens
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: _buildPlayerInfoSection(),
              ),
              Expanded(
                flex: 1,
                child: _buildTeamBiddingSection(isWideScreen: false),
              ),
            ],
          );
        }
      },
    );
  }

  // Extracted Player Info Section for reusability
  Widget _buildPlayerInfoSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (playerImageUrl != null)
            CircleAvatar(
              backgroundImage: NetworkImage(playerImageUrl),
              radius: 60,
              backgroundColor: Colors.transparent,
            ),
          const SizedBox(height: 20),
          Text(
            playerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Category: $playerCategory',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Current Bid:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ),
          Text(
            '$currentBid PTS',
            style: const TextStyle(
              color: accentOrange,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (selectedTeam != null)
            Text(
              'Highest Bid by: $selectedTeam',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_isAdmin)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Bid Increment:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bidIncrementController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: lightBlue.withOpacity(0.5),
                      hintText: 'Enter increment amount',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        bidIncrement = int.tryParse(value) ?? 10;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Extracted Team Bidding Section for reusability
  Widget _buildTeamBiddingSection({required bool isWideScreen}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          if (isWideScreen)
            // Wide screen layout (using GridView that can scroll vertically)
            Expanded(
              child: GridView.builder(
                itemCount: teams.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150, // Max width of each team item
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final teamName = team['name'] as String;
                  final teamId = team['id'] as int;
                  final teamLogo = team['logo'] as String;
                  final playersBoughtCount = soldPlayers
                      .where((player) => player['soldTo'] == teamName)
                      .length;
                  final playersPerTeamLimit = team['players_per_team'] as int;
                  final isTeamFull = playersBoughtCount >= playersPerTeamLimit;
                  final isBiddable = _isAdmin && !isTeamFull;

                  return GestureDetector(
                    onTap: isBiddable
                        ? () => increaseBid(teamName)
                        : _isAdmin
                            ? () => _showSnackbar(
                                '$teamName has reached its player limit!')
                            : () => _showTeamPlayersDialog(teamName, teamId),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedTeam == teamName
                                  ? accentOrange
                                  : Colors.transparent,
                              width: selectedTeam == teamName ? 3.0 : 0.0,
                            ),
                            boxShadow: selectedTeam == teamName
                                ? [
                                    BoxShadow(
                                      color: accentOrange.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                    )
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(teamLogo),
                            backgroundColor:
                                isTeamFull ? Colors.white10 : lightBlue,
                            radius: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teamName,
                          style: TextStyle(
                            color: isTeamFull ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${team['wallet']} PTS',
                          style: TextStyle(
                            color: isTeamFull ? Colors.white38 : Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        if (isTeamFull && _isAdmin)
                          const Text(
                            'FULL',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            // Mobile layout (using horizontally scrollable row)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: teams.map((team) {
                  final teamName = team['name'] as String;
                  final teamId = team['id'] as int;
                  final teamLogo = team['logo'] as String;
                  final playersBoughtCount = soldPlayers
                      .where((player) => player['soldTo'] == teamName)
                      .length;
                  final playersPerTeamLimit = team['players_per_team'] as int;
                  final isTeamFull = playersBoughtCount >= playersPerTeamLimit;
                  final isBiddable = _isAdmin && !isTeamFull;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: isBiddable
                          ? () => increaseBid(teamName)
                          : _isAdmin
                              ? () => _showSnackbar(
                                  '$teamName has reached its player limit!')
                              : () => _showTeamPlayersDialog(teamName, teamId),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedTeam == teamName
                                    ? accentOrange
                                    : Colors.transparent,
                                width: selectedTeam == teamName ? 3.0 : 0.0,
                              ),
                              boxShadow: selectedTeam == teamName
                                  ? [
                                      BoxShadow(
                                        color: accentOrange.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                      )
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(teamLogo),
                              backgroundColor:
                                  isTeamFull ? Colors.white10 : lightBlue,
                              radius: 30,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teamName,
                            style: TextStyle(
                              color: isTeamFull ? Colors.white38 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${team['wallet']} PTS',
                            style: TextStyle(
                              color:
                                  isTeamFull ? Colors.white38 : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          if (isTeamFull && _isAdmin)
                            const Text(
                              'FULL',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const Spacer(), // Pushes the buttons to the bottom
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: assignPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text('Sell Player',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: markUnsold,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text('Mark Unsold',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: refreshPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    child: const Text('Next Player',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Widget to build the players list tab
  Widget _buildPlayersTab(String status) {
    List<Map<String, dynamic>> displayedPlayers = [];
    if (status == 'All') {
      displayedPlayers = allPlayers;
    } else if (status == 'Sold') {
      displayedPlayers = soldPlayers;
    } else if (status == 'Unsold') {
      displayedPlayers = unsoldPlayers;
    }

    return RefreshIndicator(
      onRefresh: _refreshAllPlayersFromBackend,
      color: accentOrange,
      backgroundColor: primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: displayedPlayers.length,
          itemBuilder: (context, index) {
            final player = displayedPlayers[index];
            return Card(
              color: lightBlue.withOpacity(0.8), // Semi-transparent background
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: const BorderSide(color: Colors.white10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentOrange,
                  backgroundImage: NetworkImage(player['imageUrl'] ??
                      'https://placehold.co/100x100/333333/FFFFFF?text=Player'),
                  radius: 25,
                ),
                title: Text(
                  player['playerName'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Text(
                  player['playerCategory'],
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The favorite button is visible to all, but only admin can update
                    if (status == 'All' && _isAdmin)
                      IconButton(
                        icon: Icon(
                          (player['isFavorite'] ?? false)
                              ? Icons.star
                              : Icons.star_border,
                          color: (player['isFavorite'] ?? false)
                              ? accentOrange
                              : Colors.white70,
                        ),
                        onPressed: () {
                          // Only allow admin to toggle favorite status
                          if (_isAdmin) {
                            toggleFavorite(index);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Only the admin can mark players as favorite.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    Text(
                      player['status'] == 'Sold to ${player['soldTo']}'
                          ? 'Sold for: ${player['soldPrice']}'
                          : player['status'],
                      style: TextStyle(
                        color: player['status'] == 'Unsold'
                            ? Colors.redAccent
                            : player['status'].startsWith('Sold')
                                ? Colors.greenAccent
                                : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
