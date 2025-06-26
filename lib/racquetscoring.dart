import 'package:flutter/material.dart';

class RacquetScoringScreen extends StatefulWidget {
  final List<String> team1Players;
  final List<String> team2Players;

  const RacquetScoringScreen({
    super.key,
    required this.team1Players,
    required this.team2Players,
  });

  @override
  State<RacquetScoringScreen> createState() => _RacquetScoringScreenState();
}

class _RacquetScoringScreenState extends State<RacquetScoringScreen> {
  int _team1Score = 0; // Current points for Team 1 in the active set
  int _team2Score = 0; // Current points for Team 2 in the active set

  int _team1Sets = 0; // Number of sets won by Team 1
  int _team2Sets = 0; // Number of sets won by Team 2

  // Stores history of points for undo functionality within the current set.
  // '1' means Team 1 scored, '2' means Team 2 scored.
  List<int> _pointHistory = [];

  // List to store the scores of each completed set
  // Each map will contain {'team1': score, 'team2': score} for a set
  List<Map<String, int>> _setScores = [];

  // Serve indicator: 1 for Team 1 serving, 2 for Team 2 serving, 0 for no active server
  // This will be managed automatically now.
  int _servingTeam = 0;

  final int _targetScore =
      21; // Target points to win a set (e.g., for badminton/pickleball)
  final int _winningLead = 2; // Required lead to win a set
  final int _targetSets = 3; // Best of 3 sets to win the match

