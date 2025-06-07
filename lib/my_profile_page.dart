import 'package:flutter/material.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  final Map<String, dynamic> _userProfile = const {
    'name': 'John Doe',
    'photoUrl': null,
    'sports': ['Cricket', 'Football', 'Pickleball'],
    'tournaments': [
      {'name': 'Cricket Premier League', 'date': 'May 10 - June 15'},
      {'name': 'Football Cup 2025', 'date': 'June 1 - July 10'},
      {'name': 'Pickleball Masters', 'date': 'May 20 - June 5'},
    ],
    'totalMatches': 45,
    'totalRuns': 1234,
    'goals': 18,
  };

  @override
  Widget build(BuildContext context) {
    final user = _userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 65,
              backgroundImage: user['photoUrl'] != null
                  ? NetworkImage(user['photoUrl'])
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            Text(
              user['name'],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: List<Widget>.from(
                user['sports'].map(
                  (sport) => Chip(
                    label: Text(sport),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Tournaments Section
            _sectionTitle('Tournaments Played'),
            const SizedBox(height: 10),
            _buildTournamentList(user['tournaments']),

            const SizedBox(height: 30),

            const SizedBox(height: 30),

            // Performance Summary with basic visual mockup
            _sectionTitle('Performance Summary'),
            const SizedBox(height: 14),
            _buildPerformanceBarChart(user),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildTournamentList(List<dynamic> tournaments) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: tournaments
            .map(
              (t) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  t['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  t['date'],
                  style: const TextStyle(color: Colors.grey),
                ),
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBarChart(Map<String, dynamic> user) {
    final performance = {
      'Matches': user['totalMatches'].toDouble(),
      'Runs': user['totalRuns'].toDouble(),
      'Goals': user['goals'].toDouble(),
    };

    final maxValue = performance.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: performance.entries.map((entry) {
        final value = entry.value;
        final percentage = (value / maxValue) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: percentage.isNaN ? 0 : percentage,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(value.toInt().toString()),
            ],
          ),
        );
      }).toList(),
    );
  }
}
