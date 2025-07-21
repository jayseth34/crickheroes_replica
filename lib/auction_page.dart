import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:uuid/uuid.dart'; // Required for generating unique IDs
// Removed: import 'package:url_launcher/url_launcher.dart'; // No longer needed as WhatsApp integration is removed

class AuctionPage extends StatefulWidget {
  final String tournamentName;

  const AuctionPage({required this.tournamentName, Key? key}) : super(key: key);

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  // Base URL for your simulated backend API
  // In a real application, this would be your actual backend URL.
  // For this example, we'll use a placeholder that won't actually work without a backend.
  final String _baseUrl = 'https://your-backend-api.com/api/Tournament';
  // Removed: _whatsAppApiUrl as WhatsApp integration is removed.

  final Uuid _uuid = const Uuid(); // Instance to generate unique IDs

  final int basePrice = 100;
  int currentBid = 100;
  String playerName = "No Player"; // Current player being auctioned
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
      'logo': 'https://via.placeholder.com/100/FF0000/FFFFFF?text=A',
    },
    {
      'name': 'Morkhiya stallions',
      'wallet': 800,
      'logo': 'https://via.placeholder.com/100/00FF00/FFFFFF?text=B',
    },
    {
      'name': 'RSBL',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'Riddhi siddhi bullions limited',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'The shah and nahar cup',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
    },
    {
      'name': 'Team F',
      'wallet': 600,
      'logo': 'https://via.placeholder.com/100/0000FF/FFFFFF?text=C',
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
          'playerName': playerName,
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

    // Example endpoint for saving favorite status
    // User provided: 'https://sportsdecor.somee.com/api/Tournament/saveFavouritesplayer/$id'
    // Adapting for generic player status update
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
          // Add any other relevant player fields you want to save individually
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
  // This is called when no existing state is found for a tournament or on API load failure.
  void _fetchInitialPlayersFromBackend() {
    // Clear existing players to ensure a fresh "fetch" or default set
    allPlayers.clear();
    for (int i = 1; i <= 15; i++) {
      allPlayers.add({
        'id': _uuid.v4(), // Generate a unique ID for each player
        'playerName': "Player $i",
        'price': basePrice,
        'status': 'Upcoming',
        'isFavorite': false,
      });
    }
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
        currentBid = basePrice; // Reset bid for the new player
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

    // Optionally sort unsold players (e.g., by name or original order)
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
      currentBid += bidIncrement;
      selectedTeam = teamName;
    });
    // Removed _saveAuctionStateToBackend() call here as per request.
  }

  // Removed: _launchWhatsApp function as WhatsApp integration is removed.

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
              '$teamName Players',
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
                                      'Sold for: ₹${player['price']}',
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
      team['wallet'] -= currentBid;

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
        content: Text('Player sold to $selectedTeam for ₹$currentBid'),
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
    // This function will now attempt to load the full state from the backend.
    // The _loadAuctionStateFromBackend already handles fetching all players
    // and falling back to dummy data if the fetch fails or returns empty.
    await _loadAuctionStateFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the current user is an admin
    bool isCurrentUserAdmin = (_currentUserId == _adminUserId);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Auction - ${widget.tournamentName}'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.gavel), text: 'Auction'),
              Tab(icon: Icon(Icons.check_circle), text: 'Sold'),
              Tab(icon: Icon(Icons.cancel), text: 'Unsold'),
              Tab(icon: Icon(Icons.people), text: 'All Players'),
            ],
          ),
        ),
        body: TabBarView(
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
                            const Text('Admin Mode'),
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
                            ),
                          ],
                        ),
                      const SizedBox(height: 10), // Spacing below the switch
                      if (_auctionPhase == 'setup') // Auction is in setup phase
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCurrentUserAdmin) // Admin sees start buttons
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _preparePlayersForMainAuction,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text("Start Main Auction"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 32),
                                        textStyle:
                                            const TextStyle(fontSize: 20),
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
                                          backgroundColor: Colors.orangeAccent,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 32),
                                          textStyle:
                                              const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                  ],
                                )
                              else // Non-admin sees "Auction is yet to be started"
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
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              if (unsoldPlayers
                                  .isNotEmpty) // Only show if there are unsold players
                                ElevatedButton.icon(
                                  onPressed: _preparePlayersForUnsoldAuction,
                                  icon: const Icon(Icons.redo),
                                  label: const Text(
                                      "Start Unsold Players Auction"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 32),
                                    textStyle: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _auctionPhase =
                                        'setup'; // Go back to setup to restart
                                    _currentPlayerIndex = 0;
                                    playerName = "No Player";
                                    currentBid = basePrice;
                                    selectedTeam = null;
                                    soldTo = null;
                                    bidIncrement = 10;
                                    _bidIncrementController.text = '10';
                                    allPlayers.clear();
                                    soldPlayers.clear();
                                    unsoldPlayers.clear();
                                    _fetchInitialPlayersFromBackend(); // Re-initialize all players
                                    _initializeDefaultTeams(); // Re-initialize teams
                                  });
                                  _saveAuctionStateToBackend(); // Save the reset state
                                },
                                icon: const Icon(Icons.restart_alt),
                                label: const Text("Reset All Auction Data"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 32),
                                  textStyle: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                        )
                      else // Auction is ongoing (main or unsold)
                        Column(
                          children: [
                            // Current Player Card
                            Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundImage: NetworkImage(
                                          'https://via.placeholder.com/150'),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      playerName,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Base Price: ₹$basePrice',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Current Bid: ₹$currentBid',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Bid Increment Input
                            TextField(
                              controller: _bidIncrementController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Increase Bid By',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.add),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  bidIncrement = int.tryParse(value) ?? 10;
                                });
                                _saveAuctionStateToBackend(); // Save state after bid increment change
                              },
                            ),
                            const SizedBox(height: 24),

                            // Teams Section
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Teams (Tap to Interact)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: teams.map((team) {
                                final isSelected = team['name'] == selectedTeam;
                                return GestureDetector(
                                  onTap: () {
                                    if (_isAdmin && isCurrentUserAdmin) {
                                      // Only admin can bid when in admin mode
                                      increaseBid(team['name']);
                                    } else {
                                      // Non-admin users or admin in non-admin mode see players
                                      _showTeamPlayersDialog(team['name']);
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: isSelected ? 36 : 32,
                                        backgroundColor: isSelected
                                            ? Colors.amber
                                            : Colors.transparent,
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundImage:
                                              NetworkImage(team['logo']),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 80,
                                        child: Tooltip(
                                          message: team['name'],
                                          child: Text(
                                            team['name'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹${team['wallet']}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: selectedTeam != null &&
                                            soldTo == null &&
                                            _isAdmin &&
                                            isCurrentUserAdmin // Only admin can assign
                                        ? assignPlayer
                                        : null,
                                    icon: const Icon(Icons.gavel),
                                    label: const Text("Assign Player"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xffc5a3fb),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: soldTo == null &&
                                            _isAdmin &&
                                            isCurrentUserAdmin // Only admin can mark unsold
                                        ? markUnsold
                                        : null,
                                    icon: const Icon(Icons.cancel),
                                    label: const Text("Mark Unsold"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: soldTo == null &&
                                      _isAdmin &&
                                      isCurrentUserAdmin // Only admin can reset bid
                                  ? resetBid
                                  : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset Bid"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xfff9c4c4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
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
                    ? const Center(child: Text('No players sold yet.'))
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
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: Colors.blueGrey),
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
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sold to: ${player['soldTo']} for ₹${player['price']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
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
                    ? const Center(child: Text('No players marked unsold yet.'))
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
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Base Price: ₹${player['price']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
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
                  // Added RefreshIndicator
                  onRefresh: _refreshAllPlayersFromBackend, // Call to re-fetch
                  child: allPlayers.isEmpty
                      ? const Center(
                          child: Text(
                              'No players generated yet. Pull down to refresh.'))
                      : ListView.builder(
                          itemCount: allPlayers.length,
                          itemBuilder: (context, index) {
                            final player = allPlayers[index];
                            final isFavorite = player['isFavorite'] ?? false;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      player['status'] == 'Upcoming'
                                          ? Icons.hourglass_empty
                                          : player['status'].startsWith('Sold')
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                      color: player['status'] == 'Upcoming'
                                          ? Colors.orange
                                          : player['status'].startsWith('Sold')
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
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Base Price: ₹${player['price']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (player['status']
                                              .startsWith('Sold'))
                                            Text(
                                              'Status: ${player['status']} for ₹${player['soldPrice']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Status: ${player['status']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
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
                                        onPressed: () => toggleFavorite(index),
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
      ),
    );
  }
}
