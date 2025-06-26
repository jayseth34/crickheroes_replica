import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Keep this import as you included it
import 'racquetscoring.dart'; // Import the scoring screen

// NOTE: The main() function and ChangeNotifierProvider are assumed to be in your actual main.dart,
// wrapping the MyApp and consequently this RacquetSportApp.
// Therefore, this file does not include main() or its own MaterialApp.

// Enum to represent the type of match (singles or doubles).
// Moved to a top-level definition to be accessible.
enum MatchType { singles, doubles }

class RacquetSportApp extends StatelessWidget {
  const RacquetSportApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Since RacquetSportApp is now the widget provided by main.dart,
    // its build method should return the initial screen of this "app" module.
    return const NewMatchSetupScreen();
  }
}

// The screen for setting up a new match (singles or doubles).
class NewMatchSetupScreen extends StatefulWidget {
  const NewMatchSetupScreen({super.key});

  @override
  State<NewMatchSetupScreen> createState() => _NewMatchSetupScreenState();
}

class _NewMatchSetupScreenState extends State<NewMatchSetupScreen> {
  // MatchType _selectedMatchType = MatchType.singles; // Default match type is singles.
  // Now using the globally defined MatchType enum
  MatchType _selectedMatchType =
      MatchType.singles; // Default match type is singles.

  // Text controllers for capturing player names for both singles and doubles.
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  final TextEditingController _team1PlayerAController = TextEditingController();
  final TextEditingController _team1PlayerBController = TextEditingController();
  final TextEditingController _team2PlayerXController = TextEditingController();
  final TextEditingController _team2PlayerYController = TextEditingController();

  @override
  void dispose() {
    // Dispose of all text editing controllers to free up resources
    // when the widget is removed from the widget tree.
    _player1Controller.dispose();
    _player2Controller.dispose();
    _team1PlayerAController.dispose();
    _team1PlayerBController.dispose();
    _team2PlayerXController.dispose();
    _team2PlayerYController.dispose();
    super.dispose();
  }

