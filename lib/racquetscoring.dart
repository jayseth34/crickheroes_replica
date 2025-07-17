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

  // Service control
  List<String> _allPlayers =
      []; // Combined list of all players for serve rotation
  int _currentServerIndex = 0; // Global index of the player currently serving
  int _servingTeam =
      0; // 1 for Team 1 serving, 2 for Team 2 serving, 0 for no active server

  final int _targetScore =
      21; // Target points to win a set (e.g., for badminton/pickleball)
  final int _winningLead = 2; // Required lead to win a set
  final int _targetSets = 3; // Best of 3 sets to win the match

  @override
  void initState() {
    super.initState();
    _allPlayers = [...widget.team1Players, ...widget.team2Players];

    // Prompt for initial serve when the screen loads for a new match
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_team1Sets == 0 && _team2Sets == 0 && _servingTeam == 0) {
        _promptForInitialServe();
      }
    });
  }

  // Helper to determine team ID from player name
  int _getTeamIdForPlayer(String playerName) {
    if (widget.team1Players.contains(playerName)) {
      return 1;
    } else if (widget.team2Players.contains(playerName)) {
      return 2;
    }
    return 0; // Should not happen if player is in _allPlayers
  }

  // Dialog to prompt for which player serves first
  Future<void> _promptForInitialServe() async {
    String? initialServerName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Who serves first?',
              style: TextStyle(color: Colors.blueAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allPlayers
                .map((playerName) => ListTile(
                      title: Text(playerName),
                      onTap: () => Navigator.of(dialogContext).pop(playerName),
                    ))
                .toList(),
          ),
        );
      },
    );

    if (initialServerName != null) {
      setState(() {
        _currentServerIndex = _allPlayers.indexOf(initialServerName);
        _servingTeam = _getTeamIdForPlayer(initialServerName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '$initialServerName (${_servingTeam == 1 ? 'Team 1' : 'Team 2'}) will serve first.')),
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

      // If Team 1 was NOT serving and they scored (service break)
      if (_servingTeam != 1) {
        _currentServerIndex = (_currentServerIndex + 1) %
            _allPlayers.length; // Rotate to next player globally
        _servingTeam = _getTeamIdForPlayer(_allPlayers[_currentServerIndex]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Serve changed to ${_allPlayers[_currentServerIndex]}')),
        );
      } else {
        // Team 1 was serving and won the point. Now, the other player on Team 1 should serve.
        List<String> currentServingTeamPlayers = widget.team1Players;
        if (currentServingTeamPlayers.length > 1) {
          // Only if there's another player to switch to
          String currentServerName = _allPlayers[_currentServerIndex];
          int currentServerTeamPlayerIndex =
              currentServingTeamPlayers.indexOf(currentServerName);

          // Find the next player in the current serving team's list
          int nextPlayerInTeamIndex = (currentServerTeamPlayerIndex + 1) %
              currentServingTeamPlayers.length;
          String nextServerName =
              currentServingTeamPlayers[nextPlayerInTeamIndex];

          _currentServerIndex =
              _allPlayers.indexOf(nextServerName); // Update global index
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Serve changed to $nextServerName (Team 1)')),
          );
        }
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

      // If Team 2 was NOT serving and they scored (service break)
      if (_servingTeam != 2) {
        _currentServerIndex = (_currentServerIndex + 1) %
            _allPlayers.length; // Rotate to next player globally
        _servingTeam = _getTeamIdForPlayer(_allPlayers[_currentServerIndex]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Serve changed to ${_allPlayers[_currentServerIndex]}')),
        );
      } else {
        // Team 2 was serving and won the point. Now, the other player on Team 2 should serve.
        List<String> currentServingTeamPlayers = widget.team2Players;
        if (currentServingTeamPlayers.length > 1) {
          // Only if there's another player to switch to
          String currentServerName = _allPlayers[_currentServerIndex];
          int currentServerTeamPlayerIndex =
              currentServingTeamPlayers.indexOf(currentServerName);

          // Find the next player in the current serving team's list
          int nextPlayerInTeamIndex = (currentServerTeamPlayerIndex + 1) %
              currentServingTeamPlayers.length;
          String nextServerName =
              currentServingTeamPlayers[nextPlayerInTeamIndex];

          _currentServerIndex =
              _allPlayers.indexOf(nextServerName); // Update global index
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Serve changed to $nextServerName (Team 2)')),
          );
        }
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

      // Determine next server: Winning team gets to serve the next set.
      _servingTeam = winningTeam; // The winning team serves next set.

      // Find the next available player in the rotation from the winning team to serve
      int startingSearchIndex = _currentServerIndex;
      int nextServerIndex = -1;
      for (int i = 0; i < _allPlayers.length; i++) {
        int potentialServerIndex =
            (startingSearchIndex + i) % _allPlayers.length;
        String playerName = _allPlayers[potentialServerIndex];
        int playerTeam = _getTeamIdForPlayer(playerName);

        if (playerTeam == winningTeam) {
          nextServerIndex = potentialServerIndex;
          break;
        }
      }
      // Fallback to first player of winning team if calculation fails or list is empty
      _currentServerIndex = nextServerIndex != -1 ? nextServerIndex : 0;
      // Ensure the serving team is correctly set based on the chosen player
      _servingTeam = _getTeamIdForPlayer(_allPlayers[_currentServerIndex]);

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
        } else if (lastScoredTeam == 2 && _team2Score > 0) {
          _team2Score--;
        }
        // Reverting serve logic on undo can be complex for a circular rotation.
        // For simplicity, we won't automatically revert server index on undo
        // but will allow manual adjustment via _toggleServe or resetting set/match.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Last point undone. Serve might need manual adjustment.')),
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
      _servingTeam = 0; // Reset serve indicator to trigger initial prompt
    });
    _promptForInitialServe(); // Prompt for serve again for the new set
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Current set score reset!')),
    );
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
      _servingTeam = 0; // Reset serve indicator to trigger initial prompt
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match scores and history reset!')),
    );
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
      _currentServerIndex = (_currentServerIndex + 1) % _allPlayers.length;
      _servingTeam = _getTeamIdForPlayer(_allPlayers[_currentServerIndex]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Serve manually toggled to ${_allPlayers[_currentServerIndex]}')),
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
                  fontSize: 18, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12), // Reduced space
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.white),
                title: const Text('Undo Last Point',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13)), // Smaller font
                onTap: () {
                  _undoLastPoint();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text('Reset Current Set',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13)), // Smaller font
                onTap: () {
                  _resetCurrentSetScores();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.replay, color: Colors.white),
                title: const Text('Reset Entire Match',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13)), // Smaller font
                onTap: () {
                  _resetMatch();
                  Navigator.pop(context); // Close bottom sheet
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text('End Match',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13)), // Smaller font
                onTap: () {
                  _endMatchConfirm(); // This will handle navigation and closing bottom sheet
                },
              ),
              const SizedBox(height: 12), // Reduced space
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
                      horizontal: 12, vertical: 6), // Smaller padding
                ),
                child: const Text('Close',
                    style: TextStyle(fontSize: 13)), // Smaller font
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
          ? widget.team1Players
              .join('\n') // Use newline for wrapping multiple players
          : widget.team1Players[0];
    }

    String team2DisplayName = 'Player 2';
    if (widget.team2Players.isNotEmpty) {
      team2DisplayName = widget.team2Players.length > 1
          ? widget.team2Players
              .join('\n') // Use newline for wrapping multiple players
          : widget.team2Players[0];
    }

    // Get the name of the player currently serving for display
    String currentServerName = (_servingTeam != 0 &&
            _currentServerIndex >= 0 &&
            _currentServerIndex < _allPlayers.length)
        ? _allPlayers[_currentServerIndex]
        : 'N/A';

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
          // Main Score and Team Info Section
          Expanded(
            flex: 5, // Give more flex to the main scoring area
            child: Row(
              children: [
                // Team 1 Section (Left Side)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0), // Added padding
                    color: Colors.blue.shade900,
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly, // Distribute space
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Team 1 Name
                            Text(
                              team1DisplayName,
                              style: const TextStyle(
                                fontSize: 16, // Smaller font for names
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2, // Limit to 2 lines
                              overflow: TextOverflow.ellipsis, // Add ellipsis
                            ),
                            // Current Server for Team 1
                            if (_servingTeam == 1)
                              Text(
                                '($currentServerName serving)', // Explicit serving text
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11), // Smaller font
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        // Team 1 Score
                        Text(
                          '$_team1Score',
                          style: const TextStyle(
                            fontSize: 90, // Further adjusted score font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Team 1 Sets (Optional: could be moved to center or a summary)
                        Text(
                          'Sets: $_team1Sets',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Central Control Column
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.18, // Adjusted width for controls
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly, // Distribute space
                    children: [
                      // Reset Current Set Scores button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _resetCurrentSetScores,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 2), // Smaller padding
                            minimumSize: const Size(0, 30), // Min height
                          ),
                          child: const Icon(Icons.refresh, size: 16),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Serve Indicator Toggle Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _toggleServe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Icon(Icons.sports_tennis, size: 16),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // More Options button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showMoreOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Icon(Icons.more_horiz, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // Team 2 Section (Right Side)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0), // Added padding
                    color: Colors.blue.shade900,
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly, // Distribute space
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Team 2 Name
                            Text(
                              team2DisplayName,
                              style: const TextStyle(
                                fontSize: 16, // Smaller font for names
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2, // Limit to 2 lines
                              overflow: TextOverflow.ellipsis, // Add ellipsis
                            ),
                            // Current Server for Team 2
                            if (_servingTeam == 2)
                              Text(
                                '($currentServerName serving)', // Explicit serving text
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11), // Smaller font
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        // Team 2 Score
                        Text(
                          '$_team2Score',
                          style: const TextStyle(
                            fontSize: 90, // Further adjusted score font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Team 2 Sets (Optional: could be moved to center or a summary)
                        Text(
                          'Sets: $_team2Sets',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Point Increment Buttons (at the bottom)
          Expanded(
            flex: 1, // Give less flex to the buttons area
            child: Container(
              color: Colors.blue.shade900,
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _incrementTeam1Score,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12), // Reduced padding
                      ),
                      child: Text(
                        '${widget.team1Players.firstOrNull ?? 'Team 1'}\n+1',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold), // Smaller font
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Decrement buttons moved here for compactness
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.18, // Match central column width
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _decrementTeam1Score,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0), // No horizontal padding
                              minimumSize: const Size(30, 0), // Min size to fit
                            ),
                            child:
                                const Text('-', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _decrementTeam2Score,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0), // No horizontal padding
                              minimumSize: const Size(30, 0),
                            ),
                            child:
                                const Text('-', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _incrementTeam2Score,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '${widget.team2Players.firstOrNull ?? 'Team 2'}\n+1',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Set History
          Container(
            color: Colors.blue.shade900,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Column(
              children: [
                if (_setScores.isNotEmpty)
                  Column(
                    children: [
                      const Text(
                        'Set History:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 1.0,
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
                                  fontSize: 10),
                            ),
                            backgroundColor: Colors.blue.shade600,
                            elevation: 0.5,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
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
