import 'package:flutter/material.dart';

class PlayersPage extends StatelessWidget {
  final String teamName;
  const PlayersPage({super.key, required this.teamName});

  // Define custom colors based on the provided theme
  static const Color primaryBlue = Color(0xFF1A0F49); // Darker purplish-blue
  static const Color accentOrange = Color(0xFFF26C4F); // Orange
  static const Color lightBlue = Color(0xFF3F277B); // Lighter purplish-blue

  @override
  Widget build(BuildContext context) {
    final mockPlayers = [
      {'name': 'Alice', 'role': 'Batsman'},
      {'name': 'Bob', 'role': 'Bowler'},
      {'name': 'Charlie', 'role': 'All-Rounder'},
    ];

    return Scaffold(
      backgroundColor: primaryBlue, // Set scaffold background
      appBar: AppBar(
        backgroundColor: lightBlue, // Set app bar to lightBlue
        title: Text(
          '$teamName - Players',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockPlayers.length,
        itemBuilder: (context, index) {
          final player = mockPlayers[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: lightBlue.withOpacity(0.7), // Card background with opacity
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    accentOrange, // Accent orange for avatar background
                child: Text(
                  player['name']![0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                player['name']!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white), // Text color
              ),
              subtitle: Text(player['role']!,
                  style: const TextStyle(
                      color: Colors.white70)), // Subtitle text color
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color: accentOrange), // Accent orange for trailing icon
              onTap: () {
                // Optional: Show more player details in the future
              },
            ),
          );
        },
      ),
    );
  }
}
