import 'package:flutter/material.dart';

class PlayerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerDetailsPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final sports = (player['sports'] as List<dynamic>? ?? []).cast<String>();
    final hasPickleball = sports.contains('Pickleball');

    return Scaffold(
      appBar: AppBar(
        title: Text(player['name']),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 36),
              _buildSectionTitle('Sports'),
              const SizedBox(height: 12),
              _buildSportsChips(sports),
              const SizedBox(height: 36),
              _buildSectionTitle('Player Statistics'),
              const SizedBox(height: 16),
              _buildPlayerStats(hasPickleball),
              const SizedBox(height: 36),
              _buildSectionTitle('Performance Summary'),
              const SizedBox(height: 12),
              _buildPerformanceSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Card(
        elevation: 8,
        shadowColor: Colors.blue.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.blue.shade200,
                backgroundImage: player['photoUrl'] != null
                    ? NetworkImage(player['photoUrl'])
                    : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 20),
              Text(
                player['name'],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSportsChips(List<String> sports) {
    if (sports.isEmpty) {
      return const Text('No sports information available.',
          style: TextStyle(fontSize: 16, color: Colors.black54));
    }
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: sports
          .map(
            (sport) => Chip(
              label: Text(
                sport,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                  fontSize: 16,
                ),
              ),
              avatar: _sportIcon(sport),
              backgroundColor: Colors.blue.shade50,
              elevation: 4,
              shadowColor: Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _sportIcon(String sport) {
    IconData iconData;
    switch (sport.toLowerCase()) {
      case 'cricket':
        iconData = Icons.sports_cricket;
        break;
      case 'football':
        iconData = Icons.sports_soccer;
        break;
      case 'pickleball':
        iconData = Icons.sports_tennis;
        break;
      default:
        iconData = Icons.sports;
    }
    return Icon(iconData, color: Colors.blueAccent, size: 22);
  }

  Widget _buildPlayerStats(bool hasPickleball) {
    final tournaments =
        (player['tournaments'] as List<dynamic>? ?? []).cast<String>();
    final totalMatches = player['totalMatches'] ?? 0;

    List<Widget> statsWidgets = [
      _buildStatRow(
          'Tournaments Played',
          tournaments.isEmpty ? 'N/A' : tournaments.join(', '),
          Icons.emoji_events),
      _buildStatRow(
          'Total Matches', totalMatches.toString(), Icons.sports_score),
    ];

    if (hasPickleball) {
      final pickleballAces = player['pickleballAces'] ?? 0;
      final pickleballWins = player['pickleballWins'] ?? 0;
      statsWidgets.addAll([
        _buildStatRow('Aces', pickleballAces.toString(), Icons.flash_on),
        _buildStatRow('Wins', pickleballWins.toString(), Icons.emoji_events),
      ]);
    } else {
      final totalRuns = player['totalRuns'] ?? 0;
      final goals = player['goals'] ?? 0;

      if (totalRuns > 0) {
        statsWidgets.add(_buildStatRow(
            'Total Runs', totalRuns.toString(), Icons.run_circle));
      }
      if (goals > 0) {
        statsWidgets.add(_buildStatRow(
            'Total Goals', goals.toString(), Icons.sports_soccer));
      }
    }

    return Card(
      elevation: 6,
      shadowColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statsWidgets,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 28),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.black54,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        'Detailed stats, charts, highlights, or other insights about the player’s performance can be shown here to give a comprehensive view of their achievements and progress over time.',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 17,
          height: 1.4,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
