import 'package:flutter/material.dart';

class PlayersPage extends StatelessWidget {
  final String teamName;
  const PlayersPage({super.key, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final mockPlayers = [
      {'name': 'Alice', 'role': 'Batsman'},
      {'name': 'Bob', 'role': 'Bowler'},
      {'name': 'Charlie', 'role': 'All-Rounder'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurpleAccent,
                child: Text(
                  player['name']![0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                player['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(player['role']!),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
