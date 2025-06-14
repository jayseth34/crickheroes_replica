import 'package:flutter/material.dart';
import 'dart:math';

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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming 'Inter' font is available or a fallback
      ),
      home: const MatchDetailPage(match: {
        'match': 'T20 Match',
        'teamA': 'Team India',
        'teamB': 'Team South Africa',
      }), // Pass dummy match data
    );
  }
}

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;

  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _scorecardTeamTabController;

  // Live match data
  int _currentRuns = 0;
  int _currentWickets = 0;
  double _currentOvers = 0.0; // Format as X.Y where Y is balls
  int _ballsInCurrentOver = 0;
  int _extras = 0;
  int _partnershipRuns = 0;
  int _partnershipBalls = 0;

  // Innings tracking
  bool _isFirstInnings = true;
  int _firstInningsRuns = 0;
  int _firstInningsWickets = 0;
  int _targetScore = 0;

  // Store which team was selected to bat first
  String? _selectedFirstBattingTeamName;
  String _currentBattingTeamName = '';
  String _currentBowlingTeamName = '';

  // Player Data - These will hold the live stats for the current match
  List<Map<String, dynamic>> _teamABattingStats = [];
  List<Map<String, dynamic>> _teamABowlingStats = [];
  List<Map<String, dynamic>> _teamBBattingStats = [];
  List<Map<String, dynamic>> _teamBBowlingStats = [];

  // Over-by-over summary for the *current* innings
  List<Map<String, dynamic>> _overByOverSummary = [];
  // Detailed ball-by-ball events for the *current* innings
  List<Map<String, dynamic>> _ballEvents = [];

  // Current active players
  int _activeBatsman1Index = 0; // The striker
  int _activeBatsman2Index = 1; // The non-striker
  int _activeBowlerIndex = 0; // Index in the *current* bowling team's list

  // For Undo functionality: Store the state before the last action
  Map<String, dynamic>? _lastGameStateSnapshot;

  @override
  void initState() {
    super.initState();

    // Only 'Scoring', 'Scorecard', and 'Balls' tabs remain as requested
    _mainTabController = TabController(length: 3, vsync: this);
    _scorecardTeamTabController = TabController(length: 2, vsync: this);

    _teamABattingStats = [
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
    _teamBBowlingStats = [
      {
        'name': 'Kagiso Rabada',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Anrich Nortje',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Keshav Maharaj',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Marco Jansen',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Tabraiz Shamsi',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Gerald Coetzee',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
    ];

    _teamBBattingStats = [
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

    _teamABowlingStats = [
      {
        'name': 'Jasprit Bumrah',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Hardik Pandya',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Axar Patel',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Mohammed Siraj',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Kuldeep Yadav',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
      {
        'name': 'Arshdeep Singh',
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0
      },
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialSetup();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _scorecardTeamTabController.dispose();
    super.dispose();
  }

  // --- Helper for taking snapshots for Undo ---
  Map<String, dynamic> _createGameStateSnapshot() {
    return {
      'currentRuns': _currentRuns,
      'currentWickets': _currentWickets,
      'currentOvers': _currentOvers,
      'ballsInCurrentOver': _ballsInCurrentOver,
      'extras': _extras,
      'partnershipRuns': _partnershipRuns,
      'partnershipBalls': _partnershipBalls,
      'activeBatsman1Index': _activeBatsman1Index,
      'activeBatsman2Index': _activeBatsman2Index,
      'activeBowlerIndex': _activeBowlerIndex,
      // Deep copy lists to ensure independent state
      'teamABattingStats': _teamABattingStats.map((e) => Map.from(e)).toList(),
      'teamABowlingStats': _teamABowlingStats.map((e) => Map.from(e)).toList(),
      'teamBBattingStats': _teamBBattingStats.map((e) => Map.from(e)).toList(),
      'teamBBowlingStats': _teamBBowlingStats.map((e) => Map.from(e)).toList(),
      'overByOverSummary': _overByOverSummary.map((e) => Map.from(e)).toList(),
      'ballEvents': _ballEvents.map((e) => Map.from(e)).toList(),
    };
  }

  void _restoreGameStateFromSnapshot(Map<String, dynamic> snapshot) {
    setState(() {
      _currentRuns = snapshot['currentRuns'];
      _currentWickets = snapshot['currentWickets'];
      _currentOvers = snapshot['currentOvers'];
      _ballsInCurrentOver = snapshot['ballsInCurrentOver'];
      _extras = snapshot['extras'];
      _partnershipRuns = snapshot['partnershipRuns'];
      _partnershipBalls = snapshot['partnershipBalls'];
      _activeBatsman1Index = snapshot['activeBatsman1Index'];
      _activeBatsman2Index = snapshot['activeBatsman2Index'];
      _activeBowlerIndex = snapshot['activeBowlerIndex'];
      _teamABattingStats = snapshot['teamABattingStats'];
      _teamABowlingStats = snapshot['teamABowlingStats'];
      _teamBBattingStats = snapshot['teamBBattingStats'];
      _teamBBowlingStats = snapshot['teamBBowlingStats'];
      _overByOverSummary = snapshot['overByOverSummary'];
      _ballEvents = snapshot['ballEvents'];
    });
  }

  Future<void> _initialSetup() async {
    String? battingTeamChoice = await _showBattingTeamSelectionDialog();
    if (battingTeamChoice == null) {
      battingTeamChoice = widget.match['teamA'] ?? 'Team A';
    }

    setState(() {
      _selectedFirstBattingTeamName = battingTeamChoice;
      _currentBattingTeamName = _selectedFirstBattingTeamName!;
      _currentBowlingTeamName =
          (battingTeamChoice == (widget.match['teamA'] ?? 'Team A'))
              ? (widget.match['teamB'] ?? 'Team B')
              : (widget.match['teamA'] ?? 'Team A');
    });

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
                title: Text(widget.match['teamA'] ?? 'Team A'),
                onTap: () => Navigator.of(dialogContext)
                    .pop(widget.match['teamA'] ?? 'Team A'),
              ),
              ListTile(
                title: Text(widget.match['teamB'] ?? 'Team B'),
                onTap: () => Navigator.of(dialogContext)
                    .pop(widget.match['teamB'] ?? 'Team B'),
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
                  title: Text(player['name']),
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
        (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABattingStats
            : _teamBBattingStats;

    int? batsman1Index = await _showPlayerSelectionDialog(
      title: 'Select On-Strike Batsman for ${_currentBattingTeamName}',
      players: currentBattingTeam,
      excludedIndices: [],
      isBatsman: true,
    );
    if (batsman1Index == null) return;

    int? batsman2Index = await _showPlayerSelectionDialog(
      title: 'Select Non-Strike Batsman for ${_currentBattingTeamName}',
      players: currentBattingTeam,
      excludedIndices: [batsman1Index],
      isBatsman: true,
    );
    if (batsman2Index == null) return;

    setState(() {
      _activeBatsman1Index = batsman1Index;
      _activeBatsman2Index = batsman2Index;
    });

    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    int? bowlerIndex = await _showPlayerSelectionDialog(
      title: 'Select Bowler for ${_currentBowlingTeamName}',
      players: currentBowlingTeam,
      excludedIndices: [],
      isBatsman: false,
    );
    if (bowlerIndex == null) return;

    setState(() {
      _activeBowlerIndex = bowlerIndex;
    });
  }

  // This function increments ball count for overs and partnership
  void _incrementBallAndOverStats() {
    setState(() {
      _ballsInCurrentOver++;
      _updateOvers();
      _partnershipBalls++;
    });
  }

  void _recordBallEvent({
    required int batsmanRuns,
    required int extraRuns,
    String? extraType,
    required bool wicketTaken,
    Map<String, dynamic>? wicketDetails,
  }) {
    setState(() {
      final List<Map<String, dynamic>> currentBattingTeamPlayers =
          (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      final List<Map<String, dynamic>> currentBowlingTeamPlayers =
          (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
              ? _teamABowlingStats
              : _teamBBowlingStats;

      // Determine the batsman name for the ball event
      String batsmanName;
      if (wicketTaken &&
          wicketDetails?['type'] == 'Run Out' &&
          wicketDetails?['run_out_batsman_index'] != null) {
        batsmanName =
            currentBattingTeamPlayers[wicketDetails!['run_out_batsman_index']]
                    ['name'] ??
                'N/A';
      } else if (wicketTaken) {
        batsmanName =
            currentBattingTeamPlayers[_activeBatsman1Index]['name'] ?? 'N/A';
      } else if (extraType != null &&
          (extraType == 'Wide' || extraType == 'No Ball')) {
        batsmanName = 'Extras';
      } else {
        batsmanName =
            currentBattingTeamPlayers[_activeBatsman1Index]['name'] ?? 'N/A';
      }

      _ballEvents.add({
        'over_display':
            '${_currentOvers.floor()}.${_ballsInCurrentOver == 0 ? 6 : _ballsInCurrentOver}',
        'batsman_runs': batsmanRuns,
        'extra_runs': extraRuns,
        'extra_type': extraType,
        'wicket_taken': wicketTaken,
        'wicket_details': wicketDetails,
        'dismissal': wicketDetails?['full_dismissal_text'],
        'batsman_name': batsmanName,
        'bowler_name':
            currentBowlingTeamPlayers[_activeBowlerIndex]['name'] ?? 'N/A',
        'total_score_after_ball':
            '$_currentRuns-${_currentWickets} (${_currentOvers.toStringAsFixed(1)})',
      });
    });
  }

  void _addRunsToScore({
    required int totalRunsAdded,
    int batsmanRuns = 0,
    bool isExtra = false,
    String? extraType, // 'Wide', 'No Ball', 'Bye', 'Leg Bye'
    bool isBoundary = false,
    bool isSix = false,
  }) {
    // Capture state before changes for undo
    _lastGameStateSnapshot = _createGameStateSnapshot();

    setState(() {
      _currentRuns += totalRunsAdded;
      _partnershipRuns += totalRunsAdded;

      // Update batsman stats for runs off bat
      if (batsmanRuns > 0) {
        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        final int activeBatsmanIndex = _activeBatsman1Index;
        if (activeBatsmanIndex < currentBattingTeam.length) {
          currentBattingTeam[activeBatsmanIndex]['runs'] += batsmanRuns;
          // Balls faced for batsman are now incremented in button handlers BEFORE strike swap.
          if (isBoundary) {
            if (batsmanRuns == 4)
              currentBattingTeam[activeBatsmanIndex]['fours'] += 1;
            if (batsmanRuns == 6)
              currentBattingTeam[activeBatsmanIndex]['sixes'] += 1;
          }
          _updateStrikeRate(currentBattingTeam[activeBatsmanIndex]);
        }
      }

      // Update extras count
      if (isExtra) {
        _extras += totalRunsAdded;
      }

      // Update bowler stats (runs conceded)
      final List<Map<String, dynamic>> currentBowlingTeam =
          (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
              ? _teamABowlingStats
              : _teamBBowlingStats;
      if (_activeBowlerIndex < currentBowlingTeam.length) {
        // Bowler runs are NOT updated for Byes and Leg Byes.
        if (extraType != 'Bye' && extraType != 'Leg Bye') {
          currentBowlingTeam[_activeBowlerIndex]['runs'] += totalRunsAdded;
        }
        _updateEconomyRate(currentBowlingTeam[_activeBowlerIndex]);
      }
      // Strike rotation logic is now handled explicitly in button callbacks after ball processing.
    });
  }

  void _addWicket() async {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    final List<Map<String, dynamic>> currentBattingTeam =
        (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABattingStats
            : _teamBBattingStats;
    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    final List<Map<String, dynamic>> allOpponentPlayersForFielding =
        (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? [..._teamBBattingStats, ..._teamBBowlingStats]
            : [..._teamABattingStats, ..._teamABowlingStats];

    Map<String, dynamic>? dismissalDetails = await _showWicketTypeDialog(
      batsmanName: currentBattingTeam[_activeBatsman1Index]['name'],
      bowlerName: currentBowlingTeam[_activeBowlerIndex]['name'],
      teamBattingStats: currentBattingTeam,
      allOpponentPlayersForFielding: allOpponentPlayersForFielding,
    );

    if (dismissalDetails == null) {
      _restoreGameStateFromSnapshot(_lastGameStateSnapshot!);
      _lastGameStateSnapshot = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wicket action cancelled.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int runsCompletedOnRunOut = 0;
    if (dismissalDetails['type'] == 'Run Out') {
      int? r = await showDialog<int>(
        // Use direct showDialog for runs on run out
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Runs Completed Before Run Out'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  7, // Options for 0 to 6 runs
                  (index) => ListTile(
                        title: Text('$index run${index != 1 ? 's' : ''}'),
                        onTap: () => Navigator.of(dialogContext).pop(index),
                      )),
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

      if (r == null) {
        _restoreGameStateFromSnapshot(_lastGameStateSnapshot!);
        _lastGameStateSnapshot = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Run Out cancelled.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      runsCompletedOnRunOut = r;

      setState(() {
        _currentRuns += runsCompletedOnRunOut;
        _partnershipRuns += runsCompletedOnRunOut;

        // Credit runs to the batsman who was on strike BEFORE any potential strike swap for these runs
        final int batsmanToCreditRunsIndex = _activeBatsman1Index;
        if (batsmanToCreditRunsIndex < currentBattingTeam.length) {
          currentBattingTeam[batsmanToCreditRunsIndex]['runs'] +=
              runsCompletedOnRunOut;
          _updateStrikeRate(currentBattingTeam[batsmanToCreditRunsIndex]);
        }
        // Apply the strike rotation for the completed runs before the wicket.
        // This effectively changes who would be on strike for the *next* ball had the wicket not fallen.
        if (runsCompletedOnRunOut % 2 != 0) {
          _swapStrike();
        }
      });
    }

    setState(() {
      _currentWickets++;
      _partnershipRuns = 0;
      _partnershipBalls = 0;

      final int dismissedBatsmanIndex = dismissalDetails['type'] == 'Run Out' &&
              dismissalDetails['run_out_batsman_index'] != null
          ? dismissalDetails['run_out_batsman_index']
          : _activeBatsman1Index; // Default to current striker if not a specific run out

      // Increment balls faced for the dismissed batsman as this delivery resulted in their wicket.
      currentBattingTeam[dismissedBatsmanIndex]['balls']++;
      currentBattingTeam[dismissedBatsmanIndex]['dismissal'] =
          dismissalDetails['full_dismissal_text'];

      _incrementBallAndOverStats(); // A wicket always consumes a ball for the over count

      if (dismissalDetails['bowler_wicket']) {
        if (_activeBowlerIndex < currentBowlingTeam.length) {
          currentBowlingTeam[_activeBowlerIndex]['wickets'] += 1;
        }
      }
      _updateEconomyRate(currentBowlingTeam[_activeBowlerIndex]);

      _recordBallEvent(
        batsmanRuns: runsCompletedOnRunOut, // Record completed runs for run out
        extraRuns: 0,
        extraType: null,
        wicketTaken: true,
        wicketDetails: dismissalDetails,
      );

      // Find next available batsman
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
        // Logic to replace the dismissed batsman
        // If the dismissed batsman was the current striker, the new batsman becomes striker.
        // If the dismissed batsman was the non-striker, the new batsman becomes non-striker.
        if (dismissedBatsmanIndex == _activeBatsman1Index) {
          _activeBatsman1Index = nextBatsmanIndex;
        } else if (dismissedBatsmanIndex == _activeBatsman2Index) {
          _activeBatsman2Index = nextBatsmanIndex;
        } else {
          // This case should ideally not happen if dismissal is always active batsman
          // Handle defensively: if somehow another player was dismissed, replace them on the non-strike end.
          _activeBatsman2Index = nextBatsmanIndex;
        }
      } else {
        _endInnings(); // End innings if all wickets fallen or no available batsmen
        return;
      }

      _checkWinCondition();
    });
  }

  Future<Map<String, dynamic>?> _showWicketTypeDialog({
    required String batsmanName,
    required String bowlerName,
    required List<Map<String, dynamic>> teamBattingStats,
    required List<Map<String, dynamic>> allOpponentPlayersForFielding,
  }) async {
    String? selectedWicketType;
    String? caughtFielderName;
    int? runOutBatsmanIndex; // Changed from runOutPlayerIndex for clarity
    String? runOutDirectThrowerName;
    String? runOutReceiverName;

    final List<String> uniqueOpponentPlayerNames = allOpponentPlayersForFielding
        .map((player) => player['name'] as String)
        .toSet()
        .toList();
    uniqueOpponentPlayerNames.sort();

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
                  mainAxisSize: MainAxisSize.min,
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
                        'Obstructing the field'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedWicketType = newValue;
                          caughtFielderName = null;
                          runOutBatsmanIndex = null;
                          runOutDirectThrowerName = null;
                          runOutReceiverName = null;
                        });
                      },
                    ),
                    if (selectedWicketType == 'Caught') ...[
                      DropdownButtonFormField<String>(
                        value: caughtFielderName,
                        hint: const Text('Select Fielder (Optional)'),
                        items: uniqueOpponentPlayerNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
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
                      DropdownButtonFormField<int>(
                        value: runOutBatsmanIndex,
                        hint: const Text('Batsman Run Out'),
                        items: [
                          DropdownMenuItem<int>(
                            value: _activeBatsman1Index,
                            child: Text(teamBattingStats[_activeBatsman1Index]
                                    ['name'] +
                                " (Striker)"),
                          ),
                          DropdownMenuItem<int>(
                            value: _activeBatsman2Index,
                            child: Text(teamBattingStats[_activeBatsman2Index]
                                    ['name'] +
                                " (Non-Striker)"),
                          ),
                        ],
                        onChanged: (int? newValue) {
                          setState(() {
                            runOutBatsmanIndex = newValue;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: runOutDirectThrowerName,
                        hint: const Text('Direct Thrower (Optional)'),
                        items: uniqueOpponentPlayerNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
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
                        items: uniqueOpponentPlayerNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
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
                    Navigator.of(dialogContext).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedWicketType != null) {
                      String dismissalText = selectedWicketType!;
                      bool bowlerWicket = false;

                      switch (selectedWicketType) {
                        case 'Bowled':
                        case 'LBW':
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
                              : 'Fielder';
                          String receiver = runOutReceiverName != null &&
                                  runOutReceiverName!.isNotEmpty
                              ? runOutReceiverName!
                              : 'Fielder';
                          dismissalText = 'run out ($thrower/$receiver)';
                          bowlerWicket = false;
                          break;
                        case 'Hit Wicket':
                          dismissalText = 'hit wicket b $bowlerName';
                          bowlerWicket = true;
                          break;
                        case 'Obstructing the field':
                          dismissalText = 'obstructing the field';
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
                        'run_out_batsman_index': selectedWicketType == 'Run Out'
                            ? runOutBatsmanIndex
                            : null, // Add dismissed batsman index
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

  void _addDotBall() {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    setState(() {
      final List<Map<String, dynamic>> currentBattingTeam =
          (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
              ? _teamABattingStats
              : _teamBBattingStats;
      currentBattingTeam[_activeBatsman1Index]
          ['balls']++; // Striker faces the dot ball
    });

    _incrementBallAndOverStats(); // Dot ball consumes a ball
    _recordBallEvent(
      batsmanRuns: 0,
      extraRuns: 0,
      extraType: null,
      wicketTaken: false,
    );
    _checkWinCondition();
  }

  void _updateOvers() {
    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    if (_ballsInCurrentOver == 6) {
      _currentOvers = (_currentOvers.floor() + 1).toDouble();
      _ballsInCurrentOver = 0;
      _overByOverSummary.add({
        'over': _currentOvers.toInt(),
        'runs': _currentRuns,
        'wickets': _currentWickets,
      });
      if (_activeBowlerIndex < currentBowlingTeam.length) {
        currentBowlingTeam[_activeBowlerIndex]['overs'] =
            (currentBowlingTeam[_activeBowlerIndex]['overs'].floor() + 1.0);
      }
      _updateEconomyRate(currentBowlingTeam[_activeBowlerIndex]);

      _changeBowler();
      _swapStrike(); // Strike changes automatically at the end of an over
    } else {
      _currentOvers =
          _currentOvers.floorToDouble() + (_ballsInCurrentOver / 10.0);
      if (_activeBowlerIndex < currentBowlingTeam.length) {
        currentBowlingTeam[_activeBowlerIndex]['overs'] =
            _currentOvers.floorToDouble() + (_ballsInCurrentOver / 10.0);
      }
    }
  }

  void _updateStrikeRate(Map<String, dynamic> player) {
    if (player['balls'] > 0) {
      player['sr'] = double.parse(
          (player['runs'] / player['balls'] * 100).toStringAsFixed(2));
    } else {
      player['sr'] = 0.0;
    }
  }

  void _updateEconomyRate(Map<String, dynamic> bowler) {
    if (bowler['overs'] > 0) {
      bowler['economy'] =
          double.parse((bowler['runs'] / bowler['overs']).toStringAsFixed(2));
    } else {
      bowler['economy'] = 0.0;
    }
  }

  Future<void> _changeBowler() async {
    final List<Map<String, dynamic>> currentBowlingTeam =
        (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    int? newBowlerIndex = await _showPlayerSelectionDialog(
      title: 'Select New Bowler for ${_currentBowlingTeamName}',
      players: currentBowlingTeam,
      excludedIndices: [_activeBowlerIndex],
      isBatsman: false,
    );

    if (newBowlerIndex != null) {
      setState(() {
        _activeBowlerIndex = newBowlerIndex;
      });
    }
  }

  void _swapStrike() {
    setState(() {
      final temp = _activeBatsman1Index;
      _activeBatsman1Index = _activeBatsman2Index;
      _activeBatsman2Index = temp;
    });
  }

  Future<void> _handleByes() async {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    int? runs = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Byes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                5, // Options for 0 to 4 runs (1-4 on field + 1 extra)
                (index) => ListTile(
                      title:
                          Text('${index + 1} run${index + 1 > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(index + 1),
                    )),
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
        _addRunsToScore(totalRunsAdded: runs, isExtra: true, extraType: 'Bye');

        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        currentBattingTeam[_activeBatsman1Index]
            ['balls']++; // Striker faces the ball for Byes

        _incrementBallAndOverStats(); // Byes count as a ball in the over

        if (runs % 2 != 0) _swapStrike();
        _recordBallEvent(
          batsmanRuns: 0,
          extraRuns: runs,
          extraType: 'Bye',
          wicketTaken: false,
        );
      });
      _checkWinCondition();
    }
  }

  Future<void> _handleLegByes() async {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    int? runs = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs from Leg Byes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                5, // Options for 0 to 4 runs (1-4 on field + 1 extra)
                (index) => ListTile(
                      title:
                          Text('${index + 1} run${index + 1 > 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(index + 1),
                    )),
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
        _addRunsToScore(
            totalRunsAdded: runs, isExtra: true, extraType: 'Leg Bye');

        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        currentBattingTeam[_activeBatsman1Index]
            ['balls']++; // Striker faces the ball for Leg Byes

        _incrementBallAndOverStats(); // Leg Byes count as a ball in the over

        if (runs % 2 != 0) _swapStrike();
        _recordBallEvent(
          batsmanRuns: 0,
          extraRuns: runs,
          extraType: 'Leg Bye',
          wicketTaken: false,
        );
      });
      _checkWinCondition();
    }
  }

  Future<void> _handleWide() async {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    int? additionalRuns = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Additional Runs from Wide (excluding 1 penalty)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                7, // Options for 0 to 6 additional runs
                (index) => ListTile(
                      title: Text('$index run${index != 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(index),
                    )),
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

    if (additionalRuns != null) {
      setState(() {
        int totalRuns =
            1 + additionalRuns; // 1 for wide penalty + additional runs
        _addRunsToScore(
            totalRunsAdded: totalRuns, isExtra: true, extraType: 'Wide');

        // Wide does NOT count as a ball in the over or for batsman's balls faced.
        _recordBallEvent(
          batsmanRuns: 0,
          extraRuns: totalRuns, // Record total runs as extra
          extraType: 'Wide',
          wicketTaken: false,
        );
        // Only swap strike if additional runs (from fielding, excluding penalty) are odd
        if (additionalRuns % 2 != 0) _swapStrike();
      });
      _checkWinCondition();
    }
  }

  Future<void> _handleNoBall() async {
    _lastGameStateSnapshot =
        _createGameStateSnapshot(); // Capture state for undo

    int? runsOffBat = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Runs off Bat from No Ball'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                7, // Options for 0 to 6 runs off bat
                (index) => ListTile(
                      title: Text('$index run${index != 1 ? 's' : ''}'),
                      onTap: () => Navigator.of(dialogContext).pop(index),
                    )),
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
      setState(() {
        int totalRunsAdded =
            1 + runsOffBat; // 1 for no-ball penalty + runs off bat
        _addRunsToScore(
            totalRunsAdded: totalRunsAdded,
            batsmanRuns: runsOffBat,
            isExtra: true,
            extraType: 'No Ball');

        final List<Map<String, dynamic>> currentBattingTeam =
            (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
                ? _teamABattingStats
                : _teamBBattingStats;
        if (runsOffBat > 0 &&
            _activeBatsman1Index < currentBattingTeam.length) {
          currentBattingTeam[_activeBatsman1Index]
              ['balls']++; // Batsman faces a ball for runs off bat
        }

        // No Ball does NOT count as a ball in the over.
        if (runsOffBat % 2 != 0)
          _swapStrike(); // Only runs off bat change strike
        _recordBallEvent(
          batsmanRuns: runsOffBat,
          extraRuns: 1, // Record the 1 extra for no-ball penalty
          extraType: 'No Ball',
          wicketTaken: false,
        );
      });
      _checkWinCondition();
    }
  }

  void _endInnings() {
    if (_isFirstInnings) {
      _firstInningsRuns = _currentRuns;
      _firstInningsWickets = _currentWickets;
      _targetScore = _firstInningsRuns + 1;

      setState(() {
        _isFirstInnings = false;
        String tempTeamName = _currentBattingTeamName;
        _currentBattingTeamName = _currentBowlingTeamName;
        _currentBowlingTeamName = tempTeamName;

        _currentRuns = 0;
        _currentWickets = 0;
        _currentOvers = 0.0;
        _ballsInCurrentOver = 0;
        _extras = 0;
        _partnershipRuns = 0;
        _partnershipBalls = 0;
        _activeBatsman1Index = 0;
        _activeBatsman2Index = 1;
        _activeBowlerIndex = 0;

        // Reset player stats for the new innings (deep copy to avoid reference issues)
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
                  'maidens': 0,
                  'runs': 0,
                  'wickets': 0,
                  'economy': 0.0
                })
            .toList();

        _overByOverSummary.clear();
        _ballEvents.clear();
      });

      _showInningsBreakDialog();
    } else {
      _showWinnerDialog();
    }
  }

  void _showWinnerDialog() {
    String winnerText = '';
    String winningTeam = '';
    String losingTeam = '';

    if (_currentRuns >= _targetScore) {
      winningTeam = widget.match['teamB'] ?? 'Team South Africa';
      losingTeam = widget.match['teamA'] ?? 'Team India';
      winnerText = '$winningTeam won by ${10 - _currentWickets} wickets!';
    } else {
      winningTeam = widget.match['teamA'] ?? 'Team India';
      losingTeam = widget.match['teamB'] ?? 'Team South Africa';
      winnerText =
          '$winningTeam won by ${_firstInningsRuns - _currentRuns} runs!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor:
              Colors.blue.shade200.withOpacity(0.9), // Transparent blue
          title: const Text('Match Result',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          content: Text(
            winnerText,
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold)), // Changed to white
            ),
          ],
        );
      },
    );
  }

  void _showInningsBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor:
              Colors.blue.shade200.withOpacity(0.9), // Transparent blue
          title: const Text('Innings Break!',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          content: Text(
            '${widget.match['teamA'] ?? 'Team A'} scored $_firstInningsRuns/$_firstInningsWickets in their innings.\nTarget for ${widget.match['teamB'] ?? 'Team B'} is $_targetScore runs.',
            style: const TextStyle(color: Colors.blue, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continue',
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold)), // Changed to white
            ),
          ],
        );
      },
    );
  }

  void _checkWinCondition() {
    if (!_isFirstInnings) {
      if (_currentRuns >= _targetScore) {
        _showWinnerDialog();
      } else if (_currentWickets == 10 || _currentOvers >= 20.0) {
        _endInnings();
      }
    } else {
      if (_currentWickets == 10 || _currentOvers >= 20.0) {
        _endInnings();
      }
    }
  }

  // --- Undo Functionality ---
  void _undoLastAction() {
    if (_lastGameStateSnapshot != null) {
      _restoreGameStateFromSnapshot(_lastGameStateSnapshot!);
      _lastGameStateSnapshot = null; // Clear snapshot after undo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last action undone.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No action to undo.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey
      appBar: AppBar(
        title:
            const Text('Match Centre', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade100
            .withOpacity(0.5), // Lighter transparent blue for app bar
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _mainTabController,
          isScrollable: true,
          labelColor: Colors.blue.shade900, // Darker blue for selected label
          unselectedLabelColor: Colors.blue.shade500
              .withOpacity(0.7), // Mid transparent blue for unselected
          indicatorColor: Colors.blue.shade300
              .withOpacity(0.9), // Transparent light blue accent for indicator
          tabs: const [
            Tab(text: 'Scoring'),
            Tab(text: 'Scorecard'),
            Tab(text: 'Balls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildScoringView(match),
          _buildScorecardTabView(), // Call the method without args, it will use state
          _buildBallsView(),
        ],
      ),
    );
  }

  Widget _buildScoringView(Map<String, dynamic> match) {
    double crr = (_currentOvers > 0) ? (_currentRuns / _currentOvers) : 0.0;

    double rrr = 0.0;
    if (!_isFirstInnings &&
        _currentOvers < 20.0 &&
        _targetScore > _currentRuns) {
      int ballsRemaining = (20 * 6) - (_currentOvers * 6).round();
      int runsNeeded = _targetScore - _currentRuns;
      if (ballsRemaining > 0) {
        rrr = (runsNeeded / ballsRemaining) * 6;
      }
    }

    final List<Map<String, dynamic>> currentBattingTeamPlayers =
        (_currentBattingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABattingStats
            : _teamBBattingStats;
    final List<Map<String, dynamic>> currentBowlingTeamPlayers =
        (_currentBowlingTeamName == (widget.match['teamA'] ?? 'Team A'))
            ? _teamABowlingStats
            : _teamBBowlingStats;

    final String batsman1Name =
        (_activeBatsman1Index < currentBattingTeamPlayers.length &&
                _activeBatsman1Index >= 0)
            ? currentBattingTeamPlayers[_activeBatsman1Index]['name']
            : 'N/A';
    final String batsman2Name =
        (_activeBatsman2Index < currentBattingTeamPlayers.length &&
                _activeBatsman2Index >= 0)
            ? currentBattingTeamPlayers[_activeBatsman2Index]['name']
            : 'N/A';
    final String bowlerName =
        (_activeBowlerIndex < currentBowlingTeamPlayers.length &&
                _activeBowlerIndex >= 0)
            ? currentBowlingTeamPlayers[_activeBowlerIndex]['name']
            : 'N/A';

    final String batsman1Runs =
        (_activeBatsman1Index < currentBattingTeamPlayers.length &&
                _activeBatsman1Index >= 0)
            ? currentBattingTeamPlayers[_activeBatsman1Index]['runs'].toString()
            : '0';
    final String batsman1Balls = (_activeBatsman1Index <
                currentBattingTeamPlayers.length &&
            _activeBatsman1Index >= 0)
        ? currentBattingTeamPlayers[_activeBatsman1Index]['balls'].toString()
        : '0';
    final String batsman2Runs =
        (_activeBatsman2Index < currentBattingTeamPlayers.length &&
                _activeBatsman2Index >= 0)
            ? currentBattingTeamPlayers[_activeBatsman2Index]['runs'].toString()
            : '0';
    final String batsman2Balls = (_activeBatsman2Index <
                currentBattingTeamPlayers.length &&
            _activeBatsman2Index >= 0)
        ? currentBattingTeamPlayers[_activeBatsman2Index]['balls'].toString()
        : '0';

    final String bowlerOvers =
        (_activeBowlerIndex < currentBowlingTeamPlayers.length &&
                _activeBowlerIndex >= 0)
            ? currentBowlingTeamPlayers[_activeBowlerIndex]['overs']
                .toStringAsFixed(1)
            : '0.0';
    final String bowlerRuns =
        (_activeBowlerIndex < currentBowlingTeamPlayers.length &&
                _activeBowlerIndex >= 0)
            ? currentBowlingTeamPlayers[_activeBowlerIndex]['runs'].toString()
            : '0';
    final String bowlerWickets = (_activeBowlerIndex <
                currentBowlingTeamPlayers.length &&
            _activeBowlerIndex >= 0)
        ? currentBowlingTeamPlayers[_activeBowlerIndex]['wickets'].toString()
        : '0';

    return Column(
      children: [
        // Top Match Info Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50
              .withOpacity(0.3), // Very light transparent blue for top section
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                match['match'] ?? 'Unknown Match',
                style: TextStyle(color: Colors.blue.shade900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.match['teamA'] ?? 'Team A',
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (_selectedFirstBattingTeamName ==
                                  (widget.match['teamA'] ?? 'Team A'))
                              ? '$_currentRuns/$_currentWickets (${_currentOvers.toStringAsFixed(1)})'
                              : (_isFirstInnings
                                  ? ''
                                  : '$_firstInningsRuns/$_firstInningsWickets (20.0 Ov)'),
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text('vs',
                      style: TextStyle(
                          color: Colors.blue.shade700.withOpacity(0.8),
                          fontSize: 16)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.match['teamB'] ?? 'Team B',
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          (_selectedFirstBattingTeamName ==
                                  (widget.match['teamB'] ?? 'Team B'))
                              ? '$_currentRuns/$_currentWickets (${_currentOvers.toStringAsFixed(1)})'
                              : (_isFirstInnings
                                  ? ''
                                  : 'Target: $_targetScore'),
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isFirstInnings)
                Text(
                  '${_currentBattingTeamName} Batting',
                  style: TextStyle(
                      color: Colors.blue.shade700
                          .withOpacity(0.9), // Transparent blue
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                )
              else if (!_isFirstInnings && _targetScore > 0)
                Column(
                  children: [
                    Text(
                      '${_currentBattingTeamName} needs ${_targetScore - _currentRuns} runs in ${(20 * 6) - (_currentOvers * 6).round()} balls',
                      style: TextStyle(
                          color: Colors.blue.shade700
                              .withOpacity(0.9), // Transparent blue
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CRR: ${crr.toStringAsFixed(2)} RRR: ${rrr.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.blue.shade700.withOpacity(0.8),
                          fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bowler Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50
                        .withOpacity(0.4), // Light transparent blue
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blue.shade100
                            .withOpacity(0.6)), // Mid transparent blue border
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bowler',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bowlerName,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Runs/Wickets',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$bowlerRuns/$bowlerWickets ($bowlerOvers Ov)',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Batsmen Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50
                        .withOpacity(0.4), // Light transparent blue
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blue.shade100
                            .withOpacity(0.6)), // Mid transparent blue border
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Striker',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$batsman1Name*',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Runs (Balls)',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$batsman1Runs ($batsman1Balls)',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(
                          height: 20,
                          thickness: 1,
                          color: Colors.blue.shade100
                              .withOpacity(0.6)), // Transparent blue divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Non-Striker',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                batsman2Name,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Runs (Balls)',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$batsman2Runs ($batsman2Balls)',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Partnership - $_partnershipRuns($_partnershipBalls)',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(height: 16),
                // Last 5 Balls Summary
                if (_ballEvents.isNotEmpty) ...[
                  Text('Last 5 Balls:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900)), // Consistent blue
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _ballEvents.reversed.take(5) // Take last 5 events
                        .map((ball) {
                      String result = '';
                      Color ballColor = Colors.blue.shade200.withOpacity(
                          0.7); // Default transparent blue ball color
                      if (ball['wicket_taken']) {
                        result = 'W';
                        ballColor = Colors.red.shade700.withOpacity(
                            0.8); // Keep red for wicket, add transparency
                      } else if (ball['extra_runs'] > 0) {
                        result =
                            '${ball['extra_type'][0]}${ball['extra_runs']}';
                        ballColor = Colors.orange.shade700.withOpacity(
                            0.8); // Keep orange for extra, add transparency
                      } else {
                        result = ball['batsman_runs'].toString();
                        if (ball['batsman_runs'] == 4)
                          ballColor = Colors.blue.shade400.withOpacity(
                              0.8); // Darker transparent blue for 4
                        if (ball['batsman_runs'] == 6)
                          ballColor = Colors.blue.shade600.withOpacity(
                              0.9); // Even darker transparent blue for 6
                      }
                      return Chip(
                        label: Text(result,
                            style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: ballColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final List<Map<String, dynamic>> currentBattingTeam =
                              (_currentBattingTeamName ==
                                      (widget.match['teamA'] ?? 'Team A'))
                                  ? _teamABattingStats
                                  : _teamBBattingStats;

                          int? newBatsman1Index =
                              await _showPlayerSelectionDialog(
                            title:
                                'Select On-Strike Batsman for ${_currentBattingTeamName}',
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
                                'Select Non-Strike Batsman for ${_currentBattingTeamName}',
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
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Change Batsmen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade300
                              .withOpacity(0.7), // Transparent blue button
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _changeBowler,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Change Bowler'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade300
                              .withOpacity(0.7), // Transparent blue button
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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

  Widget _buildScoreButton(String text, VoidCallback onPressed,
      {bool isSecondary = false, bool isDanger = false}) {
    Color buttonColor = Colors.blue.shade50
        .withOpacity(0.9); // Default transparent blue button color
    Color textColor = Colors.blue.shade900; // Default text color
    if (isSecondary) {
      buttonColor = Colors.blue.shade100
          .withOpacity(0.8); // Lighter transparent blue for secondary
      textColor = Colors.blue.shade900;
    } else if (isDanger) {
      buttonColor = Colors.red.shade700
          .withOpacity(0.8); // Keep red for danger, add transparency
      textColor = Colors.white;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: 10), // Reduced vertical padding
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildScoringPad() {
    return Container(
      color: Colors.blue.shade50
          .withOpacity(0.6), // Light transparent blue for scoring pad
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildScoreButton('1', () {
                _addRunsToScore(totalRunsAdded: 1, batsmanRuns: 1);
                final List<Map<String, dynamic>> currentBattingTeam =
                    (_currentBattingTeamName ==
                            (widget.match['teamA'] ?? 'Team A'))
                        ? _teamABattingStats
                        : _teamBBattingStats;
                currentBattingTeam[_activeBatsman1Index]
                    ['balls']++; // Add ball to current striker
                _incrementBallAndOverStats();
                _recordBallEvent(
                  batsmanRuns: 1,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                );
                _swapStrike(); // Swap strike after all processing for odd runs
                _checkWinCondition();
              }),
              _buildScoreButton('2', () {
                _addRunsToScore(totalRunsAdded: 2, batsmanRuns: 2);
                final List<Map<String, dynamic>> currentBattingTeam =
                    (_currentBattingTeamName ==
                            (widget.match['teamA'] ?? 'Team A'))
                        ? _teamABattingStats
                        : _teamBBattingStats;
                currentBattingTeam[_activeBatsman1Index]
                    ['balls']++; // Add ball to current striker
                _incrementBallAndOverStats();
                _recordBallEvent(
                  batsmanRuns: 2,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                );
                // No strike swap for even runs
                _checkWinCondition();
              }),
              _buildScoreButton('3', () {
                _addRunsToScore(totalRunsAdded: 3, batsmanRuns: 3);
                final List<Map<String, dynamic>> currentBattingTeam =
                    (_currentBattingTeamName ==
                            (widget.match['teamA'] ?? 'Team A'))
                        ? _teamABattingStats
                        : _teamBBattingStats;
                currentBattingTeam[_activeBatsman1Index]
                    ['balls']++; // Add ball to current striker
                _incrementBallAndOverStats();
                _recordBallEvent(
                  batsmanRuns: 3,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                );
                _swapStrike(); // Swap strike after all processing for odd runs
                _checkWinCondition();
              }),
              _buildScoreButton('4', () {
                _addRunsToScore(
                    totalRunsAdded: 4, batsmanRuns: 4, isBoundary: true);
                final List<Map<String, dynamic>> currentBattingTeam =
                    (_currentBattingTeamName ==
                            (widget.match['teamA'] ?? 'Team A'))
                        ? _teamABattingStats
                        : _teamBBattingStats;
                currentBattingTeam[_activeBatsman1Index]
                    ['balls']++; // Add ball to current striker
                _incrementBallAndOverStats();
                _recordBallEvent(
                  batsmanRuns: 4,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                );
                // No strike swap for even runs
                _checkWinCondition();
              }),
              _buildScoreButton('6', () {
                _addRunsToScore(
                    totalRunsAdded: 6,
                    batsmanRuns: 6,
                    isBoundary: true,
                    isSix: true);
                final List<Map<String, dynamic>> currentBattingTeam =
                    (_currentBattingTeamName ==
                            (widget.match['teamA'] ?? 'Team A'))
                        ? _teamABattingStats
                        : _teamBBattingStats;
                currentBattingTeam[_activeBatsman1Index]
                    ['balls']++; // Add ball to current striker
                _incrementBallAndOverStats();
                _recordBallEvent(
                  batsmanRuns: 6,
                  extraRuns: 0,
                  extraType: null,
                  wicketTaken: false,
                );
                // No strike swap for even runs
                _checkWinCondition();
              }),
            ],
          ),
          Row(
            children: [
              _buildScoreButton('LB', _handleLegByes),
              _buildScoreButton('Bye', _handleByes),
              _buildScoreButton('Wide', _handleWide),
              _buildScoreButton('NB', _handleNoBall),
              _buildScoreButton('Dot', _addDotBall, isSecondary: true),
            ],
          ),
          Row(
            children: [
              _buildScoreButton('Out', _addWicket, isDanger: true),
              _buildScoreButton('Undo', _undoLastAction, isSecondary: true),
              _buildScoreButton('End Innings', _endInnings, isDanger: true),
            ],
          ),
        ],
      ),
    );
  }

  // --- Scorecard Tab View (dynamic data) ---
  Widget _buildScorecardTabView() {
    // Determine which team's stats to show based on the currently selected tab
    // These lists hold the overall stats, not specific to current innings.
    // The scorecard should always show the full batting/bowling lists for each team.

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(
                0.5), // Light transparent blue for tab bar background
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _scorecardTeamTabController,
            labelColor: Colors.blue.shade900, // Darker blue for selected label
            unselectedLabelColor: Colors.blue.shade500
                .withOpacity(0.7), // Mid transparent blue for unselected label
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.blue.shade300
                  .withOpacity(0.7), // Mid transparent blue for indicator
            ),
            tabs: [
              Tab(text: widget.match['teamA'] ?? 'Team A'),
              Tab(text: widget.match['teamB'] ?? 'Team B'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _scorecardTeamTabController,
            children: [
              // Team A's scorecard view: Team A Batting, Team B Bowling
              _buildTeamScorecard(
                widget.match['teamA'] ?? 'Team A', // Batting Team Name
                _teamABattingStats, // Team A's batting stats
                _teamBBowlingStats, // Team B's bowling stats against Team A
                widget.match['teamB'] ??
                    'Team B', // Bowling Team Name for title
              ),
              // Team B's scorecard view: Team B Batting, Team A Bowling
              _buildTeamScorecard(
                widget.match['teamB'] ?? 'Team B', // Batting Team Name
                _teamBBattingStats, // Team B's batting stats
                _teamABowlingStats, // Team A's bowling stats against Team B
                widget.match['teamA'] ??
                    'Team A', // Bowling Team Name for title
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                  color: Colors.blue)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: battingStats.length,
            itemBuilder: (context, index) {
              final player = battingStats[index];
              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player['name'] +
                                (player['dismissal'] == 'not out' ? '*' : ''),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'R: ${player['runs']} (B: ${player['balls']})',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '4s: ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${player['fours']}',
                            style: TextStyle(
                                color: Colors.blue.shade700.withOpacity(0.9),
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ', 6s: ',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${player['sixes']}',
                            style: TextStyle(
                                color: Colors.blue.shade700.withOpacity(0.9),
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ', SR: ${player['sr'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Text('Dismissal: ${player['dismissal']}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
          Card(
            elevation: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Extras',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _extras.toString(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  color: Colors.blue)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bowlingStats.length,
            itemBuilder: (context, index) {
              final player = bowlingStats[index];
              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player['name'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'O: ${player['overs'].toStringAsFixed(1)}, M: ${player['maidens']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                          'R: ${player['runs']}, W: ${player['wickets']}, Econ: ${player['economy'].toStringAsFixed(2)}'),
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
                  color: Colors.blue)), // Consistent blue
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _overByOverSummary.length,
            itemBuilder: (context, index) {
              final over = _overByOverSummary[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50
                        .withOpacity(0.5), // Light transparent blue
                    child: Text('${over['over']}',
                        style: TextStyle(
                            color: Colors.blue.shade800)), // Darker blue text
                  ),
                  title: Text('Runs: ${over['runs']}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text('Wickets: ${over['wickets']}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBallsView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ball-by-Ball Commentary',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue)), // Consistent blue
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ballEvents.length,
              reverse: true, // Show latest ball first
              itemBuilder: (context, index) {
                final ball = _ballEvents[index];
                String ballDescription = '${ball['over_display']} ';
                if (ball['wicket_taken']) {
                  ballDescription += 'WICKET! ${ball['dismissal']}';
                } else if (ball['extra_runs'] > 0) {
                  ballDescription +=
                      '${ball['extra_runs']} ${ball['extra_type']}';
                } else {
                  ballDescription +=
                      '${ball['batsman_runs']} run${ball['batsman_runs'] != 1 ? 's' : ''}';
                }
                ballDescription +=
                    ' by ${ball['batsman_name']} (Bowled by ${ball['bowler_name']}) - ${ball['total_score_after_ball']}';

                return Card(
                  elevation: 0.5,
                  margin:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      ballDescription,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
