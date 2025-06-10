import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

// Data model for a single ball event
class BallEvent {
  final String bowler;
  final String batsman;
  final String event; // e.g., '1', '4', 'W', 'WD', 'NB', '0', 'B1', 'LB2'
  final int runs;
  String? dismissalDetails; // Made mutable now
  final bool isExtra; // True if Wide, No Ball, Bye, Leg Bye

  BallEvent({
    required this.bowler,
    required this.batsman,
    required this.event,
    required this.runs,
    this.dismissalDetails,
    this.isExtra = false,
  });
}

class MatchDetailPage extends StatefulWidget {
  final Map<String, dynamic> match;
  // isAdmin removed from constructor, as per previous request
  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage>
    with TickerProviderStateMixin {
  late TabController
      _teamTabController; // Not used currently, but kept for potential future use
  late TabController _inningsTabController;

  // Teams data - more structured
  // In a real app, these would likely come from a backend or props
  final Map<String, List<String>> allTeamPlayers = {
    'Team A': [
      'Js',
      'Db',
      'Mr',
      'Rm',
      'Tp',
      'Ak',
      'Jk',
      'Sl',
      'Np',
      'Vk',
      'Db2',
    ],
    'Team B': [
      'Pqr',
      'Sty',
      'Uvw',
      'Xyz',
      'Abc',
      'Def',
      'Ghi',
      'Jkl',
      'Mno',
      'Pqs',
      'Rst',
    ],
  };

  // Bowlers for both teams (simulated)
  final Map<String, List<String>> allTeamBowlers = {
    'Team A': ['Aisi', 'Bisi', 'Cisi', 'Disi'],
    'Team B': ['Zola', 'Yolo', 'Xena', 'Worm'],
  };

  // Current match state
  String currentBattingTeam = '';
  String currentBowlingTeam = '';

  // Innings data structure
  Map<int, InningsData> innings = {
    1: InningsData(inningsNumber: 1, teamName: 'Team A'),
    2: InningsData(inningsNumber: 2, teamName: 'Team B'),
  };
  int currentInningsNumber = 1;
  int maxOvers = 20; // Example max overs per innings

  // Get current innings data
  InningsData get currentInnings => innings[currentInningsNumber]!;

  @override
  void initState() {
    super.initState();
    _teamTabController = TabController(length: 2, vsync: this);
    _inningsTabController = TabController(length: 2, vsync: this);

    // Initialize the first innings
    currentBattingTeam = widget.match['team1'] ?? 'Team A';
    currentBowlingTeam = widget.match['team2'] ?? 'Team B';

    innings[1] = InningsData(
      inningsNumber: 1,
      teamName: currentBattingTeam,
      teamPlayers: allTeamPlayers[currentBattingTeam]!,
      bowlers: allTeamBowlers[currentBowlingTeam]!,
    );
    innings[2] = InningsData(
      inningsNumber: 2,
      teamName: currentBowlingTeam,
      teamPlayers: allTeamPlayers[currentBattingTeam]!,
      bowlers: allTeamBowlers[currentBattingTeam]!,
    );

    // Show batsmen selection for 1st innings when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialBatsmenSelectionDialog(innings[1]!).then((_) {
        // After batsmen are selected, initialize bowler
        _initializeBowlerStats(innings[1]!);
        innings[1]!.selectedBowlerName =
            innings[1]!.bowlers.isNotEmpty ? innings[1]!.bowlers[0] : null;
      });
    });

    // Listen to tab changes for innings
    _inningsTabController.addListener(() {
      if (!_inningsTabController.indexIsChanging) {
        setState(() {
          currentInningsNumber = _inningsTabController.index + 1;
        });
      }
    });
  }

  // --- Initial Batsmen Selection Dialog ---
  Future<void> _showInitialBatsmenSelectionDialog(
      InningsData inningsData) async {
    String? selectedStriker;
    String? selectedNonStriker;

    // Filter out already selected batsmen from the list of all players
    List<String> availableBatsmen = List.from(inningsData.teamPlayers);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must select batsmen
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Opening Batsmen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Striker'),
                      value: selectedStriker,
                      items: availableBatsmen
                          .where((player) => player != selectedNonStriker)
                          .map((player) => DropdownMenuItem(
                                value: player,
                                child: Text(player),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedStriker = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Non-Striker'),
                      value: selectedNonStriker,
                      items: availableBatsmen
                          .where((player) => player != selectedStriker)
                          .map((player) => DropdownMenuItem(
                                value: player,
                                child: Text(player),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedNonStriker = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    if (selectedStriker != null && selectedNonStriker != null) {
                      setState(() {
                        inningsData.batsmen = [
                          {
                            'name': selectedStriker!,
                            'runs': 0,
                            'balls': 0,
                            'fours': 0,
                            'sixes': 0,
                            'sr': 0.0
                          },
                          {
                            'name': selectedNonStriker!,
                            'runs': 0,
                            'balls': 0,
                            'fours': 0,
                            'sixes': 0,
                            'sr': 0.0
                          },
                        ];
                      });
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _initializeBowlerStats(InningsData inningsData) {
    inningsData.bowlersStats = {};
    for (var b in inningsData.bowlers) {
      inningsData.bowlersStats[b] = {
        'name': b,
        'overs': 0.0,
        'maidens': 0,
        'runs': 0,
        'wickets': 0,
        'economy': 0.0,
      };
    }
    if (inningsData.selectedBowlerName == null &&
        inningsData.bowlers.isNotEmpty) {
      inningsData.selectedBowlerName = inningsData.bowlers[0];
    }
  }

  @override
  void dispose() {
    _teamTabController.dispose();
    _inningsTabController.dispose();
    super.dispose();
  }

  void _handleBall(String value, {int extraRuns = 0}) {
    if (currentInnings.selectedBowlerName == null) return;

    if (currentInnings.batsmen.isEmpty || currentInnings.batsmen.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select opening batsmen first!')),
      );
      return;
    }

    setState(() {
      int runsScored = 0;
      bool isExtra = false;
      bool isBallCounted = true;
      String eventType = value;
      String batsmanName =
          currentInnings.batsmen[currentInnings.strikerIndex]['name'];

      if (['1', '2', '3', '4', '6', '0', '.'].contains(value)) {
        runsScored = int.tryParse(value) ?? 0;
      } else if (value == 'Wide' || value == 'NB') {
        isExtra = true;
        isBallCounted = false;
        runsScored = 1 + extraRuns;
      } else if (value.startsWith('B') || value.startsWith('LB')) {
        isExtra = true;
        runsScored = extraRuns;
        if (runsScored == 0 && value != '0' && extraRuns == 0) {
          _showExtraRunsDialog(value);
          return;
        }
      }

      currentInnings.totalRuns += runsScored;

      if (!isExtra) {
        currentInnings.batsmen[currentInnings.strikerIndex]['runs'] +=
            runsScored;
        currentInnings.batsmen[currentInnings.strikerIndex]['balls'] += 1;

        if (runsScored == 4)
          currentInnings.batsmen[currentInnings.strikerIndex]['fours'] += 1;
        if (runsScored == 6)
          currentInnings.batsmen[currentInnings.strikerIndex]['sixes'] += 1;
      }

      if (value != 'B' && value != 'LB') {
        currentInnings.currentBowler['runs'] += runsScored;
      }

      currentInnings.batsmen[currentInnings.strikerIndex]['sr'] =
          (currentInnings.batsmen[currentInnings.strikerIndex]['balls'] > 0)
              ? (currentInnings.batsmen[currentInnings.strikerIndex]['runs'] /
                      currentInnings.batsmen[currentInnings.strikerIndex]
                          ['balls']) *
                  100
              : 0.0;

      if (isBallCounted) {
        currentInnings.currentOverBalls++;
      }

      currentInnings.ballEvents.add(BallEvent(
        bowler: currentInnings.selectedBowlerName!,
        batsman: batsmanName,
        event: eventType,
        runs: runsScored,
        isExtra: isExtra,
        dismissalDetails: null,
      ));

      if (currentInnings.currentOverBalls >= 6) {
        currentInnings.currentOver++;
        currentInnings.currentOverBalls = 0;

        currentInnings.currentBowler['overs'] =
            currentInnings.currentOver.toDouble();

        bool isMaiden = true;
        int ballsConsideredForMaiden = 0;
        for (int i = currentInnings.ballEvents.length - 1;
            i >= 0 && ballsConsideredForMaiden < 6;
            i--) {
          final ball = currentInnings.ballEvents[i];
          if (ball.bowler == currentInnings.selectedBowlerName &&
              !ball.isExtra) {
            if (ball.runs > 0) {
              isMaiden = false;
              break;
            }
            ballsConsideredForMaiden++;
          }
        }
        if (isMaiden && ballsConsideredForMaiden == 6) {
          currentInnings.currentBowler['maidens'] += 1;
        }

        currentInnings.strikerIndex =
            (currentInnings.strikerIndex == 0) ? 1 : 0;

        currentInnings.lastDismissalDetails = null;

        if (currentInnings.currentOver < maxOvers &&
            currentInnings.totalWickets < 10) {
          _showBowlerChangeDialog();
        } else {
          _checkInningsEnd();
        }
      } else if (runsScored % 2 == 1 && !isExtra) {
        currentInnings.strikerIndex =
            (currentInnings.strikerIndex == 0) ? 1 : 0;
        currentInnings.lastDismissalDetails = null;
      } else if (runsScored % 2 == 0 && !isExtra && value != 'Out') {
        currentInnings.lastDismissalDetails = null;
      }

      currentInnings.currentBowler['economy'] =
          currentInnings.currentBowler['overs'] == 0
              ? 0.0
              : currentInnings.currentBowler['runs'] /
                  currentInnings.currentBowler['overs'];
    });
  }

  void _showExtraRunsDialog(String type) {
    TextEditingController _runsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Runs for $type'),
          content: TextField(
            controller: _runsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Runs'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final runs = int.tryParse(_runsController.text) ?? 0;
                Navigator.of(context).pop();
                _handleBall(type, extraRuns: runs);
              },
              child: const Text('Add Runs'),
            ),
          ],
        );
      },
    );
  }

  void _showBowlerChangeDialog() {
    List<String> availableBowlers = currentInnings.bowlers;

    String? newBowlerSelection = currentInnings.selectedBowlerName;
    if (newBowlerSelection == null && availableBowlers.isNotEmpty) {
      newBowlerSelection = availableBowlers[0];
    } else if (availableBowlers.isEmpty) {
      newBowlerSelection = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('End of Over! Change Bowler'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Select New Bowler'),
                    value: newBowlerSelection,
                    items: availableBowlers
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() => newBowlerSelection = val);
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: newBowlerSelection != null
                      ? () {
                          setState(() {
                            currentInnings.selectedBowlerName =
                                newBowlerSelection;
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Confirm Bowler'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWicketDialog() {
    if (currentInnings.selectedBowlerName == null) return;

    List<String> availableNewBatsmen = currentInnings.teamPlayers
        .where((name) =>
            !currentInnings.batsmen.map((b) => b['name']).contains(name) &&
            !currentInnings.batsmenAlreadyOut.contains(name))
        .toList();

    String? selectedNewBatsman;
    String? selectedDismissalType;
    String? catcherName;
    String? runOutBy;

    if (availableNewBatsmen.length == 1) {
      selectedNewBatsman = availableNewBatsmen[0];
    }

    List<String> dismissalTypes = [
      'Caught',
      'Bowled',
      'LBW',
      'Run Out',
      'Stumped',
      'Hit Wicket',
      'Other',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Wicket! Select Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'New Batsman'),
                    value: selectedNewBatsman,
                    items: availableNewBatsmen
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() => selectedNewBatsman = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Dismissal Type'),
                    value: selectedDismissalType,
                    items: dismissalTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedDismissalType = val;
                        if (val != 'Caught' &&
                            val != 'Stumped' &&
                            val != 'Run Out') {
                          catcherName = null;
                          runOutBy = null;
                        }
                      });
                    },
                  ),
                  if (selectedDismissalType == 'Caught' ||
                      selectedDismissalType == 'Stumped') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          labelText: selectedDismissalType == 'Caught'
                              ? 'Caught By'
                              : 'Stumped By'),
                      value: catcherName,
                      items: currentInnings.bowlers
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => catcherName = val);
                      },
                    ),
                  ],
                  if (selectedDismissalType == 'Run Out') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Run Out By'),
                      value: runOutBy,
                      items: currentInnings.bowlers
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => runOutBy = val);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed:
                    selectedNewBatsman != null && selectedDismissalType != null
                        ? () {
                            Navigator.of(context).pop();
                            _processWicket(
                              newBatsman: selectedNewBatsman!,
                              dismissalType: selectedDismissalType!,
                              catcher: catcherName,
                              runOutBy: runOutBy,
                            );
                          }
                        : null,
                child: const Text('Confirm'),
              ),
            ],
          );
        });
      },
    );
  }

  void _processWicket({
    required String newBatsman,
    required String dismissalType,
    String? catcher,
    String? runOutBy,
  }) {
    setState(() {
      currentInnings.totalWickets++;

      if (dismissalType != 'Run Out' &&
          currentInnings.selectedBowlerName != null) {
        currentInnings.currentBowler['wickets'] += 1;
      }

      final Map<String, dynamic> dismissedBatsmanStats =
          Map.from(currentInnings.batsmen[currentInnings.strikerIndex]);
      String outBatsmanName = dismissedBatsmanStats['name'];

      currentInnings.batsmenAlreadyOut.add(outBatsmanName);

      String details =
          "$outBatsmanName ${dismissedBatsmanStats['runs']} runs (${dismissedBatsmanStats['balls']} balls, ${dismissedBatsmanStats['fours']}x4, ${dismissedBatsmanStats['sixes']}x6) $dismissalType";
      if (dismissalType == 'Caught' && catcher != null) {
        details += " by $catcher";
      } else if (dismissalType == 'Stumped' && catcher != null) {
        details += " by $catcher";
      } else if (dismissalType == 'Run Out' && runOutBy != null) {
        details += " by $runOutBy";
      }
      currentInnings.lastDismissalDetails = details;

      if (currentInnings.ballEvents.isNotEmpty) {
        currentInnings.ballEvents.last.dismissalDetails =
            currentInnings.lastDismissalDetails;
      }

      currentInnings.batsmen[currentInnings.strikerIndex] = {
        'name': newBatsman,
        'runs': 0,
        'balls': 0,
        'fours': 0,
        'sixes': 0,
        'sr': 0.0,
      };

      currentInnings.currentOverBalls++;

      if (currentInnings.currentOverBalls >= 6) {
        currentInnings.currentOver++;
        currentInnings.currentOverBalls = 0;
        currentInnings.currentBowler['overs'] =
            currentInnings.currentOver.toDouble();

        bool isMaiden = true;
        int ballsConsideredForMaiden = 0;
        for (int i = currentInnings.ballEvents.length - 1;
            i >= 0 && ballsConsideredForMaiden < 6;
            i--) {
          final ball = currentInnings.ballEvents[i];
          if (ball.bowler == currentInnings.selectedBowlerName &&
              !ball.isExtra) {
            if (ball.runs > 0) {
              isMaiden = false;
              break;
            }
            ballsConsideredForMaiden++;
          }
        }
        if (isMaiden && ballsConsideredForMaiden == 6) {
          currentInnings.currentBowler['maidens'] += 1;
        }

        currentInnings.strikerIndex =
            (currentInnings.strikerIndex == 0) ? 1 : 0;
      } else {}

      currentInnings.currentBowler['economy'] =
          currentInnings.currentBowler['overs'] == 0
              ? 0.0
              : currentInnings.currentBowler['runs'] /
                  currentInnings.currentBowler['overs'];

      _checkInningsEnd();
    });
  }

  void _checkInningsEnd() {
    if ((currentInnings.currentOver >= maxOvers) ||
        (currentInnings.totalWickets >= 10) ||
        (currentInnings.batsmenAlreadyOut.length >=
            currentInnings.teamPlayers.length - 1)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Innings Over!'),
            content: Text(
                '${currentInnings.teamName} has scored ${currentInnings.totalRuns}-${currentInnings.totalWickets} in ${currentInnings.oversDisplay} overs.'),
            actions: [
              if (currentInningsNumber < 2)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startNextInnings();
                  },
                  child: const Text('Start Next Innings'),
                ),
              if (currentInningsNumber == 2 ||
                  (currentInningsNumber == 1 &&
                      (currentInnings.totalWickets >= 10 ||
                          currentInnings.currentOver >= maxOvers ||
                          currentInnings.batsmenAlreadyOut.length >=
                              currentInnings.teamPlayers.length - 1)))
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _endMatch();
                  },
                  child: const Text('End Match'),
                ),
            ],
          );
        },
      );
    }
  }

  void _startNextInnings() async {
    setState(() {
      if (currentInningsNumber < 2) {
        currentInningsNumber++;
        String tempBattingTeam = currentBattingTeam;
        currentBattingTeam = currentBowlingTeam;
        currentBowlingTeam = tempBattingTeam;

        innings[currentInningsNumber] = InningsData(
          inningsNumber: currentInningsNumber,
          teamName: currentBattingTeam,
          teamPlayers: allTeamPlayers[currentBattingTeam]!,
          bowlers: allTeamBowlers[currentBowlingTeam]!,
        );

        _inningsTabController.animateTo(currentInningsNumber - 1);
      }
    });

    await _showInitialBatsmenSelectionDialog(currentInnings);

    setState(() {
      _initializeBowlerStats(currentInnings);
      currentInnings.selectedBowlerName =
          currentInnings.bowlers.isNotEmpty ? currentInnings.bowlers[0] : null;
    });
  }

  void _endMatch() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String result = '';
        final innings1 = innings[1]!;
        final innings2 = innings[2]!;

        if (innings1.totalRuns > innings2.totalRuns) {
          result =
              '${innings1.teamName} won by ${innings1.totalRuns - innings2.totalRuns} runs!';
        } else if (innings2.totalRuns > innings1.totalRuns) {
          if (innings2.totalRuns > innings1.totalRuns) {
            result =
                '${innings2.teamName} won by ${10 - innings2.totalWickets} wickets! (Target: ${innings1.totalRuns + 1})';
          } else {
            result = 'Match Ended!';
          }
        } else {
          result = 'Match Drawn!';
        }

        return AlertDialog(
          title: const Text('Match Ended!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Final Score:'),
              Text(
                  '${innings1.teamName}: ${innings1.totalRuns}-${innings1.totalWickets} (${innings1.oversDisplay} Overs)'),
              Text(
                  '${innings2.teamName}: ${innings2.totalRuns}-${innings2.totalWickets} (${innings2.oversDisplay} Overs)'),
              const SizedBox(height: 10),
              Text(result,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match['match'] ?? 'Match Detail'),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        bottom: TabBar(
          controller: _inningsTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Innings 1'),
            Tab(text: 'Innings 2'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _inningsTabController,
        children: innings.entries.map((entry) {
          final inningsData = entry.value;
          return _buildInningsView(
              inningsData, entry.key == currentInningsNumber);
        }).toList(),
      ),
    );
  }

  Widget _buildInningsView(InningsData inningsData, bool isActiveInnings) {
    return SingleChildScrollView(
      // Main vertical scroll
      child: Column(
        children: [
          // Main Score Card
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade400
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "${widget.match['match']} - ${inningsData.inningsNumber}st Innings",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "(${inningsData.teamName})",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "${inningsData.totalRuns}-${inningsData.totalWickets}",
                    style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  Text(
                    "Overs: ${inningsData.oversDisplay} / $maxOvers | CRR: ${inningsData.oversAsDecimal == 0 ? 0.0 : (inningsData.totalRuns / inningsData.oversAsDecimal).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  if (inningsData.lastDismissalDetails != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      inningsData.lastDismissalDetails!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                          fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Batsman Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Batsmen",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple)),
                  const Divider(color: Colors.deepPurpleAccent),
                  SingleChildScrollView(
                    // Horizontal scroll for Batsman DataTable
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 10,
                      horizontalMargin: 0,
                      columns: const [
                        DataColumn(
                            label: Text("Name",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("R",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("B",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("4s",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("6s",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("SR",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: inningsData.batsmen.map((batsman) {
                        bool isStriker = inningsData.batsmen.indexOf(batsman) ==
                                inningsData.strikerIndex &&
                            isActiveInnings;
                        return DataRow(
                          cells: [
                            DataCell(Text(
                                "${batsman['name']}${isStriker ? ' *' : ''}",
                                style: TextStyle(
                                    fontWeight: isStriker
                                        ? FontWeight.bold
                                        : FontWeight.normal))),
                            DataCell(Text("${batsman['runs']}")),
                            DataCell(Text("${batsman['balls']}")),
                            DataCell(Text("${batsman['fours']}")),
                            DataCell(Text("${batsman['sixes']}")),
                            DataCell(
                                Text("${batsman['sr'].toStringAsFixed(1)}")),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  if (inningsData.batsmenAlreadyOut.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text("Dismissed Batsmen",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepPurple)),
                    const Divider(color: Colors.deepPurpleAccent),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: inningsData.batsmenAlreadyOut
                          .map((name) => Chip(
                                label: Text(name,
                                    style: const TextStyle(fontSize: 13)),
                                backgroundColor: Colors.grey.shade200,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Bowler Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bowlers",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple)),
                  const Divider(color: Colors.deepPurpleAccent),
                  SingleChildScrollView(
                    // Horizontal scroll for Bowler DataTable
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 10,
                      horizontalMargin: 0,
                      columns: const [
                        DataColumn(
                            label: Text("Name",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("O",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("M",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("R",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("W",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text("Econ",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: inningsData.bowlersStats.values.map((bowler) {
                        return DataRow(cells: [
                          DataCell(Text(bowler['name'])),
                          DataCell(Text(bowler['overs'].toStringAsFixed(1))),
                          DataCell(Text("${bowler['maidens']}")),
                          DataCell(Text("${bowler['runs']}")),
                          DataCell(Text("${bowler['wickets']}")),
                          DataCell(
                              Text("${bowler['economy'].toStringAsFixed(2)}")),
                        ]);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (inningsData.selectedBowlerName != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Current Bowler:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        DropdownButton<String>(
                          value: inningsData.selectedBowlerName,
                          items: inningsData.bowlers
                              .map((b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ))
                              .toList(),
                          onChanged: isActiveInnings
                              ? (val) {
                                  setState(() {
                                    inningsData.selectedBowlerName = val;
                                  });
                                }
                              : null,
                          dropdownColor: Colors.white,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Overs Summary Section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildOverByOverSummary(inningsData),
            ),
          ),
          const SizedBox(height: 10),

          // Admin Input Panel (always visible as per previous request)
          if (isActiveInnings &&
              currentInnings.totalWickets < 10 &&
              currentInnings.currentOver < maxOvers)
            _buildAdminInputPanel(),

          // End Match / Start Next Innings Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                if (!isActiveInnings &&
                    currentInningsNumber < 2 &&
                    (innings[1]!.totalWickets >= 10 ||
                        innings[1]!.currentOver >= maxOvers ||
                        innings[1]!.batsmenAlreadyOut.length >=
                            innings[1]!.teamPlayers.length - 1))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startNextInnings,
                      icon: const Icon(Icons.forward),
                      label: const Text('Start Next Innings',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if ((currentInnings.totalWickets >= 10 ||
                    currentInnings.currentOver >= maxOvers ||
                    currentInningsNumber == 2 ||
                    currentInnings.batsmenAlreadyOut.length >=
                        currentInnings.teamPlayers.length - 1))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endMatch,
                      icon: const Icon(Icons.flag),
                      label: const Text('End Match',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Extra space at the bottom
        ],
      ),
    );
  }

  Widget _buildOverByOverSummary(InningsData inningsData) {
    Map<int, List<BallEvent>> oversMap = {};
    for (int i = 0; i < inningsData.ballEvents.length; i++) {
      final ballEvent = inningsData.ballEvents[i];
      final overNumber = i ~/ 6;
      oversMap.putIfAbsent(overNumber, () => []).add(ballEvent);
    }

    List<Widget> overWidgets = [];
    // Iterate through overs in reverse order to show most recent first
    for (int i = oversMap.length - 1; i >= 0; i--) {
      final List<BallEvent> ballsInOver = oversMap[i]!;
      overWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Over ${i + 1}:",
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
              const SizedBox(height: 5),
              SingleChildScrollView(
                // Horizontal scroll for balls in an over
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ballsInOver.map((ball) {
                    String displayText;
                    Color bgColor;
                    Color textColor =
                        Colors.white; // Default text color for circles

                    if (ball.dismissalDetails != null) {
                      displayText = 'W';
                      bgColor = Colors.red;
                    } else if (ball.event == 'Wide') {
                      displayText = 'WD';
                      bgColor = Colors.orangeAccent;
                      textColor = Colors
                          .black; // Text color for clarity on light orange
                    } else if (ball.event == 'NB') {
                      displayText = 'NB';
                      bgColor = Colors.orangeAccent;
                      textColor = Colors.black;
                    } else if (ball.event == 'B') {
                      displayText = 'B${ball.runs}';
                      bgColor = Colors.orangeAccent;
                      textColor = Colors.black;
                    } else if (ball.event == 'LB') {
                      displayText = 'LB${ball.runs}';
                      bgColor = Colors.orangeAccent;
                      textColor = Colors.black;
                    } else if (ball.runs == 4) {
                      displayText = '4';
                      bgColor = Colors.greenAccent.shade700;
                    } else if (ball.runs == 6) {
                      displayText = '6';
                      bgColor = Colors.green; // Darker green for 6
                    } else if (ball.event == '.') {
                      displayText = '.';
                      bgColor = Colors.grey.shade400;
                      textColor = Colors.black;
                    } else {
                      // 0, 1, 2, 3 runs
                      displayText = '${ball.runs}';
                      bgColor = Colors.blueAccent;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Overs Summary",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.deepPurple)),
        const Divider(color: Colors.deepPurpleAccent),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: overWidgets,
        ),
      ],
    );
  }

  Widget _buildAdminInputPanel() {
    final labels = [
      '1',
      '2',
      '3',
      '4',
      '6',
      '.',
      'Out',
      'Wide',
      'NB',
      'B',
      'LB'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: labels
            .map((label) => ElevatedButton(
                  onPressed: () {
                    if (label == 'Out') {
                      _showWicketDialog();
                    } else if (label == 'B' || label == 'LB') {
                      _showExtraRunsDialog(label);
                    } else {
                      _handleBall(label);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        label == 'Out' ? Colors.red.shade600 : Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 5,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text(label),
                ))
            .toList(),
      ),
    );
  }
}

// Helper class to encapsulate innings data
class InningsData {
  final int inningsNumber;
  final String teamName;
  final List<String> teamPlayers;
  final List<String> bowlers;

  int totalRuns = 0;
  int totalWickets = 0;
  int currentOverBalls = 0;
  int currentOver = 0;
  String? lastDismissalDetails;

  List<Map<String, dynamic>> batsmen = [];
  int strikerIndex = 0;

  List<String> batsmenAlreadyOut = [];

  Map<String, Map<String, dynamic>> bowlersStats = {};
  String? selectedBowlerName;

  List<BallEvent> ballEvents = [];

  Map<String, dynamic> get currentBowler {
    if (selectedBowlerName != null &&
        bowlersStats.containsKey(selectedBowlerName)) {
      return bowlersStats[selectedBowlerName!]!;
    }
    return {
      'name': 'N/A',
      'overs': 0.0,
      'maidens': 0,
      'runs': 0,
      'wickets': 0,
      'economy': 0.0
    };
  }

  String get oversDisplay {
    return '$currentOver.$currentOverBalls';
  }

  double get oversAsDecimal {
    return currentOver + (currentOverBalls / 6.0);
  }

  InningsData({
    required this.inningsNumber,
    required this.teamName,
    this.teamPlayers = const [],
    this.bowlers = const [],
  });
}
