import 'dart:async';
import 'package:flutter/material.dart';

class FootballScoringScreen extends StatefulWidget {
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Name;
  final String team2Name;

  const FootballScoringScreen({
    super.key,
    required this.team1Players,
    required this.team2Players,
    this.team1Name = 'HOME',
    this.team2Name = 'AWAY',
  });

  @override
  State<FootballScoringScreen> createState() => _FootballScoringScreenState();
}

class _FootballScoringScreenState extends State<FootballScoringScreen>
    with SingleTickerProviderStateMixin {
  int _team1Goals = 0;
  int _team2Goals = 0;
  int _matchDuration = 45; // in minutes
  int _secondsRemaining = 0;
  bool _isTimerRunning = false;
  Timer? _matchTimer;

  List<String> _team1GoalScorers = [];
  List<String> _team2GoalScorers = [];

  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  final Color darkBlue = const Color(0xFF1C2541);
  final Color cardBlue = const Color(0xFF3A506B);
  final Color tealAccent = const Color(0xFF5BC0BE);
  final Color lightText = const Color(0xFFEFF6EE);
  final Color danger = const Color(0xFFFC7753);

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scoreAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
          parent: _scoreAnimationController, curve: Curves.easeOutBack),
    );

    if (widget.team1Players.isEmpty) _addDefaultPlayers(1);
    if (widget.team2Players.isEmpty) _addDefaultPlayers(2);
  }

  void _addDefaultPlayers(int teamId) {
    if (teamId == 1) {
      widget.team1Players.addAll(['Player 1', 'Player 2']);
    } else {
      widget.team2Players.addAll(['Player A', 'Player B']);
    }
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = _matchDuration * 60;
      _isTimerRunning = true;
    });
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerRunning = false;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _incrementGoal(int teamId) async {
    final players = teamId == 1 ? widget.team1Players : widget.team2Players;
    final scorer = await _selectScorerDialog(players, teamId);
    if (scorer != null) {
      setState(() {
        if (teamId == 1) {
          _team1Goals++;
          _team1GoalScorers.add(
              "$scorer - ${_formatTime((_matchDuration * 60) - _secondsRemaining)}");
        } else {
          _team2Goals++;
          _team2GoalScorers.add(
              "$scorer - ${_formatTime((_matchDuration * 60) - _secondsRemaining)}");
        }
      });
      _scoreAnimationController.forward(from: 0.0);
    }
  }

  void _decrementGoal(int teamId) {
    setState(() {
      if (teamId == 1 && _team1Goals > 0) {
        _team1Goals--;
        _team1GoalScorers.removeLast();
      } else if (teamId == 2 && _team2Goals > 0) {
        _team2Goals--;
        _team2GoalScorers.removeLast();
      }
    });
    _scoreAnimationController.forward(from: 0.0);
  }

  Future<String?> _selectScorerDialog(List<String> players, int teamId) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
            'Who scored for ${teamId == 1 ? widget.team1Name : widget.team2Name}?'),
        backgroundColor: cardBlue,
        titleTextStyle: TextStyle(
            color: tealAccent, fontWeight: FontWeight.bold, fontSize: 18),
        children: players
            .map(
              (player) => SimpleDialogOption(
                child: Text(player, style: TextStyle(color: lightText)),
                onPressed: () => Navigator.pop(context, player),
              ),
            )
            .toList(),
      ),
    );
  }

  void _resetMatch() {
    _matchTimer?.cancel();
    setState(() {
      _team1Goals = 0;
      _team2Goals = 0;
      _team1GoalScorers.clear();
      _team2GoalScorers.clear();
      _isTimerRunning = false;
      _secondsRemaining = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Match reset!"),
      backgroundColor: danger,
    ));
  }

  Widget _teamScoreDisplay(String name, int score) {
    return Column(
      children: [
        Text(name,
            style: TextStyle(
                color: lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
        const SizedBox(height: 6),
        Text('$score',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: tealAccent,
                shadows: [
                  Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(2, 3))
                ])),
      ],
    );
  }

  Widget _floatingGoalButtons(int teamId) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: 'add_$teamId',
          onPressed: () => _incrementGoal(teamId),
          backgroundColor: tealAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'remove_$teamId',
          onPressed: () => _decrementGoal(teamId),
          backgroundColor: danger,
          child: const Icon(Icons.remove, color: Colors.white),
        ),
      ],
    );
  }

  Widget _goalTimeline(List<String> scorers) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBlue.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Match Events",
                style: TextStyle(
                    color: tealAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: scorers.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white24),
                itemBuilder: (context, index) {
                  final entry = scorers[index];
                  return Row(
                    children: [
                      const Icon(Icons.sports_soccer,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry,
                            style: TextStyle(
                                color: lightText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: const Text('Football Scoring',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetMatch),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: lightText),
                    decoration: InputDecoration(
                      labelText: 'Half Duration (min)',
                      labelStyle: TextStyle(color: tealAccent),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: tealAccent),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final input = int.tryParse(val);
                      if (input != null && input > 0) {
                        _matchDuration = input;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isTimerRunning ? null : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Start Timer"),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _isTimerRunning
                  ? "Time Remaining: ${_formatTime(_secondsRemaining)}"
                  : "Timer Not Started",
              style: TextStyle(color: lightText, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _teamScoreDisplay(widget.team1Name, _team1Goals),
                  const Text("vs",
                      style: TextStyle(fontSize: 20, color: Colors.white70)),
                  _teamScoreDisplay(widget.team2Name, _team2Goals),
                ],
              ),
            ),
            Row(
              children: [
                _floatingGoalButtons(1),
                const Spacer(),
                _floatingGoalButtons(2),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  _goalTimeline(_team1GoalScorers),
                  _goalTimeline(_team2GoalScorers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