  // Function to prepare player names and navigate to the scoring screen.
  void _startMatch() {
    // Initialize lists for team players
    List<String> team1Players = [];
    List<String> team2Players = [];

    // Populate teamPlayers based on the selected match type.
    // If a text field is empty, a default name is used.
    if (_selectedMatchType == MatchType.singles) {
      team1Players.add(_player1Controller.text.trim().isEmpty
          ? 'Player 1'
          : _player1Controller.text.trim());
      team2Players.add(_player2Controller.text.trim().isEmpty
          ? 'Player 2'
          : _player2Controller.text.trim());
    } else {
      // Doubles match
      team1Players.add(_team1PlayerAController.text.trim().isEmpty
          ? 'Team 1 Player A'
          : _team1PlayerAController.text.trim());
      team1Players.add(_team1PlayerBController.text.trim().isEmpty
          ? 'Team 1 Player B'
          : _team1PlayerBController.text.trim());
      team2Players.add(_team2PlayerXController.text.trim().isEmpty
          ? 'Team 2 Player X'
          : _team2PlayerXController.text.trim());
      team2Players.add(_team2PlayerYController.text.trim().isEmpty
          ? 'Team 2 Player Y'
          : _team2PlayerYController.text.trim());
    }

    // Navigate to the RacquetScoringScreen, passing the collected team player names.
    Navigator.push(
      context,
      MaterialPageRoute(
        // Now passing team1Players and team2Players as expected by RacquetScoringScreen
        builder: (context) => RacquetScoringScreen(
            team1Players: team1Players, team2Players: team2Players),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('New Match Setup'), // AppBar title for the setup screen.
        elevation: 0, // Removes the shadow under the AppBar for a cleaner look.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the main content.
        child: SingleChildScrollView(
          // Allows content to scroll if it overflows.
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretches children horizontally.
            children: <Widget>[
              // Section for selecting match type (Singles/Doubles).
              Card(
                elevation: 4, // Adds a subtle shadow to the card.
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        15)), // Rounded corners for the card.
                child: Padding(
                  padding:
                      const EdgeInsets.all(20.0), // Inner padding for the card.
                  child: Column(
                    children: [
                      const Text(
                        'Select Match Type:',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20), // Vertical space.
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceAround, // Distributes space evenly.
                        children: <Widget>[
                          // Singles button.
                          _buildMatchSelectionButton(
                            context,
                            MatchType.singles,
                            Icons.person,
                            'Singles (1 vs 1)',
                          ),
                          // Doubles button.
                          _buildMatchSelectionButton(
                            context,
                            MatchType.doubles,
                            Icons.group,
                            'Doubles (2 vs 2)',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30), // Vertical space.

              // Section for entering player names, conditionally displayed based on match type.
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        _selectedMatchType == MatchType.singles
                            ? 'Enter Player Names (Singles):'
                            : 'Enter Team Names (Doubles):', // Dynamic title.
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Renders singles or doubles input fields.
                      _selectedMatchType == MatchType.singles
                          ? _buildSinglesPlayerInput()
                          : _buildDoublesPlayerInput(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30), // Vertical space.

              // "Start Match" button.
              ElevatedButton.icon(
                onPressed:
                    _startMatch, // Calls the _startMatch function on press.
                icon: const Icon(Icons.play_arrow, size: 28), // Play icon.
                label: const Text(
                  'Start Match',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // Text/icon color.
                  backgroundColor: Colors.green.shade600, // Background color.
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30), // Pill-shaped button.
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15), // Button padding.
                  elevation:
                      8, // Increased elevation for a more prominent button.
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the match type selection buttons.
  Widget _buildMatchSelectionButton(
      BuildContext context, MatchType matchType, IconData icon, String label) {
    bool isSelected = _selectedMatchType ==
        matchType; // Check if this button is currently selected.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8.0), // Horizontal padding for separation.
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMatchType =
                  matchType; // Update selected match type on tap.
            });
          },
          borderRadius: BorderRadius.circular(
              15), // Rounded corners for InkWell's ripple effect.
          child: AnimatedContainer(
            duration: const Duration(
                milliseconds:
                    300), // Animation duration for smooth transitions.
            curve: Curves.easeInOut, // Animation curve.
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.shade600
                  : Colors.blue.shade100, // Color changes based on selection.
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                // Shadow effect.
                BoxShadow(
                  color: isSelected
                      ? Colors.blue.shade800.withOpacity(0.4)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                // Border color and width change based on selection.
                color: isSelected ? Colors.blue.shade800 : Colors.blue.shade200,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? Colors.white
                      : Colors.blue.shade700, // Icon color changes.
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.blue.shade900, // Text color changes.
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build input fields for singles match.
  Widget _buildSinglesPlayerInput() {
    return Column(
      children: <Widget>[
        _buildPlayerInputField(
            _player1Controller, 'Player 1 Name', 'Player 1', Icons.person),
        const SizedBox(height: 20),
        _buildPlayerInputField(
            _player2Controller, 'Player 2 Name', 'Player 2', Icons.person),
      ],
    );
  }

  // Helper widget to build input fields for doubles match.
  Widget _buildDoublesPlayerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start.
      children: <Widget>[
        const Text(
          'Team 1 Player Names:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 10),
        _buildPlayerInputField(_team1PlayerAController, 'Team 1 Player A Name',
            'Team 1 Player A', Icons.person),
        const SizedBox(height: 20),
        _buildPlayerInputField(_team1PlayerBController, 'Team 1 Player B Name',
            'Team 1 Player B', Icons.person),
        const SizedBox(height: 30),
        const Text(
          'Team 2 Player Names:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 10),
        _buildPlayerInputField(_team2PlayerXController, 'Team 2 Player X Name',
            'Team 2 Player X', Icons.person),
        const SizedBox(height: 20),
        _buildPlayerInputField(_team2PlayerYController, 'Team 2 Player Y Name',
            'Team 2 Player Y', Icons.person),
      ],
    );
  }

  // Reusable widget to create a consistent player name input text field.
  Widget _buildPlayerInputField(TextEditingController controller,
      String labelText, String hintText, IconData icon) {
    return TextField(
      controller: controller, // Assign the controller to the text field.
      decoration: InputDecoration(
        labelText: labelText, // Label above the input.
        hintText: hintText, // Placeholder text.
        prefixIcon:
            Icon(icon, color: Colors.blueGrey), // Icon inside the input field.
        border: OutlineInputBorder(
          // Outline border.
          borderRadius:
              BorderRadius.circular(10), // Rounded corners for the input field.
          borderSide: BorderSide
              .none, // No visible border line, using filled background instead.
        ),
        filled: true, // Enable background fill.
        fillColor: Colors.blue.shade50, // Light blue background for the input.
        contentPadding: const EdgeInsets.symmetric(
            vertical: 15, horizontal: 20), // Padding inside the input.
      ),
      style: const TextStyle(fontSize: 16), // Text style for input.
      textCapitalization: TextCapitalization
          .words, // Capitalizes the first letter of each word.
    );
  }
}