  @override
  void initState() {
    super.initState();
    // Prompt for initial serve when the screen loads for a new match
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_team1Sets == 0 && _team2Sets == 0 && _servingTeam == 0) {
        _promptForInitialServe();
      }
    });
  }

  // Dialog to prompt for which team serves first
  Future<void> _promptForInitialServe() async {
    int? initialServer = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Who serves first?',
              style: TextStyle(color: Colors.blueAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(widget.team1Players.firstOrNull ?? 'Team 1'),
                onTap: () => Navigator.of(dialogContext).pop(1),
              ),
              ListTile(
                title: Text(widget.team2Players.firstOrNull ?? 'Team 2'),
                onTap: () => Navigator.of(dialogContext).pop(2),
              ),
            ],
          ),
        );
      },
    );

    if (initialServer != null) {
      setState(() {
        _servingTeam = initialServer;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team $_servingTeam will serve first.')),
        );
      });
    }
  }

  // Function to check if a set has been won
  void _checkSetWin() {
    bool team1WinsSet = false;
    bool team2WinsSet = false;

    // Standard winning condition: reach target score AND have a 2-point lead
    if (_team1Score >= _targetScore &&
        (_team1Score - _team2Score >= _winningLead)) {
      team1WinsSet = true;
    } else if (_team2Score >= _targetScore &&
        (_team2Score - _team1Score >= _winningLead)) {
      team2WinsSet = true;
    }
    // Deuce rule: if scores are tied at (target - 1) or higher (e.g., 20-20, 21-21),
    // play continues until one team has a 2-point lead.
    else if (_team1Score >= (_targetScore - 1) &&
        _team2Score >= (_targetScore - 1)) {
      if (_team1Score >= _team2Score + _winningLead) {
        team1WinsSet = true;
      } else if (_team2Score >= _team1Score + _winningLead) {
        team2WinsSet = true;
      }
    }

    if (team1WinsSet) {
      _endSet(1); // Team 1 wins the set
    } else if (team2WinsSet) {
      _endSet(2); // Team 2 wins the set
    }
  }

  // Function to increment Team 1's score
  void _incrementTeam1Score() {
    setState(() {
      _team1Score++;
      _pointHistory.add(1); // Record that Team 1 scored

      // Automatic serve change logic for rally scoring
      // If Team 1 was NOT serving and they scored, they get the serve.
      if (_servingTeam != 1) {
        _servingTeam = 1;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Serve changed to Team 1')),
        // );
      }
      _checkSetWin(); // Check for set win after each point
    });
  }

  // Function to decrement Team 1's score (cannot go below 0)
  // This is primarily for "undo" functionality.
  void _decrementTeam1Score() {
    setState(() {
      if (_team1Score > 0) {
        _team1Score--;
      }
    });
  }

  // Function to increment Team 2's score
  void _incrementTeam2Score() {
    setState(() {
      _team2Score++;
      _pointHistory.add(2); // Record that Team 2 scored

      // Automatic serve change logic for rally scoring
      // If Team 2 was NOT serving and they scored, they get the serve.
      if (_servingTeam != 2) {
        _servingTeam = 2;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serve changed to Team 2')),
        );
      }
      _checkSetWin(); // Check for set win after each point
    });
  }

  // Function to decrement Team 2's score (cannot go below 0)
  // This is primarily for "undo" functionality.
  void _decrementTeam2Score() {
    setState(() {
      if (_team2Score > 0) {
        _team2Score--;
      }
    });
  }

  // Function to end a set
  void _endSet(int winningTeam) {
    setState(() {
      // Store the current set's scores
      _setScores.add({'team1': _team1Score, 'team2': _team2Score});

      // Increment the winning team's set count
      if (winningTeam == 1) {
        _team1Sets++;
      } else {
        _team2Sets++;
      }

      // Reset current point scores and point history for the new set
      _team1Score = 0;
      _team2Score = 0;
      _pointHistory.clear(); // Clear point history as a new set begins

      // Determine next server: alternate serving team after each set
      _servingTeam =
          (winningTeam == 1) ? 2 : 1; // Winning team gets serve in next set.

      _showSetWinnerDialog(winningTeam == 1 ? 'Team 1' : 'Team 2');
    });
    // After set ends, check if the match has been won
    _checkMatchWin();
  }

  // Function to undo the last point scored in the current set
  void _undoLastPoint() {
    setState(() {
      if (_pointHistory.isNotEmpty) {
        int lastScoredTeam = _pointHistory.removeLast();
        if (lastScoredTeam == 1 && _team1Score > 0) {
          _team1Score--;
          // If undoing causes the score to be 0-0 and no previous serve, reset serve.
          // Or if the undone point was the one that gave a team the serve, revert serve.
          // This can get complex, for simplicity, we'll only revert serve if scores match
          // what they were before the point and the other team was serving.
          if (_team1Score == 0 && _team2Score == 0) {
            _servingTeam = 0; // Reset serve if back to 0-0
            _promptForInitialServe(); // Re-prompt for initial serve
          } else {
            // A more complex undo for serve would require tracking serve changes in _pointHistory
            // For now, we'll assume manual serve adjustment if undo breaks automatic flow.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Serve might need manual adjustment.')),
            );
          }
        } else if (lastScoredTeam == 2 && _team2Score > 0) {
          _team2Score--;
          if (_team1Score == 0 && _team2Score == 0) {
            _servingTeam = 0;
            _promptForInitialServe();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Serve might need manual adjustment.')),
            );
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last point undone.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No points to undo in current set.')),
        );
      }
    });
  }

  // Function to reset current set scores (not the entire match)
  void _resetCurrentSetScores() {
    setState(() {
      _team1Score = 0;
      _team2Score = 0;
      _pointHistory.clear(); // Also clear point history for the current set
      _servingTeam = 0; // Reset serve indicator
      _promptForInitialServe(); // Prompt for serve again for the new set
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current set score reset!')),
      );
    });
  }

  // Function to reset the entire match scores and set history
  void _resetMatch() {
    setState(() {
      _team1Score = 0;
      _team2Score = 0;
      _team1Sets = 0;
      _team2Sets = 0;
      _setScores.clear(); // Clear all recorded set scores
      _pointHistory.clear(); // Clear all point history
      _servingTeam = 0; // Reset serve indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match scores and history reset!')),
      );
    });
    // After resetting the match, prompt for the initial serve again
    _promptForInitialServe();
  }

  // Show set winner dialog
  void _showSetWinnerDialog(String winner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Winner!',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          content: Text(
              '$winner won the set! Current sets: Team 1: $_team1Sets, Team 2: $_team2Sets',
              style: const TextStyle(color: Colors.blueGrey)),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('OK', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to check if the match has been won
  void _checkMatchWin() {
    String? matchWinner;
    if (_team1Sets >= _targetSets) {
      matchWinner = widget.team1Players.firstOrNull ?? 'Team 1';
    } else if (_team2Sets >= _targetSets) {
      matchWinner = widget.team2Players.firstOrNull ?? 'Team 2';
    }

    if (matchWinner != null) {
      _showMatchWinnerDialog(matchWinner);
    }
  }

  // Show match winner dialog
  void _showMatchWinnerDialog(String winner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Match Over!',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          content: Text(
              'Congratulations! $winner won the match $_team1Sets - $_team2Sets.',
              style: const TextStyle(color: Colors.blueGrey)),
          actions: <Widget>[
            TextButton(
              child: const Text('New Match',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _resetMatch(); // Reset everything for a new match
              },
            ),
            ElevatedButton(
              child: const Text('Exit Match',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Go back to the previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700, // Blue button
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to confirm and end the match
  void _endMatchConfirm() {
    Navigator.pop(context); // Close bottom sheet first if it's open
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Match?',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          content: const Text(
              'Are you sure you want to end the current match? All current scores and set history will be lost.',
              style: TextStyle(color: Colors.blueGrey)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            ElevatedButton(
              child: const Text('End Match',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _resetMatch(); // Reset all scores and history
                Navigator.pop(
                    context); // Go back to the previous screen (e.g., tournament page)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700, // Red for destructive action
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to toggle the serving team (manual override)
  void _toggleServe() {
    setState(() {
      if (_servingTeam == 1) {
        _servingTeam = 2;
      } else {
        _servingTeam = 1;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serve toggled to Team $_servingTeam')),
      );
    });
  }

  // "More Options" functionality
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.blue.shade800, // Dark blue background for bottom sheet
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(15), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'More Options',
                style: TextStyle(
                  fontSize: 20, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15), // Reduced space
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.white),
                title: const Text('Undo Last Point',
                    style: TextStyle(
                        color: Colors.white, fontSize: 14)), // Smaller font
                onTap: () {
                  _undoLastPoint();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text('Reset Current Set',
                    style: TextStyle(
                        color: Colors.white, fontSize: 14)), // Smaller font
                onTap: () {
                  _resetCurrentSetScores();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.replay, color: Colors.white),
                title: const Text('Reset Entire Match',
                    style: TextStyle(
                        color: Colors.white, fontSize: 14)), // Smaller font
                onTap: () {
                  _resetMatch();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text('End Match',
                    style: TextStyle(
                        color: Colors.white, fontSize: 14)), // Smaller font
                onTap: () {
                  _endMatchConfirm(); // This will handle navigation and closing bottom sheet
                },
              ),
              const SizedBox(height: 15), // Reduced space
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600, // Button color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        8), // Slightly smaller border radius
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 8), // Smaller padding
                ),
                child: const Text('Close',
                    style: TextStyle(fontSize: 14)), // Smaller font
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine player names for display, ensuring they don't overflow
    String team1DisplayName = 'Player 1';
    if (widget.team1Players.isNotEmpty) {
      team1DisplayName = widget.team1Players.length > 1
          ? widget.team1Players.join(' / ')
          : widget.team1Players[0];
    }

    String team2DisplayName = 'Player 2';
    if (widget.team2Players.isNotEmpty) {
      team2DisplayName = widget.team2Players.length > 1
          ? widget.team2Players.join(' / ')
          : widget.team2Players[0];
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Match Scoring', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.blue.shade900, // AppBar background
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade900, // Overall background
      body: Column(
        children: <Widget>[
          // Player Names and Main Scores Section
          Expanded(
            flex: 4,
            child: Row(
              children: [
                // Team 1 Section (Left Side)
                Expanded(
                  child: Container(
                    color: Colors.blue.shade900, // Matching background
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          // Row for name and serve icon
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              team1DisplayName,
                              style: const TextStyle(
                                fontSize: 28, // Smaller font
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_servingTeam ==
                                1) // Show icon if Team 1 is serving
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.sports_tennis,
                                    color: Colors.amber,
                                    size: 24), // Amber for serve icon
                              ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced space
                        Text(
                          '$_team1Score', // Current points for Team 1
                          style: const TextStyle(
                            fontSize: 150, // Smaller score font
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White score
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Separator/Controls Column (Middle)
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.25, // Further adjusted width
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Set Scores
                      Text(
                        '$_team1Sets', // Team 1 Sets
                        style: const TextStyle(
                          fontSize: 40, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_team2Sets', // Team 2 Sets
                        style: const TextStyle(
                          fontSize: 40, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10), // Reduced space
                      // Reset Current Set Scores button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _resetCurrentSetScores,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue.shade700, // Blue button
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(6), // Smaller radius
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 6), // Smaller padding
                          ),
                          child: const Icon(Icons.refresh,
                              size: 20), // Smaller icon
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      // Serve Indicator Toggle Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _toggleServe, // Call the serve toggle function
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue.shade700, // Blue button
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Icon(Icons.sports_tennis,
                              size: 20), // Shuttlecock icon
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      // Decrement buttons and More Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _decrementTeam1Score,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue.shade700, // Blue button
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text('-',
                                  style:
                                      TextStyle(fontSize: 20)), // Smaller font
                            ),
                          ),
                          const SizedBox(width: 4), // Reduced spacing
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _showMoreOptions, // Linked to more options bottom sheet
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue.shade700, // Blue button
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Icon(Icons.more_horiz,
                                  size: 20), // Smaller icon
                            ),
                          ),
                          const SizedBox(width: 4), // Reduced spacing
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _decrementTeam2Score,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue.shade700, // Blue button
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text('-',
                                  style:
                                      TextStyle(fontSize: 20)), // Smaller font
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Team 2 Section (Right Side)
                Expanded(
                  child: Container(
                    color: Colors.blue.shade900, // Matching background
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          // Row for name and serve icon
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              team2DisplayName,
                              style: const TextStyle(
                                fontSize: 28, // Smaller font
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_servingTeam ==
                                2) // Show icon if Team 2 is serving
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.sports_tennis,
                                    color: Colors.amber,
                                    size: 24), // Amber for serve icon
                              ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced space
                        Text(
                          '$_team2Score', // Current points for Team 2
                          style: const TextStyle(
                            fontSize: 150, // Smaller score font
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White score
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Point Increment Buttons (at the bottom) - these are the big +1 buttons
          Container(
            color: Colors.blue.shade900, // Matching background
            padding:
                const EdgeInsets.fromLTRB(15, 8, 15, 15), // Reduced padding
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _incrementTeam1Score,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700, // Blue button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Smaller radius
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // Reduced padding
                    ),
                    child: Text(
                      '${widget.team1Players.firstOrNull ?? 'Team 1'}\n+1', // Dynamic label
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold), // Smaller font
                    ),
                  ),
                ),
                const SizedBox(width: 15), // Reduced spacing
                Expanded(
                  child: ElevatedButton(
                    onPressed: _incrementTeam2Score,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700, // Blue button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Smaller radius
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20), // Reduced padding
                    ),
                    child: Text(
                      '${widget.team2Players.firstOrNull ?? 'Team 2'}\n+1', // Dynamic label
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold), // Smaller font
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Set History
          Container(
            color: Colors.blue.shade900, // Matching background
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 15), // Reduced padding
            child: Column(
              children: [
                if (_setScores.isNotEmpty)
                  Column(
                    children: [
                      const Text(
                        'Set History:',
                        style: TextStyle(
                          fontSize: 16, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced space
                      // Use a Wrap for better flow of set score chips
                      Wrap(
                        spacing: 6.0, // Reduced horizontal space between chips
                        runSpacing: 3.0, // Reduced vertical space between lines
                        alignment: WrapAlignment.center,
                        children: _setScores.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, int> set = entry.value;
                          return Chip(
                            label: Text(
                              'S${index + 1}: ${set['team1']}-${set['team2']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12), // Smaller font
                            ),
                            backgroundColor: Colors.blue.shade600, // Blue chip
                            elevation: 1, // Reduced elevation
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2), // Smaller padding
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10), // Reduced space
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
