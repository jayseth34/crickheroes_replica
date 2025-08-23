import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async'; // Required for Future and async operations
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // For JSON encoding/decoding
import 'package:signalr_core/signalr_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Scorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Using the primaryBlue for the overall theme, but specific widgets will override
        primaryColor: const Color(0xFF1A0F49),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming 'Inter' font is available or a fallback
      ),
      home: const MatchDetailPage(
        match: {
          'matchId': 1, // Using integer ID for backend API compatibility
          'teamAId': 1, // Example team ID for Team India
          'teamBId': 2, // Example team ID for Team South Africa
          'match': 'T20 Match',
          'teamA': 'Team India',
          'teamB': 'Team South Africa',
        },
        matchId: 1, // Pass dummy match data, for SignalR connection
      ),
    );
  }
}

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;
  final int matchId;

  const MatchDetailPage({Key? key, required this.match, required this.matchId})
      : super(key: key);

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _scorecardTeamTabController;

  // SignalR Hub Connection instance
  late HubConnection _hubConnection;

  // API Base URL
  final String _apiBaseUrl = "https://localhost:7116/api/Score";

  // Live match data (these are the only fields that will be updated by SignalR/GetScore API)
  int _currentRuns = 0; // Total runs for the current innings
  int _currentWickets = 0; // Total wickets for the current innings
  int _ballsInCurrentOver =
      0; // Balls bowled in the current over (0-5 for display)
  int _totalLegalBallsBowledInInnings =
      0; // Total legal balls bowled in the current innings

  // Local state (these will NOT be updated by SignalR/GetScore API as per user's request)
  int _extras = 0;
  int _partnershipRuns = 0;
  int _partnershipBalls = 0;

  bool _isFirstInnings = true;
  int _firstInningsRuns = 0;
  int _firstInningsWickets = 0;
  int _targetScore = 0;

  String? _selectedFirstBattingTeamName;
  String _currentBattingTeamName = '';
  String _currentBowlingTeamName = '';
  int _currentBattingTeamId = 0; // Team ID for API calls
  int _currentBowlingTeamId = 0; // Team ID for API calls

  List<Map<String, dynamic>> _teamABattingStats = [];
  List<Map<String, dynamic>> _teamABowlingStats = [];
  List<Map<String, dynamic>> _teamBBattingStats = [];
  List<Map<String, dynamic>> _teamBBowlingStats = [];

  List<Map<String, dynamic>> _overByOverSummary = [];
  List<Map<String, dynamic>> _ballEvents = [];

  int _activeBatsman1Index = 0;
  int _activeBatsman2Index = 1;
  int _activeBowlerIndex = 0;

  // Debounce timer for API calls
  Timer? _updateTimer;
  final Duration _debounceDuration =
      const Duration(milliseconds: 300); // Adjust as needed

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  void initState() {
    super.initState();

    _mainTabController = TabController(length: 2, vsync: this);
    _scorecardTeamTabController = TabController(length: 2, vsync: this);

    // Initialize player data. This would typically come from an API or database.
    // For this example, it's hardcoded.
    _teamABattingStats = _initializeBattingStats();
    _teamBBattingStats = _initializeBattingStatsB(); // Separate for Team B
    _teamABowlingStats = _initializeBowlingStats();
    _teamBBowlingStats = _initializeBowlingStatsB(); // Separate for Team B

    // Initialize and connect to SignalR
    _initSignalR();

    // Perform initial setup like batting team selection after the first frame
    // to ensure `context` is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSetup();
    });
  }

  // Helper function to initialize batting stats for Team A
  List<Map<String, dynamic>> _initializeBattingStats() {
    return [
      {
        'name': 'Virat Kohli',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Rohit Sharma',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Suryakumar Yadav',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Axar Patel',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Hardik Pandya',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Ravindra Jadeja',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Rishabh Pant',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Kuldeep Yadav',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Mohammed Siraj',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Jasprit Bumrah',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Arshdeep Singh',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
    ];
  }

  // Helper function to initialize batting stats for Team B
  List<Map<String, dynamic>> _initializeBattingStatsB() {
    return [
      {
        'name': 'Quinton de Kock',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Temba Bavuma',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Heinrich Klaasen',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'David Miller',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Aiden Markram',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Tristan Stubbs',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Wayne Parnell',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Kagiso Rabada',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Anrich Nortje',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Keshav Maharaj',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
      {
        'name': 'Marco Jansen',
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
        'dismissal': 'not out'
      },
    ];
  }

  // Helper function to initialize bowling stats for Team A
  List<Map<String, dynamic>> _initializeBowlingStats() {
    return [
      {
        'name': 'Jasprit Bumrah',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Hardik Pandya',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Axar Patel',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Mohammed Siraj',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Kuldeep Yadav',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Arshdeep Singh',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
    ];
  }

  // Helper function to initialize bowling stats for Team B
  List<Map<String, dynamic>> _initializeBowlingStatsB() {
    return [
      {
        'name': 'Kagiso Rabada',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Anrich Nortje',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Keshav Maharaj',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Marco Jansen',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Tabraiz Shamsi',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Gerald Coetzee',
        'overs': 0.0,
        'total_legal_balls_bowled': 0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
    ];
  }

  // Method to initialize and connect to SignalR
  Future<void> _initSignalR() async {
    const hubUrl = "https://localhost:7116/scoreHub"; // Replace with actual URL

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        // .configureLogging(LogLevel.information) // ✅ lowercase for enum
        .build();

    _hubConnection.onclose((error) {
      print("SignalR Connection Closed: $error");
    });

    try {
      await _hubConnection.start();
      print("Connected to SignalR hub");

      await _hubConnection.invoke("JoinMatchGroup", args: [widget.matchId]);
      print("Joined match group: ${widget.matchId}");

      _hubConnection.on("ReceiveScoreUpdate", (scoreData) {
        print("Live Score Update Received: $scoreData");

        if (scoreData != null && scoreData.isNotEmpty) {
          final data = scoreData[0] as Map<String, dynamic>;
          _updateScoreFromMatchEvent(data); // Use the simplified update method
        }
      });
    } catch (e) {
      print("Error connecting to SignalR hub: $e");
    }
  }

  // New method to update UI state based on received simplified MatchEvent data
  void _updateScoreFromMatchEvent(Map<String, dynamic> matchEvent) {
    setState(() {
      _currentRuns = matchEvent['runs'] ?? _currentRuns;
      _currentWickets = matchEvent['wickets'] ?? _currentWickets;
      // Convert overs (double) and balls (int) from MatchEvent to totalLegalBallsBowledInInnings
      final double overs = matchEvent['overs'] ?? 0.0;
      final int balls = matchEvent['balls'] ?? 0;
      _totalLegalBallsBowledInInnings = (overs.floor() * 6) + balls;
      _ballsInCurrentOver = balls; // Update balls in current over directly

      // Update team IDs based on the MatchEvent's TeamId, assuming it's the batting team
      _currentBattingTeamId = matchEvent['teamId'] ?? _currentBattingTeamId;
      // Determine current batting/bowling team names based on IDs
      if (_currentBattingTeamId == (widget.match['teamAId'] as int? ?? 0)) {
        _currentBattingTeamName = widget.match['teamA']?.toString() ?? 'Team A';
        _currentBowlingTeamName = widget.match['teamB']?.toString() ?? 'Team B';
        _currentBowlingTeamId = widget.match['teamBId'] as int? ?? 0;
      } else if (_currentBattingTeamId ==
          (widget.match['teamBId'] as int? ?? 0)) {
        _currentBattingTeamName = widget.match['teamB']?.toString() ?? 'Team B';
        _currentBowlingTeamName = widget.match['teamA']?.toString() ?? 'Team A';
        _currentBowlingTeamId = widget.match['teamAId'] as int? ?? 0;
      }

      debugPrint(
          "UI updated from SignalR (simplified): $_currentRuns/$_currentWickets in ${_currentOversDisplay.toStringAsFixed(1)} overs");
    });
  }

  // Debounced function to send simplified score update to backend
  void _debouncedUpdateScoreOnBackend({
    required String eventType,
    bool isMatchOver = false,
  }) {
    _updateTimer?.cancel(); // Cancel any existing timer
    _updateTimer = Timer(_debounceDuration, () {
      _updateScoreOnBackend(eventType: eventType, isMatchOver: isMatchOver);
    });
  }

  // Function to send simplified score update to backend (actual HTTP call)
  Future<void> _updateScoreOnBackend({
    required String eventType,
    bool isMatchOver = false,
  }) async {
    final int matchId = widget.matchId as int? ?? 0;

    final double oversDisplay = _currentOversDisplay;
    final int fullOvers = oversDisplay.floor();
    final int ballsInOver = (_totalLegalBallsBowledInInnings % 6);

    final Map<String, dynamic> data = {
      "matchId": matchId,
      "teamId": _currentBattingTeamId,
      "runs": _currentRuns,
      "wickets": _currentWickets,
      "overs":
          fullOvers + (ballsInOver / 10.0), // Represent overs as X.Y double
      "eventType": eventType,
      "balls": ballsInOver, // Send balls in current over
      "isMatchOver": isMatchOver,
    };

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        debugPrint('Score updated successfully: ${response.body}');
      } else {
        debugPrint(
            'Failed to update score. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating score: $e');
    }
  }

  // Function to fetch simplified score from backend
  Future<void> _fetchScoreFromBackend() async {
    final int matchId = widget.matchId as int? ?? 0;
    print("Match id: " + widget.matchId.toString());

    if (matchId == 0) {
      debugPrint("Cannot fetch score: Match ID is invalid.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_apiBaseUrl/getScore?MatchId=$matchId&TeamId=${_currentBattingTeamId}'),
        headers: {
          'Accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> scoreData = json.decode(response.body);
        _updateScoreFromMatchEvent(
            scoreData); // Use the simplified update method
        debugPrint('Score fetched successfully.');
      } else {
        debugPrint(
            'Failed to fetch score. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching score: $e');
    }
  }

  @override
  void dispose() {
    _hubConnection
        .stop(); // Stop SignalR connection when the widget is disposed
    _mainTabController.dispose();
    _scorecardTeamTabController.dispose();
    _updateTimer?.cancel(); // Cancel any pending debounce timer
    super.dispose();
  }

  // Getter to display overs in X.Y format (e.g., 2.3 for 2 overs and 3 balls)
  double get _currentOversDisplay {
    return _totalLegalBallsBowledInInnings.floor() ~/ 6 +
        (_totalLegalBallsBowledInInnings % 6) / 10.0;
  }

  Future<void> _initialSetup() async {
    String? battingTeamChoice = await _showBattingTeamSelectionDialog();
    if (battingTeamChoice == null) {
      // If user cancels, default to Team A batting first
      battingTeamChoice = widget.match['teamA']?.toString() ?? 'Team A';
    }

    setState(() {
      _selectedFirstBattingTeamName = battingTeamChoice;
      _currentBattingTeamName = _selectedFirstBattingTeamName!;
      _currentBowlingTeamName =
          (battingTeamChoice == (widget.match['teamA']?.toString() ?? 'Team A'))
              ? (widget.match['teamB']?.toString() ?? 'Team B')
              : (widget.match['teamA']?.toString() ?? 'Team A');

      _currentBattingTeamId =
          (battingTeamChoice == (widget.match['teamA']?.toString() ?? 'Team A'))
              ? (widget.match['teamAId'] as int? ?? 0)
              : (widget.match['teamBId'] as int? ?? 0);
      _currentBowlingTeamId =
          (battingTeamChoice == (widget.match['teamA']?.toString() ?? 'Team A'))
              ? (widget.match['teamBId'] as int? ?? 0)
              : (widget.match['teamAId'] as int? ?? 0);
    });

    // Fetch initial score from backend after setting team IDs
    await _fetchScoreFromBackend();

    _selectInitialPlayers();
  }

  Future<String?> _showBattingTeamSelectionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Who will bat first?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(widget.match['teamA']?.toString() ?? 'Team A'),
                onTap: () => Navigator.of(dialogContext)
                    .pop(widget.match['teamA']?.toString() ?? 'Team A'),
              ),
              ListTile(
                title: Text(widget.match['teamB']?.toString() ?? 'Team B'),
                onTap: () => Navigator.of(dialogContext)
                    .pop(widget.match['teamB']?.toString() ?? 'Team B'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showPlayerSelectionDialog({
    required String title,
    required List<Map<String, dynamic>> players,
    required List<int> excludedIndices,
    required bool isBatsman,
  }) async {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final List<Map<String, dynamic>> availablePlayers = players
            .asMap()
            .entries
            .where((entry) {
              if (excludedIndices.contains(entry.key)) {
                return false;
              }
              // For batsmen, only show players who are 'not out'
              if (isBatsman && entry.value['dismissal'] != 'not out') {
                return false;
              }
              return true;
            })
            .map((entry) => {'index': entry.key, 'player': entry.value})
            .toList();

        if (availablePlayers.isEmpty) {
          return AlertDialog(
            title: Text(title),
            content: const Text('No more available players.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('OK'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availablePlayers.map((item) {
                final int playerIndex = item['index'];
                final Map<String, dynamic> player = item['player'];
                return ListTile(
                  title: Text(player['name']?.toString() ?? 'Unknown Player'),
                  onTap: () {
                    Navigator.of(context).pop(playerIndex);
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectInitialPlayers() async {
    final List<Map<String, dynamic>> currentBattingTeam =
        (_currentBattingTeamName ==
                (widget.match['teamA']?.toString() ?? 'Team A'))
            ? _teamABattingStats
            : _teamBBattingStats;

    // Select active batsman 1 (striker)
    int? batsman1Index = await _showPlayerSelectionDialog(
      title: 'Select On-Strike Batsman for $_currentBattingTeamName',
      players: currentBattingTeam,
      excludedIndices: [],
      isBatsman: true,
    );
    if (batsman1Index == null) return; // User cancelled

    // Select active batsman 2 (non-striker)
    int? batsman2Index = await _showPlayerSelectionDialog(
      title: 'Select Non-Strike Batsman for $_currentBattingTeamName',
      players: currentBattingTeam,
      excludedIndices: [batsman1Index], // Exclude the striker
      isBatsman: true,
    );
    if (batsman2Index == null) return; // User cancelled

    setState(() {
      _activeBatsman1Index = batsman1Index;
      _activeBatsman2Index = batsman2Index;
    });

    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName ==
                (widget.match['teamA']?.toString() ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    // Select active bowler
    int? bowlerIndex = await _showPlayerSelectionDialog(
      title: 'Select Bowler for $_currentBowlingTeamName',
      players: currentBowlingTeam,
      excludedIndices: [],
      isBatsman: false,
    );
    if (bowlerIndex == null) return; // User cancelled

    setState(() {
      _activeBowlerIndex = bowlerIndex;
    });
  }

  // This method increments the ball count and updates overs. It's called for every legal delivery.
  void _processLegalBall({String eventType = 'Dot'}) {
    setState(() {
      _ballsInCurrentOver++;
      _totalLegalBallsBowledInInnings++;
      _partnershipBalls++;

      final List<Map<String, dynamic>> currentBowlingTeam =
          (_currentBowlingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABowlingStats
              : _teamBBowlingStats;
      // Increment bowler's legal balls bowled
      if (_activeBowlerIndex >= 0 &&
          _activeBowlerIndex < currentBowlingTeam.length) {
        currentBowlingTeam[_activeBowlerIndex]['total_legal_balls_bowled']++;
        _updateBowlerOversDisplay(currentBowlingTeam[_activeBowlerIndex]);
      }

      // Check for end of over
      if (_ballsInCurrentOver == 6) {
        _ballsInCurrentOver = 0; // Reset balls in current over
        _overByOverSummary.add({
          'over': (_totalLegalBallsBowledInInnings ~/ 6),
          'runs': _currentRuns,
          'wickets': _currentWickets,
        });

        _changeBowler(); // Prompt for new bowler
        _swapStrike(); // Strike changes automatically at the end of an over
      }

      _checkWinCondition();
    });
    _debouncedUpdateScoreOnBackend(eventType: eventType); // Debounced call
  }

  // Updates bowler's overs display (e.g., 2.3)
  void _updateBowlerOversDisplay(Map<String, dynamic> bowler) {
    int legalBalls = bowler['total_legal_balls_bowled'];
    bowler['overs'] =
        (legalBalls ~/ 6) + (legalBalls % 6) / 10.0; // Correct X.Y format
  }

  // Records a ball event for display in the commentary/all balls summary.
  void _recordBallEvent({
    required int batsmanRuns,
    required int
        extraRuns, // extraRuns here means runs counted towards _extras (Wide penalty etc.)
    String? extraType,
    required bool wicketTaken,
    Map<String, dynamic>? wicketDetails,
    int? totalRunsOnBall, // The total runs (batsman + extra) for this ball
  }) {
    setState(() {
      final List<Map<String, dynamic>> currentBattingTeamPlayers =
          (_currentBattingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      final List<Map<String, dynamic>> currentBowlingTeamPlayers =
          (_currentBowlingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABowlingStats
              : _teamBBowlingStats;

      // Determine batsman name for the event. If a wicket, it's the out batsman.
      // If runs are extras only (like pure wide/no ball without bat contact), it's "Extras".
      // Otherwise, it's the striker.
      String batsmanNameForEvent = '';
      if (wicketTaken) {
        batsmanNameForEvent = currentBattingTeamPlayers[_activeBatsman1Index]
                    ['name']
                ?.toString() ??
            'N/A';
      } else if (extraRuns > 0 && batsmanRuns == 0) {
        // This is for Wide/No Ball penalty where no bat contact
        batsmanNameForEvent = 'Extras';
      } else {
        batsmanNameForEvent = currentBattingTeamPlayers[_activeBatsman1Index]
                    ['name']
                ?.toString() ??
            'N/A';
      }

      _ballEvents.add({
        'over_display': _currentOversDisplay, // Use the getter for display
        'ball_in_over': _ballsInCurrentOver == 0
            ? 6
            : _ballsInCurrentOver, // Display 6 for end of over
        'batsman_runs': batsmanRuns,
        'extra_runs':
            extraRuns, // Only the 'penalty' part of extras that count towards _extras
        'extra_type': extraType,
        'wicket_taken': wicketTaken,
        'wicket_details': wicketDetails,
        'dismissal': wicketDetails?['full_dismissal_text'],
        'batsman_name': batsmanNameForEvent,
        'bowler_name':
            currentBowlingTeamPlayers[_activeBowlerIndex]['name']?.toString() ??
                'N/A',
        'total_score_after_ball':
            '$_currentRuns-${_currentWickets} (${_currentOversDisplay.toStringAsFixed(1)})',
        'total_runs_on_ball': totalRunsOnBall ?? (batsmanRuns + extraRuns),
      });
    });
  }

  // Adds runs to the score, updates player stats, and handles strike rotation.
  // totalRuns is the total increase in score for this ball.
  // batsmanRuns is specifically runs off the bat OR runs credited to batsman for byes/legbyes/no-balls.
  // extraRuns is specifically the 'extra' component that is added to _extras (e.g., 1 for wide penalty).
  void _addRuns(int totalRuns,
      {required int batsmanRuns,
      required int extraRuns, // This is for the _extras counter
      bool isBoundary = false,
      String? extraType,
      required String eventType}) {
    setState(() {
      _currentRuns += totalRuns;
      _extras += extraRuns; // Only add the 'extra' component to total extras

      final List<Map<String, dynamic>> currentBattingTeam =
          (_currentBattingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      final List<Map<String, dynamic>> currentBowlingTeam =
          (_currentBowlingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABowlingStats
              : _teamBBowlingStats;

      // Update Batsman Stats
      // batsmanRuns > 0 implies runs credited to the batsman for this ball
      if (batsmanRuns > 0) {
        final int activeBatsmanIndex = _activeBatsman1Index;
        if (activeBatsmanIndex >= 0 &&
            activeBatsmanIndex < currentBattingTeam.length) {
          currentBattingTeam[activeBatsmanIndex]['runs'] += batsmanRuns;
          // Balls faced for batsman are now incremented consistently in each button's onPressed or handler function.
          if (isBoundary) {
            if (batsmanRuns == 4) {
              currentBattingTeam[activeBatsmanIndex]['fours'] += 1;
            } else if (batsmanRuns == 6) {
              currentBattingTeam[activeBatsmanIndex]['sixes'] += 1;
            }
          }
          _updateStrikeRate(currentBattingTeam[activeBatsmanIndex]);
        }
      }

      // Update Bowler Stats (always charged for runs conceded, including extras)
      if (_activeBowlerIndex >= 0 &&
          _activeBowlerIndex < currentBowlingTeam.length) {
        if (extraType != 'Bye' && extraType != 'Leg Bye') {
          currentBowlingTeam[_activeBowlerIndex]['runs'] +=
              totalRuns; // Bowler concedes all runs
        }

        _updateEconomyRate(currentBowlingTeam[_activeBowlerIndex]);
      }

      // Partnership updates
      _partnershipRuns +=
          totalRuns; // Partnership grows by all runs on the ball
      // Partnership balls handled by _processLegalBall (for legal deliveries) or other handlers.
      print(totalRuns);
      // Strike rotation logic
      // Strike rotates after odd runs if they are from the bat, byes, leg-byes, or overthrows
      // For No Balls and Wides, the strike does NOT rotate unless the batsmen run an odd number of runs
      // after the initial penalty.
      if (totalRuns % 2 != 0 && extraType != 'Wide' && extraType != 'No Ball') {
        // Legal delivery (including Byes/Leg Byes which are now like normal runs for strike rotation)
        _swapStrike();
      } else if (extraType == 'No Ball' && totalRuns % 2 != 0) {
        // No-ball where total runs (including penalty) are odd
        _swapStrike();
      } else if (extraType == 'Wide' && totalRuns % 2 == 0) {
        // Wide where total runs (including penalty) are odd (e.g., wide + 1 bye)
        _swapStrike();
      }
      // Note: Overthrows can cause strike change if they result in an odd number of total runs
      // on the ball. Since Overthrow sets extraType: 'Overthrow', the first condition
      // `totalRuns % 2 != 0 && extraType != 'Wide' && extraType != 'No Ball'` would apply.

      _checkWinCondition();
    });
    _debouncedUpdateScoreOnBackend(eventType: eventType); // Debounced call
  }

  // Handles a wicket event, updating scores, player stats, and initiating new batsman selection.
  Future<void> _addWicket() async {
    final List<Map<String, dynamic>> currentBattingTeam =
        (_currentBattingTeamName ==
                (widget.match['teamA']?.toString() ?? 'Team A'))
            ? _teamABattingStats
            : _teamBBattingStats;
    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName ==
                (widget.match['teamA']?.toString() ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    Map<String, dynamic>? dismissalDetails = await _showWicketTypeDialog(
      batsmanName:
          currentBattingTeam[_activeBatsman1Index]['name']?.toString() ?? 'N/A',
      bowlerName:
          currentBowlingTeam[_activeBowlerIndex]['name']?.toString() ?? 'N/A',
      teamBattingStats: currentBattingTeam,
      opponentTeamPlayers: currentBowlingTeam, // Pass opponent team players
    );

    if (dismissalDetails == null) {
      return; // User cancelled wicket selection
    }

    int runsBeforeRunOut = 0;
    if (dismissalDetails['type'] == 'Run Out') {
      runsBeforeRunOut = await _showRunOutRunsDialog() ?? 0;
    }

    setState(() {
      // Determine which batsman was actually run out if 'Run Out' type selected.
      // The _showWicketTypeDialog now returns `run_out_player_index`.
      int? runOutBatsmanActualIndex = dismissalDetails['run_out_player_index'];
      if (dismissalDetails['type'] == 'Run Out' &&
          runOutBatsmanActualIndex != null) {
        // If the run-out was of the non-striker, swap the active batsman indices
        // temporarily so that the non-striker is marked out, and then swap back.
        if (runOutBatsmanActualIndex == _activeBatsman2Index) {
          int temp = _activeBatsman1Index;
          _activeBatsman1Index = _activeBatsman2Index;
          _activeBatsman2Index = temp;
        }
      }

      _currentWickets++;
      _partnershipRuns = 0; // Reset partnership on a wicket
      _partnershipBalls = 0; // Reset partnership balls

      // Add runs completed before run-out to total score and batsman's score
      _currentRuns += runsBeforeRunOut;
      if (runsBeforeRunOut > 0) {
        if (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeam.length) {
          currentBattingTeam[_activeBatsman1Index]['runs'] += runsBeforeRunOut;
        }
      }

      // Increment batsman's ball count for the ball on which they got out
      if (_activeBatsman1Index >= 0 &&
          _activeBatsman1Index < currentBattingTeam.length) {
        currentBattingTeam[_activeBatsman1Index]['balls']++;
        _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
      }

      if (_activeBatsman1Index >= 0 &&
          _activeBatsman1Index < currentBattingTeam.length) {
        currentBattingTeam[_activeBatsman1Index]['dismissal'] =
            dismissalDetails['full_dismissal_text'];
      }

      // If odd runs completed before a run-out, strike should swap
      if (runsBeforeRunOut % 2 != 0 && dismissalDetails['type'] == 'Run Out') {
        _swapStrike();
      }

      // Process the ball, only increment ballsInCurrentOver if it's a legal delivery.
      // Run outs are considered legal deliveries for ball count purposes unless they occur off a wide/no-ball.
      // Other wickets like bowled, caught also count as a ball.
      if (dismissalDetails['type'] != 'Wide' &&
          dismissalDetails['type'] != 'No Ball') {
        _processLegalBall(
            eventType:
                'Wicket'); // Only process legal ball if it's a legal delivery that results in a wicket
      } else {
        // If it's a wicket off a wide or no-ball, we still update backend but don't call _processLegalBall
        // as that increments legal ball count. The ball event will be recorded separately.
        _debouncedUpdateScoreOnBackend(eventType: 'Wicket'); // Debounced call
      }
      // Regardless of legal ball or not, bowler still gets runs conceded
      if (_activeBowlerIndex >= 0 &&
          _activeBowlerIndex < currentBowlingTeam.length) {
        currentBowlingTeam[_activeBowlerIndex]['runs'] += runsBeforeRunOut;
        _updateEconomyRate(currentBowlingTeam[_activeBowlerIndex]);
      }

      if (dismissalDetails['bowler_wicket']) {
        // Bowler gets credit for wicket only if it's a bowler-credited dismissal type
        if (_activeBowlerIndex >= 0 &&
            _activeBowlerIndex < currentBowlingTeam.length) {
          currentBowlingTeam[_activeBowlerIndex]['wickets'] += 1;
        }
      }

      _recordBallEvent(
        batsmanRuns: runsBeforeRunOut, // Runs made by batsmen before wicket
        extraRuns:
            0, // Wicket event itself typically doesn't have extra runs associated
        extraType: null,
        wicketTaken: true,
        wicketDetails: dismissalDetails,
        totalRunsOnBall: runsBeforeRunOut, // Total runs for this event
      );

      // Find the next available batsman
      int nextBatsmanIndex = -1;
      for (int i = 0; i < currentBattingTeam.length; i++) {
        if (currentBattingTeam[i]['dismissal'] == 'not out' &&
            i != _activeBatsman1Index &&
            i != _activeBatsman2Index) {
          nextBatsmanIndex = i;
          break;
        }
      }

      if (nextBatsmanIndex != -1 && _currentWickets < 10) {
        // Now, after handling the dismissal, if the previously `_activeBatsman1Index` was the one out,
        // assign the new batsman to `_activeBatsman1Index`.
        // If the non-striker was out (via run out), then `_activeBatsman2Index` should be updated.
        // Since we temporarily swapped to make the run-out batsman the striker, `_activeBatsman1Index`
        // is indeed the one that needs to be replaced.
        _activeBatsman1Index = nextBatsmanIndex;
      } else {
        // All out or no more batsmen available
        _endInnings();
        return;
      }

      _checkWinCondition();
    });
  }

  // Dialog to get runs completed before a run-out
  Future<int?> _showRunOutRunsDialog() async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs Completed Before Run Out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0, 1, 2, 3] // Possible runs completed
                .map((r) => ListTile(
                      title: Text('$r run${r != 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to select the type of wicket
  Future<Map<String, dynamic>?> _showWicketTypeDialog({
    required String batsmanName,
    required String bowlerName,
    required List<Map<String, dynamic>> teamBattingStats,
    required List<Map<String, dynamic>> opponentTeamPlayers,
  }) async {
    String? selectedWicketType;
    String? caughtFielderName;
    // Default to striker for run out dialog, but allow selection
    int? runOutPlayerIndex = _activeBatsman1Index;
    String? runOutDirectThrowerName;
    String? runOutReceiverName;

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Dismissal for $batsmanName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Corrected from isScrollable
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedWicketType,
                      hint: const Text('Select Dismissal Type'),
                      items: <String>[
                        'Bowled',
                        'Caught',
                        'LBW',
                        'Run Out',
                        'Stumped',
                        'Hit Wicket',
                        'Obstructing the field',
                        'Hit the ball twice', // Added for completeness
                        'Timed out', // Added for completeness
                        'Retired Out', // Added for completeness
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWicketType = newValue;
                          // Reset dependent fields when dismissal type changes
                          caughtFielderName = null;
                          runOutPlayerIndex =
                              _activeBatsman1Index; // Reset to striker by default
                          runOutDirectThrowerName = null;
                          runOutReceiverName = null;
                        });
                      },
                    ),
                    if (selectedWicketType == 'Caught' ||
                        selectedWicketType == 'Stumped') ...[
                      // Fielder/WK for caught/stumped
                      DropdownButtonFormField<String>(
                        value: caughtFielderName,
                        hint: const Text('Select Fielder/WK (Optional)'),
                        items: opponentTeamPlayers.map((player) {
                          return DropdownMenuItem<String>(
                            value:
                                player['name']?.toString() ?? 'Unknown Fielder',
                            child: Text(player['name']?.toString() ??
                                'Unknown Fielder'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            caughtFielderName = newValue;
                          });
                        },
                      ),
                    ],
                    if (selectedWicketType == 'Run Out') ...[
                      // For run-out, which batsman was out
                      DropdownButtonFormField<int>(
                        value: runOutPlayerIndex,
                        hint: const Text('Batsman Run Out'),
                        items: teamBattingStats
                            .asMap()
                            .entries
                            .map((entry) {
                              final int idx = entry.key;
                              final Map<String, dynamic> player = entry.value;
                              // Only show active batsmen who are not out
                              if (player['dismissal'] == 'not out' &&
                                  (idx == _activeBatsman1Index ||
                                      idx == _activeBatsman2Index)) {
                                return DropdownMenuItem<int>(
                                  value: idx,
                                  child: Text((player['name']?.toString() ??
                                          'Unknown Player') +
                                      (idx == _activeBatsman1Index
                                          ? ' (Striker)'
                                          : ' (Non-Striker)')),
                                );
                              }
                              return null;
                            })
                            .whereType<DropdownMenuItem<int>>()
                            .toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            runOutPlayerIndex = newValue;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: runOutDirectThrowerName,
                        hint: const Text('Direct Thrower (Optional)'),
                        items: opponentTeamPlayers.map((player) {
                          return DropdownMenuItem<String>(
                            value:
                                player['name']?.toString() ?? 'Unknown Player',
                            child: Text(
                                player['name']?.toString() ?? 'Unknown Player'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            runOutDirectThrowerName = newValue;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: runOutReceiverName,
                        hint: const Text('Receiver (Optional)'),
                        items: opponentTeamPlayers.map((player) {
                          return DropdownMenuItem<String>(
                            value:
                                player['name']?.toString() ?? 'Unknown Player',
                            child: Text(
                                player['name']?.toString() ?? 'Unknown Player'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            runOutReceiverName = newValue;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(null); // Cancel
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedWicketType != null) {
                      String dismissalText = selectedWicketType!;
                      bool bowlerWicket =
                          false; // By default, not bowler's wicket

                      switch (selectedWicketType) {
                        case 'Bowled':
                        case 'LBW':
                        case 'Hit Wicket':
                          dismissalText = '$selectedWicketType b $bowlerName';
                          bowlerWicket = true;
                          break;
                        case 'Stumped':
                          dismissalText =
                              'st ${caughtFielderName ?? 'WK'} b $bowlerName';
                          bowlerWicket = true;
                          break;
                        case 'Caught':
                          dismissalText =
                              'c ${caughtFielderName ?? 'Fielder'} b $bowlerName';
                          bowlerWicket = true;
                          break;
                        case 'Run Out':
                          String thrower = runOutDirectThrowerName != null &&
                                  runOutDirectThrowerName!.isNotEmpty
                              ? runOutDirectThrowerName!
                              : '';
                          String receiver = runOutReceiverName != null &&
                                  runOutReceiverName!.isNotEmpty
                              ? runOutReceiverName!
                              : '';
                          dismissalText =
                              'run out (${thrower.isNotEmpty ? thrower : "fielder"}${receiver.isNotEmpty ? "/$receiver" : ""})';
                          bowlerWicket =
                              false; // Run out is not a bowler's wicket
                          break;
                        case 'Obstructing the field':
                          dismissalText = 'obstructing the field';
                          bowlerWicket = false;
                          break;
                        case 'Hit the ball twice':
                          dismissalText = 'hit the ball twice';
                          bowlerWicket = false;
                          break;
                        case 'Timed out':
                          dismissalText = 'timed out';
                          bowlerWicket = false;
                          break;
                        case 'Retired Out':
                          dismissalText = 'retired out';
                          bowlerWicket = false;
                          break;
                        default:
                          break;
                      }

                      Navigator.of(dialogContext).pop({
                        'type': selectedWicketType,
                        'fielder': caughtFielderName,
                        'bowler_wicket': bowlerWicket,
                        'full_dismissal_text': dismissalText,
                        'run_out_player_index':
                            runOutPlayerIndex, // Pass this back
                      });
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Handles a dot ball (no runs, legal delivery)
  void _addBall() {
    setState(() {
      final List<Map<String, dynamic>> currentBattingTeam =
          (_currentBattingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      // Increment batsman's ball count for a dot ball
      if (_activeBatsman1Index >= 0 &&
          _activeBatsman1Index < currentBattingTeam.length) {
        currentBattingTeam[_activeBatsman1Index]['balls']++;
        _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
      }
    });

    _processLegalBall(eventType: 'Dot'); // This is a legal delivery
    _recordBallEvent(
      batsmanRuns: 0,
      extraRuns: 0,
      extraType: null,
      wicketTaken: false,
      totalRunsOnBall: 0,
    );
  }

  // Calculates and updates batsman's strike rate
  void _updateStrikeRate(Map<String, dynamic> player) {
    if ((player['balls'] as int? ?? 0) > 0) {
      player['sr'] = double.parse(
          ((player['runs'] as int? ?? 0) / (player['balls'] as int? ?? 0) * 100)
              .toStringAsFixed(2));
    } else {
      player['sr'] = 0.0;
    }
  }

  // Calculates and updates bowler's economy rate
  void _updateEconomyRate(Map<String, dynamic> bowler) {
    // Economy rate is runs conceded per over (6 balls)
    // Runs conceded includes all runs: runs off bat, wide, no-ball, byes, leg-byes etc.
    // Use total_legal_balls_bowled for the 'overs' part of the economy calculation.
    int legalBalls = bowler['total_legal_balls_bowled'] as int? ?? 0;
    if (legalBalls > 0) {
      bowler['economy'] = double.parse(
          ((bowler['runs'] as int? ?? 0) / legalBalls * 6).toStringAsFixed(2));
    } else {
      bowler['economy'] = 0.0;
    }
  }

  // Dialog to change the active bowler
  Future<void> _changeBowler() async {
    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName ==
                (widget.match['teamA']?.toString() ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    int? newBowlerIndex = await _showPlayerSelectionDialog(
      title: 'Select New Bowler for ${_currentBowlingTeamName}',
      players: currentBowlingTeam,
      excludedIndices: [_activeBowlerIndex], // Exclude current bowler
      isBatsman: false,
    );

    if (newBowlerIndex != null) {
      setState(() {
        _activeBowlerIndex = newBowlerIndex;
      });
    }
  }

  // Swaps the active striker and non-striker batsmen
  void _swapStrike() {
    setState(() {
      final temp = _activeBatsman1Index;
      _activeBatsman1Index = _activeBatsman2Index;
      _activeBatsman2Index = temp;
    });
  }

  // Handles byes: adds runs to batsman and total score, counts as legal delivery, not as 'extra'
  Future<void> _handleByes() async {
    int? runs = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Byes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3, 4]
                .map((r) => ListTile(
                      title: Text('$r run${r > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (runs != null) {
      setState(() {
        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName ==
                    (widget.match['teamA']?.toString() ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        if (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeam.length) {
          currentBattingTeam[_activeBatsman1Index]['balls']++;
          _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
        }
      });
      // Runs are credited to batsman, no 'extra' for the extras counter
      _addRuns(runs,
          batsmanRuns: 0, extraRuns: runs, extraType: 'Bye', eventType: 'Bye');
      _processLegalBall(eventType: 'Bye'); // Byes count as a legal delivery
      _recordBallEvent(
        batsmanRuns: 0, // Show runs credited to batsman in event
        extraRuns: runs, // No extra count here for the event
        extraType: 'Bye',
        wicketTaken: false,
        totalRunsOnBall: runs,
      );
    }
  }

  // Handles leg byes: adds runs to batsman and total score, counts as legal delivery, not as 'extra'
  Future<void> _handleLegByes() async {
    int? runs = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Leg Byes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3, 4]
                .map((r) => ListTile(
                      title: Text('$r run${r > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    print("legbye runs" + runs.toString());
    if (runs != null) {
      setState(() {
        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName ==
                    (widget.match['teamA']?.toString() ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        if (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeam.length) {
          currentBattingTeam[_activeBatsman1Index]['balls']++;
          _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
        }
      });
      // Runs are credited to batsman, no 'extra' for the extras counter
      print("leg bye extra runs" + runs.toString());
      _addRuns(runs,
          batsmanRuns: 0,
          extraRuns: runs,
          extraType: 'Leg Bye',
          eventType: 'LegBye');
      _processLegalBall(
          eventType: 'LegBye'); // Leg Byes count as a legal delivery
      _recordBallEvent(
        batsmanRuns: 0, // Show runs credited to batsman in event
        extraRuns: runs, // No extra count here for the event
        extraType: 'Leg Bye',
        wicketTaken: false,
        totalRunsOnBall: runs,
      );
    }
  }

  // Handles wide: +1 extra, plus any runs run. Not counted as legal delivery.
  Future<void> _handleWide() async {
    int? runsFromWide = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Wide'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3, 4, 5] // 1 (wide) + additional runs if run
                .map((r) => ListTile(
                      title: Text('$r wide run${r > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (runsFromWide != null) {
      print(runsFromWide);
      // 1 run is the wide penalty, (runsFromWide - 1) are byes off the wide.
      // These runs are NOT credited to batsman, but are extras for the _extras counter.
      _addRuns(runsFromWide,
          batsmanRuns: 0,
          extraRuns: runsFromWide,
          extraType: 'Wide',
          eventType: 'Wide');
      // No _processLegalBall() here as wide is not a legal delivery.
      _recordBallEvent(
        batsmanRuns: 0,
        extraRuns: runsFromWide, // Record total extra runs for the event
        extraType: 'Wide',
        wicketTaken: false,
        totalRunsOnBall: runsFromWide,
      );
    }
  }

  // Handles no-ball: total runs (1 penalty + off bat) credited to batsman, not counted as legal delivery.
  Future<void> _handleNoBall() async {
    int? runsOffBat = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs off Bat from No Ball'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Corrected from isScrollable
            children: [0, 1, 2, 3, 4, 5, 6] // Runs from bat on a no-ball
                .map((r) => ListTile(
                      title: Text('$r run${r != 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (runsOffBat != null) {
      int totalRuns = 1 + runsOffBat; // 1 for no-ball penalty + runs off bat

      // Increment batsman's ball count for a no-ball where they faced it
      final List<Map<String, dynamic>> currentBattingTeam =
          (_currentBattingTeamName ==
                  (widget.match['teamA']?.toString() ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      if (_activeBatsman1Index >= 0 &&
          _activeBatsman1Index < currentBattingTeam.length) {
        currentBattingTeam[_activeBatsman1Index]['balls']++;
        _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
      }
      _partnershipBalls++; // No-balls count for partnership balls

      // All runs (penalty + off bat) are attributed to the batsman, no 'extra' for the extras counter
      _addRuns(totalRuns,
          batsmanRuns:
              totalRuns, // Total runs (including penalty) attributed to batsman
          extraRuns: 0, // No extra count here for the extras counter
          extraType: 'No Ball',
          eventType: 'NoBall');
      // No _processLegalBall() here as no-ball is not a legal delivery.
      _recordBallEvent(
        batsmanRuns:
            totalRuns, // Show total runs (incl. penalty) credited to batsman in event
        extraRuns: 0, // No extra count here for the event record
        extraType: 'No Ball',
        wicketTaken: false,
        totalRunsOnBall: totalRuns,
      );
    }
  }

  // Handles overthrows: runs added, credited to batsman, no ball added anywhere.
  Future<void> _handleOverthrow() async {
    int? runs = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Overthrow'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [1, 2, 3, 4, 5]
                .map((r) => ListTile(
                      title: Text('$r run${r > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(r),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (runs != null) {
      // Overthrows add to total runs and are credited to the batsman on strike.
      // They do NOT increment the main ball count, bowler's balls, or batsman's faced balls for this event.
      _addRuns(runs,
          batsmanRuns:
              runs, // Overthrow runs go to the batsman if it was off bat.
          extraRuns: 0, // Not counted in the 'extras' section on the scorecard.
          extraType: 'Overthrow',
          eventType: 'Overthrow');

      _recordBallEvent(
        batsmanRuns: runs,
        extraRuns: 0, // No extra count here, these are actual runs
        extraType: 'Overthrow',
        wicketTaken: false,
        totalRunsOnBall: runs,
      );
    }
  }

  // Ends the current innings and prepares for the next, or ends the match.
  void _endInnings() async {
    if (_isFirstInnings) {
      _firstInningsRuns = _currentRuns;
      _firstInningsWickets = _currentWickets;
      _targetScore = _firstInningsRuns + 1;

      setState(() {
        _isFirstInnings = false;
        // Swap batting and bowling teams for the second innings
        String tempTeamName = _currentBattingTeamName;
        _currentBattingTeamName = _currentBowlingTeamName;
        _currentBowlingTeamName = tempTeamName;

        int tempTeamId = _currentBattingTeamId;
        _currentBattingTeamId = _currentBowlingTeamId;
        _currentBowlingTeamId = tempTeamId;

        _currentRuns = 0;
        _currentWickets = 0;
        _ballsInCurrentOver = 0;
        _totalLegalBallsBowledInInnings = 0;
        _extras = 0; // Reset extras for the new innings
        _partnershipRuns = 0;
        _partnershipBalls = 0;
        _activeBatsman1Index = 0;
        _activeBatsman2Index = 1;
        _activeBowlerIndex = 0;

        // Reset player stats for the new innings (only those relevant to current innings)
        // Keep career stats (runs/wickets from previous innings) in a separate structure if needed for full match.
        // For this app, batting/bowling stats lists are reset for the *current* innings display.
        _teamABattingStats = _teamABattingStats
            .map((e) => {
                  ...e,
                  'runs': 0,
                  'balls': 0,
                  'fours': 0,
                  'sixes': 0,
                  'sr': 0.0,
                  'dismissal': 'not out'
                })
            .toList();
        _teamBBattingStats = _teamBBattingStats
            .map((e) => {
                  ...e,
                  'runs': 0,
                  'balls': 0,
                  'fours': 0,
                  'sixes': 0,
                  'sr': 0.0,
                  'dismissal': 'not out'
                })
            .toList();
        _teamABowlingStats = _teamABowlingStats
            .map((e) => {
                  ...e,
                  'overs': 0.0,
                  'total_legal_balls_bowled': 0, // Reset for new innings
                  'maidens': 0,
                  'runs': 0,
                  'wickets': 0,
                  'economy': 0.0
                })
            .toList();
        _teamBBowlingStats = _teamBBowlingStats
            .map((e) => {
                  ...e,
                  'overs': 0.0,
                  'total_legal_balls_bowled': 0, // Reset for new innings
                  'maidens': 0,
                  'runs': 0,
                  'wickets': 0,
                  'economy': 0.0
                })
            .toList();

        _overByOverSummary.clear();
        _ballEvents.clear();
      });

      _debouncedUpdateScoreOnBackend(
          eventType: 'EndInnings', isMatchOver: false); // Debounced call
      _showInningsBreakDialog();
    } else {
      // This case handles the explicit 'End Innings' button being pressed in the second innings.
      // The _checkWinCondition will determine the winner based on current scores.
      _debouncedUpdateScoreOnBackend(
          eventType: 'EndMatch', isMatchOver: true); // Debounced call
      _checkWinCondition();
    }
  }

  // Shows a dialog for innings break
  void _showInningsBreakDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: lightBlue, // Adjusted for blue theme
          title: const Text('Innings Break!',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            '${_selectedFirstBattingTeamName} scored $_firstInningsRuns/$_firstInningsWickets in their innings.\nTarget for ${_currentBattingTeamName} is $_targetScore runs.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    // After the dialog is dismissed, re-select players for the new innings
    _selectInitialPlayers();
  }

  // New method to show final match results
  Future<void> _showMatchResultDialog({
    required String winningTeam,
    required String losingTeam,
    required int winningTeamScore,
    required int winningTeamWickets,
    required int losingTeamScore,
    required int losingTeamWickets,
    required String result,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext dialogContext) {
        // Determine which team is Team A and which is Team B for display
        final String teamAName = widget.match['teamA']?.toString() ?? 'Team A';
        final String teamBName = widget.match['teamB']?.toString() ?? 'Team B';

        int teamARuns;
        int teamAWickets;
        int teamBRuns;
        int teamBWickets;

        // Assign scores based on who batted first and who is currently batting/bowling
        // This ensures the final scorecard displays correct full match scores.
        if (_selectedFirstBattingTeamName == teamAName) {
          // Team A batted first, so first innings stats are Team A's, current stats are Team B's
          teamARuns = _firstInningsRuns;
          teamAWickets = _firstInningsWickets;
          teamBRuns = _currentRuns;
          teamBWickets = _currentWickets;
        } else {
          // Team B batted first, so first innings stats are Team B's, current stats are Team A's
          teamARuns = _currentRuns;
          teamAWickets = _currentWickets;
          teamBRuns = _firstInningsRuns;
          teamBWickets = _firstInningsWickets;
        }

        return AlertDialog(
          title: const Text('Match Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(result,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Text('$teamAName Score: $teamARuns-$teamAWickets'),
                Text('$teamBName Score: $teamBRuns-$teamBWickets'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Optionally reset game state or navigate to a new screen after match ends
                // For example, you might want to call a method to reset all game variables to initial state.
              },
            ),
          ],
        );
      },
    );
  }

  // --- Check Win Condition ---
  void _checkWinCondition() {
    // Only check win condition if it's the second innings
    if (!_isFirstInnings) {
      final String teamA = widget.match['teamA']?.toString() ?? 'Team A';
      final String teamB = widget.match['teamB']?.toString() ?? 'Team B';

      String winningTeamName = '';
      String losingTeamName = '';
      String resultText = '';
      bool matchEnded = false;

      // Scenario 1: Batting team reaches or exceeds the target
      if (_currentRuns >= _targetScore) {
        winningTeamName = _currentBattingTeamName;
        losingTeamName = _currentBowlingTeamName;
        final int wicketsRemaining = 10 - _currentWickets;
        resultText = '$winningTeamName won by ${wicketsRemaining} wickets.';
        matchEnded = true;
      }

      // Scenario 2: Bowling team wins (batting team all out or overs completed and target not reached)
      final bool isAllOut = _currentWickets >= 10;
      final bool isOversComplete =
          _currentOversDisplay.floor() >= 20; // Assuming 20 overs for T20

      if (!matchEnded && (isAllOut || isOversComplete)) {
        if (_currentRuns < _targetScore - 1) {
          // Current team did not reach target, and didn't tie
          winningTeamName = _currentBowlingTeamName;
          losingTeamName = _currentBattingTeamName;
          final int runsDifference =
              _targetScore - _currentRuns - 1; // Subtract 1 for target
          resultText = '$winningTeamName won by $runsDifference runs.';
          matchEnded = true;
        } else if (_currentRuns == _targetScore - 1) {
          // Current team tied the score
          resultText = 'Match Tied!';
          matchEnded = true;
        }
      }

      if (matchEnded) {
        _showMatchResultDialog(
            winningTeam: winningTeamName,
            losingTeam: losingTeamName,
            winningTeamScore: (_currentBattingTeamName == teamA)
                ? _currentRuns
                : _firstInningsRuns,
            winningTeamWickets: (_currentBattingTeamName == teamA)
                ? _currentWickets
                : _firstInningsWickets,
            losingTeamScore: (_currentBattingTeamName == teamA)
                ? _firstInningsRuns
                : _currentRuns,
            losingTeamWickets: (_currentBattingTeamName == teamA)
                ? _firstInningsWickets
                : _currentWickets,
            result: resultText);
        _debouncedUpdateScoreOnBackend(
            eventType: 'MatchEnd',
            isMatchOver: true); // Inform backend match is over
        return; // Match ended
      }
    } else {
      // First innings: check for all out or overs complete
      if (_currentWickets == 10 || _currentOversDisplay.floor() >= 20) {
        _endInnings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Scaffold(
      backgroundColor: primaryBlue, // Very light blue background
      appBar: AppBar(
        title:
            const Text('Match Centre', style: TextStyle(color: Colors.white)),
        backgroundColor: lightBlue, // Dark blue for app bar
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _mainTabController,
          isScrollable: true,
          labelColor: Colors.white, // White for selected label
          unselectedLabelColor: Colors.white70, // Lighter blue for unselected
          indicatorColor: accentOrange, // Solid white for indicator
          tabs: const [
            Tab(text: 'Scoring'),
            Tab(text: 'Scorecard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildScoringView(match),
          _buildScorecardTabView(), // Call the method without args, it will use state
        ],
      ),
    );
  }

  // Builds the main scoring view, displaying current match info and scoring controls.
  Widget _buildScoringView(Map<String, dynamic> match) {
    // Current Run Rate calculation
    double crr = (_totalLegalBallsBowledInInnings > 0)
        ? (_currentRuns / _totalLegalBallsBowledInInnings * 6)
        : 0.0;

    // Required Run Rate calculation for second innings
    double rrr = 0.0;
    if (!_isFirstInnings &&
        _currentOversDisplay.floor() < 20 &&
        _targetScore > _currentRuns) {
      int ballsRemaining = (20 * 6) - _totalLegalBallsBowledInInnings;
      int runsNeeded = _targetScore - _currentRuns;
      if (ballsRemaining > 0) {
        rrr = (runsNeeded / ballsRemaining) * 6;
      }
    }

    // Determine which team's batting stats to display based on `_currentBattingTeamName`
    List<Map<String, dynamic>> currentBattingTeamPlayers;
    if (_currentBattingTeamName ==
        (widget.match['teamA']?.toString() ?? 'Team A')) {
      currentBattingTeamPlayers = _teamABattingStats;
    } else {
      currentBattingTeamPlayers = _teamBBattingStats;
    }

    // Determine which team's bowling stats to display based on `_currentBowlingTeamName`
    List<Map<String, dynamic>> currentBowlingTeamPlayers;
    if (_currentBowlingTeamName ==
        (widget.match['teamA']?.toString() ?? 'Team A')) {
      currentBowlingTeamPlayers = _teamABowlingStats;
    } else {
      currentBowlingTeamPlayers = _teamBBowlingStats;
    }

    final String batsman1Name = (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeamPlayers.length)
        ? currentBattingTeamPlayers[_activeBatsman1Index]['name']?.toString() ??
            'N/A'
        : 'N/A';
    final String batsman2Name = (_activeBatsman2Index >= 0 &&
            _activeBatsman2Index < currentBattingTeamPlayers.length)
        ? currentBattingTeamPlayers[_activeBatsman2Index]['name']?.toString() ??
            'N/A'
        : 'N/A';
    final String bowlerName = (_activeBowlerIndex >= 0 &&
            _activeBowlerIndex < currentBowlingTeamPlayers.length)
        ? currentBowlingTeamPlayers[_activeBowlerIndex]['name']?.toString() ??
            'N/A'
        : 'N/A';

    final String batsman1Runs = (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeamPlayers.length)
        ? (currentBattingTeamPlayers[_activeBatsman1Index]['runs'] as int? ?? 0)
            .toString()
        : '0';
    final String batsman1Balls = (_activeBatsman1Index >= 0 &&
            _activeBatsman1Index < currentBattingTeamPlayers.length)
        ? (currentBattingTeamPlayers[_activeBatsman1Index]['balls'] as int? ??
                0)
            .toString()
        : '0';
    final String batsman2Runs = (_activeBatsman2Index >= 0 &&
            _activeBatsman2Index < currentBattingTeamPlayers.length)
        ? (currentBattingTeamPlayers[_activeBatsman2Index]['runs'] as int? ?? 0)
            .toString()
        : '0';
    final String batsman2Balls = (_activeBatsman2Index >= 0 &&
            _activeBatsman2Index < currentBattingTeamPlayers.length)
        ? (currentBattingTeamPlayers[_activeBatsman2Index]['balls'] as int? ??
                0)
            .toString()
        : '0';

    final String bowlerOvers = (_activeBowlerIndex >= 0 &&
            _activeBowlerIndex < currentBowlingTeamPlayers.length)
        ? (currentBowlingTeamPlayers[_activeBowlerIndex]['overs'] as double? ??
                0.0)
            .toStringAsFixed(1)
        : '0.0';
    final String bowlerRuns = (_activeBowlerIndex >= 0 &&
            _activeBowlerIndex < currentBowlingTeamPlayers.length)
        ? (currentBowlingTeamPlayers[_activeBowlerIndex]['runs'] as int? ?? 0)
            .toString()
        : '0';
    final String bowlerWickets = (_activeBowlerIndex >= 0 &&
            _activeBowlerIndex < currentBowlingTeamPlayers.length)
        ? (currentBowlingTeamPlayers[_activeBowlerIndex]['wickets'] as int? ??
                0)
            .toString()
        : '0';

    String winningMessage = '';
    bool isMatchOverDisplay = false; // Separate variable for display purposes

    // Check for match over conditions and set winning message if applicable
    if (!_isFirstInnings) {
      if (_currentRuns >= _targetScore) {
        isMatchOverDisplay = true;
        final int wicketsRemaining = 10 - _currentWickets;
        winningMessage =
            '${_currentBattingTeamName} won by ${wicketsRemaining} wickets.';
      } else {
        final bool isAllOut = _currentWickets >= 10;
        final bool isOversComplete = _currentOversDisplay.floor() >= 20.0;
        if (isAllOut || isOversComplete) {
          isMatchOverDisplay = true;
          if (_currentRuns < _targetScore - 1) {
            final int runsDifference = _targetScore - _currentRuns - 1;
            winningMessage =
                '${_currentBowlingTeamName} won by $runsDifference runs.';
          } else if (_currentRuns == _targetScore - 1) {
            winningMessage = 'Match Tied!';
          }
        }
      }
    } else {
      if (_currentWickets == 10 || _currentOversDisplay.floor() >= 20.0) {
        isMatchOverDisplay = true; // First innings concluded
        // No explicit winning message for first innings conclusion here
      }
    }

    return Column(
      children: [
        // Top Match Info Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: lightBlue, // Dark blue background for match info
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                match['match']?.toString() ?? 'Unknown Match',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (isMatchOverDisplay &&
                  winningMessage
                      .isNotEmpty) // Display winning message if applicable
                Text(
                  winningMessage,
                  style: const TextStyle(
                      color: accentOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              else if (_isFirstInnings) // Display for First Innings
                Column(
                  children: [
                    Text(
                      _currentBattingTeamName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: $_currentRuns/$_currentWickets (${_currentOversDisplay.toStringAsFixed(1)})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              else // Display for Second Innings (Target-based)
                Column(
                  children: [
                    Text(
                      '$_currentBattingTeamName Batting',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: $_currentRuns/$_currentWickets (${_currentOversDisplay.toStringAsFixed(1)})',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: $_targetScore | Needs ${_targetScore - _currentRuns} runs from ${((20 * 6) - _totalLegalBallsBowledInInnings)} balls',
                      style: const TextStyle(
                          color: accentOrange, // Amber for target info
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('RRR: ${rrr.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: accentOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Spacer to push the scoring pad to the bottom
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Extras, Overs, CRR row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Extras - $_extras',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text(
                        'Overs - ${_currentOversDisplay.toStringAsFixed(1)} / 20',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    Text('CRR - ${crr.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Partnership - $_partnershipRuns($_partnershipBalls)',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12), // Reduced spacing
                // Batsman Info Table
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batsman',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)), // Consistent blue
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4), // Reduced padding
                      decoration: BoxDecoration(
                        color: lightBlue.withOpacity(
                            0.5), // Semi-transparent card background
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: lightBlue, // Light blue for header row
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(6.0), // Reduced padding
                                child: Text('Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color:
                                            Colors.white)), // Reduced font size
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('R',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('B',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('4s',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('6s',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('SR',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                    6.0), // Reduced padding
                                child: Text('$batsman1Name*',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color:
                                            Colors.white)), // Reduced font size
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(batsman1Runs,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(batsman1Balls,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman1Index >= 0 &&
                                            _activeBatsman1Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman1Index]
                                                    ['fours'] as int? ??
                                                0)
                                            .toString()
                                        : '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman1Index >= 0 &&
                                            _activeBatsman1Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman1Index]
                                                    ['sixes'] as int? ??
                                                0)
                                            .toString()
                                        : '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman1Index >= 0 &&
                                            _activeBatsman1Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman1Index]
                                                    ['sr'] as double? ??
                                                0.0)
                                            .toStringAsFixed(1)
                                        : '0.0',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(batsman2Name,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(batsman2Runs,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(batsman2Balls,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman2Index >= 0 &&
                                            _activeBatsman2Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman2Index]
                                                    ['fours'] as int? ??
                                                0)
                                            .toString()
                                        : '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman2Index >= 0 &&
                                            _activeBatsman2Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman2Index]
                                                    ['sixes'] as int? ??
                                                0)
                                            .toString()
                                        : '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBatsman2Index >= 0 &&
                                            _activeBatsman2Index <
                                                currentBattingTeamPlayers
                                                    .length)
                                        ? (currentBattingTeamPlayers[
                                                        _activeBatsman2Index]
                                                    ['sr'] as double? ??
                                                0.0)
                                            .toStringAsFixed(1)
                                        : '0.0',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced spacing
                // Bowler Info Table
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bowler',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)), // Consistent blue
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4), // Reduced padding
                      decoration: BoxDecoration(
                        color: lightBlue.withOpacity(
                            0.5), // Semi-transparent card background
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: lightBlue, // Light blue for header row
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(6.0), // Reduced padding
                                child: Text('Name',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color:
                                            Colors.white)), // Reduced font size
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('O',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('M',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('R',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('W',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Text('Econ',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(bowlerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(bowlerOvers,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBowlerIndex >= 0 &&
                                            _activeBowlerIndex <
                                                currentBowlingTeamPlayers
                                                    .length)
                                        ? (currentBowlingTeamPlayers[
                                                        _activeBowlerIndex]
                                                    ['maidens'] as int? ??
                                                0)
                                            .toString()
                                        : '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(bowlerRuns,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(bowlerWickets,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                    (_activeBowlerIndex >= 0 &&
                                            _activeBowlerIndex <
                                                currentBowlingTeamPlayers
                                                    .length)
                                        ? (currentBowlingTeamPlayers[
                                                        _activeBowlerIndex]
                                                    ['economy'] as double? ??
                                                0.0)
                                            .toStringAsFixed(1)
                                        : '0.0',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced spacing
                // All Balls Summary - Horizontal Scrollable
                if (_ballEvents.isNotEmpty) ...[
                  const Text('All Balls Commentary:',
                      style: TextStyle(
                          fontSize: 15, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40, // Reduced height for the horizontal list
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ballEvents.length,
                      itemBuilder: (context, index) {
                        final ball = _ballEvents[_ballEvents.length -
                            1 -
                            index]; // Iterate in reverse order
                        String result = '';
                        Color ballColor = lightBlue
                            .withOpacity(0.7); // Default light blue ball color
                        Color textColor = Colors.white;

                        if (ball['wicket_taken'] == true) {
                          result = 'W';
                          ballColor = Colors.red.shade400;
                          textColor = Colors.white;
                        } else if ((ball['extra_runs'] ?? 0) > 0 &&
                            ball['extra_type'] != 'Overthrow') {
                          // Display actual total runs for the ball if extras (Wide penalty only now)
                          result =
                              '${ball['extra_type'][0]}${ball['extra_runs']}'; // Only show the 'extra penalty' amount
                          ballColor = accentOrange;
                          textColor = Colors.white;
                        } else {
                          result = (ball['batsman_runs'] ?? 0).toString();
                          ballColor = ((ball['batsman_runs'] ?? 0) == 4)
                              ? lightBlue // Medium blue for 4
                              : ((ball['batsman_runs'] ?? 0) == 6)
                                  ? Colors.green.shade400 // Green for 6
                                  : lightBlue
                                      .withOpacity(0.7); // Default light blue
                          textColor = Colors.white; // White text for runs
                        }

                        // Determine if a separator is needed AFTER this ball's chip
                        // Calculate original index to check for end of over
                        final int legalBallsBeforeThis = _ballEvents
                            .where((e) =>
                                e['extra_type'] != 'Wide' &&
                                e['extra_type'] != 'No Ball' &&
                                _ballEvents.indexOf(e) <=
                                    (_ballEvents.length - 1 - index))
                            .length;
                        bool isEndOfOverSeparator =
                            legalBallsBeforeThis % 6 == 0 &&
                                legalBallsBeforeThis > 0 &&
                                (legalBallsBeforeThis) <
                                    _totalLegalBallsBowledInInnings;

                        return Row(
                          children: [
                            Chip(
                              label: Text(result,
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)), // Reduced font size
                              backgroundColor: ballColor,
                              materialTapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // Make chip smaller
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0), // Adjust chip padding
                            ),
                            const SizedBox(
                                width: 4), // Small space between chips
                            if (isEndOfOverSeparator) // Add separator after the chip
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0), // Reduced padding
                                child: Container(
                                  width: 2, // Width of the separator line
                                  height: 20, // Height of the separator line
                                  color: Colors
                                      .grey.shade400, // Color of the separator
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                ],
                // Player Change Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final List<Map<String, dynamic>> currentBattingTeam =
                              (_currentBattingTeamName ==
                                      (widget.match['teamA']?.toString() ??
                                          'Team A'))
                                  ? _teamABattingStats
                                  : _teamBBattingStats;

                          int? newBatsman1Index =
                              await _showPlayerSelectionDialog(
                            title:
                                'Select On-Strike Batsman for $_currentBattingTeamName',
                            players: currentBattingTeam,
                            excludedIndices: [_activeBatsman2Index],
                            isBatsman: true,
                          );
                          if (newBatsman1Index != null) {
                            setState(() {
                              _activeBatsman1Index = newBatsman1Index;
                            });
                          }
                          int? newBatsman2Index =
                              await _showPlayerSelectionDialog(
                            title:
                                'Select Non-Strike Batsman for $_currentBattingTeamName',
                            players: currentBattingTeam,
                            excludedIndices: [_activeBatsman1Index],
                            isBatsman: true,
                          );
                          if (newBatsman2Index != null) {
                            setState(() {
                              _activeBatsman2Index = newBatsman2Index;
                            });
                          }
                        },
                        icon: const Icon(Icons.person_add,
                            size: 16), // Reduced icon size
                        label: const Text('Change Batsmen',
                            style:
                                TextStyle(fontSize: 13)), // Reduced font size
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6), // Reduced padding
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _changeBowler,
                        icon: const Icon(Icons.person_add,
                            size: 16), // Reduced icon size
                        label: const Text('Change Bowler',
                            style:
                                TextStyle(fontSize: 13)), // Reduced font size
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6), // Reduced padding
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Scoring Pad
        _buildScoringPad(),
      ],
    );
  }

  // Helper widget to build consistent-looking score buttons.
  Widget _buildScoreButton(String text, VoidCallback onPressed,
      {Color? customColor,
      Color? textColor,
      double fontSize = 16,
      EdgeInsetsGeometry? padding}) {
    Color buttonColor = customColor ?? Colors.white; // Default white
    Color buttonTextColor = textColor ?? Colors.black; // Default black

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0), // Reduced padding around buttons
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8), // Slightly smaller rounded corners
            ),
            padding: padding ??
                const EdgeInsets.symmetric(
                    vertical: 14), // Reduced vertical padding
            textStyle: TextStyle(
              fontSize: fontSize, // Use passed font size or default
              fontWeight: FontWeight.bold,
            ),
            elevation: 2.0, // Reduced elevation
          ),
          child: Text(text),
        ),
      ),
    );
  }

  // Builds the scoring input pad with various buttons for runs, extras, and wickets.
  Widget _buildScoringPad() {
    return Container(
      color: lightBlue, // Background for the scoring pad
      padding: const EdgeInsets.all(6.0), // Reduced overall padding
      child: Column(
        children: [
          // First row of buttons (1, 2, 3, 4, 6) for runs
          Row(
            children: [
              _buildScoreButton('1', () {
                setState(() {
                  final List<Map<String, dynamic>> currentBattingTeam =
                      (_currentBattingTeamName ==
                              (widget.match['teamA']?.toString() ?? 'Team A'))
                          ? _teamABattingStats
                          : _teamBBattingStats;
                  if (_activeBatsman1Index >= 0 &&
                      _activeBatsman1Index < currentBattingTeam.length) {
                    currentBattingTeam[_activeBatsman1Index]['balls']++;
                    _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
                  }
                });
                _addRuns(1, batsmanRuns: 1, extraRuns: 0, eventType: 'Single');
                _processLegalBall(eventType: 'Single');
                _recordBallEvent(
                  batsmanRuns: 1,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                  totalRunsOnBall: 1,
                );
              }, customColor: accentOrange, textColor: Colors.white),
              _buildScoreButton('2', () {
                setState(() {
                  final List<Map<String, dynamic>> currentBattingTeam =
                      (_currentBattingTeamName ==
                              (widget.match['teamA']?.toString() ?? 'Team A'))
                          ? _teamABattingStats
                          : _teamBBattingStats;
                  if (_activeBatsman1Index >= 0 &&
                      _activeBatsman1Index < currentBattingTeam.length) {
                    currentBattingTeam[_activeBatsman1Index]['balls']++;
                    _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
                  }
                });
                _addRuns(2, batsmanRuns: 2, extraRuns: 0, eventType: 'Double');
                _processLegalBall(eventType: 'Double');
                _recordBallEvent(
                  batsmanRuns: 2,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                  totalRunsOnBall: 2,
                );
              }, customColor: accentOrange, textColor: Colors.white),
              _buildScoreButton('3', () {
                setState(() {
                  final List<Map<String, dynamic>> currentBattingTeam =
                      (_currentBattingTeamName ==
                              (widget.match['teamA']?.toString() ?? 'Team A'))
                          ? _teamABattingStats
                          : _teamBBattingStats;
                  if (_activeBatsman1Index >= 0 &&
                      _activeBatsman1Index < currentBattingTeam.length) {
                    currentBattingTeam[_activeBatsman1Index]['balls']++;
                    _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
                  }
                });
                _addRuns(3, batsmanRuns: 3, extraRuns: 0, eventType: 'Triple');
                _processLegalBall(eventType: 'Triple');
                _recordBallEvent(
                  batsmanRuns: 3,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                  totalRunsOnBall: 3,
                );
              }, customColor: accentOrange, textColor: Colors.white),
              _buildScoreButton('4', () {
                setState(() {
                  final List<Map<String, dynamic>> currentBattingTeam =
                      (_currentBattingTeamName ==
                              (widget.match['teamA']?.toString() ?? 'Team A'))
                          ? _teamABattingStats
                          : _teamBBattingStats;
                  if (_activeBatsman1Index >= 0 &&
                      _activeBatsman1Index < currentBattingTeam.length) {
                    currentBattingTeam[_activeBatsman1Index]['balls']++;
                    _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
                  }
                });
                _addRuns(4,
                    batsmanRuns: 4,
                    extraRuns: 0,
                    isBoundary: true,
                    eventType: 'Four');
                _processLegalBall(eventType: 'Four');
                _recordBallEvent(
                  batsmanRuns: 4,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                  totalRunsOnBall: 4,
                );
              }, customColor: accentOrange, textColor: Colors.white),
              _buildScoreButton('6', () {
                setState(() {
                  final List<Map<String, dynamic>> currentBattingTeam =
                      (_currentBattingTeamName ==
                              (widget.match['teamA']?.toString() ?? 'Team A'))
                          ? _teamABattingStats
                          : _teamBBattingStats;
                  if (_activeBatsman1Index >= 0 &&
                      _activeBatsman1Index < currentBattingTeam.length) {
                    currentBattingTeam[_activeBatsman1Index]['balls']++;
                    _updateStrikeRate(currentBattingTeam[_activeBatsman1Index]);
                  }
                });
                _addRuns(6,
                    batsmanRuns: 6,
                    extraRuns: 0,
                    isBoundary: true,
                    eventType: 'Six');
                _processLegalBall(eventType: 'Six');
                _recordBallEvent(
                  batsmanRuns: 6,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                  totalRunsOnBall: 6,
                );
              }, customColor: accentOrange, textColor: Colors.white),
            ],
          ),
          // Second row of buttons (LB, Bye, Wide, NB, Dot) for extras and dot ball
          Row(
            children: [
              _buildScoreButton('LB', _handleLegByes,
                  customColor: primaryBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('Bye', _handleByes,
                  customColor: primaryBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('Wide', _handleWide,
                  customColor: primaryBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('NB', _handleNoBall,
                  customColor: primaryBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('Dot', _addBall, // Calls the _addBall method
                  customColor: primaryBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ],
          ),
          // Third row of buttons (Overthrow, Out, End Innings) for special events
          Row(
            children: [
              _buildScoreButton('Overthrow', _handleOverthrow,
                  customColor: lightBlue,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('Out', _addWicket,
                  customColor: Colors.red.shade700,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              _buildScoreButton('End Innings', _endInnings,
                  customColor: Colors.orange.shade700,
                  textColor: Colors.white,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Scorecard Tab View (dynamic data) ---
  Widget _buildScorecardTabView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                lightBlue.withOpacity(0.5), // Light blue for tab bar background
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _scorecardTeamTabController,
            labelColor: Colors.white, // Darker blue for selected label
            unselectedLabelColor:
                Colors.white70, // Mid blue for unselected label
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: accentOrange, // Light blue for indicator
            ),
            tabs: [
              Tab(text: widget.match['teamA']?.toString() ?? 'Team A'),
              Tab(text: widget.match['teamB']?.toString() ?? 'Team B'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _scorecardTeamTabController,
            children: [
              // Team A's scorecard view: Team A Batting, Team B Bowling
              _buildTeamScorecard(
                widget.match['teamA']?.toString() ??
                    'Team A', // Batting Team Name
                _teamABattingStats, // Team A's batting stats
                _teamBBowlingStats, // Team B's bowling stats against Team A
                widget.match['teamB']?.toString() ??
                    'Team B', // Bowling Team Name for title
              ),
              // Team B's scorecard view: Team B Batting, Team A Bowling
              _buildTeamScorecard(
                widget.match['teamB']?.toString() ??
                    'Team B', // Batting Team Name
                _teamBBattingStats, // Team B's batting stats
                _teamABowlingStats, // Team A's bowling stats against Team B
                widget.match['teamA']?.toString() ??
                    'Team A', // Bowling Team Name for title
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Builds a detailed scorecard for a given team, including batting, bowling, and over-by-over summaries.
  Widget _buildTeamScorecard(
    String battingTeamName,
    List<Map<String, dynamic>> battingStats,
    List<Map<String, dynamic>> bowlingStats,
    String bowlingTeamName, // Added for clearer title
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Scorecard
          Text('$battingTeamName Batting',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: battingStats.length,
            itemBuilder: (context, index) {
              final player = battingStats[index];
              return Card(
                elevation: 2.0, // Increased elevation
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)), // Rounded corners
                color: lightBlue.withOpacity(0.7), // Card background
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (player['name']?.toString() ?? 'N/A') +
                                ((player['dismissal'] == 'not out') ? '*' : ''),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            'R: ${player['runs'] ?? 0} (B: ${player['balls'] ?? 0})',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '4s: ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${player['fours'] ?? 0}',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ', 6s: ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${player['sixes'] ?? 0}',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ', SR: ${(player['sr'] as double? ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                          'Dismissal: ${player['dismissal']?.toString() ?? 'N/A'}',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          ),
          Card(
            elevation: 2.0, // Increased elevation
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)), // Rounded corners
            color: lightBlue.withOpacity(0.7), // Card background
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extras',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    _extras.toString(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bowling Scorecard
          Text('$bowlingTeamName Bowling',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bowlingStats.length,
            itemBuilder: (context, index) {
              final player = bowlingStats[index];
              return Card(
                elevation: 2.0, // Increased elevation
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)), // Rounded corners
                color: lightBlue.withOpacity(0.7), // Card background
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player['name']?.toString() ?? 'N/A',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            'O: ${(player['overs'] as double? ?? 0.0).toStringAsFixed(1)}, M: ${player['maidens'] ?? 0}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                          'R: ${player['runs'] ?? 0}, W: ${player['wickets'] ?? 0}, Econ: ${(player['economy'] as double? ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Over-by-Over Summary
          const Text('Over-by-Over Summary (Current Innings)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _overByOverSummary.length,
            itemBuilder: (context, index) {
              final over = _overByOverSummary[index];
              return Card(
                elevation: 2.0, // Increased elevation
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)), // Rounded corners
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lightBlue.withOpacity(0.7), // Light blue
                    child: Text('${over['over'] ?? 0}',
                        style:
                            TextStyle(color: Colors.white)), // Darker blue text
                  ),
                  title: Text('Runs: ${over['runs'] ?? 0}',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white)),
                  trailing: Text('Wickets: ${over['wickets'] ?? 0}',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
